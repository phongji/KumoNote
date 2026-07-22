// Copy all content into text_object.dart (z-index v2).
enum TextObjectAlignment { left, center, right, justify }

final class TextObjectBounds {
  const TextObjectBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotationRadians = 0,
  }) : assert(width > 0),
       assert(height > 0);

  final double x;
  final double y;
  final double width;
  final double height;
  final double rotationRadians;

  TextObjectBounds move({required double deltaX, required double deltaY}) {
    return TextObjectBounds(
      x: x + deltaX,
      y: y + deltaY,
      width: width,
      height: height,
      rotationRadians: rotationRadians,
    );
  }

  TextObjectBounds resize({
    required double newWidth,
    required double newHeight,
  }) {
    if (newWidth <= 0 || newHeight <= 0) {
      return this;
    }

    return TextObjectBounds(
      x: x,
      y: y,
      width: newWidth,
      height: newHeight,
      rotationRadians: rotationRadians,
    );
  }

  TextObjectBounds rotate(double angleRadians) {
    return TextObjectBounds(
      x: x,
      y: y,
      width: width,
      height: height,
      rotationRadians: angleRadians,
    );
  }
}

final class TextObject {
  const TextObject({
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
    required this.bounds,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.richTextData,
    this.zIndex = 0,
  }) : assert(fontSize > 0),
       assert(weight >= 100 && weight <= 900),
       assert(lineHeight > 0);

  final String id;
  final String pageId;
  final String plainText;
  final String? richTextData;
  final String fontFamilyToken;
  final double fontSize;
  final int weight;
  final TextObjectAlignment alignment;
  final int colorValue;
  final double lineHeight;
  final String languageCode;
  final TextObjectBounds bounds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final int zIndex;

  bool get isEmpty => plainText.trim().isEmpty;

  TextObject edit({
    required String newPlainText,
    required DateTime now,
    String? newRichTextData,
  }) {
    return copyWith(
      plainText: newPlainText,
      richTextData: newRichTextData,
      updatedAt: now,
      version: version + 1,
    );
  }

  TextObject move({
    required double deltaX,
    required double deltaY,
    required DateTime now,
  }) {
    return copyWith(
      bounds: bounds.move(deltaX: deltaX, deltaY: deltaY),
      updatedAt: now,
      version: version + 1,
    );
  }

  TextObject resize({
    required double width,
    required double height,
    required DateTime now,
  }) {
    return copyWith(
      bounds: bounds.resize(newWidth: width, newHeight: height),
      updatedAt: now,
      version: version + 1,
    );
  }

  TextObject rotate({required double angleRadians, required DateTime now}) {
    return copyWith(
      bounds: bounds.rotate(angleRadians),
      updatedAt: now,
      version: version + 1,
    );
  }

  TextObject restyle({
    required String fontFamilyToken,
    required double fontSize,
    required int weight,
    required TextObjectAlignment alignment,
    required int colorValue,
    required double lineHeight,
    required DateTime now,
  }) {
    return copyWith(
      fontFamilyToken: fontFamilyToken,
      fontSize: fontSize,
      weight: weight,
      alignment: alignment,
      colorValue: colorValue,
      lineHeight: lineHeight,
      updatedAt: now,
      version: version + 1,
    );
  }

  TextObject reorder({required int newZIndex, required DateTime now}) {
    return copyWith(zIndex: newZIndex, updatedAt: now, version: version + 1);
  }

  TextObject copyWith({
    String? plainText,
    String? richTextData,
    String? fontFamilyToken,
    double? fontSize,
    int? weight,
    TextObjectAlignment? alignment,
    int? colorValue,
    double? lineHeight,
    String? languageCode,
    TextObjectBounds? bounds,
    DateTime? updatedAt,
    int? version,
    int? zIndex,
  }) {
    return TextObject(
      id: id,
      pageId: pageId,
      plainText: plainText ?? this.plainText,
      richTextData: richTextData ?? this.richTextData,
      fontFamilyToken: fontFamilyToken ?? this.fontFamilyToken,
      fontSize: fontSize ?? this.fontSize,
      weight: weight ?? this.weight,
      alignment: alignment ?? this.alignment,
      colorValue: colorValue ?? this.colorValue,
      lineHeight: lineHeight ?? this.lineHeight,
      languageCode: languageCode ?? this.languageCode,
      bounds: bounds ?? this.bounds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      zIndex: zIndex ?? this.zIndex,
    );
  }
}
