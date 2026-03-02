import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/database/app_database.dart';
import 'core/config/supabase_config.dart';
import 'core/sync/sync_manager.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/email_verification_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/change_password_screen.dart';
import 'features/admin/screens/dashboard_screen.dart';
import 'features/admin/screens/user_accounts_screen.dart';
import 'core/widgets/responsive_shell.dart';
import 'features/warehouse/screens/dashboard_screen.dart';
import 'features/customer/screens/dashboard_screen.dart';
import 'features/delivery/screens/dashboard_screen.dart';
import 'core/auth/auth_service.dart';
import 'features/auth/data/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  final database = AppDatabase();
  
  // Initialize SyncManager with shared database
  SyncManager.initialize(database);
  
  // Initialize AuthService with shared database
  AuthService.initializeWithDatabase(database);
  
  // Seed admin user if database is empty
  final authRepository = AuthRepository(database);
  await authRepository.seedAdminUserIfEmpty();
  
  // Check connectivity and sync pending records on startup
  try {
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = !connectivityResults.contains(ConnectivityResult.none);
    if (isOnline) {
      debugPrint('🚀 App started with internet - syncing pending data...');
      await SyncManager.instance.syncPendingData();
    }
  } catch (e) {
    debugPrint('⚠️ Startup sync check failed: $e');
  }
  
  runApp(VillahermosaInventoryApp(database: database));
}

class VillahermosaInventoryApp extends StatelessWidget {

  const VillahermosaInventoryApp({
    required this.database,
    super.key,
  });
  final AppDatabase database;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Villahermosa Inventory System',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.grey,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF424242),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    ),
    routes: {
      '/': (context) => AuthScreen(database: database),
      '/login': (context) => LoginScreen(database: database),
      '/signup': (context) => const SignupScreen(),
      '/admin/dashboard': (context) => AdminDashboardScreen(database: database, syncManager: SyncManager.instance),
      '/admin/users': (context) => ResponsiveShell(
        database: database,
        selectedRoute: '/admin/users',
        child: UserAccountsScreen(database: database),
      ),
      '/warehouse/dashboard': (context) => const WarehouseDashboardScreen(),
      '/customer/dashboard': (context) => const CustomerDashboardScreen(),
      '/delivery/dashboard': (context) => const DeliveryDashboardScreen(),
      '/email-verification': (context) => const EmailVerificationScreen(),
      '/forgot-password': (context) => const ForgotPasswordScreen(),
      '/change-password': (context) => ChangePasswordScreen(database: database),
    },
    initialRoute: '/',
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppDatabase>('database', database));
  }
}
