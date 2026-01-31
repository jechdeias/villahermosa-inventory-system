import 'package:flutter/material.dart';

class TabletWarehouseTheme {
  // Tablet-optimized dimensions
  static const double sidebarWidth = 320; // Wider sidebar for tablet
  static const double contentPadding = 24;
  static const double cardSpacing = 16;
  static const double gridColumns = 2; // Grid layout for tablets
  
  // Responsive breakpoints
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;
  
  // Tablet-specific spacing
  static const double largeTouchTarget = 48; // Larger touch targets for tablet
  static const double cardHeight = 120; // Taller cards for tablet
  
  // Color scheme (same as warehouse theme)
  static const Color darkSidebar = Color(0xFF1E1E1E);
  static const Color darkSidebarVariant = Color(0xFF2A2A2A);
  static const Color lightBackground = Color(0xFFF4F4F4);
  static const Color whiteCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static double getSidebarWidth(BuildContext context) {
    if (isDesktop(context)) {
      return sidebarWidth;
    } else if (isTablet(context)) {
      return 280; // Slightly narrower for smaller tablets
    } else {
      return 0; // Hidden on mobile, use bottom nav
    }
  }

  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) {
      return 3;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 1;
    }
  }

  static EdgeInsets getContentPadding(BuildContext context) {
    if (isTablet(context)) {
      return const EdgeInsets.all(contentPadding);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  static double getCardHeight(BuildContext context) {
    if (isTablet(context)) {
      return cardHeight;
    } else {
      return 100;
    }
  }

  // Responsive layout builder
  static Widget responsiveLayout({
    required BuildContext context,
    required Widget mobile,
    required Widget tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // Tablet-optimized card
  static Widget tabletCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: getCardHeight(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  if (subtitle != null)
                    Flexible(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: isTablet(context) ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tablet-optimized list tile
  static Widget tabletListTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData leadingIcon,
    required IconData trailingIcon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet(context) ? 20 : 16,
        vertical: 8,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? info).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          leadingIcon,
          color: iconColor ?? info,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isTablet(context) ? 16 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: isTablet(context) ? 14 : 12,
                color: textSecondary,
              ),
            )
          : null,
      trailing: Icon(trailingIcon, color: textSecondary),
      onTap: onTap,
    );
  }

  // Responsive grid
  static Widget responsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    double childAspectRatio = 1.2,
  }) {
    final columns = getGridColumns(context);
    final spacing = cardSpacing;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      children: children,
    );
  }

  // Tablet-optimized app bar
  static PreferredSizeWidget tabletAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
  }) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: isTablet(context) ? 20 : 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: darkSidebar,
      foregroundColor: Colors.white,
      actions: actions,
      toolbarHeight: isTablet(context) ? 64 : 56,
    );
  }

  // Tablet-optimized floating action button
  static Widget tabletFAB({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: info,
      foregroundColor: Colors.white,
      mini: !isTablet(context),
      tooltip: tooltip,
      child: Icon(
        icon,
        size: isTablet(context) ? 28 : 24,
      ),
    );
  }
}
