import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/auth_theme.dart';

/// Responsive wrapper for authentication screens
/// Handles mobile and desktop layouts with proper padding and centering
class ResponsiveAuthScreen extends StatelessWidget {

  const ResponsiveAuthScreen({
    super.key,
    required this.child,
    this.backgroundImage,
    this.showBackgroundPattern = false,
  });
  final Widget child;
  final String? backgroundImage;
  final bool showBackgroundPattern;

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AuthTheme.backgroundColor,
      body: Stack(
        children: [
          // Background pattern or image
          if (showBackgroundPattern)
            Positioned.fill(
              child: CustomPaint(
                painter: _BackgroundPatternPainter(),
              ),
            ),
          
          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Mobile layout
                if (constraints.maxWidth < 600) {
                  return _buildMobileLayout();
                }
                // Desktop layout
                return _buildDesktopLayout();
              },
            ),
          ),
        ],
      ),
    );

  Widget _buildMobileLayout() => Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: SingleChildScrollView(
          child: child,
        ),
      ),
    );

  Widget _buildDesktopLayout() => Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(48.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          child: child,
        ),
      ),
    );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('backgroundImage', backgroundImage));
    properties.add(DiagnosticsProperty<bool>('showBackgroundPattern', showBackgroundPattern));
  }
}

/// Custom painter for background pattern
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    const dotSize = 2.0;
    const spacing = 30.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          dotSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
