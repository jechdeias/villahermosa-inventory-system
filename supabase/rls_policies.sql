-- Villahermosa Inventory System — RLS policies
-- YOU run this manually in the Supabase SQL Editor. Claude Code wrote it,
-- it does not execute it — no Supabase CLI/dashboard access from that
-- environment. Read the notes below before running; this is production data.
--
-- ============================================================================
-- IMPORTANT — read this before running anything below
-- ============================================================================
--
-- This app's local `users.uuid` (used for sync) is NOT the same value as
-- the Supabase Auth user id. AuthService.signup() sets uuid to
-- `DateTime.now().millisecondsSinceEpoch.toString()`, completely unrelated
-- to whatever id `supabase.auth.signUp()` generates. Nothing in this
-- codebase ever links the two, for any of the ~410 existing accounts or
-- any new one.
--
-- That breaks the two standard building blocks for per-role RLS:
--   - `auth.uid() = <local id column>` never matches, for anyone.
--   - `auth.jwt() ->> 'role'` reads the Postgres/session role claim
--     ("authenticated"), not this app's `users.role` column (admin/
--     warehouse/sales_rep/delivery/customer) — there is no custom claims
--     hook anywhere in this codebase setting that.
--
-- Writing policies that check `auth.user_role() = 'admin'` (a function
-- built on either of the above) would not "almost work" — it would ALWAYS
-- evaluate false, for every user including real admins, the moment RLS is
-- enabled. That doesn't fail safe by restricting access; it fails by
-- locking every screen in the app to empty tables and rejected writes,
-- immediately, in production.
--
-- The correct fix for real per-role database-level restriction is to
-- backfill `users.uuid` to match the real Supabase Auth id (matching
-- existing accounts by email, a one-time migration over ~410 real rows)
-- and add a SECURITY DEFINER lookup function. That's a bigger, separate
-- change this file does not attempt — it touches real customer/staff
-- accounts and needs its own careful review and testing, not something to
-- fold into a broader pass sight-unseen against a live production table.
--
-- What THIS file delivers instead, honestly: it closes the two vulnerabilities
-- that ARE fully achievable and verifiable today —
--   1. Fully anonymous access. Right now, with zero RLS on 8 of 9 tables,
--      anyone holding the app's anon key (extractable from any installed
--      build, no login needed) has complete read/write access to
--      everything. Requiring a genuine authenticated session closes that
--      entirely. It's a large, real improvement even though it doesn't yet
--      distinguish admin from warehouse from sales rep — this is a small
--      internal-staff tool today, not a multi-tenant app with per-customer
--      data isolation, so "must be a logged-in staff/customer account" is a
--      meaningful bar, just not a role-differentiated one yet.
--   2. The `users` table's actual privilege-escalation hole (see below) —
--      this one IS fully fixable today without the identity migration,
--      because it doesn't need role differentiation: the fix is simply to
--      stop allowing the client to write to `users` at all. All writes to
--      `users` now go exclusively through the privileged-sync Edge
--      Function, which enforces the role check server-side by verified
--      email (not auth.uid(), not anything the client sends) — see
--      supabase/functions/privileged-sync/index.ts.
--
-- Residual gap after running this file: payments, customer credit data,
-- stock movements etc. are readable/writable by ANY authenticated account,
-- including a self-registered customer — not restricted to admin/staff
-- roles. That's a real, known limitation of this pass, not an oversight —
-- closing it properly requires the identity-correlation fix above.
--
-- ============================================================================

-- Enable RLS on every table that doesn't already have it.
-- (public.users already has RLS enabled — see supabase_users_table.sql.)
ALTER TABLE public.products         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deliveries       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers        ENABLE ROW LEVEL SECURITY;

-- Operational tables: any authenticated session may read/write. Every push
-- for these tables (sync_engine.dart's _pushProducts/_pushCustomers/
-- _pushOrders/_pushOrderItems/_pushPayments/_pushStockMovements/
-- _pushDeliveries) already goes through the plain authenticated client, not
-- the Edge Function — a stricter policy here would break sync outright, not
-- just tighten it.
CREATE POLICY "products_authenticated_access" ON public.products
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "customers_authenticated_access" ON public.customers
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "orders_authenticated_access" ON public.orders
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "order_items_authenticated_access" ON public.order_items
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "payments_authenticated_access" ON public.payments
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "stock_movements_authenticated_access" ON public.stock_movements
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "deliveries_authenticated_access" ON public.deliveries
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- Suppliers: reads open to any authenticated session; writes go exclusively
-- through the privileged-sync Edge Function (service key, bypasses RLS by
-- design — no client-side write policy needed or wanted here).
CREATE POLICY "suppliers_authenticated_read" ON public.suppliers
  FOR SELECT USING (auth.role() = 'authenticated');

-- ============================================================================
-- USERS TABLE — close the actual escalation hole
-- ============================================================================

-- This is the dangerous one: it lets ANY authenticated user insert a row
-- with any role value at all, including 'admin' — the WITH CHECK only
-- verifies they're logged in, not what they're inserting.
DROP POLICY IF EXISTS "Authenticated users can insert users" ON public.users;

-- These "service role can ..." policies are now redundant rather than
-- wrong: the privileged-sync Edge Function's service-role client bypasses
-- RLS entirely regardless of policy, so they're dropped for clarity, not
-- because they were a hole.
DROP POLICY IF EXISTS "Service role can manage all users" ON public.users;
DROP POLICY IF EXISTS "Service role can insert users" ON public.users;
DROP POLICY IF EXISTS "Service role can update users" ON public.users;

-- No replacement client-side INSERT/UPDATE policy. After this session's
-- refactor, every write to `users` (signup, staff creation, sync) goes
-- through the Edge Function's service-role client — removing client write
-- access entirely closes the hole completely, rather than trying to
-- narrow it with a WITH CHECK that would need the broken role
-- correlation to be trustworthy.

-- Keep the existing "Users can view own profile" policy (auth.jwt()->>'email'
-- is a real, standard Supabase Auth JWT claim — unlike the app's custom
-- `role` column, this one isn't broken). Add a broader read policy so the
-- admin User Accounts screen can still see the full roster (it currently
-- pulls the whole table via the plain authenticated client) — subsumes the
-- "own profile" policy but that one is left in place rather than dropped,
-- to minimize changes to a working policy.
CREATE POLICY "users_authenticated_read" ON public.users
  FOR SELECT USING (auth.role() = 'authenticated');

-- The broader read policy above would otherwise expose password_hash to
-- every logged-in customer, not just the row owner. Postgres column-level
-- privileges (not RLS, which is row-level only) close that specifically —
-- this doesn't depend on the broken identity correlation at all.
REVOKE SELECT (password_hash) ON public.users FROM authenticated, anon;
