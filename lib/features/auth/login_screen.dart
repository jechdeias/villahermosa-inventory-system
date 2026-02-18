import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/auth/auth_service.dart';
import '../../core/business/role_based_access.dart';
import '../../core/sync/sync_manager.dart';
import 'viewmodels/auth_viewmodel.dart';
import '../auth/widgets/responsive_auth_screen.dart';
import '../auth/widgets/auth_card.dart';
import '../../core/services/navigation_service.dart';

/// Login Screen
/// Handles user authentication and role-based navigation
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.database, super.key,
  });

  final AppDatabase database;

  @override
  State<LoginScreen> createState() => _LoginScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppDatabase>('database', database));
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // Changed from email to identifier
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel(AuthService.instance);
    
    // Check if user is already authenticated
    if (_authViewModel.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToDashboard();
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      _authViewModel.clearError();
      
      final success = await _authViewModel.login(
        _identifierController.text.trim(), // Can be email or username
        _passwordController.text,
      );

      if (success && mounted) {
        debugPrint('LOGIN SUCCESS');
        _navigateToDashboard();
      }
    } catch (e) {
      // Error is handled in AuthViewModel
    }
  }

  Future<void> _navigateToDashboard() async {
    final navigationService = NavigationService(
      AuthService.instance,
      RoleBasedAccess(widget.database),
      widget.database,
      SyncManager.instance,
    );
    final initialRoute = await navigationService.getInitialRoute();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(initialRoute);
    }
  }

  @override
  Widget build(BuildContext context) => ResponsiveAuthScreen(
      showBackgroundPattern: true,
      child: AuthCard(
        // Configurable text content
        logoIcon: '📦',
        title: 'Villahermosa\nSales and Marketing',
        subtitle: 'Inventory Management System',
        emailLabel: 'Email or Username', // Updated label
        emailHint: 'Enter your email or username', // Updated hint
        passwordLabel: 'Password',
        passwordHint: 'Enter your password',
        primaryButtonText: 'Sign In',
        promptText: "Don't have an account?",
        linkText: 'Sign up',
        
        // Form controllers
        emailController: _identifierController, // Using identifier controller
        passwordController: _passwordController,
        
        // Form state
        formKey: _formKey,
        isLoading: _authViewModel.isLoading,
        errorMessage: _authViewModel.errorMessage,
        
        // Callbacks
        onPrimaryButtonPressed: _login,
        onLinkPressed: () {
          Navigator.pushNamed(context, '/signup');
        },
        onPasswordVisibilityToggle: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
    );

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
