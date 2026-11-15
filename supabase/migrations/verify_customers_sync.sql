-- verify_customers_sync.sql
--
-- READ-ONLY. Every statement below is a SELECT: no DDL, no writes. Safe to run
-- on production. Paste into the Supabase SQL Editor and run each query
-- separately (the editor shows only the last result of a multi-statement run).
--
-- Purpose: confirm the customers sync change (push sends 'uuid', upserts with
-- onConflict: 'uuid', and still sends 'id') behaves correctly against live data.
--
--   Query A proves 'uuid': record.uuid is actually being sent.
--   Query B proves onConflict: 'uuid' updates one row instead of inserting a copy.
--   Query C proves FK id-parity: orders.customer_id still points at the right
--           customer (the check the reverted data.remove('id') would have broken).
--
-- Do an app test first: create ONE new customer in the app, edit one existing
-- customer, sync twice, then run these.


-- =====================================================================
-- A. Backfilled vs. real uuids
-- What to look for: the customer created in the app after the change should
-- show a REAL uuid (not 'sb-customer-<id>'). real_uuid_count > 0 and the newest
-- row in the list below having a non-'sb-customer-' uuid means the app is
-- sending 'uuid': record.uuid.
-- =====================================================================

-- A1. Counts
SELECT
  count(*) FILTER (WHERE uuid LIKE 'sb-customer-%')     AS backfilled_uuid_count,
  count(*) FILTER (WHERE uuid NOT LIKE 'sb-customer-%') AS real_uuid_count,
  count(*) FILTER (WHERE uuid IS NULL)                  AS null_uuid_count
FROM public.customers;

-- A2. Five most recent rows
SELECT id, uuid, name, created_at
FROM public.customers
ORDER BY created_at DESC
LIMIT 5;


-- =====================================================================
-- B. Duplicate detection
-- What to look for: BOTH queries should return ZERO rows. After editing an
-- existing customer and syncing twice there must still be one row for it.
-- =====================================================================

-- B1. Any uuid appearing more than once
SELECT uuid, count(*) AS copies, array_agg(id ORDER BY id) AS ids
FROM public.customers
WHERE uuid IS NOT NULL
GROUP BY uuid
HAVING count(*) > 1;

-- B2. Same name + phone under different ids
SELECT a.id AS id_a, b.id AS id_b, a.name, a.phone, a.uuid AS uuid_a, b.uuid AS uuid_b
FROM public.customers a
JOIN public.customers b
  ON a.name = b.name
 AND a.phone IS NOT DISTINCT FROM b.phone
 AND a.id < b.id
ORDER BY a.name, a.id;


-- =====================================================================
-- C. FK id-parity (orders -> customers)
-- What to look for: C2 must return orphan_orders = 0. C1 should show each
-- recent order joined to a sensible customer name.
-- =====================================================================

-- C1. Ten most recent orders with their joined customer
SELECT o.id AS order_id,
       o.order_number,
       o.customer_id,
       c.name AS customer_name,
       c.uuid AS customer_uuid
FROM public.orders o
LEFT JOIN public.customers c ON c.id = o.customer_id
ORDER BY o.id DESC
LIMIT 10;

-- C2. Orders whose customer_id is set but matches no customer
SELECT count(*) AS orphan_orders
FROM public.orders o
WHERE o.customer_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM public.customers c WHERE c.id = o.customer_id);
