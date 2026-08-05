-- Villahermosa Inventory System — add missing columns: payments, stock_movements
-- YOU run this manually in the Supabase SQL Editor.
--
-- customers was NOT included here — it was already fixed in an earlier
-- commit (668d930) against a real data dump; no further changes needed.
--
-- All ADD COLUMN IF NOT EXISTS — safe to run even if some of these already
-- exist; never touches existing data.

-- ============================================================================
-- PAYMENTS
-- ============================================================================
-- Unlike orders/stock_movements, there's no real information_schema result
-- for payments anywhere in this session to verify against — only
-- confirmation the table itself exists. Every column below is written
-- against the local Drift schema (lib/core/database/tables/payments_table.dart)
-- instead of a verified diff. IF NOT EXISTS makes this safe regardless: any
-- column that turns out to already exist is silently skipped, not altered.
-- Sync for payments doesn't exist at all yet (no push, no pull, not
-- registered in the sync loop) — this migration is a prerequisite for that,
-- added in the same commit as this file.

ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS payment_id text,
  ADD COLUMN IF NOT EXISTS order_id bigint,
  ADD COLUMN IF NOT EXISTS order_code text,
  ADD COLUMN IF NOT EXISTS store_name text,
  ADD COLUMN IF NOT EXISTS sales_rep_id bigint,
  ADD COLUMN IF NOT EXISTS sales_rep_name text,
  ADD COLUMN IF NOT EXISTS order_amount numeric(10, 2),
  ADD COLUMN IF NOT EXISTS amount_paid numeric(10, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS balance numeric(10, 2),
  ADD COLUMN IF NOT EXISTS payment_method text,
  ADD COLUMN IF NOT EXISTS payment_date timestamp with time zone,
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'unpaid',
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS sync_status text DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS created_at timestamp with time zone DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- ============================================================================
-- STOCK_MOVEMENTS
-- ============================================================================
-- Verified against the real schema pasted earlier this session: id,
-- product_id, movement_type, quantity, notes, created_by, sync_status,
-- created_at, updated_at (9 columns). Drift's `notes` and `createdBy`
-- fields already line up with the real `notes`/`created_by` columns — the
-- push mapping was just never using them (it was sending `reason` into a
-- column called `notes` and `user_id` into a column called `created_by`,
-- fixed separately in sync_engine.dart). Everything below is genuinely
-- missing: reason is a real, separate, always-populated field from notes
-- (it's the required reason code from the Record Movement panel; notes is
-- optional free text) and needs its own column, not to be folded into notes.

ALTER TABLE public.stock_movements
  ADD COLUMN IF NOT EXISTS uuid text,
  ADD COLUMN IF NOT EXISTS reference_type text,
  ADD COLUMN IF NOT EXISTS reference_id text,
  ADD COLUMN IF NOT EXISTS reason text,
  ADD COLUMN IF NOT EXISTS user_id text,
  ADD COLUMN IF NOT EXISTS user_name text,
  ADD COLUMN IF NOT EXISTS from_location text,
  ADD COLUMN IF NOT EXISTS to_location text,
  ADD COLUMN IF NOT EXISTS unit_cost numeric(10, 2),
  ADD COLUMN IF NOT EXISTS total_cost numeric(10, 2),
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'completed',
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS is_deleted boolean DEFAULT false;
