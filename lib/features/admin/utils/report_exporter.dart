import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/database/app_database.dart';
import '../providers/reports_provider.dart';

// ─── Villahermosa brand colours ───────────────────────────────────────────────
// PdfColor(r, g, b) takes values 0.0–1.0
final _kPrimary   = PdfColor.fromHex('1D4ED8'); // matches AppTheme.primary
final _kPrimaryBg = PdfColor.fromHex('EFF6FF');
final _kSuccess   = PdfColor.fromHex('16A34A');
final _kError     = PdfColor.fromHex('DC2626');
final _kWarning   = PdfColor.fromHex('D97706');
final _kText      = PdfColor.fromHex('111827');
final _kMuted     = PdfColor.fromHex('6B7280');
final _kBorder    = PdfColor.fromHex('E5E7EB');
final _kHeaderBg  = PdfColor.fromHex('F9FAFB');
const _kWhite     = PdfColors.white;

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _peso(double v) =>
    '₱${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';

String _rangeLabel(ReportsRange range, DateTime? start, DateTime end) {
  switch (range) {
    case ReportsRange.week:
      return 'Last 7 days';
    case ReportsRange.month:
      return 'Last 30 days';
    case ReportsRange.quarter:
      return 'Last 3 months';
    case ReportsRange.year:
      return 'Last 12 months';
    case ReportsRange.all:
      return 'All time';
    case ReportsRange.custom:
      return start != null ? '${_fmt(start)} – ${_fmt(end)}' : 'Custom range';
  }
}

// ─── PDF ──────────────────────────────────────────────────────────────────────

Future<void> exportPdf({
  required List<Order> orders,
  required List<Payment> payments,
  required List<ProductSales> topProducts,
  required List<StatusCount> statusBreakdown,
  required Map<String, dynamic> stats,
  required ReportsRange range,
  required DateTime? rangeStart,
  required DateTime rangeEnd,
}) async {
  final pdf = pw.Document(
    title: 'Villahermosa Sales Report',
    author: 'Villahermosa Marketing',
  );

  // Load logo
  pw.ImageProvider? logoImage;
  try {
    final data = await rootBundle.load('assets/images/logo/vm_logo.png');
    logoImage = pw.MemoryImage(data.buffer.asUint8List());
  } catch (_) {}

  // Load fonts that support ₱ (peso sign). NotoSans has full Unicode coverage.
  final ttf = await PdfGoogleFonts.notoSansRegular();
  final ttfBold = await PdfGoogleFonts.notoSansBold();
  // NotoSansMono for order numbers / SKUs
  final ttfMono = await PdfGoogleFonts.notoSansMonoRegular();

  final baseStyle     = pw.TextStyle(font: ttf,     fontSize: 9,  color: _kText);
  final boldStyle     = pw.TextStyle(font: ttfBold,  fontSize: 9,  color: _kText);
  final monoStyle     = pw.TextStyle(font: ttfMono,  fontSize: 8,  color: _kText);
  final mutedStyle    = pw.TextStyle(font: ttf,     fontSize: 8,  color: _kMuted);
  final headingStyle  = pw.TextStyle(font: ttfBold,  fontSize: 14, color: _kText);
  final subStyle      = pw.TextStyle(font: ttf,     fontSize: 10, color: _kMuted);
  final sectionStyle  = pw.TextStyle(font: ttfBold,  fontSize: 10, color: _kText);
  final labelStyle    = pw.TextStyle(font: ttfBold,  fontSize: 7,  color: _kMuted, letterSpacing: 0.5);

  final rangeLabel = _rangeLabel(range, rangeStart, rangeEnd);
  final generatedAt = DateTime.now();

  // ── Stat helpers ──
  final totalRevenue   = stats['totalRevenue'] as double;
  final orderCount     = stats['orderCount'] as int;
  final collected      = stats['collected'] as double;
  final outstanding    = stats['outstanding'] as double;
  final lowStock       = stats['lowStockCount'] as int;
  final avgOrder       = stats['avgOrderValue'] as double;
  final growthRate     = stats['growthRate'] as double?;

  String growthLabel() {
    if (growthRate == null) return '—';
    return '${growthRate! >= 0 ? '+' : ''}${growthRate!.toStringAsFixed(1)}%';
  }

  PdfColor growthColor() {
    if (growthRate == null) return _kMuted;
    return growthRate! >= 0 ? _kSuccess : _kError;
  }

  // ── Shared widgets ──
  pw.Widget _divider() => pw.Container(
    height: 0.5,
    color: _kBorder,
    margin: const pw.EdgeInsets.symmetric(vertical: 6),
  );

  pw.Widget _sectionHeader(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Row(children: [
      pw.Container(width: 3, height: 14, color: _kPrimary),
      pw.SizedBox(width: 6),
      pw.Text(title, style: sectionStyle),
    ]),
  );

  // ── Stat tile ──
  pw.Widget _statTile(String label, String value, {PdfColor? valueColor}) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _kWhite,
          border: pw.Border.all(color: _kBorder, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(), style: labelStyle),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(font: ttfBold, fontSize: 15, color: valueColor ?? _kText)),
          ],
        ),
      );

  // ── Table header cell ──
  pw.Widget _thCell(String text, {pw.TextAlign align = pw.TextAlign.left, int flex = 1}) =>
      pw.Expanded(
        flex: flex,
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          color: _kHeaderBg,
          child: pw.Text(text, style: labelStyle, textAlign: align),
        ),
      );

  // ── Table data cell ──
  pw.Widget _tdCell(String text, {pw.TextStyle? style, pw.TextAlign align = pw.TextAlign.left, int flex = 1}) =>
      pw.Expanded(
        flex: flex,
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(text, style: style ?? baseStyle, textAlign: align, maxLines: 2),
        ),
      );

  // ── Build pages ──
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      footer: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _kBorder, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Villahermosa Marketing · Confidential', style: mutedStyle),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: mutedStyle),
          ],
        ),
      ),
      build: (context) => [
        // ── Letterhead ──────────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: _kPrimary,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null) ...[
                pw.Container(
                  width: 48,
                  height: 48,
                  decoration: pw.BoxDecoration(
                    color: _kWhite,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Image(logoImage),
                ),
                pw.SizedBox(width: 14),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('VILLAHERMOSA MARKETING',
                        style: pw.TextStyle(font: ttfBold, fontSize: 16, color: _kWhite, letterSpacing: 1.0)),
                    pw.SizedBox(height: 2),
                    pw.Text('Boac, Marinduque · Sales & Inventory Report',
                        style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColor.fromInt(0xFFBFDBFE))),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('REPORT PERIOD',
                      style: pw.TextStyle(font: ttfBold, fontSize: 7, color: PdfColor.fromInt(0xFF93C5FD), letterSpacing: 0.5)),
                  pw.SizedBox(height: 2),
                  pw.Text(rangeLabel,
                      style: pw.TextStyle(font: ttfBold, fontSize: 11, color: _kWhite)),
                  pw.SizedBox(height: 6),
                  pw.Text('Generated ${_fmt(generatedAt)}',
                      style: pw.TextStyle(font: ttf, fontSize: 7, color: PdfColor.fromInt(0xFFBFDBFE))),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // ── Summary stats grid ──────────────────────────────────────────
        _sectionHeader('Summary'),
        pw.Row(children: [
          pw.Expanded(child: _statTile('Total Revenue', _peso(totalRevenue))),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statTile('Total Orders', '$orderCount')),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statTile('Avg Order Value', _peso(avgOrder))),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(child: _statTile('Collected', _peso(collected), valueColor: _kSuccess)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statTile('Outstanding', _peso(outstanding), valueColor: _kError)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statTile('Low Stock Alerts', '$lowStock', valueColor: lowStock > 0 ? _kWarning : _kSuccess)),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(
            child: _statTile('Growth Rate', growthLabel(), valueColor: growthColor()),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.SizedBox()),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.SizedBox()),
        ]),

        pw.SizedBox(height: 20),

        // ── Orders by status ────────────────────────────────────────────
        if (statusBreakdown.isNotEmpty) ...[
          _sectionHeader('Orders by Status'),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _kBorder, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(children: [
              // Header
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: _kHeaderBg,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(6),
                    topRight: pw.Radius.circular(6),
                  ),
                ),
                child: pw.Row(children: [
                  _thCell('STATUS', flex: 3),
                  _thCell('COUNT', flex: 1, align: pw.TextAlign.right),
                  _thCell('SHARE', flex: 1, align: pw.TextAlign.right),
                ]),
              ),
              ...statusBreakdown.map((s) {
                final total = statusBreakdown.fold(0, (sum, x) => sum + x.count);
                final pct = total > 0 ? (s.count / total * 100).toStringAsFixed(1) : '0.0';
                final label = s.status.isEmpty ? s.status : s.status[0].toUpperCase() + s.status.substring(1);
                return pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: _kBorder, width: 0.5)),
                  ),
                  child: pw.Row(children: [
                    _tdCell(label, flex: 3),
                    _tdCell('${s.count}', align: pw.TextAlign.right, flex: 1),
                    _tdCell('$pct%', align: pw.TextAlign.right, style: mutedStyle, flex: 1),
                  ]),
                );
              }),
            ]),
          ),
          pw.SizedBox(height: 20),
        ],

        // ── Top products ────────────────────────────────────────────────
        if (topProducts.isNotEmpty) ...[
          _sectionHeader('Top Products'),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _kBorder, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(children: [
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: _kHeaderBg,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(6),
                    topRight: pw.Radius.circular(6),
                  ),
                ),
                child: pw.Row(children: [
                  _thCell('SKU', flex: 2),
                  _thCell('PRODUCT', flex: 5),
                  _thCell('QTY SOLD', flex: 2, align: pw.TextAlign.right),
                  _thCell('REVENUE', flex: 3, align: pw.TextAlign.right),
                ]),
              ),
              ...topProducts.map((p) => pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: _kBorder, width: 0.5)),
                ),
                child: pw.Row(children: [
                  _tdCell(p.sku, style: monoStyle, flex: 2),
                  _tdCell(p.name, flex: 5),
                  _tdCell('${p.quantity}', align: pw.TextAlign.right, style: boldStyle, flex: 2),
                  _tdCell(_peso(p.revenue), align: pw.TextAlign.right, flex: 3),
                ]),
              )),
            ]),
          ),
          pw.SizedBox(height: 20),
        ],

        // ── Order list ──────────────────────────────────────────────────
        _sectionHeader('Order Details  (${orders.length} orders)'),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kBorder, width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(children: [
            pw.Container(
              decoration: pw.BoxDecoration(
                color: _kHeaderBg,
                borderRadius: pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(6),
                  topRight: pw.Radius.circular(6),
                ),
              ),
              child: pw.Row(children: [
                _thCell('ORDER #', flex: 3),
                _thCell('DATE', flex: 2),
                _thCell('STORE', flex: 4),
                _thCell('ROUTE', flex: 3),
                _thCell('SALES REP', flex: 3),
                _thCell('STATUS', flex: 2),
                _thCell('AMOUNT', flex: 3, align: pw.TextAlign.right),
              ]),
            ),
            ...orders.map((o) {
              final statusColor = switch (o.status) {
                'completed' => _kSuccess,
                'cancelled' => _kError,
                'pending'   => _kWarning,
                _           => _kMuted,
              };
              return pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: _kBorder, width: 0.5)),
                ),
                child: pw.Row(children: [
                  _tdCell(o.orderNumber, style: monoStyle, flex: 3),
                  _tdCell(_fmt(o.createdAt), flex: 2),
                  _tdCell(o.storeName ?? '—', flex: 4),
                  _tdCell(o.routeName ?? '—', flex: 3),
                  _tdCell(o.salesRepName ?? '—', flex: 3),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: pw.Text(
                        o.status.isEmpty ? o.status : o.status[0].toUpperCase() + o.status.substring(1),
                        style: pw.TextStyle(font: ttfBold, fontSize: 7, color: statusColor),
                      ),
                    ),
                  ),
                  _tdCell(_peso(o.totalAmount), align: pw.TextAlign.right, style: boldStyle, flex: 3),
                ]),
              );
            }),
          ]),
        ),

        pw.SizedBox(height: 24),

        // ── Footer note ─────────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _kPrimaryBg,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _kBorder, width: 0.5),
          ),
          child: pw.Text(
            'This report is generated automatically by the Villahermosa Inventory System. '
            'All figures are based on recorded transactions within the selected period. '
            'For questions, contact your system administrator.',
            style: mutedStyle,
          ),
        ),
      ],
    ),
  );

  final bytes = await pdf.save();
  await _saveAndOpen(bytes, 'VillahermosaReport_${_stamp(generatedAt)}.pdf');
}

// ─── CSV ──────────────────────────────────────────────────────────────────────

Future<void> exportCsv({
  required List<Order> orders,
  required List<Payment> payments,
  required List<ProductSales> topProducts,
  required Map<String, dynamic> stats,
  required ReportsRange range,
  required DateTime? rangeStart,
  required DateTime rangeEnd,
}) async {
  final now = DateTime.now();
  final rangeLabel = _rangeLabel(range, rangeStart, rangeEnd);

  final buf = StringBuffer();

  // ── Metadata block ──
  buf.writeln('# VILLAHERMOSA MARKETING — SALES REPORT');
  buf.writeln('# Generated:,${ _fmtDateTime(now)}');
  buf.writeln('# Period:,$rangeLabel');
  buf.writeln('# Total Revenue:,${_peso(stats['totalRevenue'] as double)}');
  buf.writeln('# Orders:,${stats['orderCount']}');
  buf.writeln('# Collected:,${_peso(stats['collected'] as double)}');
  buf.writeln('# Outstanding:,${_peso(stats['outstanding'] as double)}');
  buf.writeln('# Avg Order Value:,${_peso(stats['avgOrderValue'] as double)}');
  final gr = stats['growthRate'] as double?;
  buf.writeln('# Growth Rate:,${gr == null ? 'N/A' : '${gr >= 0 ? '+' : ''}${gr.toStringAsFixed(1)}%'}');
  buf.writeln('# Low Stock Alerts:,${stats['lowStockCount']}');
  buf.writeln('#');

  // ── SECTION 1: Orders ──
  buf.writeln('## ORDERS');
  _csvRow(buf, ['Order Number', 'Date', 'Time', 'Store', 'Route', 'Sales Rep', 'Status', 'Warehouse Status', 'Total Amount (PHP)', 'Order UUID']);
  for (final o in orders) {
    _csvRow(buf, [
      o.orderNumber,
      _fmt(o.createdAt),
      '${o.createdAt.hour.toString().padLeft(2,'0')}:${o.createdAt.minute.toString().padLeft(2,'0')}',
      o.storeName ?? '',
      o.routeName ?? '',
      o.salesRepName ?? '',
      o.status,
      o.warehouseStatus ?? '',
      o.totalAmount.toStringAsFixed(2),
      o.uuid,
    ]);
  }
  buf.writeln();

  // ── SECTION 2: Top Products ──
  if (topProducts.isNotEmpty) {
    buf.writeln('## TOP PRODUCTS');
    _csvRow(buf, ['Rank', 'SKU', 'Product Name', 'Qty Sold', 'Revenue (PHP)']);
    for (var i = 0; i < topProducts.length; i++) {
      final p = topProducts[i];
      _csvRow(buf, [
        '${i + 1}',
        p.sku,
        p.name,
        '${p.quantity}',
        p.revenue.toStringAsFixed(2),
      ]);
    }
    buf.writeln();
  }

  // ── SECTION 3: Payments ──
  if (payments.isNotEmpty) {
    buf.writeln('## PAYMENTS');
    _csvRow(buf, ['Payment Date', 'Order #', 'Store', 'Sales Rep', 'Order Amount (PHP)', 'Amount Paid (PHP)', 'Balance (PHP)', 'Status', 'Method', 'Notes']);
    for (final p in payments) {
      _csvRow(buf, [
        _fmt(p.paymentDate),
        p.orderCode,
        p.storeName,
        p.salesRepName,
        p.orderAmount.toStringAsFixed(2),
        p.amountPaid.toStringAsFixed(2),
        p.balance.toStringAsFixed(2),
        p.status,
        p.paymentMethod ?? '',
        p.notes ?? '',
      ]);
    }
  }

  final bytes = Uint8List.fromList(buf.toString().codeUnits);
  await _saveAndOpen(bytes, 'VillahermosaReport_${_stamp(now)}.csv');
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

void _csvRow(StringBuffer buf, List<String> cells) {
  buf.writeln(cells.map((v) {
    final escaped = v.replaceAll('"', '""');
    return (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n'))
        ? '"$escaped"'
        : escaped;
  }).join(','));
}

String _stamp(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2,'0')}${d.day.toString().padLeft(2,'0')}'
    '_${d.hour.toString().padLeft(2,'0')}${d.minute.toString().padLeft(2,'0')}';

String _fmtDateTime(DateTime d) =>
    '${_fmt(d)} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

Future<void> _saveAndOpen(Uint8List bytes, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes);

  if (fileName.endsWith('.pdf')) {
    // On desktop/mobile: open the native print/share dialog so the user
    // can preview, save to a custom location, or print.
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
  // CSV: file is already written to documents dir; caller shows the path.
}
