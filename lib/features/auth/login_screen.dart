import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../auth/data/auth_repository.dart';
import '../auth/viewmodels/auth_viewmodel.dart';
import '../auth/widgets/responsive_auth_screen.dart';
import '../auth/widgets/auth_card.dart';
import '../../core/constants/user_roles.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel(AuthRepository(widget.database));
    
    // Check if user is already authenticated
    if (_authViewModel.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Navigate to appropriate dashboard based on role
        Navigator.of(context).pushReplacementNamed(
          '/admin/dashboard',
        );
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await _authViewModel.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (_authViewModel.isAuthenticated) {
        // Debug print for successful login
        debugPrint('LOGIN SUCCESS');
        
        // Navigate based on user role
        _navigateBasedOnRole(_authViewModel.currentUser!);
      }
    } catch (e) {
      // Error is handled in AuthViewModel
    }
  }

  void _navigateBasedOnRole(User user) {
    RoleBasedNavigation.navigate(context, user.role);
  }

  @override
  Widget build(BuildContext context) => ResponsiveAuthScreen(
      showBackgroundPattern: true,
      child: AuthCard(
        // Configurable text content
        logoIcon: '📦',
        title: 'Villahermosa\nSales and Marketing',
        subtitle: 'Inventory Management System',
        emailLabel: 'Email',
        emailHint: 'Enter your email',
        passwordLabel: 'Password',
        passwordHint: 'Enter your password',
        primaryButtonText: 'Sign In',
        promptText: "Don't have an account?",
        linkText: 'Sign up',
        
        // Form controllers
        emailController: _emailController,
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
