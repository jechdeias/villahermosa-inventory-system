import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';
import '../providers/warehouse_providers.dart' show isItemPicked;

// ── Brand colours ─────────────────────────────────────────────────────────────
final _kPrimary = PdfColor.fromHex('1E1E1E');
final _kSuccess = PdfColor.fromHex('059669');
final _kWarning = PdfColor.fromHex('D97706');
final _kMuted   = PdfColor.fromHex('6B7280');
final _kBorder  = PdfColor.fromHex('E5E7EB');
final _kBg      = PdfColor.fromHex('F9FAFB');
const _kWhite   = PdfColors.white;

/// Generates a picklist PDF for [order] with [lines] and stock lookup from [products].
Future<pw.Document> buildPicklistPdf(
  Order order,
  List<OrderItem> lines,
  List<Product> products,
) async {
  final doc = pw.Document();
  final now = DateTime.now();
  final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  // Build product lookup map
  final productMap = {for (final p in products) p.uuid: p};

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => _header(order, dateStr, ctx.pageNumber, ctx.pagesCount),
      build: (ctx) => [
        pw.SizedBox(height: 16),
        _summaryRow(order, lines),
        pw.SizedBox(height: 20),
        _table(lines, productMap),
        pw.SizedBox(height: 24),
        _footer(),
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
            pw.Text('PICKLIST', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
            pw.SizedBox(height: 2),
            pw.Text('Villahermosa Marketing', style: pw.TextStyle(fontSize: 10, color: _kMuted)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Order ${order.orderNumber}',
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

pw.Widget _summaryRow(Order order, List<OrderItem> lines) {
  final picked = lines.where(isItemPicked).length;
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _kBg,
      borderRadius: pw.BorderRadius.circular(6),
      border: pw.Border.all(color: _kBorder),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _infoCell('Store', order.storeName ?? '—'),
        _infoCell('Route', order.routeName ?? '—'),
        _infoCell('Sales Rep', order.salesRepName ?? '—'),
        _infoCell('Items', '${lines.length}'),
        _infoCell('Picked', '$picked / ${lines.length}'),
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

pw.Widget _table(List<OrderItem> lines, Map<String, Product> productMap) {
  final headers = ['✓', 'SKU', 'Product', 'Location', 'Required', 'Available', 'Status'];
  final colWidths = [20.0, 70.0, null, 70.0, 55.0, 55.0, 55.0]; // null = flex

  return pw.TableHelper.fromTextArray(
    headers: headers,
    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _kPrimary),
    headerDecoration: pw.BoxDecoration(color: _kBg),
    cellStyle: pw.TextStyle(fontSize: 9, color: _kPrimary),
    cellAlignments: {
      0: pw.Alignment.center,
      4: pw.Alignment.centerRight,
      5: pw.Alignment.centerRight,
    },
    columnWidths: {
      for (var i = 0; i < colWidths.length; i++)
        if (colWidths[i] != null) i: pw.FixedColumnWidth(colWidths[i]!),
    },
    border: pw.TableBorder.all(color: _kBorder, width: 0.5),
    rowDecoration: pw.BoxDecoration(color: _kWhite),
    oddRowDecoration: pw.BoxDecoration(color: _kBg),
    data: lines.map((l) {
      final p = productMap[l.productId];
      final available = p?.currentStock ?? 0;
      final shortage = available < l.quantity;
      final picked = isItemPicked(l);
      return [
        picked ? '✓' : '□',
        l.productSku,
        l.productName,
        (p?.location ?? '').isEmpty ? '—' : p!.location!,
        '${l.quantity}',
        '$available',
        shortage ? 'SHORT' : (picked ? 'PICKED' : 'PENDING'),
      ];
    }).toList(),
    textStyleBuilder: (col, cell, _) {
      if (col != 6) return null;
      final color = cell == 'SHORT' ? _kWarning : (cell == 'PICKED' ? _kSuccess : null);
      return color == null ? null : pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color);
    },
  );
}

pw.Widget _footer() {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text('Prepared by: ___________________________   Signature: ___________________________',
          style: pw.TextStyle(fontSize: 9, color: _kMuted)),
    ],
  );
}
