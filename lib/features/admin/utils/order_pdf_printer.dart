import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';

// ── Brand colours ─────────────────────────────────────────────────────────────
final _kPrimary = PdfColor.fromHex('1E1E1E');
final _kSuccess = PdfColor.fromHex('059669');
final _kWarning = PdfColor.fromHex('D97706');
final _kMuted   = PdfColor.fromHex('6B7280');
final _kBorder  = PdfColor.fromHex('E5E7EB');
final _kBg      = PdfColor.fromHex('F9FAFB');
const _kWhite   = PdfColors.white;

/// Generates a sales order PDF for [order] with [lines].
/// Used by both admin and sales rep screens.
Future<pw.Document> buildOrderPdf(Order order, List<OrderItem> lines) async {
  final doc = pw.Document();
  final now = DateTime.now();
  final dateStr = _fmtDate(now);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => _header(order, dateStr, ctx.pageNumber, ctx.pagesCount),
      build: (ctx) => [
        pw.SizedBox(height: 16),
        _infoBox(order),
        pw.SizedBox(height: 20),
        _table(lines),
        pw.SizedBox(height: 12),
        _totalsRow(order),
        pw.SizedBox(height: 20),
        _statusAndNotes(order),
      ],
    ),
  );

  return doc;
}

pw.Widget _header(Order order, String date, int page, int total) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('SALES ORDER', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
            pw.SizedBox(height: 2),
            pw.Text('Villahermosa Marketing', style: pw.TextStyle(fontSize: 10, color: _kMuted)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text(order.orderNumber,
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
            pw.SizedBox(height: 2),
            pw.Text('Printed: $date  •  Page $page of $total',
                style: pw.TextStyle(fontSize: 9, color: _kMuted)),
          ]),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Divider(color: _kBorder, thickness: 1),
    ],
  );
}

pw.Widget _infoBox(Order order) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _kBg,
      borderRadius: pw.BorderRadius.circular(6),
      border: pw.Border.all(color: _kBorder),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _infoCell('Store', order.storeName ?? '—'),
            _infoCell('Route', order.routeName ?? '—'),
            _infoCell('Sales Rep', order.salesRepName ?? '—'),
            _infoCell('Date', _fmtDate(order.createdAt)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(children: [
          _infoCell('Delivery Address', order.deliveryAddress.isEmpty ? '—' : order.deliveryAddress),
        ]),
      ],
    ),
  );
}

pw.Widget _infoCell(String label, String value) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _kMuted)),
    pw.SizedBox(height: 2),
    pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
  ]);
}

pw.Widget _table(List<OrderItem> lines) {
  return pw.TableHelper.fromTextArray(
    headers: ['SKU', 'Product', 'Qty', 'Unit Price', 'Subtotal'],
    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _kPrimary),
    headerDecoration: pw.BoxDecoration(color: _kBg),
    cellStyle: pw.TextStyle(fontSize: 9, color: _kPrimary),
    cellAlignments: {
      2: pw.Alignment.centerRight,
      3: pw.Alignment.centerRight,
      4: pw.Alignment.centerRight,
    },
    columnWidths: {
      0: const pw.FixedColumnWidth(70),
      2: const pw.FixedColumnWidth(40),
      3: const pw.FixedColumnWidth(72),
      4: const pw.FixedColumnWidth(72),
    },
    border: pw.TableBorder.all(color: _kBorder, width: 0.5),
    rowDecoration: pw.BoxDecoration(color: _kWhite),
    oddRowDecoration: pw.BoxDecoration(color: _kBg),
    data: lines.map((l) => [
      l.productSku,
      l.productName,
      '${l.quantity}',
      '₱${l.unitPrice.toStringAsFixed(2)}',
      '₱${_fmtNum(l.subtotal)}',
    ]).toList(),
  );
}

pw.Widget _totalsRow(Order order) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(
          color: _kBg,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: _kBorder),
        ),
        child: pw.Row(children: [
          pw.Text('TOTAL AMOUNT  ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kMuted)),
          pw.Text('₱${_fmtNum(order.totalAmount)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
        ]),
      ),
    ],
  );
}

pw.Widget _statusAndNotes(Order order) {
  final statusColor = switch (order.status) {
    'completed' || 'delivered' => _kSuccess,
    'cancelled' => PdfColor.fromHex('DC2626'),
    'processing' || 'out_for_delivery' => PdfColor.fromHex('2563EB'),
    _ => _kWarning,
  };

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(children: [
        pw.Text('Status: ', style: pw.TextStyle(fontSize: 10, color: _kMuted)),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: pw.BoxDecoration(
            color: statusColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            order.status.toUpperCase(),
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _kWhite),
          ),
        ),
      ]),
      if ((order.customerNotes ?? '').isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Text('Notes:', style: pw.TextStyle(fontSize: 9, color: _kMuted)),
        pw.SizedBox(height: 4),
        pw.Text(order.customerNotes!, style: pw.TextStyle(fontSize: 10, color: _kPrimary)),
      ],
    ],
  );
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
