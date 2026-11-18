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
Mixed, and drifted from the original plan. `provider` + `ChangeNotifier` was the original convention (four ViewModels live under `lib/features/<feature>/viewmodels/`: admin, auth, customer, delivery), with a stated rule of not introducing Riverpod without agreement — but `flutter_riverpod` has since been adopted throughout the admin feature (every `lib/features/admin/providers/*.dart` file: products, orders, payments, stock movements, reports, settings) and is now a direct dependency. The warehouse screens (`lib/features/warehouse/providers/warehouse_providers.dart`) and customer screens (`customer_providers.dart`) are Riverpod-based too; the remaining screens (delivery, sales, auth) use plain `setState` and the ChangeNotifier ViewModels. Treat Riverpod as the convention going forward; reconcile the other roles' approach with whoever owns that decision before adding more state-management patterns.

### Database (offline-first)
- **Local:** Drift ORM over SQLite (`lib/core/database/`). Ten tables: users, products, customers, orders, order_items, deliveries, stock_movements, suppliers, payments, delivery_routes. Schema version 15 — v12/v13/v14 are "intentional database" passes dropping 33 dead columns (every column must have a live reader); v15 is a data repair, not a schema change: it sets defaults, via `customStatement`, on legacy NULLs in columns Drift declares non-nullable in `payments`, `orders`, `order_items` and `customers` (a single NULL there makes the generated `map()` throw and greys every screen watching that stream). The matching Supabase cleanup is `supabase/migrations/drop_dead_columns.sql`, run manually AFTER its companion `audit_dead_columns.sql` (read-only; shows which columns hold real data).
- **Remote:** Supabase PostgREST (`lib/core/config/supabase_config.dart`).
- **Sync:** `SyncManager` (singleton) drives push/pull via `SyncEngine`. Records carry a `sync_status` column (`pending` | `synced`, and `error` for a pulled row that failed to apply — see `SyncEngine._markRowSyncError`). Push runs on login and startup (unless disabled via Settings' auto-sync toggle); pull runs after push. Last-sync timestamp is persisted via `AppSettings` (`lib/core/settings/app_settings.dart`, backed by `shared_preferences`).

### Auth
`AuthService` singleton (`lib/core/auth/auth_service.dart`) owns the local Drift session. Supabase Auth runs alongside for token-based RLS. Passwords are bcrypt; SHA-256 hashes are migrated on next login. Note: there's a second, largely-parallel implementation in `AuthRepository` (`lib/features/auth/data/auth_repository.dart`) used for customer self-signup and staff account creation — historically it hashed with plain SHA-256 (fixed to bcrypt+migration, matching `AuthService`, but the duplication itself is unresolved debt). `AuthRepository.login()` is not wired into the live login screen at all (only `AuthService.login()` is) — it's exercised by `auth_repository_test.dart` but otherwise dead code.

### Navigation & roles
`RoleBasedNavigation.navigate()` in `lib/core/constants/user_roles.dart` routes to the correct dashboard. There are THREE shells, not one: `ResponsiveShell` (`lib/core/widgets/responsive_shell.dart`, sidebar + hamburger, bottom nav on mobile) is **admin and warehouse only** (`WarehouseShell` wraps it); `CustomerShell` (`lib/features/customer/widgets/customer_shell.dart`, bottom-nav, phone-width) is **customer only**; `SalesShell` (`lib/features/sales/widgets/sales_shell.dart`, bottom-nav, mobile-only) is used by **sales rep AND delivery** — both roles land on `/sales/home`. (`features/delivery/screens/*` also exist with their own Scaffold but login does not route to them.)

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

## Building and distributing

```
flutter build apk     --release --dart-define-from-file=secrets.json   # Android
flutter build windows --release --dart-define-from-file=secrets.json   # Windows (admin)
```
The `--dart-define-from-file` flag is **mandatory**. `lib/core/config/supabase_config.dart` reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from it; without the flag the build succeeds and then fails at runtime with empty credentials.

iOS cannot be built on Windows — Flutter requires macOS and Xcode. Builds run on Codemagic instead (`codemagic.yaml`); see §7.6 of the project documentation.

**Known flaky Windows build failure — C1083, missing `cpp_client_wrapper` sources.** The Flutter cache is intact; the copy into `windows/flutter/ephemeral` just fails sometimes (antivirus is the usual suspect, unconfirmed). Deleting `ephemeral` alone is NOT enough. Fix:
```
Remove-Item -Recurse -Force windows\flutter\ephemeral, build\windows
flutter build windows --release --dart-define-from-file=secrets.json
```
Both folders are generated and gitignored. Also close any running instance first, or the link step fails with LNK1104 because Windows locks a running exe.

**Distributing the Windows app:** ship the whole `build\windows\x64\runner\Release\` folder (~44 MB), not just the 112 KB exe — it needs the DLLs and `data\` beside it. Zip the folder. The local database lives in the user's `Documents\`, not in the app folder, so replacing the folder to update the app does **not** lose local data or unsynced orders.

### Windows installer (Inno Setup)
Script: `installer/vm_distribution.iss`. Build Flutter first, then compile it with Inno Setup's CLI:
```
& "C:\Users\jedey\AppData\Local\Programs\Inno Setup 7\ISCC.exe" installer\vm_distribution.iss
```
Output: `installer\VMDistributionSetup-1.0.0.exe` (gitignored). **Note the path:** Inno Setup 7.1.1 installs under `AppData\Local\Programs`, NOT `C:\Program Files (x86)\Inno Setup 6\`.
- **Open or compile it from `installer\`.** `BuildDir` is relative (`..\build\windows\x64\runner\Release`), so a copy opened from Downloads resolves to a path that doesn't exist and silently produces an installer containing only the uninstaller (~4.5 MB instead of ~16 MB). That exact failure happened on 18 Nov. **A healthy setup exe is ~16 MB**; ~4.5 MB means it packaged nothing.
- The installer packages whatever is in `build\windows\x64\runner\Release` **at compile time**, so build Flutter first and check the exe's timestamp.
- `AppId` is fixed at `{690807F2-B875-4E02-9DCF-35DBF4EDB1A7}`. **Never regenerate it** — Windows uses it to tell an upgrade from a separate app.
- Per-user install (`PrivilegesRequired=lowest`): no admin rights, no UAC prompt. The local SQLite DB lives in the user's Documents, not the install folder, so upgrading does not lose data.
- The script also registers the `io.supabase.villahermosa://` URL scheme under HKCU (needed for Google sign-in on Windows — see A3).
- **Zip before uploading to Drive** — Chrome blocks bare `.exe` downloads. Use Windows' own `tar.exe` from inside `installer\` (Git Bash's `tar` cannot write zips): `& "$env:SystemRoot\System32\tar.exe" -a -c -f VMDistributionSetup-1.0.0.zip VMDistributionSetup-1.0.0.exe`.

## Development conventions
- Pass `AppDatabase` and `SyncManager` down through constructors; both are singletons initialised in `main.dart`.
- Access the shared database in leaf widgets via `AuthService.instance.database`.
- Soft-delete only — never hard-delete rows. Set `is_deleted = true` and `sync_status = 'pending'`.
- After any local write, set `sync_status = 'pending'` so the next sync cycle picks it up.
- Every post-login screen is wrapped in its ROLE's shell — `ResponsiveShell` (admin, warehouse via `WarehouseShell`), `CustomerShell` (customer), `SalesShell` (sales rep and delivery). **`ResponsiveShell` is NOT used by every role** (an earlier version of this line said so and misled the sync-indicator spec). Anything meant to appear for all roles must go in all three shells.

## Current status (Nov 2026)
- **Done — admin role:** every admin screen (Dashboard, Products, Customers, Orders, Payments, Stock Movement, Deliveries/Routes, Reports, Settings, User Accounts) is real, wired to live Drift data via Riverpod stream providers.
- **Done — sync engine pull:** all 10 tables now have typed `insertOnConflictUpdate` pull implementations registered in order (users → products → customers → orders → order_items → stock_movements → payments → deliveries → suppliers → delivery_routes). All were `// Implementation needed` stubs before Nov 2026.
- **Done — delivery confirmation:** `DeliveryViewModel.confirmDeliveryByButton` and `confirmDeliveryByCode` are implemented (Drift write → `markOrderDelivered` → background sync). The QR tab now launches `SalesScanScreen`. Fixed Nov 14: the ViewModel now fetches the order by uuid and guards on `out_for_delivery` — it previously looked up the `deliveries` table, which NOTHING ever writes to (pull-only, zero rows in Supabase, `createDelivery` has no callers), so confirmation always failed. Also fixed: `_setLoading(false)` in `finally` was wiping `_error` after `_setError`, making every failure render as success.
- **Done — schema intentionality (v12–v14):** 33 dead columns dropped across order_items, users, products, customers, suppliers, orders, stock_movements (commits 1c58b7c, e0234a0, 5a9d178+fb07a3d). `app_database.g.dart` is now build_runner-generated (d62d1be replaced an earlier hand-edited copy that had dropped live columns); the table definitions in `lib/core/database/tables/` are the source of truth, so after changing one run `dart run build_runner build --delete-conflicting-outputs` and commit the result.
- **Done — route/rep assignment compiles again:** commit 22081b0 (Nov 13) shipped `assignOrderRoute`/`assignRoute`/the pickers passing String uuids into `IntColumn` orders.routeId/salesRepId — five type errors; the feature never built. Now aligned to local int ids. NOTE: those ids are vestigial (not cross-device stable, nothing filters on them); delivery dashboards match orders to reps by `salesRepName` string (`watchOrdersBySalesRep`). See arch debt before "improving" this.
- **Done — warehouse dashboard:** activity tile taps navigate to the correct sidebar section.
- **Done — customer card widget:** `CustomerCard` is a real `ConsumerWidget` using Riverpod providers.
- **Done — warehouse and customer screens:** no longer placeholders. Every warehouse screen (dashboard, incoming orders, prepare/picklist, loading & dispatch, inventory, stock movement, routes today, returns, reports, sync & activity) and the customer screens read live Drift data through Riverpod providers and have widget tests.
- **Tests:** 13 `*_test.dart` files under `test/`, 134 tests passing. Covered: the database layer (`database_test.dart`, `customers_test.dart`), the auth repository, theme/design system, sync pull behaviour (`pull_failures_test.dart` — failed rows counted and flagged; `pull_keeps_local_state_test.dart` — local-only state survives a pull, push/pull key agreement, uuid handling), and widget/screen tests for the customer screens, all warehouse screens (`warehouse_screens_test.dart`, `picklist_pick_test.dart`), the QR/manual delivery flows (`qr_delivery_flow_test.dart`, `manual_delivery_test.dart`) and the sales home scan (`sales_home_scan_test.dart`), plus an app smoke test. **Still uncovered:** the admin screens and Riverpod providers, the sales/rep order-entry flow (`new_order_flow.dart`), the login/signup UI, `AuthService` itself, and the push half of the sync engine (nothing exercises a real Supabase client; only the payload maps are tested).

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
4. **Windows (browser flow):** the Google button appears on the Windows login screen only when `googleSignInAvailable()` (`lib/features/auth/oauth_platform.dart`) confirms the `io.supabase.villahermosa://` scheme is registered in `HKCU\Software\Classes\io.supabase.villahermosa\shell\open\command` AND points at the running exe — so `flutter run` and unzipped `build\` copies correctly show no button. It depends on three things, all of which must stay true: (a) the **HKCU scheme registration written by the installer** (`installer/vm_distribution.iss` `[Registry]`); (b) `io.supabase.villahermosa://login-callback` in Supabase → Authentication → URL Configuration → Redirect URLs; (c) **`windows/runner/main.cpp` forwarding** the callback launch to the running window (`SendAppLinkToInstance`), which finds the window by its title — **it breaks silently if the title passed to `window.Create` ("Villahermosa Marketing") ever changes without updating the string in `main.cpp`** (the second process then starts a second window instead of forwarding). It can only be tested from an installed build. After the first Google sign-in the user is offered, once, to set a password (`set_password_dialog.dart`) so the account also works without Google.

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
- Status columns: `orders.status` (pending/confirmed/processing/completed/cancelled), `orders.warehouseStatus` (live values: pending → processing → ready → dispatched; `picked` and `packed` are vestigial — see note below), `deliveries.status` (pending/in_progress/delivered/failed).

### Sync engine — what moves where

- `warehouseStatus` note: nothing in the app ever WRITES `picked` or `packed` (writers set only `processing`, `ready` and `dispatched`, in `warehouse_providers.dart`). They survive only as read-side leftovers: `getOrdersForLabels()` (`app_database.dart`) still matches them, `whOrderStatus()` maps `packed` → `ready`, and `label_printer.dart` has labels/colours for them. Per-item picking progress lives in `order_items.status` instead. `shipped` and `delivered` do not appear in the code as warehouse statuses at all (delivery is `orders.status`).

**S1 — Push flow (client → Supabase)**
- Triggered: on login, on startup (if auto-sync enabled), and manually from the Settings screen.
- Tables pushed in order: users (via Edge Function), suppliers (via Edge Function), products, customers, orders, order_items, stock_movements, payments, deliveries.
- Each push selects `WHERE sync_status = 'pending'` — NOT filtered on `is_deleted` (the `getPendingSync*` helpers have no such filter), so a soft-deleted row pushes with `is_deleted = true` provided it was marked pending.
- Conflict key: `onConflict: 'uuid'` for users (via the Edge Function), products, customers, orders, order_items, deliveries and delivery_routes. **suppliers (Edge Function, `onConflict: 'id'`), payments and stock_movements upsert on the primary key** — see the multi-device hazards under architecture debt. `product_id` and `order_id` are resolved from local uuid → Supabase numeric id before the payload is sent, but orders send the LOCAL customer int id as `customer_id` (`getCustomerByIntId` on the pull side), which relies on id-parity — also under architecture debt.

**S2 — Pull flow (Supabase → client)**
- Triggered: after push on each sync cycle.
- Tables pulled in order: users, products, customers, orders, order_items, stock_movements, payments, deliveries, suppliers, delivery_routes.
- **Full fetch** (no timestamp filter): users, orders, order_items, suppliers, delivery_routes.
- **Filtered** with `updated_at >= lastSyncTime`: products, customers, stock_movements, payments, deliveries.
- Consequence for hand-applied SQL: a plain `UPDATE` run in the Supabase SQL Editor does NOT bump `updated_at`, so for those five filtered tables the fix never reaches a device that has already synced past that timestamp. Either set `updated_at = now()` in the statement, or expect to need a fresh install. A fresh install is unaffected, because `lastSyncTime` starts at epoch.
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

**B2 — FIXED IN CODE (Nov 2026), NOT YET VERIFIED END-TO-END: new/reset-password user can't log in on a device that has never seen the account**
- Cause (it was a missing call, not a design limitation): the only path by which a password reaches Supabase Auth is `AuthService.upsertSupabaseAuthUser` (the `upsert_auth_user` action of the privileged-sync Edge Function), and **nothing called it**. Admin Reset Password updated Drift and `public.users.password_hash` but left Supabase Auth on the old password, so login STEP 1b (`_attemptSupabaseAuth`) was rejected, `bootstrapUsers()` never ran, and it surfaced as "invalid credentials". The old note that `_attemptSupabaseSignup` covers admin-created accounts was wrong: the admin dialogs never called it (and it is the self-signup path).
- Fix: every place a password is set now reaches Supabase Auth, **Supabase first, then the local bcrypt hash, so a failure changes nothing and is shown to the user** (`PasswordSetException`, red snackbar), never reported as success:
  - admin Reset Password → `AuthService.adminResetPassword` (`upsert_auth_user`, then local hash + `forcePasswordChange`);
  - admin Add User → `AuthService.syncPasswordToSupabaseAuth` before the local row is created (nothing is created if it fails);
  - a user choosing their own password (forced change after a reset, or "Set a password" for a Google account) → `AuthService.setPassword`, which uses `auth.updateUser` on the caller's OWN session — `upsert_auth_user` is admin-only and would 403 for them. A forced-change user normally has that session because login STEP 2 signs into Supabase Auth with the temporary password the reset put there. `change_password_screen.dart` no longer writes SHA-256 and goes through `setPassword`.
- Consequences to know: admin Reset Password and Add User now require being **online and signed in to Supabase as an admin**; they fail (with a message) offline. A forced change with no live Supabase session also fails with a message — "sign out and sign in again while online".
- **Open risk — verify before relying on it:** `privileged-sync`'s `upsert_auth_user` calls `admin.auth.admin.listUsers()` with no paging arguments and searches that one page for the email. The default page size is 50, and there are ~410 accounts, so for most users the lookup will miss, fall through to `createUser`, and fail with "already registered" — surfaced by the new error handling as "Couldn't update the online login". Fix the Edge Function (page through, or look the user up by email) and redeploy it; this has not been tested against the live project.
- Still-open edge: self-signup staff accounts (`AuthRepository.createStaffAccount`) never create a Supabase Auth user (the caller isn't an admin, so `upsert_auth_user` would 403); an admin resetting that password afterwards fixes it.

**B3 — FIXED (Nov 2026): Wrong date (2024-12-12) on pulled orders in Windows list**
- Cause: `createdAt` missing from the `orders` `insertOnConflictUpdate` companion in `_updateLocalRecord` — Drift defaulted to epoch.
- Fix: `createdAt: Value(_toDateTime(data['created_at']) ?? DateTime.now())` added to both orders and order_items companions.

**B4 — FIXED IN CODE AND CONSOLE (Nov 15), NOT YET VERIFIED ON A DEVICE: Google Sign-In**
- Filed originally as "release APK SHA-1 not registered". It was three independent faults, each fatal on its own, and the feature has never worked in any shipped build.
- **(a) Firebase Authentication had never been set up** on the project, so `android/app/google-services.json` contained no `oauth_client` entries at all — no `client_type: 3` (web) and no `client_type: 1` (Android). There was nothing for a SHA-1 to attach to. Fixed by enabling the Google provider in Firebase Authentication and registering the release keystore SHA-1 (`79:2B:87:…`), then re-downloading `google-services.json`.
- **(b) The hardcoded client id was from a DIFFERENT Google Cloud project.** `auth_viewmodel.dart` passed `331867448304-saipigd6…`; this app's project is **378436113717** (`villahermosa-667c8`). A client id from another project can never authenticate this app. Note any older documentation quoting 331867448304 is wrong.
- **(c) `android/app/src/main/res/values/strings.xml` hand-defined `default_web_client_id`** with that same wrong id. The `com.google.gms.google-services` Gradle plugin generates this resource from `google-services.json`, but a copy in `src/main/res` overrides the generated one — so Android resolved the wrong project regardless of what `google-services.json` said. Removed; the file now carries only a comment telling you not to re-add it.
- Also corrected: `google_sign_in` **ignores `clientId` on Android** — it is an iOS/web parameter. The ID token audience comes from `serverClientId`, which is now set to the web client `378436113717-g8t37mbk9rm6162t5utlvpfgsga8rg51.apps.googleusercontent.com`. That same id is registered under Supabase → Authentication → Providers → Google → Authorized Client IDs; both must match or Supabase rejects an otherwise-valid token.
- **Still outstanding:** the **debug** SHA-1 (`7B:AE:F2:…`) is not registered, so sign-in works in **release builds only** — a `flutter run` debug build will still fail with `DEVELOPER_ERROR` (code 10). Add that fingerprint in Firebase if you want it working during development. And none of this has been exercised on a physical device yet.
- Verify the config with: parse `android/app/google-services.json` and list `oauth_client` by `client_type`; you need at least one `1` and one `3`, and the project number must be 378436113717.
- **Email/password login is unaffected** and remains the primary path.

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
- `WarehouseViewModel` no longer exists (warehouse uses Riverpod providers). `CustomerViewModel` still exists but nothing references it — the customer screens use `customer_providers.dart`. `DeliveryViewModel` confirmation methods are real (Nov 2026).
- QR scanning: `mobile_scanner: ^5.2.3` and `qr_flutter: ^4.1.0` are in `pubspec.yaml`. `SalesScanScreen` is fully implemented.
- **Rep assignment matches by name, not id (deliberate, fragile):** an order reaches a delivery rep's dashboard via `orders.salesRepName == '<rep's exact display name>'`. Renaming a rep in User Accounts strands their assigned orders; two reps with the same name see each other's. The proper fix is switching `orders.routeId`/`salesRepId` to text uuids end-to-end (Drift v16 + g.dart + sync casts + Supabase `bigint → text` + dashboard filter) — sketched at the bottom of `supabase/migrations/drop_dead_columns.sql`. Until then, keep rep display names unique and stable.
- **Sync push/pull key convention (picks, packed_at, delivery dates now sync):** `order_items.status`/`picked_at`, `orders.packed_at`/`expected_delivery_date`/`actual_delivery_date` and `stock_movements.user_id` are in the push maps and exist in Supabase, so warehouse picks CAN sync across devices — but until the sync fixes below (central `syncStatus = 'pending'` in the write helpers) no pick ever qualified to be pushed, because `setItemPicked` left the row `synced` and push only sends `pending` rows. They sync now; before that, the earlier "picks sync across devices" claim was wrong. The pull still keeps the local value whenever the server sends NULL (`?? existing...`) — rows that predate those columns are NULL server-side, and without the guard the first sync would wipe every local pick/date. The guards are the migration mechanism; do not "simplify" them away. Convention: a column's push-map key and pull-read key must be the same string AND match the real Supabase column. Mismatches are invisible from Dart (the pull just reads null) and only show up by comparing both maps against `information_schema` — that is how `stock_movements.reference` (pull read `reference_id`) and `performed_by_name` (pull read `user_name`) went unnoticed.
- **Root cause of the "local change reverts / never syncs" bugs (fixed in three layers):** the picklist-tick, role-change and Process reverts are one race, not three unrelated bugs (diagnosed from the code and covered by tests; not yet reproduced on a device; the picklist case also had a separate cause, fixed in 96b51d2: the pull's NULL-status default). `SyncManager` had no concurrency guard; Realtime subscribes to all 10 tables and fired a bare PULL (2s debounce) while a push from `syncInBackground()` was still in flight, and the pull overwrote the local row with the server's older copy (~1s after the tap). Separately, six write paths changed a `synced` row without marking it `pending`, so push never saw them at all: `softDeleteUser`, `softDeleteProduct`, `softDeleteCustomer` (**deleted users/products/customers never synced**), route status changes (`updateDeliveryRoute`), `setItemPicked` and `setItemLoaded`; `completeOrder` only marked the row pending when the order was still `pending`, so for the normal processing→ready step `warehouse_status`/`packed_at` never pushed; `updatePayment` and `updateDeliveryRoute` had no guard either (payments callers happened to pass `pending` themselves). Fixes:
  1. **Serialise sync** — `SyncManager.syncPendingData()` is single-flight (concurrent callers share the in-flight Future; if anyone joined mid-cycle and rows are still pending afterwards, exactly one more cycle runs). `performFullSync()` waits for it instead of overlapping. The Realtime handler calls `syncPendingData()` (push THEN pull), never a bare `pull()`. A standalone `pull()` (post-login) is not locked.
  2. **The pull never clobbers unpushed work** — `SyncEngine._updateLocalRecord` skips any row whose local copy has `sync_status = 'pending'` (matched the way that table's pull writes: uuid for orders/order_items/delivery_routes, id for payments, id-or-uuid for the rest) and leaves it pending so the next push sends it. The `?? existing...` guards stay (they handle legacy-NULL rows that ARE synced). Consequence: a row whose push keeps failing is never refreshed from the server until it pushes.
  3. **Make forgetting impossible** — every `update*`/`softDelete*` helper in `app_database.dart` forces `syncStatus: 'pending'` (and `updatedAt`) over whatever the caller passed; new `updateOrderById`/`updateOrderItemById` do the same and `WarehouseActions` uses them. **To mark a row synced you must write it directly** (as `SyncEngine._markRecordAsSynced` does) — `updateCustomer(..., syncStatus: 'synced')` is silently overridden. Don't add a raw `update(...).write(...)` of a synced table in feature code without setting `syncStatus`.
- **Suppliers are server-owned (checked):** `suppliers.sync_status` defaults to `'synced'` (the only table that does) deliberately — nothing creates or edits a supplier locally (`upsertSupplier` has zero callers; the UI only reads them), rows arrive only by pull. If a local supplier editor is added, set `syncStatus: 'pending'` explicitly.
- **Known gap — `orders.warehouse_status` pull has no keep-local guard:** it syncs both ways, but its pull fallback is `?? 'pending'`, not the `?? existing...` guard used for picks and `packed_at`. A legacy Supabase row with `warehouse_status` NULL therefore resets a local `ready`/`dispatched` to `pending` on pull. Push runs before pull so this normally self-corrects, but it bites when the push fails (row in `sync_status` `error`, or a network failure mid-cycle). Fix: use the same existing-value guard, with a test like `pull_keeps_local_state_test.dart`. Not done yet.
- **Multi-device id-collision hazards (known, not fixed):** local `id` is Drift's per-device autoincrement, so any table that upserts to Supabase on the primary key lets two devices overwrite each other's rows. Customers were fixed: the push upserts on `uuid` and deliberately KEEPS `id` in the payload, because orders push/pull resolve `customer_id` by local int id and depend on id-parity — a colliding id therefore fails loudly and the row stays `pending`, which is the intended trade (see the FK id-parity bullet below). Two remain:
  - **payments** has no `uuid` column locally or in Supabase, and `paymentId` is generated as max(local)+1, so two devices both produce `PAY-009`. Needs a Drift migration plus a generator fix.
  - **stock_movements** pushes a `uuid` now, but the Supabase column has no UNIQUE index and is NULL for every pre-existing row, and the push still upserts on the primary key (no `onConflict`). Switch to `onConflict: 'uuid'` only after pushes have backfilled the NULLs and the UNIQUE index exists.
  - **Two-device dispatch double-deducts stock (known, not fixed):** `OrderStockService`'s idempotency check reads `stock_movements` rows **already pulled to this device**. Two devices that dispatch the same order before their movements have synced each see "nothing deducted yet" and each deduct once. It is reachable in practice: both the warehouse Loading & Dispatch screen and the admin order panel can dispatch. It compounds with the stock_movements hazard above: the two duplicate audit rows are separate local rows but have no UNIQUE uuid server-side and the push upserts on the primary key, so on the way up they can also overwrite each other in Supabase (and the pulled product `current_stock` is last-writer-wins, so the net stock can be wrong either way). **These are the same job** as the parked stock_movements uuid work (backfill NULL uuids, UNIQUE index, `onConflict: 'uuid'`): that is the prerequisite for a real fix. Note a UNIQUE index alone is not enough — the two devices generate different random v4 uuids for what is logically the same movement — so the dispatch deduction would also need a DETERMINISTIC movement uuid (derived from order uuid + product uuid + reason), making the second device's insert collide instead of double-counting. Not fixed here.
  - **FK id-parity is relied on and already broken for orders:** orders push sends the LOCAL customer int id as `customer_id` and the orders pull resolves it with `getCustomerByIntId`, so a customer must have the same numeric id in SQLite and Supabase. That is why `_pushCustomers` keeps `id` in the payload (a colliding id fails loudly and the row stays pending). `_pushOrders` already does `data.remove('id')`, so Supabase assigns its own id to every inserted order: on a second device `getOrderByIntId` then returns null for `order_items` and `deliveries`, and they get `orderId` = the stringified remote int instead of the parent order's uuid — orphaned rows. Do NOT copy the `data.remove('id')` pattern to other tables. The real fix for both is to stop relying on id-parity (resolve FKs by uuid on both sides, or look up the remote id by uuid at push time). Documented, not attempted.
- **Frozen rows — Layer 2 × permanent push failures (known, not fixed):** the pull skips any row whose local `sync_status` is `'pending'` (5ef4f8b). A push that fails is caught per record, `debugPrint`ed, and leaves the row `'pending'`. So a row whose push can NEVER succeed — e.g. a customer whose local id collides with an existing Supabase id and fails on the primary key, which `_pushCustomers` deliberately allows (see the FK id-parity bullet) — is frozen: it never pushes, and it is never refreshed from the server either. `push()` still reports `success: true` (and `performFullSync` therefore does too), because per-record failures are swallowed, so nothing surfaces anywhere. **Fix, when there is time to test it:** after N consecutive failed push attempts for a row, set `sync_status = 'error'` (the column already supports it and `SyncEngine._markRowSyncError` exists). Layer 2 skips only `'pending'`, so an `'error'` row resumes receiving server updates. Pair it with a failed-record count in the push result (the pull side already returns `failedCount`) so a stuck row is visible instead of silent. Needs somewhere to count attempts (a column or an in-memory map) — not designed yet.
- **Trap — soft-delete doesn't propagate for three tables:** the `orders`, `order_items` and `delivery_routes` pulls filter `is_deleted = false`, so a soft-delete of one of those on another device would never reach this one. Harmless today: the only soft-delete paths in the app are `softDeleteUser`, `softDeleteProduct` and `softDeleteCustomer`, and none of the users/products/customers pulls filter on `is_deleted`. Whoever adds order (or route) deletion must remove that filter, or pull deleted rows and apply them.
- **Stock is deducted when an order is DISPATCHED (Nov 2026) — `lib/core/services/order_stock_service.dart`.** Before this, nothing in the order lifecycle changed `current_stock`; `adjustProductStock` was only reachable from manual screens. Now `OrderStockService.applyStatusChange(orderUuid, newStatus)` is the single place: → `out_for_delivery` deducts each order line (one `stock_movements` row per line, reason `Order fulfillment`, `referenceId` = the order's **uuid**, via `adjustProductStock`, so the audit trail and the product's `pending` sync come for free); → `cancelled` puts back whatever is still deducted (reason `Order cancelled`, same referenceId). Both entry points call it inside the same transaction as the status write: `WarehouseActions.dispatchOrders` and `OrdersService._setStatus` (admin panel's Dispatch / Cancel). Those are the only two code paths that set `out_for_delivery` — the sales-rep screens only READ that status (to confirm delivery); there is no rep-side dispatch. `restoreOrder` (→ pending) deliberately moves no stock.
  - **Why dispatch, not order creation:** dispatch is when goods physically leave. Reserving at creation is a different model and would double-count against this one.
  - **Why idempotency is keyed on `stock_movements`, not order status:** sync can move a status backwards and forwards (the pull overwrites; statuses flap), and a status-based "already deducted" check would double-deduct with no trace. The amount currently deducted for an order is derived from its movements: `Σ 'Order fulfillment' − Σ 'Order cancelled'` per product. Dispatch skips if anything is still deducted; cancel restores exactly what is still deducted (so a second cancel, or cancelling a never-dispatched order, does nothing). Refinement of "skip if a fulfillment row exists": a fulfillment row that has been cancelled out no longer counts, otherwise cancel → restore → dispatch again would never deduct again.
  - **Negative stock is deliberate:** ~322 of 325 products sit at 0 on the live data; refusing to dispatch when stock is short would stop dispatch working. Stock goes below zero instead, which is truthful and makes the data problem visible: negative figures render red (`stockColor` already treated `<= 0` as error) and `ProductStatusBadge` now says "Negative Stock" below zero.
  - **Failures are surfaced:** if the deduction throws, the transaction rolls the status write back too, so the order stays in its old status. The admin panel shows a red snackbar ("Couldn't Dispatch for Delivery: ORD-n was not changed. …") and stays open/selected; `WarehouseActions.dispatchOrders` returns a `DispatchResult` (each order is its own transaction, so one failure doesn't stop the rest) and the Loading & Dispatch screen shows "Dispatched 2 of 3. Out for delivery: …. NOT dispatched: ORD-x (reason)" in red. Never log-only: debugPrint is invisible in a release build.
  - **Known limits:** a line whose product no longer exists (or whose `productId` is an orphaned remote int) is logged and skipped, not an error. Two devices dispatching the same order before their `stock_movements` have synced would each deduct once — idempotency only sees movements it has already pulled.
  - **CLIENT TRAINING NOTE — double deduction:** the Stock Movement screen still offers a manual stock-out with reason **"Order fulfillment"**. Dispatching an order now deducts automatically, so **staff must stop recording order fulfilment by hand** — doing both takes the stock out twice. Manual stock-out remains correct for Damaged / Expired / adjustments.
- **Global sync status indicator (display only) — `lib/core/widgets/sync_status_indicator.dart`.** Shown by every role from its shell: `ResponsiveShell` (admin + warehouse, via `WarehouseShell`; sidebar footer on desktop, app-bar action on mobile), `CustomerShell` and `SalesShell` (a `SyncStatusStrip` that collapses to a **3px hairline in the green token** while online with nothing pending (so "all synced" is always visible, with an invisible ~20px tap target over the top of the screen that opens the sync sheet) and animates open to the full 30px strip — respecting reduced motion — when rows are pending or the device is offline; **sales reps and delivery both land on `SalesShell`**; one `SyncStatusScope` per shell shares a single `SyncStatusModel`). An earlier version put a floating dot over the bottom bar's top-right corner; it overlapped the last tab (Profile) and stole taps, so it was removed — one indicator per shell, not two. Trade-off of the hairline's tap target: it adds no height but sits over the top ~17px of the screen content while collapsed, so those screens must keep their first controls ~16px+ from the top (today they do; it is padding). It deliberately shows a **pending count, not a connection state**: offline is normal in an offline-first app, and a green "connected" dot would sit over stuck data because `push()` swallows per-record failures and returns `success: true`. Four states: online+0 → green "All synced"; online+N → amber "Syncing N items..."; offline+N → amber "N items waiting - offline"; offline+0 → grey "Offline". Tap → sheet with the per-table breakdown ("2 orders", "1 customer"), last sync time and a "Sync now" button (`SyncManager.syncPendingData`). It replaced the warehouse dashboard's `_SyncChip` (the last-sync time moved into the sheet). The count comes from `AppDatabase.watchPendingCounts()` — ONE `customSelect` UNION ALL of ten `COUNT(*)` queries over the synced tables (chosen over ten list streams so hundreds of pending rows never rebuild lists; `distinct` suppresses identical emissions).
  - **Known limitation — the count does not clear for a row that can never push:** a stuck row stays `'pending'`, so the number never reaches zero. Treat that as a feature for now (a stuck count is how someone notices). It is the frozen-rows hazard above. **Once the failed-record count / `'error'` marking exists, this widget should gain a fourth, red state for rows in `sync_status = 'error'`.**
  - **Why the indicator re-reads on `SyncManager.syncCompleted` (no timer):** `SyncEngine._markRecordAsSynced` writes `sync_status = 'synced'` with `customUpdate(...)` and no `updates:` set, which Drift cannot turn into a stream notification, so a Drift stream (this one, and any `watch*` stream) can stay stale after a successful push until some other write lands. Local writes still notify normally, so the watch stream stays for them; `SyncManager.syncCompleted` (a `ValueListenable<int>`) ticks **once per finished cycle** (a `syncPendingData` cycle or a `performFullSync`, however it ended) and the model re-reads with a one-shot `getPendingCounts()` (not `watchPendingCounts().first`, which Drift can answer from the shared stream's cached value). **Do NOT "fix" this by adding `updates:` to `_markRecordAsSynced`:** that runs per record, so a 300-row sync would fire 300 stream notifications and rebuild every watching list 300 times mid-sync. The right shape is **notify once per cycle, not per record.** (The first version of the indicator polled every 5 s; that was replaced by this signal.)
  - A bare `customStatement` also never notifies streams; if you write `sync_status` that way outside the engine, expect the same staleness.
- **Redundant Supabase column:** `stock_movements.user_name` is empty and unused (the real column is `performed_by_name`). Add it to the `drop_dead_columns` candidate list.
- **`deliveries` table is write-orphaned (both sides):** zero rows in Supabase, no trigger/function/Edge-Function writer, `createDelivery` has zero callers, pull always returns empty. It was scaffolding for a per-delivery tracking workflow (driver, timestamps, proof-of-delivery, collected amount) that was never built — order `status` is the real handoff between warehouse and delivery. Candidate for the next intentionality pass: dropping it touches the Drift table, pull registration, and generated code, so it's a code change plus SQL, not SQL alone.
- **Fixed (Nov 2026):** all sync engine pull stubs are now implemented — `_pullOrders`, `_pullOrderItems`, `_pullStockMovements`, `_pullDeliveries`, and `_pullPayments` all have typed `insertOnConflictUpdate` cases in `_updateLocalRecord`.
