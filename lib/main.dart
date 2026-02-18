import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'core/database/app_database.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/viewmodels/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final database = AppDatabase();
  
  // Seed admin user if database is empty
  final authRepository = AuthRepository(database);
  final authViewModel = AuthViewModel(authRepository);
  await authViewModel.seedAdminUserIfNeeded();
  
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
    home: AuthScreen(database: database),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppDatabase>('database', database));
  }
}
