// Copy all content into image_object.dart (z-index v2).
final class ImageObjectBounds {
  const ImageObjectBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
  }) : assert(width > 0),
       assert(height > 0);

  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  ImageObjectBounds move({required double deltaX, required double deltaY}) {
    return copyWith(x: x + deltaX, y: y + deltaY);
  }

  ImageObjectBounds resize({
    required double newWidth,
    required double newHeight,
  }) {
    return copyWith(
      width: newWidth.clamp(40, 4000).toDouble(),
      height: newHeight.clamp(40, 4000).toDouble(),
    );
  }

  ImageObjectBounds copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  }) {
    return ImageObjectBounds(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }
}

final class ImageCrop {
  const ImageCrop({
    this.left = 0,
    this.top = 0,
    this.right = 1,
    this.bottom = 1,
  }) : assert(left >= 0 && left < right),
       assert(top >= 0 && top < bottom),
       assert(right <= 1),
       assert(bottom <= 1);

  final double left;
  final double top;
  final double right;
  final double bottom;
}

final class ImageObject {
  const ImageObject({
    required this.id,
    required this.pageId,
    required this.originalPath,
    required this.checksum,
    required this.bounds,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.previewPath,
    this.thumbnailPath,
    this.crop = const ImageCrop(),
    this.opacity = 1,
    this.isOwnedFile = true,
    this.zIndex = 0,
  }) : assert(opacity >= 0 && opacity <= 1);

  final String id;
  final String pageId;
  final String originalPath;
  final String? previewPath;
  final String? thumbnailPath;
  final String checksum;
  final ImageObjectBounds bounds;
  final ImageCrop crop;
  final double opacity;
  final bool isOwnedFile;
  final int zIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  ImageObject transform({
    required ImageObjectBounds newBounds,
    required DateTime now,
  }) {
    return copyWith(bounds: newBounds, updatedAt: now, version: version + 1);
  }

  ImageObject updateAppearance({
    ImageCrop? newCrop,
    double? newOpacity,
    required DateTime now,
  }) {
    return copyWith(
      crop: newCrop,
      opacity: newOpacity?.clamp(0, 1).toDouble(),
      updatedAt: now,
      version: version + 1,
    );
  }

  ImageObject reorder({required int newZIndex, required DateTime now}) {
    return copyWith(zIndex: newZIndex, updatedAt: now, version: version + 1);
  }

  ImageObject copyWith({
    String? previewPath,
    String? thumbnailPath,
    ImageObjectBounds? bounds,
    ImageCrop? crop,
    double? opacity,
    int? zIndex,
    DateTime? updatedAt,
    int? version,
  }) {
    return ImageObject(
      id: id,
      pageId: pageId,
      originalPath: originalPath,
      previewPath: previewPath ?? this.previewPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      checksum: checksum,
      bounds: bounds ?? this.bounds,
      crop: crop ?? this.crop,
      opacity: opacity ?? this.opacity,
      isOwnedFile: isOwnedFile,
      zIndex: zIndex ?? this.zIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}
