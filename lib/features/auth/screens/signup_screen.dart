import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/constants/user_roles.dart';
import '../data/auth_repository.dart';
import '../widgets/responsive_auth_screen.dart';
import '../widgets/signup_card.dart';

class SignupScreen extends StatefulWidget {
  
  const SignupScreen({super.key, required this.database});
  final AppDatabase database;

  @override
  State<SignupScreen> createState() => _SignupScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppDatabase>('database', database));
  }
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final String _selectedRole = UserRole.customer.value; // Always customer
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = AuthRepository(widget.database);
      
      // Check if user already exists
      final existingUser = await widget.database.getUserByEmail(_emailController.text);
      if (existingUser != null) {
        setState(() {
          _errorMessage = 'User with this email already exists';
          _isLoading = false;
        });
        return;
      }

      // Create new user using AuthRepository
      final name = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final signupSuccess = await authRepository.signup(
        name,
        _emailController.text.trim(),
        _passwordController.text,
        _selectedRole,
      );

      if (!signupSuccess) {
        setState(() {
          _errorMessage = 'Signup failed. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // Auto-login after successful signup
      final user = await authRepository.login(_emailController.text, _passwordController.text);
      
      if (user != null) {
        // Navigate to appropriate dashboard based on role
        _navigateToDashboard(user.role);
      } else {
        setState(() {
          _errorMessage = 'Signup successful but auto-login failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Signup failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToDashboard(String role) {
    RoleBasedNavigation.navigate(context, role);
  }

  @override
  Widget build(BuildContext context) => ResponsiveAuthScreen(
      showBackgroundPattern: true,
      child: SignupCard(
        // Configurable text content
        logoIcon: '📦',
        title: 'Create Account',
        subtitle: 'Join our platform today',
        firstNameLabel: 'First Name',
        firstNameHint: 'Enter your first name',
        lastNameLabel: 'Last Name',
        lastNameHint: 'Enter your last name',
        emailLabel: 'Email',
        emailHint: 'Enter your email',
        passwordLabel: 'Password',
        passwordHint: 'Enter your password',
        confirmPasswordLabel: 'Confirm Password',
        confirmPasswordHint: 'Confirm your password',
        primaryButtonText: 'Sign Up',
        promptText: 'Already have an account?',
        linkText: 'Sign in',
        isPasswordVisible: _obscurePassword,
        isConfirmPasswordVisible: _obscureConfirmPassword,
        
        // Form controllers
        firstNameController: _firstNameController,
        lastNameController: _lastNameController,
        emailController: _emailController,
        passwordController: _passwordController,
        confirmPasswordController: _confirmPasswordController,
        
        // Form state
        formKey: _formKey,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        
        // Callbacks
        onPrimaryButtonPressed: _signup,
        onLinkPressed: () {
          Navigator.pop(context);
        },
        onPasswordVisibilityToggle: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        onConfirmPasswordVisibilityToggle: () {
          setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          });
        },
      ),
    );
}
