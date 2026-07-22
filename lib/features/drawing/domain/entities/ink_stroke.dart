// Copy all content into ink_stroke.dart (z-index v2).
import 'dart:math' as math;

import 'ink_point.dart';

enum InkTool { pen, pencil, highlighter, eraser }

final class InkStroke {
  InkStroke({
    required this.id,
    required this.pageId,
    required this.tool,
    required this.colorValue,
    required this.width,
    required this.opacity,
    required List<InkPoint> points,
    required this.createdAt,
    this.zIndex = 0,
  }) : assert(width > 0),
       assert(opacity >= 0),
       assert(opacity <= 1),
       points = List.unmodifiable(points);

  final String id;
  final String pageId;
  final InkTool tool;
  final int colorValue;
  final double width;
  final double opacity;
  final List<InkPoint> points;
  final DateTime createdAt;
  final int zIndex;

  bool get isEmpty => points.isEmpty;

  bool get isDrawable => points.length >= 2;

  InkStroke addPoint(InkPoint point) {
    return replacePoints([...points, point]);
  }

  InkStroke replacePoints(List<InkPoint> newPoints) {
    return InkStroke(
      id: id,
      pageId: pageId,
      tool: tool,
      colorValue: colorValue,
      width: width,
      opacity: opacity,
      points: newPoints,
      createdAt: createdAt,
      zIndex: zIndex,
    );
  }

  InkStroke translate({required double deltaX, required double deltaY}) {
    return replacePoints(
      points
          .map((point) => point.translate(deltaX: deltaX, deltaY: deltaY))
          .toList(),
    );
  }

  InkStroke recolor(int newColorValue) {
    return InkStroke(
      id: id,
      pageId: pageId,
      tool: tool,
      colorValue: newColorValue,
      width: width,
      opacity: opacity,
      points: points,
      createdAt: createdAt,
      zIndex: zIndex,
    );
  }

  InkStroke scaleAround({
    required double centerX,
    required double centerY,
    required double scale,
  }) {
    if (scale <= 0) {
      return this;
    }

    return InkStroke(
      id: id,
      pageId: pageId,
      tool: tool,
      colorValue: colorValue,
      width: width * scale,
      opacity: opacity,
      points: points.map((point) {
        return InkPoint(
          x: centerX + (point.x - centerX) * scale,
          y: centerY + (point.y - centerY) * scale,
          pressure: point.pressure,
          elapsedMicroseconds: point.elapsedMicroseconds,
        );
      }).toList(),
      createdAt: createdAt,
      zIndex: zIndex,
    );
  }

  InkStroke rotateAround({
    required double centerX,
    required double centerY,
    required double angleRadians,
  }) {
    final cosine = math.cos(angleRadians);
    final sine = math.sin(angleRadians);

    return replacePoints(
      points.map((point) {
        final translatedX = point.x - centerX;
        final translatedY = point.y - centerY;

        return InkPoint(
          x: centerX + translatedX * cosine - translatedY * sine,
          y: centerY + translatedX * sine + translatedY * cosine,
          pressure: point.pressure,
          elapsedMicroseconds: point.elapsedMicroseconds,
        );
      }).toList(),
    );
  }

  InkStroke reorder(int newZIndex) {
    return InkStroke(
      id: id,
      pageId: pageId,
      tool: tool,
      colorValue: colorValue,
      width: width,
      opacity: opacity,
      points: points,
      createdAt: createdAt,
      zIndex: newZIndex,
    );
  }

  InkStroke duplicate({
    required String newId,
    required double offsetX,
    required double offsetY,
  }) {
    return InkStroke(
      id: newId,
      pageId: pageId,
      tool: tool,
      colorValue: colorValue,
      width: width,
      opacity: opacity,
      points: points
          .map((point) => point.translate(deltaX: offsetX, deltaY: offsetY))
          .toList(),
      createdAt: DateTime.now().toUtc(),
      zIndex: zIndex + 1,
    );
  }
}
