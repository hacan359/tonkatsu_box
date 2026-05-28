import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';

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

/// Renders the widget behind [repaintKey] into a PNG. Desktop opens
/// [FilePicker.saveFile]; Android writes to the system gallery via
/// [Gal.putImageBytes] (album "Tonkatsu Box").
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

    if (Platform.isAndroid) {
      final bool hasAccess = await Gal.requestAccess();
      if (!hasAccess) {
        return const BulkExportResult(BulkExportStatus.cancelled);
      }
      final String galName = stripPngExtension(suggestedFileName);
      await Gal.putImageBytes(
        pngBytes,
        album: 'Tonkatsu Box',
        name: galName,
      );
      return BulkExportResult(BulkExportStatus.saved, path: '$galName.png');
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
