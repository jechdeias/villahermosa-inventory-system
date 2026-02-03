import 'package:flutter/material.dart';
import 'qr_service.dart';

/// QR Stub Service Implementation
/// 
/// This is a temporary stub implementation that provides placeholder QR scanning behavior
/// without depending on the incompatible qr_code_scanner package.
/// 
/// TODO: Replace this stub with real qr_code_scanner implementation
/// once package compatibility is restored with Android Gradle Plugin.
class QrStubService implements QrService {
  @override
  Future<String?> scanQrCode(BuildContext context) async {
    // Show placeholder dialog instead of launching QR scanner
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Scanner'),
        content: const Text('QR scanning will be enabled in a later build.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    // Return null to indicate no QR data was scanned
    return null;
  }
}
