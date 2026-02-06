import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/models/canvas_connection.dart';
import '../../../shared/models/canvas_item.dart';

// CustomPainter для рисования связей между элементами канваса.
//
// Поддерживает три стиля линий: solid, dashed, arrow.
// Рисует лейблы в середине линий и временную линию при создании связи.

/// Рисует связи между элементами канваса.
class CanvasConnectionPainter extends CustomPainter {
  /// Создаёт [CanvasConnectionPainter].
  CanvasConnectionPainter({
    required this.connections,
    required this.items,
    this.connectingFrom,
    this.mousePosition,
    this.labelStyle,
    this.labelBackgroundColor,
  });

  /// Список связей для отрисовки.
  final List<CanvasConnection> connections;

  /// Элементы канваса (для вычисления позиций).
  final List<CanvasItem> items;

  /// Элемент-источник при создании связи (временная линия).
  final CanvasItem? connectingFrom;

  /// Позиция мыши (для временной линии).
  final Offset? mousePosition;

  /// Стиль текста лейблов.
  final TextStyle? labelStyle;

  /// Цвет фона лейблов.
  final Color? labelBackgroundColor;

  /// Ширина линии.
  static const double _lineWidth = 2.0;

  /// Длина штриха пунктирной линии.
  static const double _dashLength = 8.0;

  /// Промежуток между штрихами.
  static const double _dashGap = 4.0;

  /// Размер стрелки (длина).
  static const double _arrowLength = 12.0;

  /// Допустимое расстояние для hit-test на линию.
  static const double hitTestThreshold = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (connections.isEmpty && connectingFrom == null) return;

    // Быстрый поиск элементов по ID
    final Map<int, CanvasItem> itemMap = <int, CanvasItem>{
      for (final CanvasItem item in items) item.id: item,
    };

    // Рисуем сохранённые связи
    for (final CanvasConnection conn in connections) {
      final CanvasItem? fromItem = itemMap[conn.fromItemId];
      final CanvasItem? toItem = itemMap[conn.toItemId];
      if (fromItem == null || toItem == null) continue;

      final Offset from = _getItemCenter(fromItem);
      final Offset to = _getItemCenter(toItem);
      final Color lineColor = _parseColor(conn.color);

      _drawConnection(canvas, from, to, lineColor, conn.style);

      if (conn.label != null && conn.label!.isNotEmpty) {
        _drawLabel(canvas, from, to, conn.label!);
      }
    }

    // Временная линия при создании связи
    if (connectingFrom != null && mousePosition != null) {
      final Offset from = _getItemCenter(connectingFrom!);
      _drawDashedLine(
        canvas,
        from,
        mousePosition!,
        Paint()
          ..color = Colors.blue.withAlpha(180)
          ..strokeWidth = _lineWidth
          ..style = PaintingStyle.stroke,
      );
    }
  }

  /// Рисует связь заданного стиля.
  void _drawConnection(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color,
    ConnectionStyle style,
  ) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = _lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (style) {
      case ConnectionStyle.solid:
        canvas.drawLine(from, to, paint);
      case ConnectionStyle.dashed:
        _drawDashedLine(canvas, from, to, paint);
      case ConnectionStyle.arrow:
        canvas.drawLine(from, to, paint);
        _drawArrowHead(canvas, from, to, color);
    }
  }

  /// Рисует пунктирную линию.
  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final Path path = Path()..moveTo(from.dx, from.dy);
    path.lineTo(to.dx, to.dy);

    final ui.PathMetrics metrics = path.computeMetrics();
    for (final ui.PathMetric metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double end =
            math.min(distance + _dashLength, metric.length);
        final ui.Path segment =
            metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += _dashLength + _dashGap;
      }
    }
  }

  /// Рисует стрелку на конце линии.
  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Color color) {
    final double angle = math.atan2(to.dy - from.dy, to.dx - from.dx);

    final Path arrowPath = Path();
    arrowPath.moveTo(to.dx, to.dy);
    arrowPath.lineTo(
      to.dx - _arrowLength * math.cos(angle - 0.4),
      to.dy - _arrowLength * math.sin(angle - 0.4),
    );
    arrowPath.lineTo(
      to.dx - _arrowLength * math.cos(angle + 0.4),
      to.dy - _arrowLength * math.sin(angle + 0.4),
    );
    arrowPath.close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  /// Рисует лейбл в середине линии.
  void _drawLabel(Canvas canvas, Offset from, Offset to, String label) {
    final TextStyle style = labelStyle ??
        const TextStyle(
          fontSize: 11,
          color: Colors.black87,
        );

    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final Offset mid = Offset(
      (from.dx + to.dx) / 2 - painter.width / 2,
      (from.dy + to.dy) / 2 - painter.height / 2,
    );

    // Фон под текстом
    final Color bgColor = labelBackgroundColor ??
        Colors.white.withAlpha(220);
    final Rect bgRect = Rect.fromLTWH(
      mid.dx - 4,
      mid.dy - 2,
      painter.width + 8,
      painter.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(3)),
      Paint()..color = bgColor,
    );

    painter.paint(canvas, mid);
  }

  /// Вычисляет центр элемента канваса.
  Offset _getItemCenter(CanvasItem item) {
    final double width =
        item.width ?? CanvasRepository.defaultCardWidth;
    final double height =
        item.height ?? CanvasRepository.defaultCardHeight;
    return Offset(item.x + width / 2, item.y + height / 2);
  }

  /// Парсит hex-строку цвета.
  static Color _parseColor(String hex) {
    try {
      final String clean = hex.startsWith('#') ? hex.substring(1) : hex;
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
      if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } on FormatException {
      // Невалидный hex — используем цвет по умолчанию
    }
    return const Color(0xFF666666);
  }

  /// Проверяет, попадает ли точка [point] рядом с какой-либо связью.
  ///
  /// Возвращает ID связи или null.
  int? hitTestConnection(Offset point) {
    final Map<int, CanvasItem> itemMap = <int, CanvasItem>{
      for (final CanvasItem item in items) item.id: item,
    };

    for (final CanvasConnection conn in connections) {
      final CanvasItem? fromItem = itemMap[conn.fromItemId];
      final CanvasItem? toItem = itemMap[conn.toItemId];
      if (fromItem == null || toItem == null) continue;

      final Offset from = _getItemCenter(fromItem);
      final Offset to = _getItemCenter(toItem);

      final double distance = _pointToLineDistance(point, from, to);
      if (distance <= hitTestThreshold) {
        return conn.id;
      }
    }
    return null;
  }

  /// Вычисляет расстояние от точки до отрезка.
  static double _pointToLineDistance(Offset point, Offset a, Offset b) {
    final double dx = b.dx - a.dx;
    final double dy = b.dy - a.dy;
    final double lengthSq = dx * dx + dy * dy;

    if (lengthSq == 0) {
      return (point - a).distance;
    }

    // Проецируем точку на линию, ограничивая отрезком [0, 1]
    final double t = ((point.dx - a.dx) * dx + (point.dy - a.dy) * dy)
        .clamp(0.0, lengthSq) / lengthSq;

    final Offset projection = Offset(a.dx + t * dx, a.dy + t * dy);
    return (point - projection).distance;
  }

  @override
  bool shouldRepaint(covariant CanvasConnectionPainter oldDelegate) {
    return connections != oldDelegate.connections ||
        items != oldDelegate.items ||
        connectingFrom != oldDelegate.connectingFrom ||
        mousePosition != oldDelegate.mousePosition;
  }
}
