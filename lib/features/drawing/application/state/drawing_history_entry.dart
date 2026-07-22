import '../../domain/entities/ink_stroke.dart';

final class DrawingHistoryEntry {
  DrawingHistoryEntry({
    required List<InkStroke> beforeStrokes,
    required List<InkStroke> afterStrokes,
  }) : beforeStrokes = List.unmodifiable(beforeStrokes),
       afterStrokes = List.unmodifiable(afterStrokes);

  final List<InkStroke> beforeStrokes;
  final List<InkStroke> afterStrokes;
}
