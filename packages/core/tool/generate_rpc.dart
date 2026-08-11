import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

/// Fails the generator instead of guessing a wire rule.
class UnsupportedWireType implements Exception {
  const UnsupportedWireType(this.type, this.where);

  final String type;
  final String where;

  @override
  String toString() =>
      'No wire rule for `$type` in $where — teach generate_rpc.dart or change '
      'the signature.';
}

/// `--survey` type-checks every DAO without writing anything — the cheap way
/// to see whether the wire rules still cover the whole surface.
Future<void> main(List<String> args) async {
  final String packageRoot = p.normalize(
    p.join(p.dirname(Platform.script.toFilePath()), '..'),
  );

  if (args.contains('--survey')) {
    final RpcGeneration result = await generateRpcSources(packageRoot);
    for (final String line in result.report) {
      stdout.writeln(line);
    }
    if (result.failures.isNotEmpty) exitCode = 1;
    return;
  }

  final RpcGeneration result = await generateRpcSources(packageRoot);
  if (result.failures.isNotEmpty) {
    result.failures.forEach(stderr.writeln);
    exitCode = 1;
    return;
  }

  final Directory outDir = Directory(rpcOutputDir(packageRoot))
    ..createSync(recursive: true);
  result.sources.forEach((String name, String content) {
    File(p.join(outDir.path, name)).writeAsStringSync(content);
  });
  stdout.writeln('${result.sources.length} files, '
      '${result.methodCount} methods across ${result.daoCount} DAOs');
}

/// Where the emitted files live, relative to the package root.
String rpcOutputDir(String packageRoot) =>
    p.join(packageRoot, 'lib', 'rpc', 'generated');

/// What one run produced, kept in memory so a test can diff it against the
/// committed files without touching the working tree.
class RpcGeneration {
  const RpcGeneration({
    required this.sources,
    required this.failures,
    required this.report,
    required this.methodCount,
    required this.daoCount,
  });

  final Map<String, String> sources;
  final List<String> failures;
  final List<String> report;
  final int methodCount;
  final int daoCount;
}

Future<RpcGeneration> generateRpcSources(String packageRoot) async {
  final String daoDir = p.join(packageRoot, 'lib', 'database', 'dao');
  final AnalysisContextCollection collection =
      AnalysisContextCollection(includedPaths: <String>[daoDir]);
  final DartFormatter formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  // Every DAO, always: a partial set would mean deciding per screen which
  // calls may cross the wire, and the rules already cover all of them.
  final List<String> targets = Directory(daoDir)
      .listSync()
      .whereType<File>()
      .map((File f) => p.basenameWithoutExtension(f.path))
      .where((String n) => n.endsWith('_dao'))
      .toList()
    ..sort();

  final Map<String, String> sources = <String, String>{};
  final List<String> failures = <String>[];
  final List<String> report = <String>[];
  final List<({String name, String file})> generated =
      <({String name, String file})>[];
  int methodCount = 0;

  for (final String fileBase in targets) {
    final String path = p.join(daoDir, '$fileBase.dart');
    final SomeResolvedLibraryResult resolved = await collection
        .contextFor(path)
        .currentSession
        .getResolvedLibrary(path);
    if (resolved is! ResolvedLibraryResult) {
      throw StateError('Could not resolve $path');
    }

    final ClassElement dao = resolved.element.classes.firstWhere(
      (ClassElement c) => c.name?.endsWith('Dao') ?? false,
    );
    final String daoName = dao.name ?? fileBase;
    final List<MethodElement> methods = _rpcMethods(dao);
    final _Emitter emitter = _Emitter(daoName, fileBase);

    try {
      sources['$fileBase.remote.rpc.dart'] =
          formatter.format(emitter.remote(methods));
      sources['$fileBase.dispatch.rpc.dart'] =
          formatter.format(emitter.dispatch(methods));
      generated.add((name: daoName, file: fileBase));
      methodCount += methods.length;
      report.add('  ok    $daoName (${methods.length})');
    } on UnsupportedWireType catch (e) {
      failures.add('  FAIL  $daoName — ${e.type} in ${e.where}');
    }
  }

  if (failures.isEmpty) {
    sources['dao_dispatch.rpc.dart'] =
        formatter.format(_dispatchTable(generated));
    sources['remote_daos.rpc.dart'] =
        formatter.format(_remoteDaoSet(generated));
  }
  report
    ..addAll(failures)
    ..add('$methodCount methods across '
        '${generated.length}/${targets.length} DAOs');

  return RpcGeneration(
    sources: sources,
    failures: failures,
    report: report,
    methodCount: methodCount,
    daoCount: generated.length,
  );
}

/// Maps a DAO name to its dispatcher. Generated with **required** parameters
/// on purpose: a new DAO stops the server compiling until it is wired in.
String _dispatchTable(List<({String name, String file})> daos) {
  final List<String> imports = <String>[
    for (final ({String name, String file}) d in daos)
      "import 'package:core/database/dao/${d.file}.dart';",
    for (final ({String name, String file}) d in daos)
      "import '${d.file}.dispatch.rpc.dart';",
  ]..sort();
  // Re-exported so a host needs this one import to name every DAO it must
  // supply below.
  final List<String> exports = <String>[
    for (final ({String name, String file}) d in daos)
      "export 'package:core/database/dao/${d.file}.dart';",
  ]..sort();

  final List<String> params = <String>[
    for (final ({String name, String file}) d in daos)
      'required ${d.name} ${_lowerFirst(d.name)},',
  ];
  final List<String> entries = <String>[
    for (final ({String name, String file}) d in daos)
      "'${d.name}': (String m, Map<String, Object?> a) => "
          'dispatch${d.name}(${_lowerFirst(d.name)}, m, a),',
  ];

  return '// GENERATED by tool/generate_rpc.dart — do not edit.\n'
      '// Regenerate after any DAO signature change; CI checks the diff is '
      'empty.\n\n'
      '${imports.join('\n')}\n\n'
      '${exports.join('\n')}\n\n'
      'typedef DaoDispatch = Future<Object?> Function(\n'
      '  String method,\n'
      '  Map<String, Object?> args,\n'
      ');\n\n'
      'Map<String, DaoDispatch> buildDaoDispatchTable({\n'
      '${params.join('\n')}\n'
      '}) {\n'
      '  return <String, DaoDispatch>{\n'
      '${entries.join('\n')}\n'
      '  };\n'
      '}\n';
}

/// The browser-side counterpart of the dispatch table: one stub per DAO over a
/// shared transport, so a new DAO reaches the client without a hand edit.
String _remoteDaoSet(List<({String name, String file})> daos) {
  final List<String> imports = <String>[
    "import 'package:core/rpc/rpc_transport.dart';",
    for (final ({String name, String file}) d in daos)
      "import 'package:core/database/dao/${d.file}.dart';",
    for (final ({String name, String file}) d in daos)
      "import '${d.file}.remote.rpc.dart';",
  ]..sort();

  final List<String> fields = <String>[
    for (final ({String name, String file}) d in daos)
      'late final ${d.name} ${_lowerFirst(d.name)} = '
          'Remote${d.name}(_transport);',
  ];

  return '// GENERATED by tool/generate_rpc.dart — do not edit.\n'
      '// Regenerate after any DAO signature change; CI checks the diff is '
      'empty.\n\n'
      '${imports.join('\n')}\n\n'
      '/// Every DAO as a browser-side stub, ready to drop into the DI points\n'
      '/// that hand out the real ones on native.\n'
      'class RemoteDaoSet {\n'
      '  RemoteDaoSet(this._transport);\n\n'
      '  final RpcTransport _transport;\n\n'
      '${fields.join('\n\n')}\n'
      '}\n';
}

String _lowerFirst(String s) => s[0].toLowerCase() + s.substring(1);

/// Public instance methods returning a Future — the RPC surface.
List<MethodElement> _rpcMethods(ClassElement dao) {
  final List<MethodElement> methods = dao.methods
      .where((MethodElement m) =>
          !m.isStatic &&
          !(m.name?.startsWith('_') ?? true) &&
          m.returnType.isDartAsyncFuture)
      .toList()
    ..sort((MethodElement a, MethodElement b) =>
        (a.name ?? '').compareTo(b.name ?? ''));
  return methods;
}

class _Emitter {
  _Emitter(this.daoName, this.fileBase);

  final String daoName;
  final String fileBase;
  final Set<String> _imports = <String>{};

  String remote(List<MethodElement> methods) {
    _imports.clear();
    final StringBuffer body = StringBuffer();
    for (final MethodElement m in methods) {
      _signatureImports(m);
      body.writeln(_remoteMethod(m));
    }

    return _file('''
${_importBlock(<String>[
          'package:core/database/dao/$fileBase.dart',
          'package:core/rpc/rpc_codec.dart',
          'package:core/rpc/rpc_transport.dart',
        ])}
/// Browser-side $daoName: every method is one round trip to `/rpc`.
class Remote$daoName implements $daoName {
  Remote$daoName(this._transport);

  final RpcTransport _transport;

$body}
''');
  }

  String dispatch(List<MethodElement> methods) {
    _imports.clear();
    final StringBuffer body = StringBuffer();
    for (final MethodElement m in methods) {
      _signatureImports(m);
      body.writeln(_dispatchCase(m));
    }

    return _file('''
${_importBlock(<String>[
          'package:core/database/dao/$fileBase.dart',
          'package:core/rpc/rpc_codec.dart',
        ])}
/// Server-side entry point: runs [method] on a real [$daoName].
Future<Object?> dispatch$daoName(
  $daoName dao,
  String method,
  Map<String, Object?> args,
) async {
  switch (method) {
$body    default:
      throw RpcCodecException('$daoName has no method "\$method"');
  }
}
''');
  }

  String _remoteMethod(MethodElement m) {
    final DartType ret = _futureValue(m.returnType);
    final String name = m.name ?? '';
    final bool isVoid = ret is VoidType;
    final StringBuffer out = StringBuffer()
      ..writeln('  @override')
      ..writeln('  ${_declaration(m)} async {')
      ..writeln('    ${isVoid ? '' : 'final Object? result = '}'
          'await _transport.call(')
      ..writeln("      '$daoName',")
      ..writeln("      '$name',")
      ..writeln('      <String, Object?>{');
    for (final FormalParameterElement pe in m.formalParameters) {
      final String pname = pe.name ?? '';
      out.writeln("        '$pname': ${_encode(pe.type, pname, '$name.$pname')},");
    }
    out.writeln('      },');
    out.writeln('    );');
    if (isVoid) {
      out.writeln('    return;');
    } else {
      out.writeln('    return ${_decode(ret, 'result', '$name result')};');
    }
    out.writeln('  }');
    return out.toString();
  }

  String _dispatchCase(MethodElement m) {
    final DartType ret = _futureValue(m.returnType);
    final String name = m.name ?? '';
    final List<String> callArgs = <String>[];
    for (final FormalParameterElement pe in m.formalParameters) {
      final String pname = pe.name ?? '';
      String read = _decode(pe.type, "args['$pname']", '$name.$pname');
      // An omitted optional must fall back to the declared default, not to
      // null — the DAO's own signature is the contract.
      final String? fallback = pe.defaultValueCode;
      if (fallback != null) {
        read = "args.containsKey('$pname') ? $read : $fallback";
      }
      callArgs.add(pe.isNamed ? '$pname: $read' : read);
    }
    final String call = 'dao.$name(${callArgs.join(', ')})';

    final StringBuffer out = StringBuffer()..writeln("    case '$name':");
    if (ret is VoidType) {
      out.writeln('      await $call;');
      out.writeln('      return null;');
    } else {
      out.writeln('      final ${_typeName(ret)} value = await $call;');
      out.writeln('      return ${_encode(ret, 'value', '$name result')};');
    }
    return out.toString();
  }

  /// The method signature, copied verbatim so `implements` keeps its grip.
  String _declaration(MethodElement m) {
    final List<String> positional = <String>[];
    final List<String> named = <String>[];
    for (final FormalParameterElement pe in m.formalParameters) {
      final String decl = '${_typeName(pe.type)} ${pe.name}';
      if (pe.isNamed) {
        final String prefix = pe.isRequired ? 'required ' : '';
        final String fallback =
            pe.defaultValueCode == null ? '' : ' = ${pe.defaultValueCode}';
        named.add('$prefix$decl$fallback');
      } else {
        positional.add(decl);
      }
    }
    final List<String> parts = <String>[
      ...positional,
      if (named.isNotEmpty) '{${named.join(', ')}}',
    ];
    return '${_typeName(m.returnType)} ${m.name}(${parts.join(', ')})';
  }

  String _encode(DartType t, String expr, String where) {
    final bool nullable = t.nullabilitySuffix == NullabilitySuffix.question;
    if (t is VoidType) return 'null';
    if (t is DynamicType || t.isDartCoreObject) return 'encodeDynamic($expr)';

    if (t.isDartCoreInt) return nullable ? 'encodeIntOrNull($expr)' : 'encodeInt($expr)';
    if (t.isDartCoreDouble || t.isDartCoreBool || t.isDartCoreString) return expr;
    if (_isDateTime(t)) {
      return nullable ? 'encodeDateTimeOrNull($expr)' : 'encodeDateTime($expr)';
    }
    if (_isEnum(t)) {
      return nullable ? '$expr?.name' : 'encodeEnum($expr)';
    }

    if (t is RecordType) return _encodeRecord(t, expr, where);

    if (t is InterfaceType) {
      if (t.isDartCoreList || t.isDartCoreSet || t.isDartCoreIterable) {
        final DartType e = t.typeArguments.first;
        // A call chain reads as `x?.map(...)`; the ternary form trips
        // prefer_null_aware_operators.
        return '$expr${nullable ? '?' : ''}'
            '.map((${_typeName(e)} e) => ${_encode(e, 'e', where)}).toList()';
      }
      if (t.isDartCoreMap) {
        final DartType k = t.typeArguments[0];
        final DartType v = t.typeArguments[1];
        if (_isRowMap(t)) {
          return nullable
              ? 'encodeNullable<Map<String, Object?>>($expr, '
                  '(Map<String, Object?> v) => encodeRow(v))'
              : 'encodeRow($expr)';
        }
        if (!_isStringableKey(k)) {
          // A record or model key has no JSON-object form, so the map goes
          // over as a list of {k, v} pairs.
          return '$expr${nullable ? '?' : ''}.entries'
              '.map((MapEntry<${_typeName(k)}, ${_typeName(v)}> e) => '
              "<String, Object?>{'k': ${_encode(k, 'e.key', where)}, "
              "'v': ${_encode(v, 'e.value', where)}}).toList()";
        }
        return '$expr${nullable ? '?' : ''}'
            '.map((${_typeName(k)} k, ${_typeName(v)} v) => '
            'MapEntry<String, Object?>(${_keyToString(k, 'k')}, '
            '${_encode(v, 'v', where)}))';
      }
      final List<InterfaceType> variants = _sealedVariants(t);
      final String name = _typeName(t).replaceAll('?', '');
      // Deliberately not `toDb()`: that is a storage codec and drops
      // in-memory state (a hydrated CollectionItem loses its media).
      String body(String v) => variants.isEmpty
          ? _encodeValueClass(t, v, where)
          : _encodeSealed(variants, v, where);
      if (!nullable) return body(expr);
      _addImport(t);
      return 'encodeNullable<$name>($expr, ($name v) => ${body('v')})';
    }
    throw UnsupportedWireType(t.getDisplayString(), where);
  }

  String _decode(DartType t, String expr, String where) {
    final bool nullable = t.nullabilitySuffix == NullabilitySuffix.question;
    if (t is VoidType) return 'null';
    if (t is DynamicType || t.isDartCoreObject) return 'decodeDynamic($expr)';

    if (t.isDartCoreInt) return nullable ? 'decodeIntOrNull($expr)' : 'decodeInt($expr)';
    if (t.isDartCoreDouble) {
      return nullable ? '($expr as num?)?.toDouble()' : '($expr as num).toDouble()';
    }
    if (t.isDartCoreBool) return '$expr as bool${nullable ? '?' : ''}';
    if (t.isDartCoreString) return '$expr as String${nullable ? '?' : ''}';
    if (_isDateTime(t)) {
      return nullable ? 'decodeDateTimeOrNull($expr)' : 'decodeDateTime($expr)';
    }
    if (_isEnum(t)) {
      final String name = _typeName(t).replaceAll('?', '');
      _addImport(t);
      return nullable
          ? 'decodeEnumOrNull<$name>($expr, $name.values)'
          : 'decodeEnum<$name>($expr, $name.values)';
    }

    if (t is RecordType) return _decodeRecord(t, expr, where);

    if (t is InterfaceType) {
      if (t.isDartCoreList || t.isDartCoreSet || t.isDartCoreIterable) {
        final DartType e = t.typeArguments.first;
        final String tail = t.isDartCoreSet ? 'toSet()' : 'toList()';
        final String mapped =
            'asList($expr).map((Object? e) => ${_decode(e, 'e', where)}).$tail';
        return nullable ? '$expr == null ? null : $mapped' : mapped;
      }
      if (t.isDartCoreMap) {
        final DartType k = t.typeArguments[0];
        final DartType v = t.typeArguments[1];
        if (_isRowMap(t)) return nullable ? '$expr == null ? null : decodeRow($expr)' : 'decodeRow($expr)';
        final String mapped;
        if (_isStringableKey(k)) {
          mapped = 'asObject($expr).map((String k, Object? v) => '
              'MapEntry<${_typeName(k)}, ${_typeName(v)}>('
              '${_keyFromString(k, 'k')}, ${_decode(v, 'v', where)}))';
        } else {
          mapped = 'Map<${_typeName(k)}, ${_typeName(v)}>.fromEntries('
              'asList($expr).map((Object? e) => '
              'MapEntry<${_typeName(k)}, ${_typeName(v)}>('
              "${_decode(k, "asObject(e)['k']", where)}, "
              "${_decode(v, "asObject(e)['v']", where)})))";
        }
        return nullable ? '$expr == null ? null : $mapped' : mapped;
      }
      final List<InterfaceType> variants = _sealedVariants(t);
      final String name = _typeName(t).replaceAll('?', '');
      String body(String v) => variants.isEmpty
          ? _decodeValueClass(t, v, where)
          : _decodeSealed(t, variants, v, where);
      if (!nullable) return body(expr);
      _addImport(t);
      return 'decodeNullable<$name>($expr, (Object? v) => ${body('v')})';
    }
    throw UnsupportedWireType(t.getDisplayString(), where);
  }

  /// A sealed hierarchy is a sum type: the wire carries which variant it was
  /// under `_`, then that variant's own fields.
  String _encodeSealed(
    List<InterfaceType> variants,
    String expr,
    String where,
  ) {
    final List<String> cases = <String>[];
    for (final InterfaceType v in variants) {
      final String name = _typeName(v);
      _addImport(v);
      // A variant with no fields must not bind a name it never reads.
      final bool empty = _unnamedCtor(v, where).formalParameters.isEmpty;
      final String pattern = empty ? '$name()' : 'final $name s';
      final String fields =
          empty ? '' : ', ...${_encodeValueClass(v, 's', '$where as $name')}';
      cases.add("$pattern => <String, Object?>{'_': '$name'$fields},");
    }
    return 'switch ($expr) { ${cases.join(' ')} }';
  }

  String _decodeSealed(
    InterfaceType t,
    List<InterfaceType> variants,
    String expr,
    String where,
  ) {
    final List<String> cases = <String>[];
    for (final InterfaceType v in variants) {
      final String name = _typeName(v);
      _addImport(v);
      cases.add("'$name' => ${_decodeValueClass(v, expr, where)},");
    }
    final String type = _typeName(t).replaceAll('?', '');
    return "switch (asObject($expr)['_']) { ${cases.join(' ')} "
        'final Object? tag => throw RpcCodecException('
        "'Unknown $type variant \$tag') }";
  }

  /// Subtypes of a sealed class all live in its own library, which is what
  /// makes this enumerable at all.
  List<InterfaceType> _sealedVariants(InterfaceType t) {
    final Element element = t.element;
    if (element is! ClassElement || !element.isSealed) {
      return const <InterfaceType>[];
    }
    final List<InterfaceType> variants = <InterfaceType>[];
    for (final ClassElement c in element.library.classes) {
      if (c.supertype?.element == element) variants.add(c.thisType);
    }
    variants.sort((InterfaceType a, InterfaceType b) =>
        _typeName(a).compareTo(_typeName(b)));
    return variants;
  }

  /// Round-trips a plain value class through its unnamed constructor: every
  /// constructor parameter is on the wire, so nothing in memory is lost.
  String _encodeValueClass(InterfaceType t, String expr, String where) {
    final ConstructorElement ctor = _unnamedCtor(t, where);
    final List<String> parts = <String>[];
    for (final FormalParameterElement pe in ctor.formalParameters) {
      final String name = pe.name ?? '';
      parts.add("'$name': "
          '${_encode(pe.type, '$expr.$name', '$where.$name')}');
    }
    return '<String, Object?>{${parts.join(', ')}}';
  }

  String _decodeValueClass(InterfaceType t, String expr, String where) {
    final ConstructorElement ctor = _unnamedCtor(t, where);
    _addImport(t);
    final String name = _typeName(t).replaceAll('?', '');
    final String obj = 'asObject($expr)';
    final List<String> parts = <String>[];
    for (final FormalParameterElement pe in ctor.formalParameters) {
      final String field = pe.name ?? '';
      final String read =
          _decode(pe.type, "$obj['$field']", '$where.$field');
      parts.add(pe.isNamed ? '$field: $read' : read);
    }
    final String prefix = parts.isEmpty && ctor.isConst ? 'const ' : '';
    return '$prefix$name(${parts.join(', ')})';
  }

  ConstructorElement _unnamedCtor(InterfaceType t, String where) {
    final Element element = t.element;
    final bool isAbstract =
        element is ClassElement && (element.isAbstract || element.isSealed);
    if (!isAbstract) {
      for (final ConstructorElement c in t.constructors) {
        final String? n = c.name;
        if ((n == null || n.isEmpty || n == 'new') && !c.isFactory) return c;
      }
    }
    throw UnsupportedWireType(
      '${t.getDisplayString()} (no generative unnamed constructor)',
      where,
    );
  }

  String _encodeRecord(RecordType t, String expr, String where) {
    final List<String> parts = <String>[];
    for (int i = 0; i < t.positionalFields.length; i++) {
      final String slot = '\$${i + 1}';
      parts.add("r'$slot': "
          '${_encode(t.positionalFields[i].type, '$expr.$slot', where)}');
    }
    for (final RecordTypeNamedField f in t.namedFields) {
      parts.add("'${f.name}': ${_encode(f.type, '$expr.${f.name}', where)}");
    }
    return '<String, Object?>{${parts.join(', ')}}';
  }

  String _decodeRecord(RecordType t, String expr, String where) {
    final String obj = 'asObject($expr)';
    final List<String> parts = <String>[];
    for (int i = 0; i < t.positionalFields.length; i++) {
      parts.add(_decode(
          t.positionalFields[i].type, "$obj[r'\$${i + 1}']", where));
    }
    for (final RecordTypeNamedField f in t.namedFields) {
      parts.add("${f.name}: ${_decode(f.type, "$obj['${f.name}']", where)}");
    }
    return '(${parts.join(', ')})';
  }

  /// JSON object keys are non-null strings, so only these three shapes fit
  /// one; everything else (records, nullable keys) goes as a list of pairs.
  bool _isStringableKey(DartType k) =>
      k.nullabilitySuffix != NullabilitySuffix.question &&
      (k.isDartCoreString || k.isDartCoreInt || _isEnum(k));

  String _keyToString(DartType k, String expr) {
    if (k.isDartCoreInt) return 'encodeInt($expr)';
    if (_isEnum(k)) return 'encodeEnum($expr)';
    return expr;
  }

  String _keyFromString(DartType k, String expr) {
    if (k.isDartCoreInt) return 'decodeInt($expr)';
    if (_isEnum(k)) {
      final String name = _typeName(k).replaceAll('?', '');
      _addImport(k);
      return 'decodeEnum<$name>($expr, $name.values)';
    }
    return expr;
  }

  /// `Map<String, dynamic>` is a raw database row, not a typed map.
  bool _isRowMap(InterfaceType t) {
    return t.isDartCoreMap &&
        t.typeArguments[0].isDartCoreString &&
        (t.typeArguments[1] is DynamicType || t.typeArguments[1].isDartCoreObject);
  }

  /// Signatures are copied verbatim, so every type they name needs an import —
  /// including the ones buried in generics.
  void _collectImports(DartType t) {
    _addImport(t);
    if (t is InterfaceType) {
      for (final DartType a in t.typeArguments) {
        _collectImports(a);
      }
    } else if (t is RecordType) {
      for (final RecordTypePositionalField f in t.positionalFields) {
        _collectImports(f.type);
      }
      for (final RecordTypeNamedField f in t.namedFields) {
        _collectImports(f.type);
      }
    }
  }

  void _signatureImports(MethodElement m) {
    _collectImports(m.returnType);
    for (final FormalParameterElement pe in m.formalParameters) {
      _collectImports(pe.type);
    }
  }

  void _addImport(DartType t) {
    final Uri? uri = t.element?.library?.uri;
    if (uri != null && uri.scheme == 'package') _imports.add(uri.toString());
  }

  String _importBlock(List<String> fixed) {
    final List<String> all = <String>{...fixed, ..._imports}.toList()..sort();
    return all.map((String u) => "import '$u';").join('\n');
  }

  String _file(String body) => '// GENERATED by tool/generate_rpc.dart — do not edit.\n'
      '// Regenerate after any DAO signature change; CI checks the diff is empty.\n'
      '\n$body';

  String _typeName(DartType t) => t.getDisplayString();
}

DartType _futureValue(DartType t) =>
    t is InterfaceType && t.isDartAsyncFuture ? t.typeArguments.first : t;

bool _isDateTime(DartType t) => t.element?.name == 'DateTime';

bool _isEnum(DartType t) {
  final Element? e = t.element;
  return e is EnumElement;
}
