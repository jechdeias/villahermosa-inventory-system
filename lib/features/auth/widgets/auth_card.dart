import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/auth_theme.dart';

/// Reusable authentication card widget
/// Replicates the exact design from the login screen image
class AuthCard extends StatefulWidget {

  const AuthCard({
    super.key,
    // Text content
    this.logoIcon = '📦',
    this.title = 'Application Title',
    this.subtitle = 'Application Subtitle',
    this.emailLabel = 'Email',
    this.emailHint = 'Enter your email',
    this.passwordLabel = 'Password',
    this.passwordHint = 'Enter your password',
    this.primaryButtonText = 'Sign In',
    this.promptText = "Don't have an account?",
    this.linkText = 'Sign up',
    this.isPasswordVisible = false,
    this.suffixIcon,
    this.forgotPasswordLink,
    
    // Callbacks
    required this.onPrimaryButtonPressed,
    this.onLinkPressed,
    this.onPasswordVisibilityToggle,
    this.onForgotPasswordPressed,
    
    // Form controllers
    this.emailController,
    this.passwordController,
    
    // Form state
    this.isLoading = false,
    this.errorMessage,
    this.formKey,
  });
  // Configurable text content
  final String logoIcon;
  final String title;
  final String subtitle;
  final String emailLabel;
  final String emailHint;
  final String passwordLabel;
  final String passwordHint;
  final String primaryButtonText;
  final String promptText;
  final String linkText;
  final bool isPasswordVisible;
  final Widget? suffixIcon;
  final String? forgotPasswordLink;
  
  // Callbacks
  final VoidCallback onPrimaryButtonPressed;
  final VoidCallback? onLinkPressed;
  final VoidCallback? onPasswordVisibilityToggle;
  final VoidCallback? onForgotPasswordPressed;
  
  // Form controllers
  final TextEditingController? emailController;
  final TextEditingController? passwordController;
  
  // Form state
  final bool isLoading;
  final String? errorMessage;
  final GlobalKey<FormState>? formKey;

  @override
  State<AuthCard> createState() => _AuthCardState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('logoIcon', logoIcon));
    properties.add(StringProperty('title', title));
    properties.add(StringProperty('subtitle', subtitle));
    properties.add(StringProperty('emailLabel', emailLabel));
    properties.add(StringProperty('emailHint', emailHint));
    properties.add(StringProperty('passwordLabel', passwordLabel));
    properties.add(StringProperty('passwordHint', passwordHint));
    properties.add(StringProperty('primaryButtonText', primaryButtonText));
    properties.add(StringProperty('promptText', promptText));
    properties.add(StringProperty('linkText', linkText));
    properties.add(DiagnosticsProperty<bool>('isPasswordVisible', isPasswordVisible));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onPrimaryButtonPressed', onPrimaryButtonPressed));
    properties.add(ObjectFlagProperty<VoidCallback?>.has('onLinkPressed', onLinkPressed));
    properties.add(ObjectFlagProperty<VoidCallback?>.has('onPasswordVisibilityToggle', onPasswordVisibilityToggle));
    properties.add(DiagnosticsProperty<TextEditingController?>('emailController', emailController));
    properties.add(DiagnosticsProperty<TextEditingController?>('passwordController', passwordController));
    properties.add(DiagnosticsProperty<bool>('isLoading', isLoading));
    properties.add(StringProperty('errorMessage', errorMessage));
    properties.add(DiagnosticsProperty<GlobalKey<FormState>?>('formKey', formKey));
  }
}

class _AuthCardState extends State<AuthCard> {
  late bool _passwordVisible;

  @override
  void initState() {
    super.initState();
    _passwordVisible = widget.isPasswordVisible;
  }

  @override
  void didUpdateWidget(AuthCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPasswordVisible != widget.isPasswordVisible) {
      _passwordVisible = widget.isPasswordVisible;
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
    widget.onPasswordVisibilityToggle?.call();
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
                          // Fallback to text if logo not found
                          return Container(
                            decoration: BoxDecoration(
                              color: AuthTheme.primaryTextColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'VM',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
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
                const SizedBox(height: 16), // Spacing after logo
                
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
                const SizedBox(height: 32), // Spacing before form
                
                // Email Field
                Text(
                  widget.emailLabel,
                  style: AuthTheme.labelStyle,
                ),
                const SizedBox(height: AuthTheme.fieldSpacing),
                TextFormField(
                  controller: widget.emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  inputFormatters: [
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) => newValue.copyWith(
                        text: newValue.text.toLowerCase(),
                      ),
                    ),
                  ],
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
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => widget.onPrimaryButtonPressed(),
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
                
                // Authentication Links - Separate rows for better UX
                Column(
                  children: [
                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.promptText,
                            style: AuthTheme.promptTextStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: widget.onLinkPressed,
                          child: Text(
                            widget.linkText,
                            style: AuthTheme.signUpLinkStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AuthTheme.linkSpacing),
                    // Forgot password link
                    GestureDetector(
                      onTap: widget.onForgotPasswordPressed,
                      child: Center(
                        child: Text(
                          'Forgot Password?',
                          style: AuthTheme.forgotPasswordLinkStyle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
}
