import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

/// Result of an export attempt.
enum BulkExportStatus { saved, cancelled, failed }

/// Keeps Unicode letters and digits, `_`, `-`, and spaces; collapses
/// everything else to `_`.
String sanitizeFileName(String name) {
  return name
      .replaceAll(RegExp(r'[^\p{L}\p{N}\-_ ]', unicode: true), '_')
      .trim();
}

/// Appends `.png` unless [path] already ends with one (case-insensitive).
String ensurePngExtension(String path) {
  return path.toLowerCase().endsWith('.png') ? path : '$path.png';
}

/// Strips a trailing `.png` (case-insensitive).
String stripPngExtension(String name) {
  return name.toLowerCase().endsWith('.png')
      ? name.substring(0, name.length - 4)
      : name;
}

class BulkExportResult {
  const BulkExportResult(this.status, {this.path, this.error});

  final BulkExportStatus status;
  final String? path;
  final Object? error;
}

/// Renders the widget behind [repaintKey] into a PNG and lets the user pick
/// where to save it via [FilePicker.saveFile].
///
/// On Android/iOS the picker opens the Storage Access Framework: [FileType.any]
/// plus [bytes] makes file_picker write the file itself at the chosen location.
/// On desktop file_picker only returns the path, so we write the bytes here.
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
    final Uint8List pngBytes = byteData.buffer.asUint8List();

    final bool mobile = Platform.isAndroid || Platform.isIOS;
    final String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: saveDialogTitle,
      fileName: suggestedFileName,
      // On Android FileType.custom blocks the picker; FileType.any opens SAF.
      type: mobile ? FileType.any : FileType.custom,
      allowedExtensions: mobile ? null : <String>['png'],
      // bytes are required on mobile — file_picker writes via SAF itself.
      bytes: mobile ? pngBytes : null,
    );
    if (outputPath == null) {
      return const BulkExportResult(BulkExportStatus.cancelled);
    }

    // Desktop: file_picker only returns the chosen path; we write the bytes.
    if (!mobile) {
      final String finalPath = ensurePngExtension(outputPath);
      await File(finalPath).writeAsBytes(pngBytes);
      return BulkExportResult(BulkExportStatus.saved, path: finalPath);
    }

    return BulkExportResult(BulkExportStatus.saved, path: outputPath);
  } on Exception catch (e) {
    return BulkExportResult(BulkExportStatus.failed, error: e);
  }
}
