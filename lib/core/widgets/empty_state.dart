import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The one empty state used across every role: grey icon disc, title, message
/// and an optional call-to-action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing3XL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                child: Icon(icon, size: 32, color: AppTheme.textLight),
              ),
              const SizedBox(height: AppTheme.spacingLG),
              Text(title, style: AppTheme.headingSmall, textAlign: TextAlign.center),
              if (message.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingSM),
                Text(message, style: AppTheme.bodySmall, textAlign: TextAlign.center),
              ],
              if (action != null) ...[
                const SizedBox(height: AppTheme.spacing2XL),
                ElevatedButton(onPressed: action, child: Text(actionLabel ?? 'Go')),
              ],
            ],
          ),
        ),
      );
}
