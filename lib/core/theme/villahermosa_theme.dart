import 'package:flutter/material.dart';

/// Villahermosa Marketing Design System Colors
/// Centralized color constants for consistent UI implementation
class VillahermosaColors {
  // Primary Colors
  static const Color sidebarDark = Color(0xFF1E1E1E);
  static const Color sidebarDarkHover = Color(0xFF2A2A2A);
  static const Color accentDark = Color(0xFF000000);
  
  // Neutral Colors
  static const Color contentBg = Color(0xFFF4F4F4);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE0E0E0);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF6B6B6B);
  
  // Status Colors
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color successText = Color(0xFF065F46);
  
  static const Color infoBg = Color(0xFFDBEAFE);
  static const Color infoText = Color(0xFF1E40AF);
  
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFF92400E);
  
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color errorText = Color(0xFF991B1B);
}

/// Villahermosa Marketing Design System Typography
/// Centralized text styles for consistent typography implementation
class VillahermosaTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: VillahermosaColors.textPrimary,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: VillahermosaColors.textPrimary,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: VillahermosaColors.textPrimary,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 1.5,
    color: VillahermosaColors.textPrimary,
  );
  
  static const TextStyle small = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: VillahermosaColors.textSecondary,
  );
  
  static const TextStyle extraSmall = TextStyle(
    fontSize: 12,
    height: 1.4,
    color: VillahermosaColors.textSecondary,
  );
}

/// Villahermosa Marketing Design System Breakpoints
/// Responsive breakpoint constants for layout decisions
class VillahermosaBreakpoints {
  static const double mobile = 768;
  static const double tablet = 1024;
  static const double desktop = 1280;
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobile;
  }
}

/// Villahermosa Marketing Design System Spacing
/// Consistent spacing values based on 4px grid
class VillahermosaSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Villahermosa Marketing Design System Border Radius
/// Consistent border radius values
class VillahermosaRadius {
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 12;
}
