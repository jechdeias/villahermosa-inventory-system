import 'qr_service.dart';
import 'qr_stub_service.dart';

/// QR Service Locator
/// 
/// Centralizes QR service dependency injection.
/// This allows us to easily swap between stub and real implementations
/// without modifying UI code.
/// 
/// TODO: Replace stub service with real implementation once QR package compatibility is restored
class QrServiceLocator {
  static QrService? _instance;

  /// Get the current QR service instance
  static QrService get instance {
    _instance ??= QrStubService();
    return _instance!;
  }

  /// Set a custom QR service instance (for testing or future real implementation)
  static void setInstance(QrService service) {
    _instance = service;
  }

  /// Reset to default stub implementation
  static void resetToStub() {
    _instance = null;
  }
}
