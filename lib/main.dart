import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/database/app_database.dart';
import 'core/config/supabase_config.dart';
import 'core/sync/sync_manager.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/admin/screens/dashboard_screen.dart';
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
  
  // Initialize AuthService with shared database
  AuthService.initializeWithDatabase(database);
  
  // Seed admin user if database is empty
  final authRepository = AuthRepository(database);
  await authRepository.seedAdminUserIfEmpty();
  
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
      '/warehouse/dashboard': (context) => const WarehouseDashboardScreen(),
      '/customer/dashboard': (context) => const CustomerDashboardScreen(),
      '/delivery/dashboard': (context) => const DeliveryDashboardScreen(),
    },
    initialRoute: '/',
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppDatabase>('database', database));
  }
}
