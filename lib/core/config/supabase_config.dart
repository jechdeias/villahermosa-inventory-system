/// Supabase connection settings.
///
/// This file deliberately contains NO credentials and is safe to commit.
/// Both values are injected at COMPILE time from `secrets.json` via
/// `--dart-define-from-file`, which is the same mechanism the rest of the
/// project already documents:
///
///     flutter run   --dart-define-from-file=secrets.json
///     flutter build --dart-define-from-file=secrets.json
///
/// Copy `secrets.json.example` → `secrets.json` and fill in the real values.
/// `secrets.json` stays gitignored; this file does not need to be.
///
/// HISTORY: this file used to hold the credentials inline and was gitignored,
/// which meant a fresh clone could not compile at all — `lib/main.dart`
/// imports it, so `git clone && flutter analyze` failed with
/// "Target of URI doesn't exist". CI hit exactly that. Reading from
/// --dart-define removes the duplicate credential path and lets the repo
/// build from a clean checkout.
///
/// The ANON key is the only key that belongs here. It is safe in a client
/// build (RLS is what protects the data). The service-role key must never
/// appear in this file or anywhere else in the Flutter client — it lives
/// server-side in the `privileged-sync` Edge Function only.
class SupabaseConfig {
  const SupabaseConfig._();

  /// Project URL, e.g. https://<project-ref>.supabase.co
  static const String url = String.fromEnvironment('SUPABASE_URL');

  /// Public anon key. Never the service-role key.
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// False when the app was built without `--dart-define-from-file=secrets.json`.
  /// Both values are empty strings in that case and Supabase calls will fail at
  /// runtime, so check this before `Supabase.initialize` if you want a clear
  /// error instead of a confusing network one.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
