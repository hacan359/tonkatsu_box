import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/wishlist/widgets/wishlist_tile.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('WishlistTile', () {
    testWidgets('should render the item text without exception',
        (WidgetTester tester) async {
      await tester.pumpApp(
        WishlistTile(
          item: createTestWishlistItem(text: 'Chrono Trigger'),
          onTap: () {},
          onResolve: () {},
          onEdit: () {},
          onDelete: () {},
        ),
        wrapInScaffold: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Chrono Trigger'), findsOneWidget);
    });

    testWidgets('should fire onTap when the row is tapped',
        (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpApp(
        WishlistTile(
          item: createTestWishlistItem(text: 'Chrono Trigger'),
          onTap: () => tapped = true,
          onResolve: () {},
          onEdit: () {},
          onDelete: () {},
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.text('Chrono Trigger'));
      expect(tapped, isTrue);
    });

    testWidgets('should fire onEdit when the edit button is tapped',
        (WidgetTester tester) async {
      bool edited = false;
      await tester.pumpApp(
        WishlistTile(
          item: createTestWishlistItem(),
          onTap: () {},
          onResolve: () {},
          onEdit: () => edited = true,
          onDelete: () {},
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.byIcon(Icons.edit));
      expect(edited, isTrue);
    });

    testWidgets('should fire onDelete when the delete button is tapped',
        (WidgetTester tester) async {
      bool deleted = false;
      await tester.pumpApp(
        WishlistTile(
          item: createTestWishlistItem(),
          onTap: () {},
          onResolve: () {},
          onEdit: () {},
          onDelete: () => deleted = true,
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.byIcon(Icons.delete));
      expect(deleted, isTrue);
    });

    testWidgets('should fire onResolve when the resolve button is tapped',
        (WidgetTester tester) async {
      bool resolved = false;
      await tester.pumpApp(
        WishlistTile(
          item: createTestWishlistItem(isResolved: false),
          onTap: () {},
          onResolve: () => resolved = true,
          onEdit: () {},
          onDelete: () {},
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      expect(resolved, isTrue);
    });

    testWidgets('should fire onResolve from the undo button when resolved',
        (WidgetTester tester) async {
      bool resolved = false;
      await tester.pumpApp(
        WishlistTile(
          item: createTestWishlistItem(isResolved: true),
          onTap: () {},
          onResolve: () => resolved = true,
          onEdit: () {},
          onDelete: () {},
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.byIcon(Icons.undo));
      expect(resolved, isTrue);
    });
  });
}
