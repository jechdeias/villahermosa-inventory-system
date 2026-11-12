# Villahermosa Inventory System — Claude Code Guide

## Project overview
Offline-first Flutter inventory management app for Villahermosa (Marinduque, Philippines). Supports four user roles: **admin**, **warehouse**, **customer**, **delivery**. Syncs local SQLite data to Supabase when online.

## Running locally
Copy `secrets.json.example` → `secrets.json` and fill in real Supabase credentials, then:
```
flutter run --dart-define-from-file=secrets.json
```
Android builds need the same flag. Never commit `secrets.json` or `lib/core/config/supabase_config.dart`.

## Architecture

### State management
Mixed, and drifted from the original plan. `provider` + `ChangeNotifier` was the original convention (five ViewModels live under `lib/features/<feature>/viewmodels/`, one per role + auth), with a stated rule of not introducing Riverpod without agreement — but `flutter_riverpod` has since been adopted throughout the admin feature (every `lib/features/admin/providers/*.dart` file: products, orders, payments, stock movements, reports, settings) and is now a direct dependency. Warehouse/customer/delivery screens still use plain `setState` or the (mostly stub) ChangeNotifier ViewModels. Treat admin as Riverpod-based going forward; reconcile the other roles' approach with whoever owns that decision before adding more state-management patterns.

### Database (offline-first)
- **Local:** Drift ORM over SQLite (`lib/core/database/`). Ten tables: users, products, customers, orders, order_items, deliveries, stock_movements, suppliers, payments, delivery_routes. Schema version 9.
- **Remote:** Supabase PostgREST (`lib/core/config/supabase_config.dart`).
- **Sync:** `SyncManager` (singleton) drives push/pull via `SyncEngine`. Records carry a `sync_status` column (`pending` | `synced`). Push runs on login and startup (unless disabled via Settings' auto-sync toggle); pull runs after push. Last-sync timestamp is persisted via `AppSettings` (`lib/core/settings/app_settings.dart`, backed by `shared_preferences`).

### Auth
`AuthService` singleton (`lib/core/auth/auth_service.dart`) owns the local Drift session. Supabase Auth runs alongside for token-based RLS. Passwords are bcrypt; SHA-256 hashes are migrated on next login. Note: there's a second, largely-parallel implementation in `AuthRepository` (`lib/features/auth/data/auth_repository.dart`) used for customer self-signup and staff account creation — historically it hashed with plain SHA-256 (fixed to bcrypt+migration, matching `AuthService`, but the duplication itself is unresolved debt). `AuthRepository.login()` is not wired into the live login screen at all (only `AuthService.login()` is) — it's exercised by `auth_repository_test.dart` but otherwise dead code.

### Navigation & roles
`RoleBasedNavigation.navigate()` in `lib/core/constants/user_roles.dart` routes to the correct dashboard. `ResponsiveShell` (`lib/core/widgets/responsive_shell.dart`) provides the sidebar + hamburger layout used by all post-login screens.

## Key files
| Path | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, Supabase init, startup sync |
| `lib/core/database/app_database.dart` | Drift DB class + all query helpers |
| `lib/core/auth/auth_service.dart` | Auth singleton (login / logout / session) |
| `lib/core/sync/sync_manager.dart` | Sync orchestrator singleton |
| `lib/core/sync/sync_engine.dart` | Push/pull implementation |
| `lib/core/config/supabase_config.dart` | Credentials (gitignored — see secrets.json.example). No service key here anymore — see below |
| `lib/features/admin/screens/` | Admin-role screens |
| `lib/features/warehouse/screens/` | Warehouse-role screens |
| `supabase_users_table.sql` | Original `users` table schema + RLS (has a known policy hole — see `supabase/rls_policies.sql`) |
| `supabase/functions/privileged-sync/index.ts` | Edge Function for privileged writes (user/supplier sync); holds the service key server-side only |
| `supabase/rls_policies.sql` | RLS policies for every other table — run manually via the Supabase SQL Editor, not applied automatically |

## Development conventions
- Pass `AppDatabase` and `SyncManager` down through constructors; both are singletons initialised in `main.dart`.
- Access the shared database in leaf widgets via `AuthService.instance.database`.
- Soft-delete only — never hard-delete rows. Set `is_deleted = true` and `sync_status = 'pending'`.
- After any local write, set `sync_status = 'pending'` so the next sync cycle picks it up.
- All screens wrapped in `ResponsiveShell` for consistent sidebar navigation.

## Current status (Nov 2026)
- **Done — admin role:** every admin screen (Dashboard, Products, Customers, Orders, Payments, Stock Movement, Deliveries/Routes, Reports, Settings, User Accounts) is real, wired to live Drift data via Riverpod stream providers.
- **Done — sync engine pull:** all 9 tables now have typed `insertOnConflictUpdate` pull implementations registered in order (users → products → customers → orders → order_items → stock_movements → payments → deliveries → suppliers). All were `// Implementation needed` stubs before Nov 2026.
- **Done — delivery confirmation:** `DeliveryViewModel.confirmDeliveryByButton` and `confirmDeliveryByCode` are implemented (Drift write → `markOrderDelivered` → background sync). The QR tab now launches `SalesScanScreen`.
- **Done — warehouse dashboard:** activity tile taps navigate to the correct sidebar section.
- **Done — customer card widget:** `CustomerCard` is a real `ConsumerWidget` using Riverpod providers.
- **Remaining stubs — warehouse, customer screens:** product list, order preparation, stock in/out, routes screens are still static UI placeholders. `WarehouseViewModel` is not referenced by any screen.
- **Dead code to clean up:** `lib/features/admin/screens/users_screen.dart` (`AdminUsersScreen`) duplicates the real, routed `user_accounts_screen.dart` and is never routed itself.
- **Tests:** only 4 test files total (`test/`), covering the database layer and auth repository. Zero UI/ViewModel test coverage across all four roles.

## Workflow testing — full end-to-end audit checklist

Use this section to verify the system works correctly after any change to sync, auth, or order flow.

### Role summary
| Role | Primary device | Key tables written | Key tables read |
|------|---------------|-------------------|-----------------|
| customer | Android (mobile) | orders, order_items | products, customers |
| admin | Windows (desktop) | users, products, customers, deliveries | all |
| warehouse | Android/Windows | stock_movements, orders (warehouseStatus) | orders, order_items, products |
| delivery | Android | deliveries | orders, order_items |

### Auth flows — test these explicitly

**A1 — Fresh install (empty local DB)**
1. Install APK on a device that has never had the app. Local `users` table is empty.
2. Enter any valid credential. `AuthService.login()` detects `localUserCount == 0` → calls `_attemptSupabaseAuth` → calls `SyncManager.bootstrapUsers()` → `_ensureLocalPasswordHash` → `_localLogin`.
3. Expected: login succeeds; home screen for the user's role appears; background pull runs and populates all tables.
4. Verify: open admin → user accounts; the user's role is correct on the phone.

**A2 — Existing device, new user added by admin on Windows**
1. Admin creates a new account (e.g. "Sales Rep / very deli") on the Windows app. The row is pushed to Supabase.
2. On the phone (non-empty local DB), the new user tries to log in.
3. Expected (after the Nov 2026 fix): `_localLogin` returns null → `_attemptSupabaseAuth` succeeds → `bootstrapUsers()` pulls the row → `_ensureLocalPasswordHash` writes bcrypt hash → `_localLogin` succeeds on retry.
4. If Supabase Auth is offline or the account has no Supabase Auth entry yet: login fails with "invalid credentials" — this is the remaining gap (see Known bugs §B2).

**A3 — Google OAuth**
1. Tap "Sign in with Google" on the phone login screen.
2. OAuth callback hits `AuthService.loginWithOAuthSession()` → `bootstrapUsers()` → lookup by email → if not found, creates a `customer` row locally.
3. Expected: navigates to the customer home. SHA-1 of the release APK must be registered in Firebase Console — debug APK fingerprint ≠ release APK fingerprint.

**A4 — Role routing**
- After login, `RoleBasedNavigation.navigate()` reads `user.role`. Verify: `admin` → AdminDashboard; `warehouse` → WarehouseDashboard; `customer` → CustomerHome; `delivery` → DeliveryDashboard.

### Order flow — offline-first through to admin confirmation

**O1 — Online order (phone)**
1. Customer logs in on phone → taps Products → adds items to cart → submits.
2. Local SQLite: new `orders` row (uuid = timestamp-based, syncStatus = 'pending') + `order_items` rows.
3. App attempts push immediately (startup sync / background trigger). Watch debug log for `📤 Pushing X orders`.
4. Supabase: row appears in `orders` table with correct uuid, order_number, customer_id.
5. Admin syncs on Windows → pull finds the new order → `watchAllOrders()` Riverpod stream fires → order appears in Orders Management with the **correct date** (Nov 2026 fix adds `createdAt` to the pull companion).
6. Admin marks order "complete" → `status = 'completed'`, `syncStatus = 'pending'` locally → push to Supabase.
7. Phone next sync: pull finds `status = 'completed'` → `insertOnConflictUpdate` with uuid-resolved local id → `watchAllOrders()` stream fires → "Order Complete!" status timeline appears on the phone My Orders screen.

**O2 — Offline order (phone, airplane mode)**
1. Enable airplane mode on the phone.
2. Customer places an order. Local row written, `syncStatus = 'pending'`.
3. Verify: order appears in My Orders on the phone immediately (Drift stream fires on insert — no manual refresh needed).
4. Reconnect to network (airplane mode off).
5. Next sync cycle (startup or manual): `_pushOrders` finds the pending row → upserts to Supabase.
6. Admin syncs → order appears in Windows. Confirm date is correct and order number matches.

**O3 — Order items visible in order detail**
- In the Windows order detail screen, `orderItemsProvider` calls `getOrderItemsByOrderId(orderUuid)` where `orderUuid` is the order's `uuid` field (not int id).
- After the Nov 2026 pull fix, `order_items` rows are upserted with `orderId` resolved to the **local order's uuid** (via `getOrderByIntId` → `.uuid`). So the lookup should work.
- If "No item details recorded for this order" appears: check whether the `order_items` rows have `orderId` = the order's uuid (not Supabase int id). Query: `SELECT orderId FROM order_items WHERE id = X`.

**O4 — Bidirectional status update**
- Customer phone → pending → warehouse confirms (warehouseStatus = 'ready') → admin marks complete → phone shows timeline.
- Each status change must set `syncStatus = 'pending'` on the row that changed. The sync engine pushes `syncStatus = 'pending'` rows; each device pulls all non-deleted orders on every sync.
- Status columns: `orders.status` (pending/confirmed/processing/completed/cancelled), `orders.warehouseStatus` (pending/picked/packed/ready/shipped/delivered), `deliveries.status` (pending/in_progress/delivered/failed).

### Sync engine — what moves where

**S1 — Push flow (client → Supabase)**
- Triggered: on login, on startup (if auto-sync enabled), and manually from the Settings screen.
- Tables pushed in order: users (via Edge Function), suppliers (via Edge Function), products, customers, orders, order_items, stock_movements, payments, deliveries.
- Each push: `SELECT * FROM <table> WHERE sync_status = 'pending' AND is_deleted = 0`.
- Conflict key: `uuid` column (upsert). `customer_id`, `product_id`, `order_id` are resolved from local uuid → Supabase numeric id before the upsert payload is sent.

**S2 — Pull flow (Supabase → client)**
- Triggered: after push on each sync cycle.
- Tables pulled in order: users, products, customers, orders, order_items, stock_movements, payments, deliveries, suppliers.
- Each pull: fetches ALL non-deleted rows (no timestamp filter) so no order is ever missed.
- Conflict resolution: `insertOnConflictUpdate` with uuid-based id resolution (see sync_engine.dart `_updateLocalRecord`).
- After pull: Drift `watchAllOrders()` stream fires automatically — no manual UI refresh needed.

**S3 — Privileged writes (users, suppliers)**
- These two tables route through `supabase/functions/privileged-sync/index.ts` (Edge Function).
- The service-role key lives only in that Edge Function — never in the Flutter client.
- The Edge Function validates the caller's role (by email lookup) server-side before allowing non-customer role assignments.
- RLS on all other tables: any authenticated Supabase session can read/write them (per-role restriction is a known gap — see arch debt).

**S4 — New device pull order dependency**
- Pull order matters: `orders` before `order_items` (FK dependency), `orders` before `payments`, `users` before everything (login depends on it).
- The registered pull order in `SyncEngine` already satisfies these dependencies.

### Known bugs and remaining gaps

**B1 — FIXED (Nov 2026): UNIQUE constraint on orders.uuid and order_items.uuid during pull**
- Cause: Supabase id ≠ local id for same uuid — `insertOnConflictUpdate` on the wrong id column.
- Fix: uuid-based lookup, local id used as conflict key. Confirmed working.

**B2 — PARTIALLY FIXED (Nov 2026): New user login on non-empty-table device**
- Fix adds Supabase Auth fallback + `bootstrapUsers()` pull when `_localLogin` returns null.
- Remaining gap: if the new account was created locally on Windows but `_attemptSupabaseSignup` hasn't run yet (or failed silently), there is no Supabase Auth entry → fallback pull has no JWT → still fails.
- Mitigation: admin-created accounts always have a password set → `_attemptSupabaseSignup` runs in the background at account creation time. If it failed, the admin can re-trigger sync.

**B3 — FIXED (Nov 2026): Wrong date (2024-12-12) on pulled orders in Windows list**
- Cause: `createdAt` missing from the `orders` `insertOnConflictUpdate` companion in `_updateLocalRecord` — Drift defaulted to epoch.
- Fix: `createdAt: Value(_toDateTime(data['created_at']) ?? DateTime.now())` added to both orders and order_items companions.

**B4 — OPEN: Google Sign-In fails on release APK**
- Cause: SHA-1 fingerprint of the release APK is not registered in Firebase Console / Google Cloud OAuth credentials.
- Fix: `keytool -list -v -keystore <release.keystore>` → copy SHA-1 → add to Firebase project → re-download `google-services.json`.

**B5 — OPEN: Order detail may show "No item details recorded"**
- Root cause tracked: `getOrderItemsByOrderId(orderUuid)` queries `order_items.orderId` by the order's uuid. After the pull fix the orderId in pulled rows is set from `getOrderByIntId(data['order_id'])?.uuid`, so it should be correct.
- If still appearing: the order_items may not have been pulled yet (pull order issue) or the order was placed before the fix. Force a full sync and check.

**B6 — OPEN: `AuthService.signup()` uuid uses millisecond timestamp, not Supabase Auth id**
- Impact: the two auth systems are never linked by id, only by email. Per-role RLS is not enforceable from SQL alone.
- Fix: one-time migration matching users by email across ~410 accounts. Not attempted — see arch debt.

## Known architecture debt
- **Fixed (Aug 2026):** the Supabase service-role key no longer ships in the client at all. It previously lived in `SupabaseConfig.serviceKey` and was used directly for user/supplier sync in `sync_engine.dart` and `auth_repository.dart` — that's now routed through the `privileged-sync` Edge Function, which holds the key server-side only. RLS was also enabled on the 8 tables that had none at all before (`supabase/rls_policies.sql`), and the pre-existing `users` table policy that let any authenticated account insert a row with `role = 'admin'` was closed (client-side writes to `users` are no longer possible at all — everything routes through the Edge Function, which verifies the caller's role server-side by email before allowing anything other than `role = 'customer'`).
- **Known limitation of that fix, not yet resolved:** there is no reliable way to determine an authenticated caller's app-level role (admin/warehouse/sales_rep/delivery) from SQL alone. `AuthService.signup()` sets the local `users.uuid` to a millisecond-timestamp string, unrelated to the real Supabase Auth user id — the two are never linked anywhere in this codebase, for any existing account or new one. That means RLS currently can't restrict payments/customer credit data/etc. to admin-only; any authenticated account (including a self-registered customer) can read and write those tables. Real per-role restriction needs a one-time migration backfilling `users.uuid` to the real Supabase Auth id (matched by email across ~410 real accounts) plus a `SECURITY DEFINER` role-lookup function — deliberately not attempted as part of the same pass that removed the service key, since it touches live production account data and needs its own dedicated testing.
- Two parallel, duplicated auth implementations (`AuthService` and `AuthRepository`) — see Auth section above.
- `WarehouseViewModel` and `CustomerViewModel` methods are stubs — business logic not yet implemented. `DeliveryViewModel` confirmation methods are now real (Nov 2026).
- QR scanning: `mobile_scanner: ^5.2.3` and `qr_flutter: ^4.1.0` are in `pubspec.yaml`. `SalesScanScreen` is fully implemented; `qr_service_locator.dart` is a dead stub not called by any real screen.
- **Fixed (Nov 2026):** all sync engine pull stubs are now implemented — `_pullOrders`, `_pullOrderItems`, `_pullStockMovements`, `_pullDeliveries`, and `_pullPayments` all have typed `insertOnConflictUpdate` cases in `_updateLocalRecord`.
