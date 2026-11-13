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

/// Generates a weekly warehouse report PDF.
Future<pw.Document> buildReportPdf({
  required List<StockMovement> movements,
  required List<Order> orders,
  required List<Product> products,
  required DateTime weekStart,
}) async {
  final doc = pw.Document();
  final now = DateTime.now();

  final week = movements.where((m) => !m.createdAt.isBefore(weekStart)).toList();
  final stockIn  = week.where((m) => m.movementType == 'in').fold<int>(0, (s, m) => s + m.quantity);
  final stockOut = week.where((m) => m.movementType == 'out').fold<int>(0, (s, m) => s + m.quantity);
  final returns  = week.where((m) => m.movementType == 'return').length;

  bool inWeek(DateTime t) => !t.isBefore(weekStart);
  bool isProcessed(Order o) =>
      o.status == 'delivered' || o.status == 'completed' || o.status == 'out_for_delivery';
  final processed = orders.where((o) => isProcessed(o) && inWeek(o.updatedAt)).toList();

  // Build daily totals
  final days = [for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day).subtract(Duration(days: i))];
  final dailyData = [
    for (final d in days)
      (
        day: d,
        qty: week.where((m) => _sameDay(m.createdAt, d)).fold<int>(0, (s, m) => s + m.quantity),
        ordersCount: processed.where((o) => _sameDay(o.updatedAt, d)).length,
      ),
  ];

  // Top moved products
  final productMap = {for (final p in products) p.uuid: p};
  final perProduct = <String, int>{};
  for (final m in week) {
    perProduct[m.productId] = (perProduct[m.productId] ?? 0) + m.quantity;
  }
  final top = (perProduct.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(8).toList();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => _header(weekStart, now, ctx.pageNumber, ctx.pagesCount),
      build: (ctx) => [
        pw.SizedBox(height: 16),
        _statSummary(stockIn, stockOut, processed.length, returns),
        pw.SizedBox(height: 20),
        _sectionTitle('Daily Movement (Last 7 Days)'),
        pw.SizedBox(height: 8),
        _dailyTable(dailyData),
        pw.SizedBox(height: 20),
        _sectionTitle('Top Moved Products This Week'),
        pw.SizedBox(height: 8),
        _topProductsTable(top, productMap),
        pw.SizedBox(height: 24),
        _footerSig(),
      ],
    ),
  );

  return doc;
}

pw.Widget _header(DateTime weekStart, DateTime now, int page, int total) {
  final weekEnd = weekStart.add(const Duration(days: 6));
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('WEEKLY REPORT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
            pw.SizedBox(height: 2),
            pw.Text('Villahermosa Marketing — Warehouse', style: pw.TextStyle(fontSize: 10, color: _kMuted)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('${_fmtDate(weekStart)} – ${_fmtDate(weekEnd)}',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
            pw.SizedBox(height: 2),
            pw.Text('Printed: ${_fmtDate(now)}  •  Page $page of $total',
                style: pw.TextStyle(fontSize: 9, color: _kMuted)),
          ]),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Divider(color: _kBorder, thickness: 1),
    ],
  );
}

pw.Widget _statSummary(int stockIn, int stockOut, int ordersProcessed, int returns) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: _kBg,
      borderRadius: pw.BorderRadius.circular(6),
      border: pw.Border.all(color: _kBorder),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _statCell('Stock In', '$stockIn units', _kSuccess),
        _statCell('Stock Out', '$stockOut units', PdfColor.fromHex('2563EB')),
        _statCell('Orders Processed', '$ordersProcessed', _kWarning),
        _statCell('Returns Logged', '$returns', PdfColor.fromHex('DC2626')),
      ],
    ),
  );
}

pw.Widget _statCell(String label, String value, PdfColor accent) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
    pw.Container(
      width: 6, height: 6,
      decoration: pw.BoxDecoration(color: accent, shape: pw.BoxShape.circle),
    ),
    pw.SizedBox(height: 4),
    pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _kPrimary)),
    pw.SizedBox(height: 2),
    pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _kMuted)),
  ]);
}

pw.Widget _sectionTitle(String title) {
  return pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kPrimary));
}

pw.Widget _dailyTable(List<({DateTime day, int qty, int ordersCount})> data) {
  return pw.TableHelper.fromTextArray(
    headers: ['Day', 'Date', 'Units Moved', 'Orders Done'],
    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _kPrimary),
    headerDecoration: pw.BoxDecoration(color: _kBg),
    cellStyle: pw.TextStyle(fontSize: 9, color: _kPrimary),
    cellAlignments: {
      2: pw.Alignment.centerRight,
      3: pw.Alignment.centerRight,
    },
    border: pw.TableBorder.all(color: _kBorder, width: 0.5),
    rowDecoration: pw.BoxDecoration(color: _kWhite),
    oddRowDecoration: pw.BoxDecoration(color: _kBg),
    data: data.map((e) => [
      _weekdayName(e.day),
      _fmtDate(e.day),
      '${e.qty}',
      '${e.ordersCount}',
    ]).toList(),
  );
}

pw.Widget _topProductsTable(List<MapEntry<String, int>> top, Map<String, Product> productMap) {
  return pw.TableHelper.fromTextArray(
    headers: ['#', 'Product', 'SKU', 'Units Moved'],
    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _kPrimary),
    headerDecoration: pw.BoxDecoration(color: _kBg),
    cellStyle: pw.TextStyle(fontSize: 9, color: _kPrimary),
    cellAlignments: {
      0: pw.Alignment.center,
      3: pw.Alignment.centerRight,
    },
    columnWidths: {
      0: const pw.FixedColumnWidth(24),
      2: const pw.FixedColumnWidth(80),
      3: const pw.FixedColumnWidth(72),
    },
    border: pw.TableBorder.all(color: _kBorder, width: 0.5),
    rowDecoration: pw.BoxDecoration(color: _kWhite),
    oddRowDecoration: pw.BoxDecoration(color: _kBg),
    data: top.asMap().entries.map((e) {
      final p = productMap[e.value.key];
      return [
        '${e.key + 1}',
        p?.name ?? 'Unknown',
        p?.sku ?? '—',
        '${e.value.value}',
      ];
    }).toList(),
  );
}

pw.Widget _footerSig() {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text('Prepared by: ___________________________   Signature: ___________________________',
          style: pw.TextStyle(fontSize: 9, color: _kMuted)),
    ],
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _weekdayName(DateTime d) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
