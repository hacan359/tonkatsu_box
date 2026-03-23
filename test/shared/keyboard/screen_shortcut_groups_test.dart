import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/screens/collection_screen.dart';
import 'package:xerabora/features/collections/screens/home_screen.dart';
import 'package:xerabora/features/collections/screens/item_detail_screen.dart';
import 'package:xerabora/features/search/screens/search_screen.dart';
import 'package:xerabora/features/tier_lists/screens/tier_list_detail_screen.dart';
import 'package:xerabora/features/tier_lists/screens/tier_lists_screen.dart';
import 'package:xerabora/features/wishlist/screens/wishlist_screen.dart';
import 'package:xerabora/shared/keyboard/keyboard_shortcuts.dart';

void main() {
  group('Screen shortcutGroups', () {
    test('HomeScreen should define shortcut group', () {
      expect(HomeScreen.shortcutGroup.title, 'Коллекции');
      expect(HomeScreen.shortcutGroup.entries, isNotEmpty);
      expect(
        HomeScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+N'),
        isTrue,
      );
      expect(
        HomeScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+I'),
        isTrue,
      );
      expect(
        HomeScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Delete'),
        isTrue,
      );
      expect(
        HomeScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'F2'),
        isTrue,
      );
    });

    test('CollectionScreen should define shortcut group', () {
      expect(CollectionScreen.shortcutGroup.title, 'Коллекция');
      expect(CollectionScreen.shortcutGroup.entries, isNotEmpty);
      expect(
        CollectionScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+E'),
        isTrue,
      );
      expect(
        CollectionScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+B'),
        isTrue,
      );
      expect(
        CollectionScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+M'),
        isTrue,
      );
    });

    test('ItemDetailScreen should define shortcut group', () {
      expect(ItemDetailScreen.shortcutGroup.title, 'Деталь элемента');
      expect(ItemDetailScreen.shortcutGroup.entries, isNotEmpty);
      expect(
        ItemDetailScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+B'),
        isTrue,
      );
      expect(
        ItemDetailScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+L'),
        isTrue,
      );
      expect(
        ItemDetailScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+M'),
        isTrue,
      );
      expect(
        ItemDetailScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Alt+1..5'),
        isTrue,
      );
      expect(
        ItemDetailScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Alt+0'),
        isTrue,
      );
    });

    test('TierListsScreen should define shortcut group', () {
      expect(TierListsScreen.shortcutGroup.title, 'Тир-листы');
      expect(TierListsScreen.shortcutGroup.entries, isNotEmpty);
      expect(
        TierListsScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+N'),
        isTrue,
      );
      expect(
        TierListsScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Delete'),
        isTrue,
      );
      expect(
        TierListsScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'F2'),
        isTrue,
      );
      expect(
        TierListsScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Enter'),
        isTrue,
      );
    });

    test('TierListDetailScreen should define shortcut group', () {
      expect(TierListDetailScreen.shortcutGroup.title, 'Тир-лист');
      expect(TierListDetailScreen.shortcutGroup.entries, isNotEmpty);
      expect(
        TierListDetailScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+E'),
        isTrue,
      );
      expect(
        TierListDetailScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+Enter'),
        isTrue,
      );
      expect(
        TierListDetailScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+Shift+D'),
        isTrue,
      );
    });

    test('WishlistScreen should define shortcut group', () {
      expect(WishlistScreen.shortcutGroup.title, 'Вишлист');
      expect(WishlistScreen.shortcutGroup.entries, isNotEmpty);
      expect(
        WishlistScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+N'),
        isTrue,
      );
      expect(
        WishlistScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+H'),
        isTrue,
      );
    });

    test('SearchScreen should define shortcut group', () {
      expect(SearchScreen.shortcutGroup.title, 'Поиск');
      expect(SearchScreen.shortcutGroup.entries, isNotEmpty);
      expect(
        SearchScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Ctrl+F'),
        isTrue,
      );
      expect(
        SearchScreen.shortcutGroup.entries
            .any((ShortcutEntry e) => e.keys == 'Escape'),
        isTrue,
      );
    });
  });
}
