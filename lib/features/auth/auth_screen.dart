import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/database/app_database.dart';
import '../auth/login_screen.dart';

class AuthScreen extends StatelessWidget {
  
  const AuthScreen({super.key, required this.database});
  final AppDatabase database;

  @override
  Widget build(BuildContext context) => LoginScreen(database: database);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppDatabase>('database', database));
  }
}