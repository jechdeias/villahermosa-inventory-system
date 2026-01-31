import 'package:flutter/material.dart';

class WarehouseTheme {
  // Global Color Palette - Minimal Black, White, Grayscale
  static const Color darkSidebar = Color(0xFF1E1E1E); // Dark charcoal
  static const Color darkSidebarVariant = Color(0xFF2A2A2A); // Dark charcoal variant
  static const Color lightBackground = Color(0xFFF4F4F4); // Light gray content background
  static const Color whiteCard = Color(0xFFFFFFFF); // White cards
  static const Color textPrimary = Color(0xFF212121); // Dark text
  static const Color textSecondary = Color(0xFF757575); // Secondary text
  static const Color textDisabled = Color(0xFFBDBDBD); // Disabled text
  static const Color divider = Color(0xFFE0E0E0); // Subtle dividers
  static const Color shadow = Color(0x1A000000); // Subtle shadows
  static const Color success = Color(0xFF4CAF50); // Success green
  static const Color warning = Color(0xFFFF9800); // Warning orange
  static const Color error = Color(0xFFF44336); // Error red
  static const Color info = Color(0xFF2196F3); // Info blue

  // Typography - Modern Sans-serif
  static const String fontFamily = 'Inter'; // or 'Roboto', 'SF Pro Display'
  
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.2,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.3,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.3,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.4,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    fontFamily: fontFamily,
    height: 1.4,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    fontFamily: fontFamily,
    height: 1.3,
  );

  // Component Themes
  static ThemeData get theme => ThemeData(
      brightness: Brightness.light,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: lightBackground,
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSidebar,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: fontFamily,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: whiteCard,
        elevation: 2,
        shadowColor: shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: whiteCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: info, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: bodyMedium.copyWith(color: textSecondary),
        hintStyle: bodyMedium.copyWith(color: textDisabled),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkSidebar,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkSidebar,
          side: const BorderSide(color: divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: info,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      
      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: bodyMedium,
        subtitleTextStyle: bodySmall,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      
      // Badge Theme
      badgeTheme: BadgeThemeData(
        backgroundColor: error,
        textColor: Colors.white,
        smallSize: 16,
        largeSize: 20,
        textStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

  // Custom Components
  static Widget sidebarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? darkSidebarVariant : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 20,
        ),
        title: Text(
          label,
          style: bodyMedium.copyWith(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );

  static Widget statusBadge({
    required String text,
    required Color color,
  }) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

  static Widget summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: bodySmall.copyWith(color: textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: headingLarge.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
}
