import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Exports a PDF document:
/// - On Windows/desktop: opens the system print dialog via [Printing.layoutPdf].
/// - On Android/mobile: opens the native share/print dialog via [Printing.sharePdf].
Future<void> exportPdf(pw.Document doc, String filename) async {
  final bytes = await doc.save();
  if (defaultTargetPlatform == TargetPlatform.windows) {
    await Printing.layoutPdf(onLayout: (_) => bytes, name: filename);
  } else {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
