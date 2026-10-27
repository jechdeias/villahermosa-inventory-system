import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'customer_common.dart';

/// The customer's delivery QR code. While the order is out for delivery the
/// customer shows it to the sales rep; once the rep has scanned it the code is
/// greyed out with a green check, and the customer confirms receipt.
class DeliveryQrCard extends StatelessWidget {
  const DeliveryQrCard({super.key, required this.orderNumber, required this.delivered, this.repName = ''});

  /// What the QR encodes — the order number the rep's scanner looks up.
  final String orderNumber;
  final bool delivered;
  final String repName;

  static const _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final qr = QrImageView(data: orderNumber, version: QrVersions.auto, size: 200, backgroundColor: Colors.white);
    return CcCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            delivered ? (repName.isEmpty ? 'Delivered' : 'Delivered by $repName') : 'Show this to your sales rep',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: delivered ? AppTheme.success : CcColors.text),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(12)),
            child: delivered
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(opacity: 0.3, child: ColorFiltered(colorFilter: _greyscale, child: qr)),
                      Container(
                        key: const ValueKey('delivered-check'),
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 36),
                      ),
                    ],
                  )
                : qr,
          ),
          const SizedBox(height: 12),
          Text(orderNumber, style: const TextStyle(fontFamily: AppTheme.monoFamily, fontSize: 14, color: CcColors.muted)),
          const SizedBox(height: 8),
          Text(
            delivered ? 'Please confirm you received your order' : 'Your rep will scan this to confirm delivery',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}

/// Shown once the customer has confirmed receipt.
class OrderCompleteCard extends StatelessWidget {
  const OrderCompleteCard({super.key, required this.receivedOn});
  final DateTime receivedOn;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.successLight,
          border: Border.all(color: const Color(0xFFA7F3D0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            const Text('Order Complete!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF065F46))),
            const SizedBox(height: 4),
            Text('Received on ${ccFullDate(receivedOn)}', style: const TextStyle(fontSize: 13, color: AppTheme.success)),
          ],
        ),
      );
}
