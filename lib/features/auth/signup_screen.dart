import 'package:flutter/material.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'widgets/responsive_auth_screen.dart';
import 'widgets/signup_card.dart';

/// Signup Screen
///
/// Provides customer self-registration.  Styled with [ResponsiveAuthScreen]
/// and [SignupCard] to match the login screen's design system.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthViewModel _authViewModel = AuthViewModel.instance;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResponsiveAuthScreen(
        showBackgroundPattern: true,
        child: ListenableBuilder(
          listenable: _authViewModel,
          builder: (context, _) => SignupCard(
            formKey: _formKey,
            firstNameController: _firstNameController,
            lastNameController: _lastNameController,
            emailController: _emailController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            isLoading: _authViewModel.isLoading,
            isGoogleLoading: _isGoogleLoading,
            errorMessage: _authViewModel.errorMessage,
            onPrimaryButtonPressed: _handleSignup,
            onGoogleSignIn: _handleGoogleSignIn,
            onLinkPressed: () => Navigator.pop(context),
            title: 'Create Account',
            subtitle: 'Join Villahermosa today',
            primaryButtonText: 'Create Account',
            promptText: 'Already have an account?',
            linkText: 'Sign in',
          ),
        ),
      );

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    _authViewModel.clearError();

    final success = await _authViewModel.signUp(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! You can now sign in.'),
          backgroundColor: Color(0xFF1E1E1E),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    _authViewModel.clearError();

    try {
      final launched = await _authViewModel.signInWithGoogle();
      if (!launched && mounted) {
        // Error already set in viewmodel; SignupCard will display it.
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }
}
