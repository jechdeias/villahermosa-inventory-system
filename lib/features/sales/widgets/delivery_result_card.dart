import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../customer/widgets/customer_common.dart' show formatPeso;
import '../services/delivery_confirmation.dart';

/// Filled circle with a white icon — the check / cross at the top of the
/// delivery result cards.
class DeliveryResultIcon extends StatelessWidget {
  const DeliveryResultIcon({super.key, required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 32),
      );
}

/// "Delivery Confirmed!" card. The QR scanner shows it over the camera view
/// and "Mark as Delivered" shows it in a dialog — same content either way.
class DeliverySuccessCard extends StatelessWidget {
  const DeliverySuccessCard({super.key, required this.result, required this.onOk});
  final ScanSuccess result;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DeliveryResultIcon(color: AppTheme.success, icon: Icons.check),
          const SizedBox(height: 16),
          const Text('Delivery Confirmed!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(result.storeName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(result.orderCode, style: const TextStyle(fontFamily: AppTheme.monoFamily, fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.warningLight,
              border: Border.all(color: const Color(0xFFFDE68A)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Expanded(child: Text(result.paymentMethod, style: const TextStyle(fontSize: 14, color: Color(0xFF92400E)))),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(result.collectOnDelivery ? 'Collect ${formatPeso(result.amount)}' : formatPeso(result.amount),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          const Text('Saved on this phone · will sync when online', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onOk,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: const Text('OK'),
          ),
        ],
      );
}

/// The success card in a dialog (used by "Mark as Delivered").
Future<void> showDeliverySuccessDialog(BuildContext context, ScanSuccess result) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: DeliverySuccessCard(result: result, onOk: () => Navigator.pop(ctx)),
          ),
        ),
      ),
    );
