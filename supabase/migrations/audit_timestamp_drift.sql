-- =============================================================================
-- audit_timestamp_drift.sql
--
-- READ-ONLY. Every statement below is a SELECT. Nothing is created, updated,
-- deleted or altered, so it is safe to run on production in the SQL Editor.
--
-- WHY: until the fix in the app, every timestamp the app pushed was a LOCAL
-- DateTime serialised with no offset ("2026-11-19T14:00:00.000"). Postgres
-- timestamptz read that as 14:00 UTC - 8 hours (Manila's offset) ahead of the
-- real instant - and the pull handed it back, so the next push added another 8
-- hours: +8h on EVERY round trip, compounding. Rows that round-tripped a lot
-- (users and suppliers looped every ~20 minutes for ~8 days) drifted months.
--
-- HOW TO READ IT. Run the three queries separately.
--   1. Per table, per timestamp column:
--        in_future                         rows whose value is after now()
--        before_created_at                 rows whose value is BEFORE created_at
--        exact_8h_multiple_from_created_at rows where (value - created_at) is a
--                                          non-zero whole multiple of 8 hours.
--                                          Ordinary edits almost never land on
--                                          that, so a large count here
--                                          fingerprints THIS corruption (it
--                                          counts drift in either direction).
--        max_value / max_value_minus_now   latest value and how far ahead of now
--      (created_at has no before/multiple check: it is the reference column.)
--      Different columns drift by different amounts (an order can show
--      actual_delivery_date earlier than created_at), so every timestamp column
--      of every synced table is covered, not just updated_at.
--   2. Roll-up: rows with ANY forward-dated timestamp, per table.
--   3. A sample of the worst users rows.
--
-- Columns checked against the live information_schema; all are timestamptz.
-- Note: a row corrupted by a whole number of round trips that is NOT in the
-- future yet (recent, only a few trips) shows up only in the 8h-multiple column.
-- DATA IS NOT REPAIRED HERE. Repair only after the app fix is on every device,
-- or the broken code re-corrupts it.
-- =============================================================================

-- 1. Per table, per timestamp column ------------------------------------------
SELECT 'users' AS table_name, 'created_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now()) AS in_future,
       NULL::bigint AS before_created_at,
       NULL::bigint AS exact_8h_multiple_from_created_at,
       max(created_at) AS max_value,
       max(created_at) - now() AS max_value_minus_now
FROM public.users

UNION ALL

SELECT 'users' AS table_name, 'updated_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE updated_at > now()) AS in_future,
       count(*) FILTER (WHERE updated_at < created_at) AS before_created_at,
       count(*) FILTER (WHERE updated_at <> created_at
                       AND mod(extract(epoch FROM (updated_at - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(updated_at) AS max_value,
       max(updated_at) - now() AS max_value_minus_now
FROM public.users

UNION ALL

SELECT 'products' AS table_name, 'created_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now()) AS in_future,
       NULL::bigint AS before_created_at,
       NULL::bigint AS exact_8h_multiple_from_created_at,
       max(created_at) AS max_value,
       max(created_at) - now() AS max_value_minus_now
FROM public.products

UNION ALL

SELECT 'products' AS table_name, 'updated_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE updated_at > now()) AS in_future,
       count(*) FILTER (WHERE updated_at < created_at) AS before_created_at,
       count(*) FILTER (WHERE updated_at <> created_at
                       AND mod(extract(epoch FROM (updated_at - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(updated_at) AS max_value,
       max(updated_at) - now() AS max_value_minus_now
FROM public.products

UNION ALL

SELECT 'customers' AS table_name, 'created_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now()) AS in_future,
       NULL::bigint AS before_created_at,
       NULL::bigint AS exact_8h_multiple_from_created_at,
       max(created_at) AS max_value,
       max(created_at) - now() AS max_value_minus_now
FROM public.customers

UNION ALL

SELECT 'customers' AS table_name, 'updated_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE updated_at > now()) AS in_future,
       count(*) FILTER (WHERE updated_at < created_at) AS before_created_at,
       count(*) FILTER (WHERE updated_at <> created_at
                       AND mod(extract(epoch FROM (updated_at - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(updated_at) AS max_value,
       max(updated_at) - now() AS max_value_minus_now
FROM public.customers

UNION ALL

SELECT 'orders' AS table_name, 'created_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now()) AS in_future,
       NULL::bigint AS before_created_at,
       NULL::bigint AS exact_8h_multiple_from_created_at,
       max(created_at) AS max_value,
       max(created_at) - now() AS max_value_minus_now
FROM public.orders

UNION ALL

SELECT 'orders' AS table_name, 'updated_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE updated_at > now()) AS in_future,
       count(*) FILTER (WHERE updated_at < created_at) AS before_created_at,
       count(*) FILTER (WHERE updated_at <> created_at
                       AND mod(extract(epoch FROM (updated_at - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(updated_at) AS max_value,
       max(updated_at) - now() AS max_value_minus_now
FROM public.orders

UNION ALL

SELECT 'orders' AS table_name, 'order_date' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE order_date > now()) AS in_future,
       count(*) FILTER (WHERE order_date < created_at) AS before_created_at,
       count(*) FILTER (WHERE order_date <> created_at
                       AND mod(extract(epoch FROM (order_date - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(order_date) AS max_value,
       max(order_date) - now() AS max_value_minus_now
FROM public.orders

UNION ALL

SELECT 'orders' AS table_name, 'packed_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE packed_at > now()) AS in_future,
       count(*) FILTER (WHERE packed_at < created_at) AS before_created_at,
       count(*) FILTER (WHERE packed_at <> created_at
                       AND mod(extract(epoch FROM (packed_at - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(packed_at) AS max_value,
       max(packed_at) - now() AS max_value_minus_now
FROM public.orders

UNION ALL

SELECT 'orders' AS table_name, 'expected_delivery_date' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE expected_delivery_date > now()) AS in_future,
       count(*) FILTER (WHERE expected_delivery_date < created_at) AS before_created_at,
       count(*) FILTER (WHERE expected_delivery_date <> created_at
                       AND mod(extract(epoch FROM (expected_delivery_date - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(expected_delivery_date) AS max_value,
       max(expected_delivery_date) - now() AS max_value_minus_now
FROM public.orders

UNION ALL

SELECT 'orders' AS table_name, 'actual_delivery_date' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE actual_delivery_date > now()) AS in_future,
       count(*) FILTER (WHERE actual_delivery_date < created_at) AS before_created_at,
       count(*) FILTER (WHERE actual_delivery_date <> created_at
                       AND mod(extract(epoch FROM (actual_delivery_date - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(actual_delivery_date) AS max_value,
       max(actual_delivery_date) - now() AS max_value_minus_now
FROM public.orders

UNION ALL

SELECT 'order_items' AS table_name, 'created_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now()) AS in_future,
       NULL::bigint AS before_created_at,
       NULL::bigint AS exact_8h_multiple_from_created_at,
       max(created_at) AS max_value,
       max(created_at) - now() AS max_value_minus_now
FROM public.order_items

UNION ALL

SELECT 'order_items' AS table_name, 'updated_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE updated_at > now()) AS in_future,
       count(*) FILTER (WHERE updated_at < created_at) AS before_created_at,
       count(*) FILTER (WHERE updated_at <> created_at
                       AND mod(extract(epoch FROM (updated_at - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(updated_at) AS max_value,
       max(updated_at) - now() AS max_value_minus_now
FROM public.order_items

UNION ALL

SELECT 'order_items' AS table_name, 'picked_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE picked_at > now()) AS in_future,
       count(*) FILTER (WHERE picked_at < created_at) AS before_created_at,
       count(*) FILTER (WHERE picked_at <> created_at
                       AND mod(extract(epoch FROM (picked_at - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(picked_at) AS max_value,
       max(picked_at) - now() AS max_value_minus_now
FROM public.order_items

UNION ALL

SELECT 'stock_movements' AS table_name, 'created_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now()) AS in_future,
       NULL::bigint AS before_created_at,
       NULL::bigint AS exact_8h_multiple_from_created_at,
       max(created_at) AS max_value,
       max(created_at) - now() AS max_value_minus_now
FROM public.stock_movements

UNION ALL

SELECT 'stock_movements' AS table_name, 'updated_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE updated_at > now()) AS in_future,
       count(*) FILTER (WHERE updated_at < created_at) AS before_created_at,
       count(*) FILTER (WHERE updated_at <> created_at
                       AND mod(extract(epoch FROM (updated_at - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(updated_at) AS max_value,
       max(updated_at) - now() AS max_value_minus_now
FROM public.stock_movements

UNION ALL

SELECT 'stock_movements' AS table_name, 'movement_date' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE movement_date > now()) AS in_future,
       count(*) FILTER (WHERE movement_date < created_at) AS before_created_at,
       count(*) FILTER (WHERE movement_date <> created_at
                       AND mod(extract(epoch FROM (movement_date - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(movement_date) AS max_value,
       max(movement_date) - now() AS max_value_minus_now
FROM public.stock_movements

UNION ALL

SELECT 'payments' AS table_name, 'created_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now()) AS in_future,
       NULL::bigint AS before_created_at,
       NULL::bigint AS exact_8h_multiple_from_created_at,
       max(created_at) AS max_value,
       max(created_at) - now() AS max_value_minus_now
FROM public.payments

UNION ALL

SELECT 'payments' AS table_name, 'updated_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE updated_at > now()) AS in_future,
       count(*) FILTER (WHERE updated_at < created_at) AS before_created_at,
       count(*) FILTER (WHERE updated_at <> created_at
                       AND mod(extract(epoch FROM (updated_at - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(updated_at) AS max_value,
       max(updated_at) - now() AS max_value_minus_now
FROM public.payments

UNION ALL

SELECT 'payments' AS table_name, 'payment_date' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE payment_date > now()) AS in_future,
       count(*) FILTER (WHERE payment_date < created_at) AS before_created_at,
       count(*) FILTER (WHERE payment_date <> created_at
                       AND mod(extract(epoch FROM (payment_date - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(payment_date) AS max_value,
       max(payment_date) - now() AS max_value_minus_now
FROM public.payments

UNION ALL

SELECT 'deliveries' AS table_name, 'created_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now()) AS in_future,
       NULL::bigint AS before_created_at,
       NULL::bigint AS exact_8h_multiple_from_created_at,
       max(created_at) AS max_value,
       max(created_at) - now() AS max_value_minus_now
FROM public.deliveries

UNION ALL

SELECT 'deliveries' AS table_name, 'updated_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE updated_at > now()) AS in_future,
       count(*) FILTER (WHERE updated_at < created_at) AS before_created_at,
       count(*) FILTER (WHERE updated_at <> created_at
                       AND mod(extract(epoch FROM (updated_at - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(updated_at) AS max_value,
       max(updated_at) - now() AS max_value_minus_now
FROM public.deliveries

UNION ALL

SELECT 'deliveries' AS table_name, 'delivery_date' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE delivery_date > now()) AS in_future,
       count(*) FILTER (WHERE delivery_date < created_at) AS before_created_at,
       count(*) FILTER (WHERE delivery_date <> created_at
                       AND mod(extract(epoch FROM (delivery_date - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(delivery_date) AS max_value,
       max(delivery_date) - now() AS max_value_minus_now
FROM public.deliveries

UNION ALL

SELECT 'deliveries' AS table_name, 'expected_start_time' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE expected_start_time > now()) AS in_future,
       count(*) FILTER (WHERE expected_start_time < created_at) AS before_created_at,
       count(*) FILTER (WHERE expected_start_time <> created_at
                       AND mod(extract(epoch FROM (expected_start_time - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(expected_start_time) AS max_value,
       max(expected_start_time) - now() AS max_value_minus_now
FROM public.deliveries

UNION ALL

SELECT 'deliveries' AS table_name, 'expected_completion_time' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE expected_completion_time > now()) AS in_future,
       count(*) FILTER (WHERE expected_completion_time < created_at) AS before_created_at,
       count(*) FILTER (WHERE expected_completion_time <> created_at
                       AND mod(extract(epoch FROM (expected_completion_time - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(expected_completion_time) AS max_value,
       max(expected_completion_time) - now() AS max_value_minus_now
FROM public.deliveries

UNION ALL

SELECT 'deliveries' AS table_name, 'actual_start_time' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE actual_start_time > now()) AS in_future,
       count(*) FILTER (WHERE actual_start_time < created_at) AS before_created_at,
       count(*) FILTER (WHERE actual_start_time <> created_at
                       AND mod(extract(epoch FROM (actual_start_time - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(actual_start_time) AS max_value,
       max(actual_start_time) - now() AS max_value_minus_now
FROM public.deliveries

UNION ALL

SELECT 'deliveries' AS table_name, 'actual_completion_time' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE actual_completion_time > now()) AS in_future,
       count(*) FILTER (WHERE actual_completion_time < created_at) AS before_created_at,
       count(*) FILTER (WHERE actual_completion_time <> created_at
                       AND mod(extract(epoch FROM (actual_completion_time - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(actual_completion_time) AS max_value,
       max(actual_completion_time) - now() AS max_value_minus_now
FROM public.deliveries

UNION ALL

SELECT 'suppliers' AS table_name, 'created_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now()) AS in_future,
       NULL::bigint AS before_created_at,
       NULL::bigint AS exact_8h_multiple_from_created_at,
       max(created_at) AS max_value,
       max(created_at) - now() AS max_value_minus_now
FROM public.suppliers

UNION ALL

SELECT 'suppliers' AS table_name, 'updated_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE updated_at > now()) AS in_future,
       count(*) FILTER (WHERE updated_at < created_at) AS before_created_at,
       count(*) FILTER (WHERE updated_at <> created_at
                       AND mod(extract(epoch FROM (updated_at - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(updated_at) AS max_value,
       max(updated_at) - now() AS max_value_minus_now
FROM public.suppliers

UNION ALL

SELECT 'delivery_routes' AS table_name, 'created_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now()) AS in_future,
       NULL::bigint AS before_created_at,
       NULL::bigint AS exact_8h_multiple_from_created_at,
       max(created_at) AS max_value,
       max(created_at) - now() AS max_value_minus_now
FROM public.delivery_routes

UNION ALL

SELECT 'delivery_routes' AS table_name, 'updated_at' AS col,
       count(*) AS rows_total,
       count(*) FILTER (WHERE updated_at > now()) AS in_future,
       count(*) FILTER (WHERE updated_at < created_at) AS before_created_at,
       count(*) FILTER (WHERE updated_at <> created_at
                       AND mod(extract(epoch FROM (updated_at - created_at))::numeric, 28800) = 0) AS exact_8h_multiple_from_created_at,
       max(updated_at) AS max_value,
       max(updated_at) - now() AS max_value_minus_now
FROM public.delivery_routes
ORDER BY table_name, col;

-- 2. Rows with any forward-dated timestamp, per table ------------------------
SELECT 'users' AS table_name, count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now() OR updated_at > now()) AS rows_with_any_future_timestamp
FROM public.users

UNION ALL

SELECT 'products' AS table_name, count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now() OR updated_at > now()) AS rows_with_any_future_timestamp
FROM public.products

UNION ALL

SELECT 'customers' AS table_name, count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now() OR updated_at > now()) AS rows_with_any_future_timestamp
FROM public.customers

UNION ALL

SELECT 'orders' AS table_name, count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now() OR updated_at > now() OR order_date > now() OR packed_at > now() OR expected_delivery_date > now() OR actual_delivery_date > now()) AS rows_with_any_future_timestamp
FROM public.orders

UNION ALL

SELECT 'order_items' AS table_name, count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now() OR updated_at > now() OR picked_at > now()) AS rows_with_any_future_timestamp
FROM public.order_items

UNION ALL

SELECT 'stock_movements' AS table_name, count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now() OR updated_at > now() OR movement_date > now()) AS rows_with_any_future_timestamp
FROM public.stock_movements

UNION ALL

SELECT 'payments' AS table_name, count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now() OR updated_at > now() OR payment_date > now()) AS rows_with_any_future_timestamp
FROM public.payments

UNION ALL

SELECT 'deliveries' AS table_name, count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now() OR updated_at > now() OR delivery_date > now() OR expected_start_time > now() OR expected_completion_time > now() OR actual_start_time > now() OR actual_completion_time > now()) AS rows_with_any_future_timestamp
FROM public.deliveries

UNION ALL

SELECT 'suppliers' AS table_name, count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now() OR updated_at > now()) AS rows_with_any_future_timestamp
FROM public.suppliers

UNION ALL

SELECT 'delivery_routes' AS table_name, count(*) AS rows_total,
       count(*) FILTER (WHERE created_at > now() OR updated_at > now()) AS rows_with_any_future_timestamp
FROM public.delivery_routes
ORDER BY table_name;

-- 3. Sample: users with an updated_at in the future ---------------------------
SELECT 'users' AS table_name, id, uuid::text AS uuid, created_at, updated_at,
       updated_at - created_at AS updated_minus_created
FROM public.users
WHERE updated_at > now()
ORDER BY updated_at DESC
LIMIT 25;
