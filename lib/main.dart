import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'core/database/app_database.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'core/auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final database = AppDatabase();
  
  // Initialize AuthService with shared database
  AuthService.initializeWithDatabase(database);
  
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
    },
    initialRoute: '/',
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppDatabase>('database', database));
  }
}
