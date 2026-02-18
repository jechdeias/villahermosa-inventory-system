import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/auth_theme.dart';

/// Signup card widget with additional fields for registration
class SignupCard extends StatefulWidget {

  const SignupCard({
    super.key,
    // Text content
    this.logoIcon = '📦',
    this.title = 'Create Account',
    this.subtitle = 'Join our platform today',
    this.firstNameLabel = 'First Name',
    this.firstNameHint = 'Enter your first name',
    this.lastNameLabel = 'Last Name',
    this.lastNameHint = 'Enter your last name',
    this.emailLabel = 'Email',
    this.emailHint = 'Enter your email',
    this.passwordLabel = 'Password',
    this.passwordHint = 'Enter your password',
    this.confirmPasswordLabel = 'Confirm Password',
    this.confirmPasswordHint = 'Confirm your password',
    this.primaryButtonText = 'Sign Up',
    this.promptText = 'Already have an account?',
    this.linkText = 'Sign in',
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    
    // Callbacks
    required this.onPrimaryButtonPressed,
    this.onLinkPressed,
    this.onPasswordVisibilityToggle,
    this.onConfirmPasswordVisibilityToggle,
    
    // Form controllers
    this.firstNameController,
    this.lastNameController,
    this.emailController,
    this.passwordController,
    this.confirmPasswordController,
    
    // Form state
    this.isLoading = false,
    this.errorMessage,
    this.formKey,
  });
  // Configurable text content
  final String logoIcon;
  final String title;
  final String subtitle;
  final String firstNameLabel;
  final String firstNameHint;
  final String lastNameLabel;
  final String lastNameHint;
  final String emailLabel;
  final String emailHint;
  final String passwordLabel;
  final String passwordHint;
  final String confirmPasswordLabel;
  final String confirmPasswordHint;
  final String primaryButtonText;
  final String promptText;
  final String linkText;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  
  // Callbacks
  final VoidCallback onPrimaryButtonPressed;
  final VoidCallback? onLinkPressed;
  final VoidCallback? onPasswordVisibilityToggle;
  final VoidCallback? onConfirmPasswordVisibilityToggle;
  
  // Form controllers
  final TextEditingController? firstNameController;
  final TextEditingController? lastNameController;
  final TextEditingController? emailController;
  final TextEditingController? passwordController;
  final TextEditingController? confirmPasswordController;
  
  // Form state
  final bool isLoading;
  final String? errorMessage;
  final GlobalKey<FormState>? formKey;

  @override
  State<SignupCard> createState() => _SignupCardState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('logoIcon', logoIcon));
    properties.add(StringProperty('title', title));
    properties.add(StringProperty('subtitle', subtitle));
    properties.add(StringProperty('firstNameLabel', firstNameLabel));
    properties.add(StringProperty('firstNameHint', firstNameHint));
    properties.add(StringProperty('lastNameLabel', lastNameLabel));
    properties.add(StringProperty('lastNameHint', lastNameHint));
    properties.add(StringProperty('emailLabel', emailLabel));
    properties.add(StringProperty('emailHint', emailHint));
    properties.add(StringProperty('passwordLabel', passwordLabel));
    properties.add(StringProperty('passwordHint', passwordHint));
    properties.add(StringProperty('confirmPasswordLabel', confirmPasswordLabel));
    properties.add(StringProperty('confirmPasswordHint', confirmPasswordHint));
    properties.add(StringProperty('primaryButtonText', primaryButtonText));
    properties.add(StringProperty('promptText', promptText));
    properties.add(StringProperty('linkText', linkText));
    properties.add(DiagnosticsProperty<bool>('isPasswordVisible', isPasswordVisible));
    properties.add(DiagnosticsProperty<bool>('isConfirmPasswordVisible', isConfirmPasswordVisible));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onPrimaryButtonPressed', onPrimaryButtonPressed));
    properties.add(ObjectFlagProperty<VoidCallback?>.has('onLinkPressed', onLinkPressed));
    properties.add(ObjectFlagProperty<VoidCallback?>.has('onPasswordVisibilityToggle', onPasswordVisibilityToggle));
    properties.add(ObjectFlagProperty<VoidCallback?>.has('onConfirmPasswordVisibilityToggle', onConfirmPasswordVisibilityToggle));
    properties.add(DiagnosticsProperty<TextEditingController?>('firstNameController', firstNameController));
    properties.add(DiagnosticsProperty<TextEditingController?>('lastNameController', lastNameController));
    properties.add(DiagnosticsProperty<TextEditingController?>('emailController', emailController));
    properties.add(DiagnosticsProperty<TextEditingController?>('passwordController', passwordController));
    properties.add(DiagnosticsProperty<TextEditingController?>('confirmPasswordController', confirmPasswordController));
    properties.add(DiagnosticsProperty<bool>('isLoading', isLoading));
    properties.add(StringProperty('errorMessage', errorMessage));
    properties.add(DiagnosticsProperty<GlobalKey<FormState>?>('formKey', formKey));
  }
}

class _SignupCardState extends State<SignupCard> {
  late bool _passwordVisible;
  late bool _confirmPasswordVisible;

  @override
  void initState() {
    super.initState();
    _passwordVisible = widget.isPasswordVisible;
    _confirmPasswordVisible = widget.isConfirmPasswordVisible;
  }

  @override
  void didUpdateWidget(SignupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPasswordVisible != widget.isPasswordVisible) {
      _passwordVisible = widget.isPasswordVisible;
    }
    if (oldWidget.isConfirmPasswordVisible != widget.isConfirmPasswordVisible) {
      _confirmPasswordVisible = widget.isConfirmPasswordVisible;
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
    widget.onPasswordVisibilityToggle?.call();
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _confirmPasswordVisible = !_confirmPasswordVisible;
    });
    widget.onConfirmPasswordVisibilityToggle?.call();
  }

  @override
  Widget build(BuildContext context) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AuthTheme.cardMaxWidth,
          minWidth: AuthTheme.cardMinWidth,
        ),
        child: Container(
          decoration: AuthTheme.getCardDecoration(),
          padding: const EdgeInsets.all(AuthTheme.cardPadding),
          child: Form(
            key: widget.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/logo/vm_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon if logo not found
                          return Container(
                            decoration: BoxDecoration(
                              color: AuthTheme.primaryTextColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                widget.logoIcon,
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AuthTheme.sectionSpacing),
                
                // Title
                Text(
                  widget.title,
                  style: AuthTheme.titleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AuthTheme.smallSpacing),
                
                // Subtitle
                Text(
                  widget.subtitle,
                  style: AuthTheme.subtitleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AuthTheme.sectionSpacing),
                
                // First Name Field
                Text(
                  widget.firstNameLabel,
                  style: AuthTheme.labelStyle,
                ),
                const SizedBox(height: AuthTheme.fieldSpacing),
                TextFormField(
                  controller: widget.firstNameController,
                  decoration: AuthTheme.getInputDecoration(
                    hintText: widget.firstNameHint,
                    prefixIcon: Icons.person_outlined,
                  ),
                  style: AuthTheme.inputTextStyle,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AuthTheme.fieldSpacing),
                
                // Last Name Field
                Text(
                  widget.lastNameLabel,
                  style: AuthTheme.labelStyle,
                ),
                const SizedBox(height: AuthTheme.fieldSpacing),
                TextFormField(
                  controller: widget.lastNameController,
                  decoration: AuthTheme.getInputDecoration(
                    hintText: widget.lastNameHint,
                    prefixIcon: Icons.person_outlined,
                  ),
                  style: AuthTheme.inputTextStyle,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AuthTheme.fieldSpacing),
                
                // Email Field
                Text(
                  widget.emailLabel,
                  style: AuthTheme.labelStyle,
                ),
                const SizedBox(height: AuthTheme.fieldSpacing),
                TextFormField(
                  controller: widget.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: AuthTheme.getInputDecoration(
                    hintText: widget.emailHint,
                    prefixIcon: Icons.email_outlined,
                  ),
                  style: AuthTheme.inputTextStyle,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AuthTheme.fieldSpacing),
                
                // Password Field
                Text(
                  widget.passwordLabel,
                  style: AuthTheme.labelStyle,
                ),
                const SizedBox(height: AuthTheme.fieldSpacing),
                TextFormField(
                  controller: widget.passwordController,
                  obscureText: !_passwordVisible,
                  decoration: AuthTheme.getInputDecoration(
                    hintText: widget.passwordHint,
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility_off : Icons.visibility,
                        color: AuthTheme.secondaryTextColor,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  style: AuthTheme.inputTextStyle,
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
                const SizedBox(height: AuthTheme.fieldSpacing),
                
                // Confirm Password Field
                Text(
                  widget.confirmPasswordLabel,
                  style: AuthTheme.labelStyle,
                ),
                const SizedBox(height: AuthTheme.fieldSpacing),
                TextFormField(
                  controller: widget.confirmPasswordController,
                  obscureText: !_confirmPasswordVisible,
                  decoration: AuthTheme.getInputDecoration(
                    hintText: widget.confirmPasswordHint,
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: AuthTheme.secondaryTextColor,
                      ),
                      onPressed: _toggleConfirmPasswordVisibility,
                    ),
                  ),
                  style: AuthTheme.inputTextStyle,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != widget.passwordController?.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AuthTheme.sectionSpacing),
                
                // Error Message
                if (widget.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[200]!),
                      borderRadius: BorderRadius.circular(AuthTheme.inputBorderRadius),
                    ),
                    child: Text(
                      widget.errorMessage!,
                      style: TextStyle(
                        color: Colors.red[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: AuthTheme.fieldSpacing),
                ],
                
                // Primary Button
                ElevatedButton(
                  onPressed: widget.isLoading ? null : widget.onPrimaryButtonPressed,
                  style: AuthTheme.getPrimaryButtonStyle(),
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(widget.primaryButtonText),
                ),
                const SizedBox(height: AuthTheme.sectionSpacing),
                
                // Sign In Prompt
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        widget.promptText,
                        style: AuthTheme.promptTextStyle,
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onLinkPressed,
                        child: Text(
                          widget.linkText,
                          style: AuthTheme.linkTextStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
}
