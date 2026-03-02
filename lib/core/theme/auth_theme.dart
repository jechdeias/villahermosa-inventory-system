import 'package:flutter/material.dart';

/// Authentication theme based on the login screen design
/// Provides consistent styling for all auth-related screens
class AuthTheme {
  // Colors following Villahermosa Design System
  static const Color backgroundColor = Color(0xFFF4F4F4);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color primaryTextColor = Color(0xFF1E1E1E);
  static const Color secondaryTextColor = Color(0xFF6B6B6B);
  static const Color placeholderTextColor = Color(0xFF9CA3AF);
  static const Color buttonBackgroundColor = Color(0xFF1E1E1E);
  static const Color buttonTextColor = Colors.white;
  static const Color inputBorderColor = Color(0xFFE0E0E0);
  static const Color focusedBorderColor = Color(0xFF1E1E1E);
  static const Color linkTextColor = Color(0xFF1E1E1E);
  
  // Border Radius
  static const double cardBorderRadius = 8;
  static const double inputBorderRadius = 6;
  static const double buttonBorderRadius = 6;
  
  // Spacing (multiples of 4px)
  static const double cardPadding = 32;
  static const double sectionSpacing = 24;
  static const double fieldSpacing = 16;
  static const double smallSpacing = 8;
  static const double linkSpacing = 16;
  
  // Card dimensions
  static const double cardMaxWidth = 400;
  static const double cardMinWidth = 320;
  
  // Button height
  static const double buttonHeight = 48;
  
  // Typography
  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
    height: 1.2,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: primaryTextColor,
    height: 1.4,
  );
  
  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: primaryTextColor,
    height: 1.2,
  );
  
  static const TextStyle placeholderStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: placeholderTextColor,
    height: 1.4,
  );
  
  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: primaryTextColor,
    height: 1.4,
  );
  
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: buttonTextColor,
    height: 1.2,
  );
  
  static const TextStyle promptTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: secondaryTextColor,
    height: 1.4,
  );

  static const TextStyle signUpLinkStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: linkTextColor,
    decoration: TextDecoration.underline,
    height: 1.4,
  );

  static const TextStyle forgotPasswordLinkStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: linkTextColor,
    decoration: TextDecoration.underline,
    height: 1.4,
  );
  
  static const TextStyle linkTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: linkTextColor,
    height: 1.4,
  );

  /// Input decoration theme for form fields
  static InputDecoration getInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
      hintText: hintText,
      hintStyle: placeholderStyle,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: secondaryTextColor) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: const BorderSide(color: inputBorderColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: const BorderSide(color: inputBorderColor, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: const BorderSide(color: focusedBorderColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: cardColor,
    );

  /// Button style for primary buttons
  static ButtonStyle getPrimaryButtonStyle() => ElevatedButton.styleFrom(
      backgroundColor: buttonBackgroundColor,
      foregroundColor: buttonTextColor,
      elevation: 0,
      minimumSize: const Size(double.infinity, buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
      ),
      textStyle: buttonTextStyle,
    );

  /// Card decoration for auth screens
  static BoxDecoration getCardDecoration() => BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(cardBorderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
}
