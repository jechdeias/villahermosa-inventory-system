-- Villahermosa Inventory System — add missing orders columns
-- YOU run this manually in the Supabase SQL Editor. Written against the
-- real local Drift schema (lib/core/database/tables/orders_table.dart),
-- not the simplified column list in the task that requested this file —
-- that list didn't match the actual schema (no orderId/storeId/orderDate
-- fields exist; the real fields are orderNumber, deliveryAddress,
-- subtotal, taxAmount, paymentStatus, warehouseStatus, priority, the
-- picker/packer workflow fields, etc.). Verified against the real
-- Supabase orders schema pasted earlier in this session (id, customer_id,
-- status, total_amount, notes, is_deleted, sync_status, created_at,
-- updated_at — 9 columns vs. Drift's 30).
--
-- customer_notes (Drift) intentionally maps to the EXISTING `notes` column
-- below, not a new column — Supabase already has one and Drift has no
-- other "notes"-like field to justify a second column.
--
-- All ADD COLUMN IF NOT EXISTS — safe to run even if some of these already
-- exist; never touches existing data.

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS uuid text,
  ADD COLUMN IF NOT EXISTS order_number text,
  ADD COLUMN IF NOT EXISTS delivery_address text,
  ADD COLUMN IF NOT EXISTS subtotal numeric(10, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tax_amount numeric(10, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS payment_status text DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS warehouse_status text DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS priority text DEFAULT 'normal',
  ADD COLUMN IF NOT EXISTS picker_id text,
  ADD COLUMN IF NOT EXISTS picked_at timestamp with time zone,
  ADD COLUMN IF NOT EXISTS packer_id text,
  ADD COLUMN IF NOT EXISTS packed_at timestamp with time zone,
  ADD COLUMN IF NOT EXISTS expected_delivery_date timestamp with time zone,
  ADD COLUMN IF NOT EXISTS actual_delivery_date timestamp with time zone,
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS store_name text,
  ADD COLUMN IF NOT EXISTS route_id bigint,
  ADD COLUMN IF NOT EXISTS route_name text,
  ADD COLUMN IF NOT EXISTS sales_rep_id bigint,
  ADD COLUMN IF NOT EXISTS sales_rep_name text,
  ADD COLUMN IF NOT EXISTS item_count integer DEFAULT 0;
