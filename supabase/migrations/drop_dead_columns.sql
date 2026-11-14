-- Villahermosa Inventory System — drop dead columns from Supabase
-- YOU run this manually in the Supabase SQL Editor.
--
-- Brings Supabase in line with the local Drift schema after the v12/v13/v14
-- cleanups (commits 1c58b7c, e0234a0, 5a9d178 + fb07a3d). Every column below
-- was already removed locally because no live code reads it.
--
-- ⚠️  DROP COLUMN IS IRREVERSIBLE AND DELETES THE DATA IN THAT COLUMN.
--     Take a backup first: Database → Backups, or pg_dump.
--
-- Verified before writing this file:
--   • No client push map sends any of these columns (sync_engine.dart).
--   • No pull branch reads any of these columns, EXCEPT suppliers.supplier_code
--     — see the PRE-FLIGHT section below; that column is deliberately NOT dropped.
--   • privileged-sync Edge Function passes the client payload straight through
--     (`.upsert({...data})`), so it sends nothing extra of its own.
--   • supabase/rls_policies.sql references none of them.
--
-- IF EXISTS on every drop — safe to re-run, and safe if a column was never
-- created on this project in the first place.


-- ============================================================================
-- PRE-FLIGHT — run this FIRST, on its own, before anything below
-- ============================================================================
-- suppliers.supplier_code is NOT dead on the Supabase side: the suppliers pull
-- branch (sync_engine.dart ~line 2084/2219) uses it as a fallback to build a
-- stable local uuid for any supplier row whose `uuid` is null:
--
--     data['uuid'] ?? 'sup-${data['supplier_code'] ?? data['id']}'
--
-- Dropping it while such rows exist changes the generated uuid, which creates
-- DUPLICATE local supplier rows on the next pull. So it stays, unless this
-- returns 0:
--
--     SELECT count(*) FROM public.suppliers WHERE uuid IS NULL;
--
-- If it returns 0, every supplier already has a real uuid, the fallback never
-- fires, and you can safely add this to the suppliers section below:
--     DROP COLUMN IF EXISTS supplier_code,
-- If it returns more than 0, backfill those uuids first, or just leave the
-- column — one extra text column is cheaper than a duplicate-supplier mess.


-- ============================================================================
-- ORDER_ITEMS — 8 columns (dropped locally in v12, commit 1c58b7c)
-- ============================================================================
-- NOTE: this drops order_items.notes. It is NOT the same column as orders.notes,
-- which is live and holds customerNotes (incl. the delivery-method line written
-- by markOrderDelivered). orders.notes is untouched by this whole file.
ALTER TABLE public.order_items
  DROP COLUMN IF EXISTS delivered_quantity,
  DROP COLUMN IF EXISTS discount_amount,
  DROP COLUMN IF EXISTS available_stock,
  DROP COLUMN IF EXISTS stock_status,
  DROP COLUMN IF EXISTS picker_id,
  DROP COLUMN IF EXISTS notes,
  DROP COLUMN IF EXISTS is_active,
  DROP COLUMN IF EXISTS remote_id;


-- ============================================================================
-- USERS — 2 columns (dropped locally in v13, commit e0234a0)
-- ============================================================================
-- users.is_active is LIVE — kept. Only these two go.
ALTER TABLE public.users
  DROP COLUMN IF EXISTS address,
  DROP COLUMN IF EXISTS remote_id;


-- ============================================================================
-- PRODUCTS — 1 column (dropped locally in v13, commit e0234a0)
-- ============================================================================
-- products.is_active is LIVE (customer product browsing filters on it) — kept.
ALTER TABLE public.products
  DROP COLUMN IF EXISTS remote_id;


-- ============================================================================
-- CUSTOMERS — 2 columns (dropped locally in v13, commit e0234a0)
-- ============================================================================
-- customers.address IS live (the customers pull reads it) — kept.
ALTER TABLE public.customers
  DROP COLUMN IF EXISTS is_active,
  DROP COLUMN IF EXISTS remote_id;


-- ============================================================================
-- SUPPLIERS — 3 columns (dropped locally in v13, commit e0234a0)
-- ============================================================================
-- supplier_code intentionally omitted — see PRE-FLIGHT above.
ALTER TABLE public.suppliers
  DROP COLUMN IF EXISTS address1,
  DROP COLUMN IF EXISTS address2,
  DROP COLUMN IF EXISTS tin;


-- ============================================================================
-- ORDERS — 7 columns (dropped locally in v14, commits 5a9d178 + fb07a3d)
-- ============================================================================
-- payment_status goes because the payments table owns payment state
-- (createPayment in new_order_flow) — nothing is lost.
-- picker_id/picked_at/packer_id were only touched by the zero-caller
-- warehouse_providers.dart. order_items.picked_at is a DIFFERENT column and is
-- live (per-item picking) — it is dropped above only as order_items.picker_id,
-- not picked_at. Check the order_items section: picked_at is NOT in it.
ALTER TABLE public.orders
  DROP COLUMN IF EXISTS tax_amount,
  DROP COLUMN IF EXISTS payment_status,
  DROP COLUMN IF EXISTS priority,
  DROP COLUMN IF EXISTS picker_id,
  DROP COLUMN IF EXISTS picked_at,
  DROP COLUMN IF EXISTS packer_id,
  DROP COLUMN IF EXISTS is_active;


-- ============================================================================
-- STOCK_MOVEMENTS — 8 columns (dropped locally in v14, commits 5a9d178 + fb07a3d)
-- ============================================================================
-- All eight existed only for the deleted lib/core/business/stock_movement_service.dart,
-- which had zero callers. The live writer is adjustProductStock, which touches
-- none of them.
ALTER TABLE public.stock_movements
  DROP COLUMN IF EXISTS unit_cost,
  DROP COLUMN IF EXISTS total_cost,
  DROP COLUMN IF EXISTS from_location,
  DROP COLUMN IF EXISTS to_location,
  DROP COLUMN IF EXISTS reference_type,
  DROP COLUMN IF EXISTS status,
  DROP COLUMN IF EXISTS is_active,
  DROP COLUMN IF EXISTS remote_id;


-- ============================================================================
-- NOT INCLUDED HERE — deliberate
-- ============================================================================
-- 1. public.deliveries (whole table). Zero rows, no writer anywhere: the app
--    never creates a delivery (createDelivery has no callers), and the project
--    has no database functions or triggers. It is pull-only and always pulls
--    empty. Dropping it means also removing the Drift table, its pull
--    registration and its generated code — a code change, not just SQL, so it
--    gets its own commit.
--
-- 2. orders.route_id / orders.sales_rep_id type change (bigint → text).
--    These are how an order is assigned to a delivery rep. The admin picker
--    already passes user.uuid and route.uuid (text), but both columns are
--    bigint on both sides, so the assignment feature does not currently
--    compile. Fixing it properly means switching both columns to text/uuid —
--    which also fixes rep matching, currently done by NAME STRING
--    (watchOrdersBySalesRep). That needs the Dart side changed first; the
--    matching SQL will follow in that commit. Do not change these types yet.
