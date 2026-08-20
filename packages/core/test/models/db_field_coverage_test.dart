import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// A forgotten `toDb` entry compiles fine and the field silently never reaches
// the database — so constructor parameters are checked against toDb keys here.

/// Constructor parameters deliberately absent from `toDb`: joined models
/// hydrated separately, or in-memory state that is never persisted.
const Map<String, Set<String>> _notStored = <String, Set<String>>{
  'CollectionItem': <String>{
    'game',
    'movie',
    'tvShow',
    'visualNovel',
    'anime',
    'manga',
    'book',
    'audioItem',
    'customMedia',
    'platform',
  },
  // Joined media plus override_name read from collection_items.
  'CanvasItem': <String>{
    'game',
    'movie',
    'tvShow',
    'visualNovel',
    'anime',
    'manga',
    'book',
    'audioItem',
    'customMedia',
    'overrideName',
  },
  // Transient: fetched with search, never stored.
  'Game': <String>{'timeToBeat'},
  // Insert-only rows: the id column is autoincrement.
  'ItemMark': <String>{'id'},
};

/// Columns whose name does not follow the `camelCase → snake_case` rule.
const Map<String, Map<String, String>> _keyOverrides =
    <String, Map<String, String>>{
  'Book': <String, String>{'isbn10': 'isbn_10', 'isbn13': 'isbn_13'},
  // GROUP is an SQL keyword.
  'MangaDexTag': <String, String>{'group': 'tag_group'},
  'TierDefinition': <String, String>{'colorValue': 'color'},
};

String _snake(String name) => name.replaceAllMapped(
      RegExp('[A-Z]'),
      (Match m) => '_${m[0]!.toLowerCase()}',
    );

Set<String> _stringLiterals(AstNode node) {
  final Set<String> found = <String>{};
  void walk(AstNode n) {
    if (n is SimpleStringLiteral) found.add(n.value);
    n.childEntities.whereType<AstNode>().forEach(walk);
  }

  walk(node);
  return found;
}

void main() {
  test('toDb mentions every stored constructor parameter', () {
    final List<String> failures = <String>[];
    final Directory dir = Directory(p.join('lib', 'models'));
    for (final File file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final CompilationUnit unit = parseFile(
        path: p.normalize(file.absolute.path),
        featureSet: FeatureSet.latestLanguageVersion(),
      ).unit;
      for (final ClassDeclaration cls
          in unit.declarations.whereType<ClassDeclaration>()) {
        final String className = cls.name.lexeme;
        MethodDeclaration? toDb;
        ConstructorDeclaration? ctor;
        for (final ClassMember member in cls.members) {
          if (member is MethodDeclaration && member.name.lexeme == 'toDb') {
            toDb = member;
          }
          if (member is ConstructorDeclaration &&
              member.name == null &&
              member.factoryKeyword == null) {
            ctor = member;
          }
        }
        if (toDb == null || ctor == null) continue;

        final Set<String> keys = _stringLiterals(toDb.body);
        for (final FormalParameter param in ctor.parameters.parameters) {
          final String? name = param.name?.lexeme;
          if (name == null) continue;
          if (_notStored[className]?.contains(name) ?? false) continue;
          final String key = _keyOverrides[className]?[name] ?? _snake(name);
          if (!keys.contains(key)) {
            failures.add(
              '$className.$name: toDb() never mentions "$key" '
              '(${p.basename(file.path)})',
            );
          }
        }
      }
    }
    expect(
      failures,
      isEmpty,
      reason: 'Fields that never reach the database:\n${failures.join('\n')}',
    );
  });
}
