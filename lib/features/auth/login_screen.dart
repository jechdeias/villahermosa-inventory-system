import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;

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


}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // Changed from email to identifier
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;

  late AuthViewModel _authViewModel;
  late final _oauthSubscription =
      Supabase.instance.client.auth.onAuthStateChange.listen(_onAuthState);

  void _onAuthState(AuthState data) {
    if (!mounted) return;
    final event = data.event;
    final session = data.session;
    if (event == AuthChangeEvent.signedIn && session != null) {
      final provider = session.user.appMetadata['provider'] as String?;
      if (provider == 'google') {
        _handleOAuthCallback(session);
      }
    }
  }

  Future<void> _handleOAuthCallback(Session session) async {
    if (!mounted) return;
    setState(() => _isGoogleLoading = true);
    try {
      final user = await AuthService.instance.loginWithOAuthSession(session);
      if (!mounted) return;
      if (user != null) {
        await _navigateToDashboard();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed. Please try again.')),
        );
        setState(() => _isGoogleLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in error: $e')),
        );
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel(AuthService.instance, widget.database);

    // Check if user is already authenticated
    if (_authViewModel.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToDashboard();
      });
    }
  }

  @override
  void dispose() {
    _oauthSubscription.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        
        // Check if user needs to change password
        final currentUser = _authViewModel.currentUser;
        if (currentUser?.forcePasswordChange == true) {
          Navigator.of(context).pushReplacementNamed('/change-password');
          return;
        }
        
        _navigateToDashboard();
      }
    } catch (e) {
      // Error is handled in AuthViewModel
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    _authViewModel.clearError();
    try {
      await _authViewModel.signInWithGoogle();
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
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
        logoIcon: '📦', // This is fallback if image fails to load
        title: 'Villahermosa\nSales and Marketing',
        subtitle: 'Inventory Management System',
        emailLabel: 'Email', // Updated label
        emailHint: 'Enter your email', // Updated hint
        passwordLabel: 'Password',
        passwordHint: 'Enter your password',
        primaryButtonText: 'Log In',
        promptText: "Don't have an account?",
        linkText: 'Sign up',
        forgotPasswordLink: 'Forgot Password?',
        
        // Form controllers
        emailController: _identifierController, // Using identifier controller
        passwordController: _passwordController,
        
        // Form state
        formKey: _formKey,
        isLoading: _authViewModel.isLoading,
        errorMessage: _authViewModel.errorMessage,
        isGoogleLoading: _isGoogleLoading,

        // Callbacks
        onPrimaryButtonPressed: _login,
        onGoogleSignIn: defaultTargetPlatform == TargetPlatform.android
            ? _handleGoogleSignIn
            : null,
        onLinkPressed: () {
          Navigator.pushNamed(context, '/signup');
        },
        onPasswordVisibilityToggle: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        onForgotPasswordPressed: () {
          Navigator.pushNamed(context, '/forgot-password');
        },
      ),
    );

}
