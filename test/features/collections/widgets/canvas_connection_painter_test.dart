import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/canvas_connection_painter.dart';
import 'package:xerabora/shared/models/canvas_connection.dart';
import 'package:xerabora/shared/models/canvas_item.dart';

void main() {
  final DateTime testDate = DateTime(2024, 6, 15);

  List<CanvasItem> createTestItems() {
    return <CanvasItem>[
      CanvasItem(
        id: 1,
        collectionId: 10,
        itemType: CanvasItemType.game,
        x: 0,
        y: 0,
        width: 100,
        height: 100,
        zIndex: 0,
        createdAt: testDate,
      ),
      CanvasItem(
        id: 2,
        collectionId: 10,
        itemType: CanvasItemType.game,
        x: 200,
        y: 0,
        width: 100,
        height: 100,
        zIndex: 1,
        createdAt: testDate,
      ),
      CanvasItem(
        id: 3,
        collectionId: 10,
        itemType: CanvasItemType.text,
        x: 0,
        y: 200,
        width: 100,
        height: 50,
        zIndex: 2,
        createdAt: testDate,
      ),
    ];
  }

  group('CanvasConnectionPainter', () {
    test('should create with required parameters', () {
      final CanvasConnectionPainter painter = CanvasConnectionPainter(
        connections: const <CanvasConnection>[],
        items: const <CanvasItem>[],
      );

      expect(painter.connections, isEmpty);
      expect(painter.items, isEmpty);
      expect(painter.connectingFrom, isNull);
      expect(painter.mousePosition, isNull);
    });

    group('shouldRepaint', () {
      test('should repaint when connections change', () {
        final List<CanvasItem> items = createTestItems();

        final CanvasConnectionPainter a = CanvasConnectionPainter(
          connections: const <CanvasConnection>[],
          items: items,
        );
        final CanvasConnectionPainter b = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 1,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        expect(a.shouldRepaint(b), isTrue);
      });

      test('should repaint when items change', () {
        final CanvasConnectionPainter a = CanvasConnectionPainter(
          connections: const <CanvasConnection>[],
          items: createTestItems(),
        );
        final CanvasConnectionPainter b = CanvasConnectionPainter(
          connections: const <CanvasConnection>[],
          items: const <CanvasItem>[],
        );

        expect(a.shouldRepaint(b), isTrue);
      });

      test('should repaint when connectingFrom changes', () {
        final List<CanvasItem> items = createTestItems();

        final CanvasConnectionPainter a = CanvasConnectionPainter(
          connections: const <CanvasConnection>[],
          items: items,
          connectingFrom: items.first,
        );
        final CanvasConnectionPainter b = CanvasConnectionPainter(
          connections: const <CanvasConnection>[],
          items: items,
        );

        expect(a.shouldRepaint(b), isTrue);
      });

      test('should repaint when mousePosition changes', () {
        final List<CanvasItem> items = createTestItems();

        final CanvasConnectionPainter a = CanvasConnectionPainter(
          connections: const <CanvasConnection>[],
          items: items,
          mousePosition: const Offset(100, 200),
        );
        final CanvasConnectionPainter b = CanvasConnectionPainter(
          connections: const <CanvasConnection>[],
          items: items,
          mousePosition: const Offset(150, 250),
        );

        expect(a.shouldRepaint(b), isTrue);
      });

      test('should not repaint when nothing changes', () {
        final List<CanvasItem> items = createTestItems();
        final List<CanvasConnection> connections = <CanvasConnection>[
          CanvasConnection(
            id: 1,
            collectionId: 10,
            fromItemId: 1,
            toItemId: 2,
            createdAt: testDate,
          ),
        ];

        final CanvasConnectionPainter a = CanvasConnectionPainter(
          connections: connections,
          items: items,
        );
        final CanvasConnectionPainter b = CanvasConnectionPainter(
          connections: connections,
          items: items,
        );

        expect(a.shouldRepaint(b), isFalse);
      });
    });

    group('hitTest', () {
      test('should detect hit on connection line', () {
        final List<CanvasItem> items = createTestItems();
        // Item 1 center: (50, 50), Item 2 center: (250, 50)
        // Line from (50,50) to (250,50) — horizontal

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 42,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        // Point on the line
        final int? result = painter.hitTestConnection(const Offset(150, 50));
        expect(result, 42);
      });

      test('should detect hit near connection line within threshold', () {
        final List<CanvasItem> items = createTestItems();

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 42,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        // Point near the line (within threshold of 8)
        final int? result = painter.hitTestConnection(const Offset(150, 55));
        expect(result, 42);
      });

      test('should not detect hit far from connection line', () {
        final List<CanvasItem> items = createTestItems();

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 42,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        // Point far from the line
        final int? result = painter.hitTestConnection(const Offset(150, 150));
        expect(result, isNull);
      });

      test('should return null when no connections', () {
        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: const <CanvasConnection>[],
          items: createTestItems(),
        );

        final int? result = painter.hitTestConnection(const Offset(100, 100));
        expect(result, isNull);
      });

      test('should return first matching connection on overlap', () {
        final List<CanvasItem> items = createTestItems();
        // Item 1→2: horizontal at y=50
        // Item 1→3: vertical at x=50 (item3 center: 50,225)

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 10,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              createdAt: testDate,
            ),
            CanvasConnection(
              id: 20,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 3,
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        // Hit on connection 10 (horizontal line at y=50)
        expect(painter.hitTestConnection(const Offset(150, 50)), 10);

        // Hit on connection 20 (vertical line at x=50)
        expect(painter.hitTestConnection(const Offset(50, 150)), 20);
      });

      test('should handle missing items gracefully', () {
        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 42,
              collectionId: 10,
              fromItemId: 999,
              toItemId: 998,
              createdAt: testDate,
            ),
          ],
          items: createTestItems(),
        );

        final int? result = painter.hitTestConnection(const Offset(100, 100));
        expect(result, isNull);
      });

      test('should handle zero-length line segment (same from and to)', () {
        final List<CanvasItem> items = <CanvasItem>[
          CanvasItem(
            id: 1,
            collectionId: 10,
            itemType: CanvasItemType.game,
            x: 100,
            y: 100,
            width: 100,
            height: 100,
            zIndex: 0,
            createdAt: testDate,
          ),
        ];

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 42,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 1,
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        // Should detect hit on point (center of item 1: 150, 150)
        final int? result = painter.hitTestConnection(const Offset(150, 150));
        expect(result, 42);
      });
    });

    group('paint', () {
      test('should not throw with empty connections', () {
        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: const <CanvasConnection>[],
          items: const <CanvasItem>[],
        );

        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        // Should not throw
        painter.paint(canvas, const Size(1000, 1000));
        recorder.endRecording();
      });

      test('should not throw with valid connections', () {
        final List<CanvasItem> items = createTestItems();

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 1,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              label: 'test',
              color: '#FF0000',
              style: ConnectionStyle.solid,
              createdAt: testDate,
            ),
            CanvasConnection(
              id: 2,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 3,
              color: '#00FF00',
              style: ConnectionStyle.dashed,
              createdAt: testDate,
            ),
            CanvasConnection(
              id: 3,
              collectionId: 10,
              fromItemId: 2,
              toItemId: 3,
              color: '#0000FF',
              style: ConnectionStyle.arrow,
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        painter.paint(canvas, const Size(1000, 1000));
        recorder.endRecording();
      });

      test('should not throw with connecting from item', () {
        final List<CanvasItem> items = createTestItems();

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: const <CanvasConnection>[],
          items: items,
          connectingFrom: items.first,
          mousePosition: const Offset(300, 300),
        );

        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        painter.paint(canvas, const Size(1000, 1000));
        recorder.endRecording();
      });

      test('should handle invalid color gracefully', () {
        final List<CanvasItem> items = createTestItems();

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 1,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              color: 'invalid',
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        // Should fall back to default color, not throw
        painter.paint(canvas, const Size(1000, 1000));
        recorder.endRecording();
      });

      test('should not throw when connectingFrom set but mousePosition null',
          () {
        final List<CanvasItem> items = createTestItems();

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: const <CanvasConnection>[],
          items: items,
          connectingFrom: items.first,
          // mousePosition is null
        );

        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        painter.paint(canvas, const Size(1000, 1000));
        recorder.endRecording();
      });

      test('should not throw with 8-char hex color', () {
        final List<CanvasItem> items = createTestItems();

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 1,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              color: '#80FF0000',
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        painter.paint(canvas, const Size(1000, 1000));
        recorder.endRecording();
      });

      test('should not throw when connection items are missing', () {
        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 1,
              collectionId: 10,
              fromItemId: 999,
              toItemId: 998,
              label: 'orphan',
              createdAt: testDate,
            ),
          ],
          items: createTestItems(),
        );

        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        painter.paint(canvas, const Size(1000, 1000));
        recorder.endRecording();
      });

      test('should not throw with empty label string', () {
        final List<CanvasItem> items = createTestItems();

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 1,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              label: '',
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        painter.paint(canvas, const Size(1000, 1000));
        recorder.endRecording();
      });

      test('should use custom labelStyle and labelBackgroundColor', () {
        final List<CanvasItem> items = createTestItems();

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 1,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              label: 'custom style',
              createdAt: testDate,
            ),
          ],
          items: items,
          labelStyle: const TextStyle(fontSize: 14, color: Colors.black),
          labelBackgroundColor: const Color(0xFFFFFF00),
        );

        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        painter.paint(canvas, const Size(1000, 1000));
        recorder.endRecording();
      });

      test('should not throw with item that has null width and height', () {
        final List<CanvasItem> items = <CanvasItem>[
          CanvasItem(
            id: 1,
            collectionId: 10,
            itemType: CanvasItemType.text,
            x: 0,
            y: 0,
            zIndex: 0,
            createdAt: testDate,
          ),
          CanvasItem(
            id: 2,
            collectionId: 10,
            itemType: CanvasItemType.text,
            x: 200,
            y: 200,
            zIndex: 1,
            createdAt: testDate,
          ),
        ];

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 1,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        painter.paint(canvas, const Size(1000, 1000));
        recorder.endRecording();
      });
    });

    group('edge point calculation (через hitTest)', () {
      // Тесты проверяют _getEdgePoint косвенно через hitTestConnection,
      // т.к. метод приватный. HitTest использует edge points для линий.

      test('should use right edge when target is to the right', () {
        // Item 1 at (0,0) size 100x100, center (50,50)
        // Item 2 at (200,0) size 100x100, center (250,50)
        // Edge points: right of item1 (100,50) → left of item2 (200,50)
        // Line goes from (100,50) to (200,50) — horizontal at y=50
        final List<CanvasItem> items = createTestItems();
        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 1,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        // Midpoint between edges: (150, 50)
        expect(painter.hitTestConnection(const Offset(150, 50)), 1);
        // Point between items at y=50 should still hit
        expect(painter.hitTestConnection(const Offset(120, 50)), 1);
        // Point far above the line should not hit
        expect(painter.hitTestConnection(const Offset(150, 20)), isNull);
      });

      test('should use bottom edge when target is below', () {
        // Item 1 at (0,0) size 100x100, center (50,50)
        // Item 3 at (0,200) size 100x50, center (50,225)
        // Edge points: bottom of item1 (50,100) → top of item3 (50,200)
        final List<CanvasItem> items = createTestItems();
        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 1,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 3,
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        // Midpoint of vertical line: (50, 150)
        expect(painter.hitTestConnection(const Offset(50, 150)), 1);
        // Point to the right should not hit
        expect(painter.hitTestConnection(const Offset(100, 150)), isNull);
      });

      test('should use correct edge with drag offsets', () {
        // Item 1 at (0,0), dragged by (50, 0) → effective pos (50,0)
        // Item 2 at (200,0) → center (250,50)
        // Item 1 effective center: (50+50,50) = (100,50)
        // Edge: right of item1 (50+100,50) = (150,50) → left of item2 (200,50)
        final List<CanvasItem> items = createTestItems();
        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 1,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              createdAt: testDate,
            ),
          ],
          items: items,
          dragOffsets: const <int, Offset>{1: Offset(50, 0)},
        );

        // Line now from (150,50) to (200,50)
        // Midpoint: (175, 50)
        expect(painter.hitTestConnection(const Offset(175, 50)), 1);
        // Original position (100, 50) — now outside the line
        expect(painter.hitTestConnection(const Offset(100, 50)), isNull);
      });

      test('should handle diagonal connection with correct edge selection', () {
        // Item 1 at (0,0) size 100x100, center (50,50)
        // Item at (200,200) — далеко по диагонали
        final List<CanvasItem> items = <CanvasItem>[
          CanvasItem(
            id: 1,
            collectionId: 10,
            itemType: CanvasItemType.game,
            x: 0,
            y: 0,
            width: 100,
            height: 100,
            zIndex: 0,
            createdAt: testDate,
          ),
          CanvasItem(
            id: 2,
            collectionId: 10,
            itemType: CanvasItemType.game,
            x: 200,
            y: 200,
            width: 100,
            height: 100,
            zIndex: 1,
            createdAt: testDate,
          ),
        ];

        final CanvasConnectionPainter painter = CanvasConnectionPainter(
          connections: <CanvasConnection>[
            CanvasConnection(
              id: 1,
              collectionId: 10,
              fromItemId: 1,
              toItemId: 2,
              createdAt: testDate,
            ),
          ],
          items: items,
        );

        // For a 1:1 aspect ratio item, diagonal → picks bottom/top edge
        // (dx.abs()*height vs dy.abs()*width — equal, falls to else/vertical)
        // Item1 center (50,50), Item2 center (250,250)
        // dx=200, dy=200, both equal → vertical edge
        // Item1 bottom: (50,100), Item2 top: (250,200)
        // Line from (50,100) to (250,200)
        // Midpoint approximately (150, 150)
        expect(painter.hitTestConnection(const Offset(150, 150)), 1);
      });
    });
  });
}
