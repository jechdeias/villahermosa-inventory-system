import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ── Brand colours ─────────────────────────────────────────────────────────────
final _kPrimary = PdfColor.fromHex('1E1E1E');
final _kSuccess = PdfColor.fromHex('059669');
final _kMuted   = PdfColor.fromHex('6B7280');
final _kBorder  = PdfColor.fromHex('E5E7EB');
final _kBg      = PdfColor.fromHex('F9FAFB');
const _kWhite   = PdfColors.white;

/// Generates a simple delivery receipt PDF.
Future<pw.Document> buildDeliveryReceiptPdf({
  required String orderNumber,
  required String storeName,
  required String deliveryAddress,
  required DateTime deliveredAt,
}) async {
  final doc = pw.Document();
  final now = DateTime.now();

  doc.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 16),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _header(now),
          pw.SizedBox(height: 16),
          pw.Divider(color: _kBorder, thickness: 0.5),
          pw.SizedBox(height: 12),
          _infoBlock(orderNumber, storeName, deliveryAddress, deliveredAt),
          pw.SizedBox(height: 16),
          pw.Divider(color: _kBorder, thickness: 0.5),
          pw.SizedBox(height: 20),
          _signatureLine(),
          pw.SizedBox(height: 20),
          _footer(),
        ],
      ),
    ),
  );

  return doc;
}

pw.Widget _header(DateTime now) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text('DELIVERY RECEIPT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
      pw.SizedBox(height: 2),
      pw.Text('Villahermosa Marketing', style: pw.TextStyle(fontSize: 10, color: _kMuted)),
      pw.SizedBox(height: 4),
      pw.Text('Printed: ${_fmtDateTime(now)}', style: pw.TextStyle(fontSize: 8, color: _kMuted)),
    ],
  );
}

pw.Widget _infoBlock(String orderNumber, String storeName, String address, DateTime deliveredAt) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _kBg,
      borderRadius: pw.BorderRadius.circular(4),
      border: pw.Border.all(color: _kBorder),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _row2('Order Number', orderNumber),
        pw.SizedBox(height: 6),
        _row2('Store', storeName),
        pw.SizedBox(height: 6),
        _row2('Delivery Address', address),
        pw.SizedBox(height: 6),
        _row2('Delivered At', _fmtDateTime(deliveredAt)),
      ],
    ),
  );
}

pw.Widget _row2(String label, String value) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 90,
        child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _kMuted)),
      ),
      pw.Expanded(
        child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
      ),
    ],
  );
}

pw.Widget _signatureLine() {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Received by:', style: pw.TextStyle(fontSize: 10, color: _kMuted)),
      pw.SizedBox(height: 28),
      pw.Container(height: 0.5, color: _kPrimary),
      pw.SizedBox(height: 4),
      pw.Text('Signature over printed name', style: pw.TextStyle(fontSize: 8, color: _kMuted)),
    ],
  );
}

pw.Widget _footer() {
  return pw.Center(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _kSuccess,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text('DELIVERED', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _kWhite)),
    ),
  );
}

String _fmtDateTime(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
