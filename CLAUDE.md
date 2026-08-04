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

## Current status (July 2026)
- **Done — admin role:** every admin screen (Dashboard, Products, Customers, Orders, Payments, Stock Movement, Deliveries/Routes, Reports, Settings, User Accounts) is real, wired to live Drift data via Riverpod stream providers. This is the most complete role by far — previous "placeholder" notes in this file were stale.
- **Stub — warehouse, customer, delivery roles:** dashboards and screens exist but are mostly static UI with no database wiring. Warehouse specifically has several duplicate/unused dashboard variants (`simple_warehouse_dashboard.dart`, `tablet_warehouse_dashboard.dart`) and a `product_list_screen_mock.dart`; delivery's route screen and QR confirmation tab are explicit unbuilt placeholders.
- **Stub — ViewModels:** `WarehouseViewModel`, `CustomerViewModel`, `DeliveryViewModel` are TODO-commented stubs that only toggle loading/error flags, no real logic. `WarehouseViewModel` isn't referenced by any screen at all.
- **Dead code to clean up:** `lib/features/admin/screens/users_screen.dart` (`AdminUsersScreen`) duplicates the real, routed `user_accounts_screen.dart` and is never routed itself.
- **Tests:** only 4 test files total (`test/`), covering the database layer and auth repository. Zero UI/ViewModel test coverage across all four roles.

## Known architecture debt
- **Fixed (Aug 2026):** the Supabase service-role key no longer ships in the client at all. It previously lived in `SupabaseConfig.serviceKey` and was used directly for user/supplier sync in `sync_engine.dart` and `auth_repository.dart` — that's now routed through the `privileged-sync` Edge Function, which holds the key server-side only. RLS was also enabled on the 8 tables that had none at all before (`supabase/rls_policies.sql`), and the pre-existing `users` table policy that let any authenticated account insert a row with `role = 'admin'` was closed (client-side writes to `users` are no longer possible at all — everything routes through the Edge Function, which verifies the caller's role server-side by email before allowing anything other than `role = 'customer'`).
- **Known limitation of that fix, not yet resolved:** there is no reliable way to determine an authenticated caller's app-level role (admin/warehouse/sales_rep/delivery) from SQL alone. `AuthService.signup()` sets the local `users.uuid` to a millisecond-timestamp string, unrelated to the real Supabase Auth user id — the two are never linked anywhere in this codebase, for any existing account or new one. That means RLS currently can't restrict payments/customer credit data/etc. to admin-only; any authenticated account (including a self-registered customer) can read and write those tables. Real per-role restriction needs a one-time migration backfilling `users.uuid` to the real Supabase Auth id (matched by email across ~410 real accounts) plus a `SECURITY DEFINER` role-lookup function — deliberately not attempted as part of the same pass that removed the service key, since it touches live production account data and needs its own dedicated testing.
- Two parallel, duplicated auth implementations (`AuthService` and `AuthRepository`) — see Auth section above.
- WarehouseViewModel, DeliveryViewModel, CustomerViewModel methods are stubs — business logic not yet implemented, and none are consistently wired into their screens.
- QR scanning was never actually wired up — there's no scanner dependency in `pubspec.yaml` at all (not even commented out), and `qr_service_locator.dart` is a pure stub returning a bare `Object()`.
- `_pullOrders()`, `_pullOrderItems()`, `_pullStockMovements()`, and `_pullDeliveries()` in `sync_engine.dart` are literal `// Implementation needed` stubs — data created on one device for these tables never appears on another. Only users/products/customers/suppliers pull correctly. `payments` isn't in the pull cycle at all — not even as a stub call, it's simply never attempted.
