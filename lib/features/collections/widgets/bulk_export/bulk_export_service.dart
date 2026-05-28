import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Result of an export attempt.
enum BulkExportStatus { saved, cancelled, failed }

/// Strips characters the system save dialog or `Gal` would reject from a
/// file name candidate. Public for testing.
String sanitizeFileName(String name) {
  return name.replaceAll(RegExp(r'[^\w\- ]'), '_').trim();
}

/// Appends `.png` to [path] unless it already ends with one (case-insensitive).
/// Public for testing — covers the case where the user wipes the extension
/// in the system save dialog.
String ensurePngExtension(String path) {
  return path.toLowerCase().endsWith('.png') ? path : '$path.png';
}

class BulkExportResult {
  const BulkExportResult(this.status, {this.path, this.error});

  final BulkExportStatus status;
  final String? path;
  final Object? error;
}

/// Renders the widget behind [repaintKey] into a PNG and saves it.
///
/// Desktop opens [FilePicker.saveFile]; Android writes to the system gallery
/// via [Gal] (album: "Tonkatsu Box"). Returns a [BulkExportResult] so the
/// caller can show a snackbar with the right tone.
Future<BulkExportResult> saveBoundaryAsPng({
  required GlobalKey repaintKey,
  required String suggestedFileName,
  required String saveDialogTitle,
  double pixelRatio = 2.0,
}) async {
  try {
    final RenderRepaintBoundary? boundary = repaintKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return const BulkExportResult(BulkExportStatus.failed);
    }

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return const BulkExportResult(BulkExportStatus.failed);
    }
    final List<int> pngBytes = byteData.buffer.asUint8List();

    if (Platform.isAndroid) {
      final bool hasAccess = await Gal.requestAccess();
      if (!hasAccess) {
        return const BulkExportResult(BulkExportStatus.cancelled);
      }
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/$suggestedFileName';
      final File temp = File(tempPath);
      await temp.writeAsBytes(pngBytes);
      await Gal.putImage(tempPath, album: 'Tonkatsu Box');
      await temp.delete();
      return BulkExportResult(BulkExportStatus.saved, path: tempPath);
    }

    final String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: saveDialogTitle,
      fileName: suggestedFileName,
      type: FileType.custom,
      allowedExtensions: <String>['png'],
    );
    if (outputPath == null) {
      return const BulkExportResult(BulkExportStatus.cancelled);
    }
    final String finalPath = ensurePngExtension(outputPath);
    await File(finalPath).writeAsBytes(pngBytes);
    return BulkExportResult(BulkExportStatus.saved, path: finalPath);
  } on Exception catch (e) {
    return BulkExportResult(BulkExportStatus.failed, error: e);
  }
}
