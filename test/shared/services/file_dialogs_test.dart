import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tonkatsu_box/shared/services/file_dialogs.dart';

/// Extends the platform interface rather than mocking it, so it keeps the
/// token the `FilePickerPlatform.instance` setter verifies.
class _StubSavePicker extends FilePickerPlatform {
  _StubSavePicker(this._answer);

  final Uri? Function(Uint8List bytes) _answer;

  String? requestedName;

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    void Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    requestedName = fileName;
    return _answer(bytes);
  }
}

final class _StubPlatformFile extends PlatformFile {
  _StubPlatformFile({this.bytes});

  final Uint8List? bytes;

  @override
  String get name => 'picked.json';

  @override
  Uri get uri => Uri.parse('content://picked.json');

  @override
  Never get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => bytes?.length;

  @override
  Future<int?> length() async => bytes?.length;

  @override
  Future<Uint8List> readAsBytes() async {
    final Uint8List? data = bytes;
    if (data == null) throw const FileSystemException('gone');
    return data;
  }

  @override
  Stream<Uint8List> readAsByteStream() =>
      Stream<Uint8List>.fromFuture(readAsBytes());
}

void main() {
  final Uint8List payload = Uint8List.fromList(<int>[1, 2, 3]);

  group('saveBytesWithDialog', () {
    late FilePickerPlatform original;
    late Directory tempDir;

    setUp(() {
      original = FilePickerPlatform.instance;
      tempDir = Directory.systemTemp.createTempSync('file_dialogs_test');
    });

    tearDown(() {
      FilePickerPlatform.instance = original;
      tempDir.deleteSync(recursive: true);
    });

    // Mirrors the real dialog, which writes the bytes before answering.
    _StubSavePicker savingAs(String name) {
      final _StubSavePicker picker = _StubSavePicker((Uint8List bytes) {
        final File file = File(p.join(tempDir.path, name))
          ..writeAsBytesSync(bytes);
        return file.uri;
      });
      FilePickerPlatform.instance = picker;
      return picker;
    }

    test('should return null when the dialog is cancelled', () async {
      FilePickerPlatform.instance = _StubSavePicker((_) => null);

      final String? result = await saveBytesWithDialog(
        fileName: 'backup.zip',
        bytes: payload,
      );

      expect(result, isNull);
    });

    test('should pass the suggested name to the dialog', () async {
      final _StubSavePicker picker = savingAs('backup.zip');

      await saveBytesWithDialog(fileName: 'backup.zip', bytes: payload);

      expect(picker.requestedName, 'backup.zip');
    });

    test('should return the saved path when it has the extension', () async {
      savingAs('backup.zip');

      final String? result = await saveBytesWithDialog(
        fileName: 'backup.zip',
        bytes: payload,
      );

      expect(result, p.join(tempDir.path, 'backup.zip'));
      expect(File(result!).readAsBytesSync(), payload);
    });

    test('should accept the extension in another case', () async {
      savingAs('BACKUP.ZIP');

      final String? result = await saveBytesWithDialog(
        fileName: 'backup.zip',
        bytes: payload,
      );

      expect(result, p.join(tempDir.path, 'BACKUP.ZIP'));
    });

    test('should add the extension when the typed name lacks it', () async {
      savingAs('mine');

      final String? result = await saveBytesWithDialog(
        fileName: 'backup.zip',
        bytes: payload,
      );

      expect(result, p.join(tempDir.path, 'mine.zip'));
      expect(File(result!).readAsBytesSync(), payload);
      expect(File(p.join(tempDir.path, 'mine')).existsSync(), isFalse);
    });

    test(
      'should leave the path alone when the name has no extension',
      () async {
        savingAs('mine');

        final String? result = await saveBytesWithDialog(
          fileName: 'log',
          bytes: payload,
        );

        expect(result, p.join(tempDir.path, 'mine'));
      },
    );

    test('should return the document name for a non-file URI', () async {
      FilePickerPlatform.instance = _StubSavePicker(
        (_) => Uri.parse('content://provider/document/saved.zip'),
      );

      final String? result = await saveBytesWithDialog(
        fileName: 'backup.zip',
        bytes: payload,
      );

      expect(result, 'saved.zip');
    });

    test('should fall back to the suggested name for an opaque URI', () async {
      FilePickerPlatform.instance = _StubSavePicker(
        (_) => Uri.parse('content://provider/'),
      );

      final String? result = await saveBytesWithDialog(
        fileName: 'backup.zip',
        bytes: payload,
      );

      expect(result, 'backup.zip');
    });
  });

  group('PickedFileBytes.readBytesOrNull', () {
    test('should return the bytes of a readable file', () async {
      final Uint8List? result = await _StubPlatformFile(bytes: payload)
          .readBytesOrNull();

      expect(result, payload);
    });

    test('should return null when the file cannot be read', () async {
      final Uint8List? result = await _StubPlatformFile().readBytesOrNull();

      expect(result, isNull);
    });
  });
}
