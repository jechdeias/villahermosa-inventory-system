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
Provider (`provider: ^6.1.2`) + `ChangeNotifier`. Five ViewModels live under `lib/features/<feature>/viewmodels/`. Some screens still use plain `setState` — the goal is to move everything to ViewModels over time. Do **not** introduce Bloc or Riverpod without agreement.

### Database (offline-first)
- **Local:** Drift ORM over SQLite (`lib/core/database/`). Seven tables: users, products, customers, orders, order_items, deliveries, stock_movements. Schema version 3.
- **Remote:** Supabase PostgREST (`lib/core/config/supabase_config.dart`).
- **Sync:** `SyncManager` (singleton) drives push/pull via `SyncEngine`. Records carry a `sync_status` column (`pending` | `synced`). Push runs on login and startup; pull runs after push.

### Auth
`AuthService` singleton (`lib/core/auth/auth_service.dart`) owns the local Drift session. Supabase Auth runs alongside for token-based RLS. Passwords are bcrypt; SHA-256 hashes are migrated on next login.

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
| `lib/core/config/supabase_config.dart` | Credentials (gitignored — see secrets.json.example) |
| `lib/features/admin/screens/` | Admin-role screens |
| `lib/features/warehouse/screens/` | Warehouse-role screens |
| `supabase_users_table.sql` | SQL schema + RLS policies for Supabase |

## Development conventions
- Pass `AppDatabase` and `SyncManager` down through constructors; both are singletons initialised in `main.dart`.
- Access the shared database in leaf widgets via `AuthService.instance.database`.
- Soft-delete only — never hard-delete rows. Set `is_deleted = true` and `sync_status = 'pending'`.
- After any local write, set `sync_status = 'pending'` so the next sync cycle picks it up.
- All screens wrapped in `ResponsiveShell` for consistent sidebar navigation.

## Current status (May 2026)
- **Done:** Auth flow, admin dashboard with charts, warehouse dashboard, sync engine, responsive shell.
- **Partial:** Product form, customer form (UI done, DB wired).
- **Stub:** Delivery screens, customer screens, all ViewModels except admin + auth.
- **Placeholder:** Admin sub-screens (inventory, customers, orders, stock, deliveries, reports, settings).

## Known architecture debt
- `serviceKey` (Supabase service role) is used in the Flutter client for user sync. Long-term fix is a Supabase Edge Function. Tracked in `sync_engine.dart` and `auth_repository.dart`.
- WarehouseViewModel, DeliveryViewModel, CustomerViewModel methods are stubs — business logic not yet implemented.
- QR scanning is wired up but the scanner dependency is commented out.
