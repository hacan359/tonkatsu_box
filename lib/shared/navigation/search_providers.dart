// Провайдеры контекстного поиска для глобального [AppTopBar].
//
// На каждый таб, поддерживающий поиск, заводится отдельный
// [StateProvider] с query — это даёт per-tab сохранение ввода.
// [searchContextFor] возвращает описание контекста текущего таба
// (какой провайдер слушать, какой hint показывать), либо null —
// когда таб поиск не поддерживает.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'nav_tab.dart';

/// Query поиска для Home (All Items) таба.
final StateProvider<String> homeSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Query поиска для Wishlist таба.
final StateProvider<String> wishlistSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Query поиска для Tier Lists таба.
final StateProvider<String> tierListsSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Query поиска для Collections таба.
final StateProvider<String> collectionsSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Query поиска для Settings таба.
final StateProvider<String> settingsSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Общий [FocusNode] для TextField в [AppTopBar].
///
/// Живёт на уровне приложения: используется [AppTopBar] для поля ввода
/// и [AppShell] для программной фокусировки при type-to-search
/// (начал печатать — фокус в шапку).
final Provider<FocusNode> appTopBarFocusProvider = Provider<FocusNode>((
  Ref ref,
) {
  final FocusNode node = FocusNode(debugLabel: 'AppTopBar-search');
  ref.onDispose(node.dispose);
  return node;
});

/// Описание контекста поиска для одного таба.
class SearchContext {
  /// Создаёт [SearchContext].
  const SearchContext({
    required this.queryProvider,
    required this.hint,
  });

  /// Куда пишется и откуда читается текущий query.
  final StateProvider<String> queryProvider;

  /// Placeholder в поле поиска для этого таба.
  final String hint;
}

/// Возвращает контекст поиска для [tab] или `null`, если таб поиск
/// пока не поддерживает (подключим в следующих этапах).
SearchContext? searchContextFor(NavTab tab, BuildContext context) {
  final S loc = S.of(context);
  switch (tab) {
    case NavTab.home:
      return SearchContext(
        queryProvider: homeSearchQueryProvider,
        hint: loc.appBarSearchHint,
      );
    case NavTab.wishlist:
      return SearchContext(
        queryProvider: wishlistSearchQueryProvider,
        hint: loc.appBarSearchHint,
      );
    case NavTab.tierLists:
      return SearchContext(
        queryProvider: tierListsSearchQueryProvider,
        hint: loc.appBarSearchHint,
      );
    case NavTab.settings:
      return SearchContext(
        queryProvider: settingsSearchQueryProvider,
        hint: loc.appBarSearchHint,
      );
    case NavTab.collections:
      return SearchContext(
        queryProvider: collectionsSearchQueryProvider,
        hint: loc.appBarSearchHint,
      );
    case NavTab.search:
      return null;
  }
}
