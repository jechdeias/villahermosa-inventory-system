import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import '../../../core/database/app_database.dart';

// ─── Brand colours (same as report_exporter) ─────────────────────────────────
final _kPrimary  = PdfColor.fromHex('1D4ED8');
final _kSuccess  = PdfColor.fromHex('16A34A');
final _kWarning  = PdfColor.fromHex('D97706');
final _kText     = PdfColor.fromHex('111827');
final _kMuted    = PdfColor.fromHex('6B7280');
final _kBorder   = PdfColor.fromHex('E5E7EB');
final _kBg       = PdfColor.fromHex('F9FAFB');
const _kWhite    = PdfColors.white;

String _peso(double v) =>
    '₱${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';

String _statusLabel(String s) => switch (s) {
  'picked'  => 'PICKED',
  'packed'  => 'PACKED',
  'ready'   => 'READY',
  _         => s.toUpperCase(),
};

PdfColor _statusColor(String s) => switch (s) {
  'ready'  => _kSuccess,
  'packed' => _kPrimary,
  'picked' => _kWarning,
  _        => _kMuted,
};

/// Generates a QR-code PNG for [data] at [size]×[size] pixels.
Future<pw.MemoryImage> _qrImage(String data, {int size = 200}) async {
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.M,
    color: const ui.Color(0xFF111827),
    emptyColor: const ui.Color(0xFFFFFFFF),
  );
  final img = await painter.toImage(size.toDouble());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return pw.MemoryImage(bytes!.buffer.asUint8List());
}

/// Builds a single shipping label widget (≈ 9 cm × 6 cm).
Future<pw.Widget> _buildLabel(
  Order order,
  pw.Font font,
  pw.Font fontBold,
  pw.MemoryImage logo,
) async {
  final qr = await _qrImage(order.uuid, size: 220);
  final statusColor = _statusColor(order.warehouseStatus);

  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _kBorder, width: 1),
      borderRadius: pw.BorderRadius.circular(6),
      color: _kWhite,
    ),
    padding: const pw.EdgeInsets.all(10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Header: logo + company + status badge ──────────────────────────
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(children: [
              pw.Image(logo, width: 22, height: 22),
              pw.SizedBox(width: 6),
              pw.Text('Villahermosa',
                  style: pw.TextStyle(font: fontBold, fontSize: 10, color: _kPrimary)),
            ]),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: pw.BoxDecoration(
                color: statusColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                _statusLabel(order.warehouseStatus),
                style: pw.TextStyle(font: fontBold, fontSize: 7, color: _kWhite),
              ),
            ),
          ],
        ),
        pw.Divider(color: _kBorder, height: 10),

        // ── Body: store name + details left, QR right ──────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Store / recipient
                  pw.Text(
                    order.storeName?.isNotEmpty == true
                        ? order.storeName!
                        : 'Unknown Store',
                    style: pw.TextStyle(font: fontBold, fontSize: 12, color: _kText),
                    maxLines: 2,
                  ),
                  pw.SizedBox(height: 4),
                  // Delivery address
                  if (order.deliveryAddress.isNotEmpty)
                    pw.Text(
                      order.deliveryAddress,
                      style: pw.TextStyle(font: font, fontSize: 8, color: _kMuted),
                      maxLines: 2,
                    ),
                  pw.SizedBox(height: 8),
                  // Order number
                  pw.Row(children: [
                    pw.Text('Order: ',
                        style: pw.TextStyle(font: font, fontSize: 8, color: _kMuted)),
                    pw.Text(order.orderNumber,
                        style: pw.TextStyle(font: fontBold, fontSize: 8, color: _kText)),
                  ]),
                  pw.SizedBox(height: 2),
                  // Item count + total
                  pw.Row(children: [
                    pw.Text('Items: ',
                        style: pw.TextStyle(font: font, fontSize: 8, color: _kMuted)),
                    pw.Text('${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                        style: pw.TextStyle(font: fontBold, fontSize: 8, color: _kText)),
                    pw.SizedBox(width: 10),
                    pw.Text('Total: ',
                        style: pw.TextStyle(font: font, fontSize: 8, color: _kMuted)),
                    pw.Text(_peso(order.totalAmount),
                        style: pw.TextStyle(font: fontBold, fontSize: 8, color: _kText)),
                  ]),
                  if (order.routeName != null && order.routeName!.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Row(children: [
                      pw.Text('Route: ',
                          style: pw.TextStyle(font: font, fontSize: 8, color: _kMuted)),
                      pw.Text(order.routeName!,
                          style: pw.TextStyle(font: fontBold, fontSize: 8, color: _kText)),
                    ]),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 8),
            // QR code
            pw.Column(
              children: [
                pw.Image(qr, width: 72, height: 72),
                pw.SizedBox(height: 2),
                pw.Text('Scan to verify',
                    style: pw.TextStyle(font: font, fontSize: 6, color: _kMuted)),
              ],
            ),
          ],
        ),

        pw.Divider(color: _kBorder, height: 10),
        // ── Footer: UUID snippet ──────────────────────────────────────────
        pw.Text(
          'ID: ${order.uuid.substring(0, 18).toUpperCase()}…',
          style: pw.TextStyle(font: font, fontSize: 6, color: _kMuted),
        ),
      ],
    ),
  );
}

/// Generates and opens (share/print) a PDF of shipping labels for [orders].
/// Lays out 2 labels per row on A4 landscape.
Future<void> printLabels(List<Order> orders) async {
  if (orders.isEmpty) return;

  final logo    = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo/vm_logo.png'))
          .buffer.asUint8List());
  final font     = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();

  final doc = pw.Document(
    title: 'Villahermosa Shipping Labels',
    author: 'Villahermosa Inventory System',
  );

  // Build all label widgets first (async QR generation)
  final labels = <pw.Widget>[];
  for (final order in orders) {
    labels.add(await _buildLabel(order, font, fontBold, logo));
  }

  // A4 landscape, 2 columns × N rows
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(16),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Villahermosa — Shipping Labels (${orders.length} order${orders.length == 1 ? '' : 's'})',
                style: pw.TextStyle(font: fontBold, fontSize: 10, color: _kPrimary),
              ),
              pw.Text(
                'Printed: ${DateTime.now().toLocal().toString().substring(0, 16)}',
                style: pw.TextStyle(font: font, fontSize: 8, color: _kMuted),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
        ],
      ),
      build: (ctx) {
        // Chunk into rows of 2
        final rows = <pw.Widget>[];
        for (var i = 0; i < labels.length; i += 2) {
          final left = labels[i];
          final right = i + 1 < labels.length ? labels[i + 1] : pw.SizedBox();
          rows.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: left),
                pw.SizedBox(width: 10),
                pw.Expanded(child: right),
              ],
            ),
          );
          rows.add(pw.SizedBox(height: 10));
        }
        return rows;
      },
    ),
  );

  final bytes = await doc.save();

  // Save locally then open print dialog
  final dir  = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/vm_labels_${DateTime.now().millisecondsSinceEpoch}.pdf');
  await file.writeAsBytes(bytes);

  await Printing.sharePdf(bytes: bytes, filename: 'vm_shipping_labels.pdf');
}
