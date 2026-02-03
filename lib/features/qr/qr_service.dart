import 'package:flutter/material.dart';

/// QR Service Interface
/// 
/// This abstraction isolates QR scanning functionality from the UI layer.
/// The UI should depend on this interface rather than directly importing qr_code_scanner.
/// 
/// TODO: Replace stub implementation with real qr_code_scanner implementation
/// once package compatibility is restored with Android Gradle Plugin.
abstract class QrService {
  /// Scan a QR code and return the result
  /// 
  /// Returns the scanned QR code data as a string, or null if scanning is cancelled
  /// or fails. The stub implementation will show placeholder UI and return null.
  Future<String?> scanQrCode(BuildContext context);
}
