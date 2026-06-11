import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/models/canvas_connection.dart';
import '../../../shared/models/canvas_item.dart';

class CanvasConnectionPainter extends CustomPainter {
  CanvasConnectionPainter({
    required this.connections,
    required this.items,
    this.connectingFrom,
    this.mousePosition,
    this.labelStyle,
    this.labelBackgroundColor,
    this.dragOffsets = const <int, Offset>{},
  });

  final List<CanvasConnection> connections;

  final List<CanvasItem> items;

  /// Source item while a new connection is being drawn (temporary line).
  final CanvasItem? connectingFrom;

  /// Mouse position the temporary line follows.
  final Offset? mousePosition;

  final TextStyle? labelStyle;

  final Color? labelBackgroundColor;

  /// In-flight drag offsets keyed by itemId (delta from the stored position).
  final Map<int, Offset> dragOffsets;

  static const double _lineWidth = 2.0;

  static const double _dashLength = 8.0;

  static const double _dashGap = 4.0;

  static const double _arrowLength = 12.0;

  /// Max distance from a line that still counts as a hit.
  static const double hitTestThreshold = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (connections.isEmpty && connectingFrom == null) return;

    final Map<int, CanvasItem> itemMap = <int, CanvasItem>{
      for (final CanvasItem item in items) item.id: item,
    };

    for (final CanvasConnection conn in connections) {
      final CanvasItem? fromItem = itemMap[conn.fromItemId];
      final CanvasItem? toItem = itemMap[conn.toItemId];
      if (fromItem == null || toItem == null) continue;

      final Offset fromCenter = _getItemCenter(fromItem);
      final Offset toCenter = _getItemCenter(toItem);
      final Offset from = _getEdgePoint(fromItem, toCenter);
      final Offset to = _getEdgePoint(toItem, fromCenter);
      final Color lineColor = _parseColor(conn.color);

      _drawConnection(canvas, from, to, lineColor, conn.style);

      if (conn.label != null && conn.label!.isNotEmpty) {
        _drawLabel(canvas, from, to, conn.label!);
      }
    }

    // Temporary line while a new connection is being drawn.
    if (connectingFrom != null && mousePosition != null) {
      final Offset from = _getEdgePoint(connectingFrom!, mousePosition!);
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

  /// Item center with the in-flight drag offset applied.
  Offset _getItemCenter(CanvasItem item) {
    final double width =
        item.width ?? CanvasRepository.defaultCardWidth;
    final double height =
        item.height ?? CanvasRepository.defaultCardHeight;
    final Offset offset = dragOffsets[item.id] ?? Offset.zero;
    return Offset(
      item.x + offset.dx + width / 2,
      item.y + offset.dy + height / 2,
    );
  }

  /// Point on the item rect facing [target]: the center of the nearest
  /// side (top/bottom/left/right).
  Offset _getEdgePoint(CanvasItem item, Offset target) {
    final double width =
        item.width ?? CanvasRepository.defaultCardWidth;
    final double height =
        item.height ?? CanvasRepository.defaultCardHeight;
    final Offset offset = dragOffsets[item.id] ?? Offset.zero;

    final double left = item.x + offset.dx;
    final double top = item.y + offset.dy;
    final double cx = left + width / 2;
    final double cy = top + height / 2;

    final double dx = target.dx - cx;
    final double dy = target.dy - cy;

    // Self-connection or coincident centers fall back to the center.
    if (dx == 0 && dy == 0) {
      return Offset(cx, cy);
    }

    // Pick the nearest side by comparing the dx/width and dy/height ratios.
    if (dx.abs() * height > dy.abs() * width) {
      if (dx > 0) {
        return Offset(left + width, cy);
      }
      return Offset(left, cy);
    } else {
      if (dy > 0) {
        return Offset(cx, top + height);
      }
      return Offset(cx, top);
    }
  }

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
      // Invalid hex falls through to the default color.
    }
    return const Color(0xFF666666);
  }

  /// Returns the id of the connection within [hitTestThreshold] of [point],
  /// or null when no connection is close enough.
  int? hitTestConnection(Offset point) {
    final Map<int, CanvasItem> itemMap = <int, CanvasItem>{
      for (final CanvasItem item in items) item.id: item,
    };

    for (final CanvasConnection conn in connections) {
      final CanvasItem? fromItem = itemMap[conn.fromItemId];
      final CanvasItem? toItem = itemMap[conn.toItemId];
      if (fromItem == null || toItem == null) continue;

      final Offset fromCenter = _getItemCenter(fromItem);
      final Offset toCenter = _getItemCenter(toItem);
      final Offset from = _getEdgePoint(fromItem, toCenter);
      final Offset to = _getEdgePoint(toItem, fromCenter);

      final double distance = _pointToLineDistance(point, from, to);
      if (distance <= hitTestThreshold) {
        return conn.id;
      }
    }
    return null;
  }

  /// Distance from a point to a line segment (not the infinite line).
  static double _pointToLineDistance(Offset point, Offset a, Offset b) {
    final double dx = b.dx - a.dx;
    final double dy = b.dy - a.dy;
    final double lengthSq = dx * dx + dy * dy;

    if (lengthSq == 0) {
      return (point - a).distance;
    }

    // Project the point onto the line, clamped to the segment.
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
        mousePosition != oldDelegate.mousePosition ||
        dragOffsets != oldDelegate.dragOffsets;
  }
}
