import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';

// ── Brand colours ─────────────────────────────────────────────────────────────
final _kPrimary = PdfColor.fromHex('1E1E1E');
final _kSuccess = PdfColor.fromHex('059669');
final _kMuted   = PdfColor.fromHex('6B7280');
final _kBorder  = PdfColor.fromHex('E5E7EB');
final _kBg      = PdfColor.fromHex('F9FAFB');
const _kWhite   = PdfColors.white;

/// Generates a simple customer receipt PDF.
Future<pw.Document> buildReceiptPdf(Order order, List<OrderItem> lines) async {
  final doc = pw.Document();
  final now = DateTime.now();

  doc.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 16),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _header(order, now),
          pw.SizedBox(height: 14),
          _storeInfo(order),
          pw.SizedBox(height: 14),
          _divider(),
          pw.SizedBox(height: 8),
          _lineItems(lines),
          pw.SizedBox(height: 8),
          _divider(),
          pw.SizedBox(height: 8),
          _total(order),
          pw.SizedBox(height: 14),
          _paymentInfo(order),
          pw.SizedBox(height: 14),
          _statusBadge(order),
          pw.SizedBox(height: 20),
          _footer(),
        ],
      ),
    ),
  );

  return doc;
}

pw.Widget _header(Order order, DateTime now) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text('RECEIPT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
      pw.SizedBox(height: 2),
      pw.Text('Villahermosa Marketing', style: pw.TextStyle(fontSize: 10, color: _kMuted)),
      pw.SizedBox(height: 6),
      pw.Text(order.orderNumber, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
      pw.SizedBox(height: 2),
      pw.Text('Printed: ${_fmtDateTime(now)}', style: pw.TextStyle(fontSize: 8, color: _kMuted)),
    ],
  );
}

pw.Widget _storeInfo(Order order) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: _kBg,
      borderRadius: pw.BorderRadius.circular(4),
      border: pw.Border.all(color: _kBorder),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _row2('Store', order.storeName ?? '—'),
        pw.SizedBox(height: 4),
        _row2('Order Date', _fmtDate(order.createdAt)),
        if ((order.salesRepName ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 4),
          _row2('Sales Rep', order.salesRepName!),
        ],
      ],
    ),
  );
}

pw.Widget _row2(String label, String value) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _kMuted)),
      pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
    ],
  );
}

pw.Widget _divider() => pw.Divider(color: _kBorder, thickness: 0.5);

pw.Widget _lineItems(List<OrderItem> lines) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      for (final l in lines)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(l.productName, style: pw.TextStyle(fontSize: 10, color: _kPrimary)),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${l.quantity} × ₱${l.unitPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 9, color: _kMuted)),
                  pw.Text('₱${_fmtNum(l.subtotal)}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
                ],
              ),
            ],
          ),
        ),
    ],
  );
}

pw.Widget _total(Order order) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text('TOTAL', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
      pw.Text('₱${_fmtNum(order.totalAmount)}',
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
    ],
  );
}

pw.Widget _paymentInfo(Order order) {
  final notes = order.customerNotes ?? '';
  String method = '—';
  if (notes.contains('payment:')) {
    final start = notes.indexOf('payment:') + 'payment:'.length;
    final end = notes.indexOf(';', start);
    method = end == -1 ? notes.substring(start).trim() : notes.substring(start, end).trim();
  }
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text('Payment Method', style: pw.TextStyle(fontSize: 9, color: _kMuted)),
      pw.Text(method, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
    ],
  );
}

pw.Widget _statusBadge(Order order) {
  final color = switch (order.status) {
    'completed' || 'delivered' => _kSuccess,
    'cancelled' => PdfColor.fromHex('DC2626'),
    _ => PdfColor.fromHex('D97706'),
  };
  return pw.Center(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(order.status.toUpperCase(),
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _kWhite)),
    ),
  );
}

pw.Widget _footer() {
  return pw.Center(
    child: pw.Text('Thank you for your order!',
        style: pw.TextStyle(fontSize: 9, color: _kMuted)),
  );
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _fmtDateTime(DateTime d) =>
    '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _fmtNum(double v) {
  final n = v.round().toString();
  final buf = StringBuffer();
  final mod = n.length % 3;
  for (var i = 0; i < n.length; i++) {
    if (i > 0 && (i - mod) % 3 == 0) buf.write(',');
    buf.write(n[i]);
  }
  return buf.toString();
}
