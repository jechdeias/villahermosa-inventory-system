import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/theme/app_theme.dart';
import '../../admin/providers/orders_provider.dart' show databaseProvider;
import '../../customer/widgets/customer_common.dart' show formatPeso;
import '../services/delivery_confirmation.dart';

/// Camera scanning exists only on Android and iOS; everywhere else (desktop,
/// web) the scanner screen falls back to typing the order number.
bool get scannerCameraSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Full-screen QR scanner the sales rep uses to confirm a delivery: scan the
/// code on the customer's order screen, or type the order number. Camera
/// scanning only exists on Android / iOS; desktop gets manual entry.
class SalesScanScreen extends ConsumerStatefulWidget {
  const SalesScanScreen({super.key});

  @override
  ConsumerState<SalesScanScreen> createState() => _SalesScanScreenState();
}

class _SalesScanScreenState extends ConsumerState<SalesScanScreen> with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  late final AnimationController _scanLine = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  final _manualCtrl = TextEditingController();
  bool _torchOn = false;
  bool _processing = false;
  ScanResult? _result;

  @override
  void initState() {
    super.initState();
    if (scannerCameraSupported) {
      _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode], detectionSpeed: DetectionSpeed.noDuplicates);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The sweeping scan line stops for reduced motion.
    if (MediaQuery.of(context).disableAnimations) {
      _scanLine.stop();
      _scanLine.value = 0.5;
    } else if (!_scanLine.isAnimating) {
      _scanLine.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scanLine.dispose();
    _controller?.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await _controller?.toggleTorch();
    if (mounted) setState(() => _torchOn = !_torchOn);
  }

  Future<void> _onQRDetected(BarcodeCapture capture) async {
    if (_processing || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;
    await _process(code);
  }

  /// Shared by the camera and the manual-entry paths.
  Future<void> _process(String code) async {
    if (_processing) return;
    _processing = true;
    try {
      final result = await confirmDeliveryByCode(ref.read(databaseProvider), code);
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) setState(() => _result = const ScanNotFound());
    } finally {
      // Stays true while a result is on screen; cleared by Try Again / OK.
      if (_result == null) _processing = false;
    }
  }

  void _resetScan() {
    setState(() {
      _result = null;
      _processing = false;
    });
  }

  Future<void> _showManualEntry() async {
    _manualCtrl.clear();
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter Order Number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: TextField(
                controller: _manualCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontFamily: AppTheme.monoFamily, fontSize: 16),
                decoration: const InputDecoration(hintText: 'e.g. ORD-2408'),
                onSubmitted: (v) => Navigator.pop(ctx, v),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, _manualCtrl.text),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              child: const Text('Confirm Delivery'),
            ),
          ],
        ),
      ),
    );
    if (code != null && code.trim().isNotEmpty) await _process(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(
        children: [
          if (_controller != null) Positioned.fill(child: MobileScanner(controller: _controller, onDetect: _onQRDetected)) else _buildManualEntryFallback(),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _scanLine,
                builder: (_, _) => CustomPaint(painter: ScannerOverlayPainter(scanProgress: _scanLine.value)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.white12),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('Scan QR Code', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                if (_controller != null)
                  IconButton(
                    tooltip: 'Torch',
                    icon: Icon(_torchOn ? Icons.flashlight_on : Icons.flashlight_off, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.white12),
                    onPressed: _toggleTorch,
                  )
                else
                  const SizedBox(width: 48),
              ]),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(children: [
              Text(
                _controller != null ? "Point at customer's order QR code" : 'Enter the customer\'s order number',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _controller != null ? "The QR code is on the customer's order detail screen" : "It's shown under the QR code on the customer's order screen",
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: OutlinedButton.icon(
              onPressed: _showManualEntry,
              icon: const Icon(Icons.keyboard_outlined, color: Colors.white),
              label: const Text('Enter order number instead', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
                backgroundColor: Colors.black38,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          if (_result != null) _buildResultOverlay(_result!),
        ],
      ),
    );
  }

  /// Desktop / web: no camera, so the frame is empty and the manual-entry
  /// button does the work.
  Widget _buildManualEntryFallback() => const Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 40),
          child: Icon(Icons.qr_code_scanner, size: 64, color: Colors.white24),
        ),
      );

  Widget _buildResultOverlay(ScanResult result) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: switch (result) {
                  ScanSuccess() => _successCard(result),
                  ScanWrongStatus() => _errorCard(title: "Can't Confirm This Order", message: _wrongStatusMessage(result)),
                  ScanNotFound() => _errorCard(title: 'Order Not Found', message: "Make sure you're connected and try again"),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _wrongStatusMessage(ScanWrongStatus r) => switch (r.status) {
        OrderStatus.delivered || OrderStatus.completed => '${r.orderCode} has already been delivered',
        OrderStatus.cancelled => '${r.orderCode} was cancelled',
        _ => '${r.orderCode} is ${OrderStatus.label(r.status).toLowerCase()} — it has not been dispatched yet',
      };

  Widget _circleIcon(Color color, IconData icon) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 32),
      );

  Widget _successCard(ScanSuccess r) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleIcon(AppTheme.success, Icons.check),
          const SizedBox(height: 16),
          const Text('Delivery Confirmed!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(r.storeName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(r.orderCode, style: const TextStyle(fontFamily: AppTheme.monoFamily, fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.warningLight,
              border: Border.all(color: const Color(0xFFFDE68A)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Expanded(child: Text(r.paymentMethod, style: const TextStyle(fontSize: 14, color: Color(0xFF92400E)))),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(r.collectOnDelivery ? 'Collect ${formatPeso(r.amount)}' : formatPeso(r.amount),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          const Text('Saved on this phone · will sync when online', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _resetScan();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            child: const Text('OK'),
          ),
        ],
      );

  Widget _errorCard({required String title, required String message}) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleIcon(AppTheme.error, Icons.close),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetScan,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                child: const Text('Try Again'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _resetScan();
                  _showManualEntry();
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                child: const Text('Enter Manually'),
              ),
            ),
          ]),
        ],
      );
}

/// Dims everything except a 240×240 window, draws a white 4px rounded frame
/// around it, and a scan line sweeping top ↔ bottom ([scanProgress] 0..1).
class ScannerOverlayPainter extends CustomPainter {
  const ScannerOverlayPainter({this.scanProgress = 0.5});

  final double scanProgress;

  static const double windowSize = 240;
  static const double radius = 12;

  /// The clear window, centred slightly above the middle.
  static Rect windowFor(Size size) => Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.42), width: windowSize, height: windowSize);

  @override
  void paint(Canvas canvas, Size size) {
    final window = RRect.fromRectAndRadius(windowFor(size), const Radius.circular(radius));

    final dim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(window)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.6));

    canvas.drawRRect(window, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);

    final y = window.top + 10 + (window.height - 20) * scanProgress.clamp(0.0, 1.0);
    final line = Paint()
      ..shader = LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white, Colors.white.withValues(alpha: 0)])
          .createShader(Rect.fromLTWH(window.left, y - 1, window.width, 2));
    canvas.drawRect(Rect.fromLTWH(window.left + 12, y - 1, window.width - 24, 2), line);
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter old) => old.scanProgress != scanProgress;
}
