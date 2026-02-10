import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import 'data/auth_repository.dart';
import 'viewmodels/auth_viewmodel.dart';

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
    properties.add(DiagnosticsProperty<AppDatabase>('database', database, defaultValue: null));
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;

  late AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    final authRepository = AuthRepository(widget.database);
    _authViewModel = AuthViewModel(authRepository);
    
    // Seed admin user if needed and check auth status
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authViewModel.seedAdminUserIfNeeded();
    
    if (_authViewModel.isAuthenticated) {
      // User is already logged in, navigate to dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateBasedOnRole(_authViewModel.currentUser!);
      });
    }
  }

  void _navigateBasedOnRole(User user) {
    String route;
    switch (user.role) {
      case 'admin':
        route = '/admin/dashboard';
        break;
      case 'warehouse':
        route = '/warehouse/dashboard';
        break;
      case 'customer':
        route = '/customer/dashboard';
        break;
      case 'delivery':
        route = '/delivery/dashboard';
        break;
      default:
        route = '/admin/dashboard'; // fallback
    }
    
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await _authViewModel.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (_authViewModel.isAuthenticated) {
        _navigateBasedOnRole(_authViewModel.currentUser!);
      }
    } catch (e) {
      // Error is handled in AuthViewModel, just trigger rebuild
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Company Logo
                  Image.asset(
                    'assets/images/logo/villahermosa_logo.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to icon if logo not found
                      return Icon(
                        Icons.inventory_2,
                        size: 80,
                        color: Colors.grey[800],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Villahermosa Inventory',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Sign in to your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_authViewModel.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _authViewModel.errorMessage!,
                        style: TextStyle(
                          color: Colors.red[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Login Button
                  ElevatedButton(
                    onPressed: _authViewModel.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _authViewModel.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Forgot Password
                  TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

  Future<void> _handleForgotPassword() async {
    final emailController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address to receive a password reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset functionality not yet implemented'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
