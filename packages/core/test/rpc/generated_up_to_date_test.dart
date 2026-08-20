import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../tool/generate_rpc.dart';

/// A field added to a model changes the wire format without changing a single
/// signature — nothing in the type system sees that, so this test does.
void main() {
  late RpcGeneration generated;
  late String outDir;

  setUpAll(() async {
    final String packageRoot = Directory.current.path;
    outDir = rpcOutputDir(packageRoot);
    generated = await generateRpcSources(packageRoot);
  });

  const String hint = 'Run: dart run tool/generate_rpc.dart (in packages/core)';

  group('generated RPC layer', () {
    test('should cover every DAO with a wire rule', () {
      expect(generated.failures, isEmpty, reason: generated.failures.join('\n'));
    });

    test('should match the committed files byte for byte', () {
      final List<String> stale = <String>[];
      generated.sources.forEach((String name, String expected) {
        final File file = File(p.join(outDir, name));
        if (!file.existsSync()) {
          stale.add('$name is missing');
        } else if (file.readAsStringSync() != expected) {
          stale.add('$name differs');
        }
      });

      expect(stale, isEmpty, reason: '${stale.join(', ')}. $hint');
    });

    test('should leave no file behind that the generator no longer emits', () {
      final List<String> orphans = Directory(outDir)
          .listSync()
          .whereType<File>()
          .map((File f) => p.basename(f.path))
          .where((String name) => !generated.sources.containsKey(name))
          .toList();

      expect(orphans, isEmpty, reason: '${orphans.join(', ')}. $hint');
    });
  });
}
