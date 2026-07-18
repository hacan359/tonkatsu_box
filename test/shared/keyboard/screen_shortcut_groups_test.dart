import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/screens/collection_screen.dart';
import 'package:tonkatsu_box/features/collections/screens/home_screen.dart';
import 'package:tonkatsu_box/features/collections/screens/item_detail_screen.dart';
import 'package:tonkatsu_box/features/search/screens/search_screen.dart';
import 'package:tonkatsu_box/features/tier_lists/screens/tier_list_detail_screen.dart';
import 'package:tonkatsu_box/features/tier_lists/screens/tier_lists_screen.dart';
import 'package:tonkatsu_box/features/wishlist/screens/wishlist_screen.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/l10n/app_localizations_ru.dart';
import 'package:tonkatsu_box/shared/keyboard/keyboard_shortcuts.dart';

void main() {
  final S l = SRu();

  bool hasKey(ShortcutGroup group, String keys) =>
      group.entries.any((ShortcutEntry e) => e.keys == keys);

  group('Screen shortcutGroups', () {
    test('HomeScreen should define shortcut group', () {
      final ShortcutGroup group = HomeScreen.shortcutGroup(l);
      expect(group.title, 'Коллекции');
      expect(group.entries, isNotEmpty);
      expect(hasKey(group, 'Ctrl+N'), isTrue);
      expect(hasKey(group, 'Ctrl+I'), isTrue);
      expect(hasKey(group, 'Delete'), isTrue);
      expect(hasKey(group, 'F2'), isTrue);
    });

    test('CollectionScreen should define shortcut group', () {
      final ShortcutGroup group = CollectionScreen.shortcutGroup(l);
      expect(group.title, 'Коллекция');
      expect(group.entries, isNotEmpty);
      expect(hasKey(group, 'Ctrl+E'), isTrue);
      expect(hasKey(group, 'Ctrl+B'), isTrue);
      expect(hasKey(group, 'Ctrl+M'), isTrue);
    });

    test('ItemDetailScreen should define shortcut group', () {
      final ShortcutGroup group = ItemDetailScreen.shortcutGroup(l);
      expect(group.title, 'Деталь элемента');
      expect(group.entries, isNotEmpty);
      expect(hasKey(group, 'Ctrl+B'), isTrue);
      expect(hasKey(group, 'Ctrl+L'), isTrue);
      expect(hasKey(group, 'Ctrl+M'), isTrue);
      expect(hasKey(group, 'Alt+1..5'), isTrue);
      expect(hasKey(group, 'Alt+0'), isTrue);
    });

    test('TierListsScreen should define shortcut group', () {
      final ShortcutGroup group = TierListsScreen.shortcutGroup(l);
      expect(group.title, 'Тир-листы');
      expect(group.entries, isNotEmpty);
      expect(hasKey(group, 'Ctrl+N'), isTrue);
      expect(hasKey(group, 'Delete'), isTrue);
      expect(hasKey(group, 'F2'), isTrue);
      expect(hasKey(group, 'Enter'), isTrue);
    });

    test('TierListDetailScreen should define shortcut group', () {
      final ShortcutGroup group = TierListDetailScreen.shortcutGroup(l);
      expect(group.title, 'Тир-лист');
      expect(group.entries, isNotEmpty);
      expect(hasKey(group, 'Ctrl+E'), isTrue);
      expect(hasKey(group, 'Ctrl+Enter'), isTrue);
      expect(hasKey(group, 'Ctrl+Shift+D'), isTrue);
    });

    test('WishlistScreen should define shortcut group', () {
      final ShortcutGroup group = WishlistScreen.shortcutGroup(l);
      expect(group.title, 'Желаемое');
      expect(group.entries, isNotEmpty);
      expect(hasKey(group, 'Ctrl+N'), isTrue);
      expect(hasKey(group, 'Ctrl+H'), isTrue);
    });

    test('SearchScreen should define shortcut group', () {
      final ShortcutGroup group = SearchScreen.shortcutGroup(l);
      expect(group.title, 'Поиск');
      expect(group.entries, isNotEmpty);
      expect(hasKey(group, 'Ctrl+F'), isTrue);
      expect(hasKey(group, 'Escape'), isTrue);
    });
  });
}
