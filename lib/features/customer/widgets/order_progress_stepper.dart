import 'package:flutter/material.dart';
import 'customer_common.dart';
import '../../../core/theme/app_theme.dart';

/// Order Placed → Processing → Out for Delivery → Delivered.
/// Steps up to [currentStep] are filled; the current step's label is bold.
/// With [completed] the last step reads "Completed ✓" in green (the customer
/// confirmed receipt).
class OrderProgressStepper extends StatelessWidget {
  const OrderProgressStepper({super.key, required this.currentStep, this.completed = false});
  final int currentStep;
  final bool completed;

  static const labels = ['Order Placed', 'Processing', 'Out for Delivery', 'Delivered'];

  /// How each label breaks across lines. Breaking is explicit (never mid-word):
  /// each line is scaled down to fit its column instead of wrapping, so a long
  /// word like "Processing" can't split on narrow screens.
  static const _lines = [
    ['Order Placed'],
    ['Processing'],
    ['Out for', 'Delivery'],
    ['Delivered'],
  ];
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Column(children: [
                SizedBox(
                  height: 22,
                  child: Row(children: [
                    Expanded(child: i == 0 ? const SizedBox() : _line(i <= currentStep)),
                    _dot(i, i == currentStep, i <= currentStep),
                    Expanded(child: i == labels.length - 1 ? const SizedBox() : _line(i < currentStep)),
                  ]),
                ),
                const SizedBox(height: 6),
                Semantics(
                  label: (completed && i == labels.length - 1) ? 'Completed' : labels[i],
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        for (final line in (completed && i == labels.length - 1) ? const ['Completed \u2713'] : _lines[i])
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              line,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.25,
                                fontWeight: i == currentStep ? FontWeight.w700 : FontWeight.w400,
                                color: (completed && i == labels.length - 1)
                                    ? AppTheme.success
                                    : (i <= currentStep ? CcColors.text : CcColors.light),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
        ],
      );

  Widget _line(bool filled) => Container(height: 3, color: filled ? CcColors.primary : CcColors.border);

  Widget _dot(int i, bool active, bool filled) => Container(
        width: active ? 22 : 16,
        height: active ? 22 : 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppTheme.border : Colors.transparent,
        ),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? CcColors.primary : Colors.white,
            border: Border.all(color: filled ? CcColors.primary : const Color(0xFFD1D5DB), width: 2),
          ),
        ),
      );
}
