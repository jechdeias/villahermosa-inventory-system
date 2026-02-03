---
📷 QR FEATURE

STATUS: ACTIVE - SERVICE ABSTRACTION

FEATURE RESPONSIBILITY:
QR code scanning functionality with service abstraction including:
- QR service interface for dependency injection
- Stub implementation for build compatibility
- Service locator for easy implementation swapping
- Placeholder UI for QR scanning interactions

CURRENT STATE:
- Complete service abstraction layer implemented
- Stub service provides placeholder dialog instead of real scanning
- Service locator ready for future real QR implementation
- Isolated from incompatible qr_code_scanner package

WHERE NEW WORK SHOULD HAPPEN:
✅ Replace QrStubService with real implementation when package is compatible
✅ Extend service interface if new QR features are needed
✅ Use QrServiceLocator.instance.scanQrCode() in UI screens
✅ Do NOT directly import qr_code_scanner package

ARCHITECTURE:
- qr_service.dart - Abstract interface for QR scanning
- qr_stub_service.dart - Placeholder implementation
- qr_service_locator.dart - Dependency injection

Rules:
- Service abstraction only (no direct UI)
- All QR functionality must go through service interface
- Use service locator for dependency injection
- Ready for future real QR implementation
---
