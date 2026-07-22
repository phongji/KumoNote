// Copy all content into ink_stroke_record.dart (z-index v2).
import '../../domain/entities/ink_stroke.dart';
import 'ink_point_record.dart';

final class InkStrokeRecord {
  const InkStrokeRecord({
    required this.id,
    required this.pageId,
    required this.tool,
    required this.colorValue,
    required this.width,
    required this.opacity,
    required this.points,
    required this.createdAt,
    required this.zIndex,
  });

  final String id;
  final String pageId;
  final String tool;
  final int colorValue;
  final double width;
  final double opacity;
  final List<InkPointRecord> points;
  final DateTime createdAt;
  final int zIndex;

  factory InkStrokeRecord.fromDomain(InkStroke stroke) {
    return InkStrokeRecord(
      id: stroke.id,
      pageId: stroke.pageId,
      tool: stroke.tool.name,
      colorValue: stroke.colorValue,
      width: stroke.width,
      opacity: stroke.opacity,
      points: stroke.points.map(InkPointRecord.fromDomain).toList(),
      createdAt: stroke.createdAt.toUtc(),
      zIndex: stroke.zIndex,
    );
  }

  factory InkStrokeRecord.fromJson(Map<String, Object?> json) {
    final pointItems = json['points'] as List<Object?>;

    return InkStrokeRecord(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      tool: json['tool'] as String,
      colorValue: (json['colorValue'] as num).toInt(),
      width: (json['width'] as num).toDouble(),
      opacity: (json['opacity'] as num).toDouble(),
      points: pointItems.map((item) {
        return InkPointRecord.fromJson(Map<String, Object?>.from(item as Map));
      }).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
    );
  }

  InkStroke toDomain() {
    return InkStroke(
      id: id,
      pageId: pageId,
      tool: InkTool.values.byName(tool),
      colorValue: colorValue,
      width: width,
      opacity: opacity,
      points: points.map((point) => point.toDomain()).toList(),
      createdAt: createdAt,
      zIndex: zIndex,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'pageId': pageId,
      'tool': tool,
      'colorValue': colorValue,
      'width': width,
      'opacity': opacity,
      'points': points.map((point) => point.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'zIndex': zIndex,
    };
  }
}
