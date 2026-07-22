// Copy all content into text_object_record.dart (z-index v2).
import '../../domain/entities/text_object.dart';

final class TextObjectRecord {
  const TextObjectRecord({
    required this.id,
    required this.pageId,
    required this.plainText,
    required this.fontFamilyToken,
    required this.fontSize,
    required this.weight,
    required this.alignment,
    required this.colorValue,
    required this.lineHeight,
    required this.languageCode,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotationRadians,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.zIndex,
    this.richTextData,
  });

  final String id;
  final String pageId;
  final String plainText;
  final String? richTextData;
  final String fontFamilyToken;
  final double fontSize;
  final int weight;
  final String alignment;
  final int colorValue;
  final double lineHeight;
  final String languageCode;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotationRadians;
  final String createdAt;
  final String updatedAt;
  final int version;
  final int zIndex;

  factory TextObjectRecord.fromDomain(TextObject object) {
    return TextObjectRecord(
      id: object.id,
      pageId: object.pageId,
      plainText: object.plainText,
      richTextData: object.richTextData,
      fontFamilyToken: object.fontFamilyToken,
      fontSize: object.fontSize,
      weight: object.weight,
      alignment: object.alignment.name,
      colorValue: object.colorValue,
      lineHeight: object.lineHeight,
      languageCode: object.languageCode,
      x: object.bounds.x,
      y: object.bounds.y,
      width: object.bounds.width,
      height: object.bounds.height,
      rotationRadians: object.bounds.rotationRadians,
      createdAt: object.createdAt.toUtc().toIso8601String(),
      updatedAt: object.updatedAt.toUtc().toIso8601String(),
      version: object.version,
      zIndex: object.zIndex,
    );
  }

  factory TextObjectRecord.fromJson(Map<String, Object?> json) {
    return TextObjectRecord(
      id: json['id']! as String,
      pageId: json['pageId']! as String,
      plainText: json['plainText']! as String,
      richTextData: json['richTextData'] as String?,
      fontFamilyToken: json['fontFamilyToken']! as String,
      fontSize: (json['fontSize']! as num).toDouble(),
      weight: json['weight']! as int,
      alignment: json['alignment']! as String,
      colorValue: json['colorValue']! as int,
      lineHeight: (json['lineHeight']! as num).toDouble(),
      languageCode: json['languageCode']! as String,
      x: (json['x']! as num).toDouble(),
      y: (json['y']! as num).toDouble(),
      width: (json['width']! as num).toDouble(),
      height: (json['height']! as num).toDouble(),
      rotationRadians: (json['rotationRadians']! as num).toDouble(),
      createdAt: json['createdAt']! as String,
      updatedAt: json['updatedAt']! as String,
      version: json['version']! as int,
      zIndex: json['zIndex'] as int? ?? 0,
    );
  }

  TextObject toDomain() {
    return TextObject(
      id: id,
      pageId: pageId,
      plainText: plainText,
      richTextData: richTextData,
      fontFamilyToken: fontFamilyToken,
      fontSize: fontSize,
      weight: weight,
      alignment: TextObjectAlignment.values.byName(alignment),
      colorValue: colorValue,
      lineHeight: lineHeight,
      languageCode: languageCode,
      bounds: TextObjectBounds(
        x: x,
        y: y,
        width: width,
        height: height,
        rotationRadians: rotationRadians,
      ),
      createdAt: DateTime.parse(createdAt).toLocal(),
      updatedAt: DateTime.parse(updatedAt).toLocal(),
      version: version,
      zIndex: zIndex,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'pageId': pageId,
      'plainText': plainText,
      'richTextData': richTextData,
      'fontFamilyToken': fontFamilyToken,
      'fontSize': fontSize,
      'weight': weight,
      'alignment': alignment,
      'colorValue': colorValue,
      'lineHeight': lineHeight,
      'languageCode': languageCode,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotationRadians': rotationRadians,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'version': version,
      'zIndex': zIndex,
    };
  }
}
