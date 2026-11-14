-- Villahermosa Inventory System — audit before dropping dead columns
-- READ-ONLY. Changes nothing. Run this in the Supabase SQL Editor BEFORE
-- running drop_dead_columns.sql.
--
-- "No live code reads it" is not the same as "no data in it". This is a
-- deployed system with real orders, suppliers and stock history, and some of
-- these columns may hold values a person actually typed in — supplier TINs,
-- unit costs, tax amounts. DROP COLUMN deletes them permanently.
--
-- This script counts, for every column drop_dead_columns.sql would drop, how
-- many rows hold something other than null/empty/the default. Anything that
-- comes back with rows_with_data = 0 is genuinely empty and safe to drop.
-- Anything above 0 is real data: export that column before dropping it, or
-- leave the column alone.
--
-- Columns that don't exist on this project are skipped silently. A column
-- whose type doesn't match the check is reported as 'CHECK MANUALLY' rather
-- than failing the script.

DROP TABLE IF EXISTS _col_audit;
CREATE TEMP TABLE _col_audit (
  tbl             text,
  col             text,
  rows_with_data  bigint,
  note            text
);

DO $$
DECLARE
  r      record;
  n      bigint;
  total  bigint;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      -- table            column                 "has real data" test
      ('order_items',     'delivered_quantity',  'delivered_quantity IS NOT NULL AND delivered_quantity <> 0'),
      ('order_items',     'discount_amount',     'discount_amount IS NOT NULL AND discount_amount <> 0'),
      ('order_items',     'available_stock',     'available_stock IS NOT NULL AND available_stock <> 0'),
      ('order_items',     'stock_status',        'stock_status IS NOT NULL AND stock_status <> ''available'''),
      ('order_items',     'picker_id',           'picker_id IS NOT NULL AND picker_id <> '''''),
      ('order_items',     'notes',               'notes IS NOT NULL AND notes <> '''''),
      ('order_items',     'is_active',           'is_active IS NOT NULL AND is_active = false'),
      ('order_items',     'remote_id',           'remote_id IS NOT NULL AND remote_id <> '''''),

      ('users',           'address',             'address IS NOT NULL AND address <> '''''),
      ('users',           'remote_id',           'remote_id IS NOT NULL AND remote_id <> '''''),

      ('products',        'remote_id',           'remote_id IS NOT NULL AND remote_id <> '''''),

      ('customers',       'is_active',           'is_active IS NOT NULL AND is_active = false'),
      ('customers',       'remote_id',           'remote_id IS NOT NULL AND remote_id <> '''''),

      ('suppliers',       'address1',            'address1 IS NOT NULL AND address1 <> '''''),
      ('suppliers',       'address2',            'address2 IS NOT NULL AND address2 <> '''''),
      ('suppliers',       'tin',                 'tin IS NOT NULL AND tin <> '''''),
      -- not dropped, but shown so you can answer the pre-flight question:
      ('suppliers',       'supplier_code',       'supplier_code IS NOT NULL AND supplier_code <> '''''),

      ('orders',          'tax_amount',          'tax_amount IS NOT NULL AND tax_amount <> 0'),
      ('orders',          'payment_status',      'payment_status IS NOT NULL AND payment_status <> ''pending'''),
      ('orders',          'priority',            'priority IS NOT NULL AND priority <> ''normal'''),
      ('orders',          'picker_id',           'picker_id IS NOT NULL AND picker_id <> '''''),
      ('orders',          'picked_at',           'picked_at IS NOT NULL'),
      ('orders',          'packer_id',           'packer_id IS NOT NULL AND packer_id <> '''''),
      ('orders',          'is_active',           'is_active IS NOT NULL AND is_active = false'),

      ('stock_movements', 'unit_cost',           'unit_cost IS NOT NULL AND unit_cost <> 0'),
      ('stock_movements', 'total_cost',          'total_cost IS NOT NULL AND total_cost <> 0'),
      ('stock_movements', 'from_location',       'from_location IS NOT NULL AND from_location <> '''''),
      ('stock_movements', 'to_location',         'to_location IS NOT NULL AND to_location <> '''''),
      ('stock_movements', 'reference_type',      'reference_type IS NOT NULL AND reference_type <> '''''),
      ('stock_movements', 'status',              'status IS NOT NULL AND status <> ''completed'''),
      ('stock_movements', 'is_active',           'is_active IS NOT NULL AND is_active = false'),
      ('stock_movements', 'remote_id',           'remote_id IS NOT NULL AND remote_id <> ''''')
    ) AS t(tbl, col, cond)
  LOOP
    -- skip columns this project doesn't have
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name   = r.tbl
        AND column_name  = r.col
    ) THEN
      CONTINUE;
    END IF;

    BEGIN
      EXECUTE format('SELECT count(*) FROM public.%I WHERE %s', r.tbl, r.cond) INTO n;
      EXECUTE format('SELECT count(*) FROM public.%I', r.tbl) INTO total;
      INSERT INTO _col_audit VALUES (
        r.tbl, r.col, n,
        CASE
          WHEN n = 0 THEN 'empty — safe to drop'
          ELSE 'HAS DATA — export or keep (' || n || ' of ' || total || ' rows)'
        END
      );
    EXCEPTION WHEN others THEN
      INSERT INTO _col_audit VALUES (r.tbl, r.col, NULL, 'CHECK MANUALLY: ' || SQLERRM);
    END;
  END LOOP;
END $$;

-- Everything, worst first.
SELECT tbl, col, rows_with_data, note
FROM _col_audit
ORDER BY (rows_with_data IS NULL) DESC, rows_with_data DESC NULLS FIRST, tbl, col;


-- ============================================================================
-- The suppliers pre-flight from drop_dead_columns.sql, repeated here
-- ============================================================================
-- If this returns 0, supplier_code is never used as a uuid fallback and you
-- may add it to the suppliers DROP list. If above 0, leave supplier_code
-- alone or backfill the missing uuids first.
SELECT count(*) AS suppliers_missing_uuid
FROM public.suppliers
WHERE uuid IS NULL;
