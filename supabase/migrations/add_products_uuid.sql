-- add_products_uuid.sql
--
-- WHY THIS EXISTS
-- ---------------
-- Commit f90d42c (Nov 12 2026) changed the products push to:
--
--     data.remove('id');
--     .from('products').upsert(data, onConflict: 'uuid');
--
-- on the assumption that public.products had a `uuid` column. It does not.
-- Confirmed against information_schema on Nov 19 2026: the table has 17
-- columns and `uuid` is not among them. Every products push since Nov 12 has
-- therefore failed with:
--
--     PostgrestException(message: Could not find the 'uuid' column of
--     'products' in the schema cache, code: PGRST204)
--
-- Consequence, and it is bigger than the sync badge: no product stock change
-- has reached Supabase for a week. The push fails, the row stays 'pending',
-- and the next pull overwrites local current_stock with the server's stale
-- value. OrderStockService's dispatch deduction is stranded locally too.
--
-- PGRST204 is in SyncEngine.isPermanentPushError, so after 3 cycles those rows
-- are flagged sync_status = 'error' and surface as "N items could not sync".
--
-- NO APP CHANGE IS NEEDED. The client is already correct; the column is
-- missing. This file is the whole fix.
--
--
-- WHY uuid AND NOT A REVERT TO onConflict: 'id'
-- ---------------------------------------------
-- Reverting looks cheaper and is wrong. The products pull writes the remote id
-- as the local id, so id-parity holds for every PULLED product — but a product
-- the admin creates locally gets Drift's next autoincrement id, which can
-- already belong to a DIFFERENT row in Supabase. Upserting on id would then
-- silently overwrite that unrelated product. uuid is the stable identity, and
-- it is what customers, orders, order_items, deliveries and delivery_routes
-- already conflict on.
--
--
-- WHY THE BACKFILL VALUE IS 'sb-product-' || id
-- ---------------------------------------------
-- sync_engine.dart (products pull) invents a deterministic uuid when the
-- server sends none, which until now has been every single row:
--
--     uuid: Value(data['uuid'] as String? ?? 'sb-product-${data['id']}'),
--
-- So every pulled product already holds 'sb-product-<remote id>' locally.
-- Backfilling the same expression server-side makes the uuids agree, and the
-- upsert then MATCHES its row instead of inserting 325 duplicates.
--
--
-- RUN STEP 0 FIRST AND READ IT. Do not run steps 1-4 until it returns 0.
-- ======================================================================


-- STEP 0 (GATE) -- run this on a device, NOT here. Against the local SQLite DB
-- at C:\Users\jedey\Documents\villahermosa_inventory.db:
--
--     select count(*) from products where uuid is null or uuid = '';
--     select count(*) from products where uuid <> 'sb-product-' || id;
--
-- Both must be 0. If the second is non-zero, those rows' local uuids do NOT
-- follow the formula (they were created locally and never overwritten by a
-- pull), and the backfill below would give them a server uuid that no device
-- recognises -- the upsert would insert a duplicate instead of matching.
-- In that case list them and backfill those ids explicitly by value first.


-- STEP 1 -- add the column, nullable for now so the backfill can run.
alter table public.products
  add column if not exists uuid text;


-- STEP 2 -- backfill to the value every device already holds locally.
-- Deliberately does NOT touch updated_at: products is one of the five tables
-- the pull filters on `updated_at >= lastSyncTime`, and bumping it here would
-- re-pull all 325 rows and overwrite local current_stock with the stale server
-- value -- the exact harm this migration exists to stop.
update public.products
   set uuid = 'sb-product-' || id
 where uuid is null;


-- STEP 3 -- the unique index PostgREST needs for onConflict: 'uuid' to resolve
-- an arbiter. Without it the upsert still fails, with a different error.
create unique index if not exists products_uuid_key
    on public.products (uuid);

alter table public.products
  alter column uuid set not null;


-- STEP 4 -- PostgREST caches the schema; a new column is invisible until it
-- reloads. Without this the push keeps returning PGRST204 against a column
-- that now exists.
notify pgrst, 'reload schema';


-- VERIFY -- all three must hold.
select count(*)                             as total,
       count(uuid)                          as have_uuid,          -- = total
       count(*) - count(distinct uuid)      as duplicate_uuids,    -- = 0
       count(*) filter (where uuid <> 'sb-product-' || id) as off_formula  -- = 0
  from public.products;

select column_name, data_type, is_nullable
  from information_schema.columns
 where table_schema = 'public' and table_name = 'products' and column_name = 'uuid';


-- AFTER RUNNING
-- -------------
-- On each device: python check_stuck.py --reset   (clears the 'error' flags so
-- the 5 products are retried), then sync. They should go 'synced' on the first
-- cycle.
--
-- KNOWN, NOT FIXED BY THIS FILE: the 4 stock_movements rows (local ids 1-4)
-- fail for a different reason -- that push upserts on the PRIMARY KEY and
-- their local ids collide with different Supabase rows. That is the parked
-- stock_movements uuid work (backfill NULL uuids, UNIQUE index,
-- onConflict: 'uuid', plus a deterministic movement uuid so two devices
-- dispatching one order collide instead of double-deducting).
--
-- ALSO NOT FIXED BY THIS FILE: product stock values that have already diverged.
-- Only the 5 rows currently pending will push their local value up; the other
-- ~320 are 'synced' locally and keep whatever Supabase holds. Reconciling that
-- is a data decision, not a schema one -- decide which device is authoritative
-- before mass-marking rows pending.
