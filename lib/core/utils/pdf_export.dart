import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

bool get _isDesktop =>
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Exports [doc] as a PDF and returns where it went.
///
/// Desktop (Windows, Linux, macOS): writes the file into the user's Downloads
/// folder (falling back to Documents) and returns its full path.
///
/// Mobile: opens the native share sheet, which lets the user save, mail or
/// print it, and returns null — there is no fixed path to report.
///
/// WHY NOT Printing.layoutPdf ON DESKTOP: it used to, and that was the bug.
/// layoutPdf opens the system PRINT dialog; it offers a printer, never a saved
/// file. Every button calling this says "Export PDF", so on Windows the user
/// got an EPSON print setup dialog and no PDF. Printing is still available
/// where it is actually meant — prepare_orders_screen calls Printing.layoutPdf
/// directly for picklists, under a button labelled Print.
Future<String?> exportPdf(pw.Document doc, String filename) async {
  final bytes = await doc.save();

  if (!_isDesktop) {
    await Printing.sharePdf(bytes: bytes, filename: filename);
    return null;
  }

  Directory? dir;
  try {
    dir = await getDownloadsDirectory();
  } catch (_) {
    // getDownloadsDirectory is desktop-only and can throw on some setups.
  }
  dir ??= await getApplicationDocumentsDirectory();

  final file = File('${dir.path}${Platform.pathSeparator}${_freeName(dir, filename)}');
  await file.writeAsBytes(bytes);
  return file.path;
}

/// Never silently overwrite an earlier export: Report.pdf, Report (2).pdf, ...
String _freeName(Directory dir, String filename) {
  final dot = filename.lastIndexOf('.');
  final stem = dot == -1 ? filename : filename.substring(0, dot);
  final ext = dot == -1 ? '' : filename.substring(dot);

  var candidate = filename;
  var n = 2;
  while (File('${dir.path}${Platform.pathSeparator}$candidate').existsSync()) {
    candidate = '$stem ($n)$ext';
    n++;
  }
  return candidate;
}
