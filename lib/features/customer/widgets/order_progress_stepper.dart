import 'package:flutter/material.dart';
import 'customer_common.dart';
import '../../../core/theme/app_theme.dart';

/// Order Placed → Processing → Out for Delivery → Delivered.
/// Steps up to [currentStep] are filled; the current step's label is bold.
class OrderProgressStepper extends StatelessWidget {
  const OrderProgressStepper({super.key, required this.currentStep});
  final int currentStep;

  static const labels = ['Order Placed', 'Processing', 'Out for Delivery', 'Delivered'];

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: i == currentStep ? FontWeight.w700 : FontWeight.w400,
                      color: i <= currentStep ? CcColors.text : CcColors.light,
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
