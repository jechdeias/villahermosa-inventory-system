import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'customer_common.dart';

/// The customer's delivery QR code. While the order is out for delivery the
/// customer shows it to the sales rep; once the rep has scanned it the code is
/// greyed out with a green check, and the customer confirms receipt.
///
/// Tap the QR to open a fullscreen bright overlay — easier for the rep to scan.
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

  void _openFullscreen(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.white,
      builder: (_) => _FullscreenQr(orderNumber: orderNumber),
    );
  }

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
          GestureDetector(
            onTap: delivered ? null : () => _openFullscreen(context),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(12),
              ),
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
          ),
          const SizedBox(height: 12),
          Text(orderNumber, style: const TextStyle(fontFamily: AppTheme.monoFamily, fontSize: 14, color: CcColors.muted)),
          const SizedBox(height: 8),
          if (!delivered)
            GestureDetector(
              onTap: () => _openFullscreen(context),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fullscreen, size: 14, color: Color(0xFF555555)),
                  SizedBox(width: 4),
                  Text(
                    'Tap to show fullscreen',
                    style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          else
            const Text(
              'Please confirm you received your order',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textLight),
            ),
        ],
      ),
    );
  }
}

/// Fullscreen white QR overlay — tap anywhere or press back to close.
class _FullscreenQr extends StatefulWidget {
  const _FullscreenQr({required this.orderNumber});
  final String orderNumber;

  @override
  State<_FullscreenQr> createState() => _FullscreenQrState();
}

class _FullscreenQrState extends State<_FullscreenQr> {
  @override
  void initState() {
    super.initState();
    // Max brightness while overlay is open.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final qrSize = (size.shortestSide * 0.78).clamp(200.0, 420.0);

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                    const Spacer(),
                    Text(
                      widget.orderNumber,
                      style: const TextStyle(fontFamily: AppTheme.monoFamily, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // balance close button
                  ],
                ),
              ),

              // QR centred in the remaining space
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: widget.orderNumber,
                        version: QrVersions.auto,
                        size: qrSize,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Show this to your delivery rep',
                        style: TextStyle(fontSize: 15, color: Color(0xFF555555)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap anywhere to close',
                        style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
