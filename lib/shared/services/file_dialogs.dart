import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../constants/platform_features.dart';

final Logger _log = Logger('FileDialogs');

/// Saves [bytes] through the platform save dialog. Returns where the file
/// landed, for display only, or null when the user cancelled.
Future<String?> saveBytesWithDialog({
  required String fileName,
  required Uint8List bytes,
  String? dialogTitle,
}) async {
  final Uri? saved = await FilePicker.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    bytes: bytes,
  );
  // The browser turns the save into a download and reports nothing back.
  if (kIsWebBuild) return fileName;
  if (saved == null) return null;
  if (saved.scheme != 'file') return _documentName(saved) ?? fileName;
  return _withExtension(saved.toFilePath(), p.extension(fileName));
}

String? _documentName(Uri uri) {
  if (uri.pathSegments.isEmpty) return null;
  final String name = uri.pathSegments.last;
  return name.isEmpty ? null : name;
}

// The desktop dialog saves under exactly what was typed, so a name entered
// without the extension would produce a file nothing can open by type.
Future<String> _withExtension(String path, String extension) async {
  if (extension.isEmpty ||
      path.toLowerCase().endsWith(extension.toLowerCase())) {
    return path;
  }
  final String target = '$path$extension';
  await File(path).rename(target);
  return target;
}

extension PickedFileBytes on PlatformFile {
  /// Null instead of a throw: a pick whose file became unreadable is treated
  /// like a cancelled one by every caller.
  Future<Uint8List?> readBytesOrNull() async {
    try {
      return await readAsBytes();
    } on Exception catch (e) {
      _log.warning('Could not read picked file $name', e);
      return null;
    }
  }
}
