class SupabaseConfig {
  // TODO: Move service key to environment variables before open-sourcing
  // Never commit real service keys to version control
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wcpvkiapbsalzubpynzw.supabase.co',
  );
  
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_IDitgHp_pS7sGxDWqoDd6Q_GRph1rJk',
  );
  
  static const String serviceKey = String.fromEnvironment(
    'SUPABASE_SERVICE_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjcHZraWFwYnNhbHp1YnB5bnp3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTUxNDI2OCwiZXhwIjoyMDg1MDkwMjY4fQ.9PwsiwqgewxN2ewITu_ITq0FTAUslYbk4lp_epPwGYU',
  );
}
