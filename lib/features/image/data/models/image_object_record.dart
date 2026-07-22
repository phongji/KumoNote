// Copy all content into image_object_record.dart (z-index v2).
import '../../domain/entities/image_object.dart';

final class ImageObjectRecord {
  const ImageObjectRecord({
    required this.id,
    required this.pageId,
    required this.originalPath,
    required this.checksum,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
    required this.opacity,
    required this.isOwnedFile,
    required this.zIndex,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.previewPath,
    this.thumbnailPath,
  });

  final String id;
  final String pageId;
  final String originalPath;
  final String? previewPath;
  final String? thumbnailPath;
  final String checksum;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;
  final double opacity;
  final bool isOwnedFile;
  final int zIndex;
  final String createdAt;
  final String updatedAt;
  final int version;

  factory ImageObjectRecord.fromDomain(ImageObject object) {
    return ImageObjectRecord(
      id: object.id,
      pageId: object.pageId,
      originalPath: object.originalPath,
      previewPath: object.previewPath,
      thumbnailPath: object.thumbnailPath,
      checksum: object.checksum,
      x: object.bounds.x,
      y: object.bounds.y,
      width: object.bounds.width,
      height: object.bounds.height,
      rotation: object.bounds.rotation,
      cropLeft: object.crop.left,
      cropTop: object.crop.top,
      cropRight: object.crop.right,
      cropBottom: object.crop.bottom,
      opacity: object.opacity,
      isOwnedFile: object.isOwnedFile,
      zIndex: object.zIndex,
      createdAt: object.createdAt.toUtc().toIso8601String(),
      updatedAt: object.updatedAt.toUtc().toIso8601String(),
      version: object.version,
    );
  }

  factory ImageObjectRecord.fromJson(Map<String, Object?> json) {
    return ImageObjectRecord(
      id: json['id']! as String,
      pageId: json['pageId']! as String,
      originalPath: json['originalPath']! as String,
      previewPath: json['previewPath'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      checksum: json['checksum']! as String,
      x: (json['x']! as num).toDouble(),
      y: (json['y']! as num).toDouble(),
      width: (json['width']! as num).toDouble(),
      height: (json['height']! as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      cropLeft: (json['cropLeft'] as num?)?.toDouble() ?? 0,
      cropTop: (json['cropTop'] as num?)?.toDouble() ?? 0,
      cropRight: (json['cropRight'] as num?)?.toDouble() ?? 1,
      cropBottom: (json['cropBottom'] as num?)?.toDouble() ?? 1,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
      isOwnedFile: json['isOwnedFile'] as bool? ?? true,
      zIndex: json['zIndex'] as int? ?? 0,
      createdAt: json['createdAt']! as String,
      updatedAt: json['updatedAt']! as String,
      version: json['version']! as int,
    );
  }

  ImageObject toDomain() {
    return ImageObject(
      id: id,
      pageId: pageId,
      originalPath: originalPath,
      previewPath: previewPath,
      thumbnailPath: thumbnailPath,
      checksum: checksum,
      bounds: ImageObjectBounds(
        x: x,
        y: y,
        width: width,
        height: height,
        rotation: rotation,
      ),
      crop: ImageCrop(
        left: cropLeft,
        top: cropTop,
        right: cropRight,
        bottom: cropBottom,
      ),
      opacity: opacity,
      isOwnedFile: isOwnedFile,
      zIndex: zIndex,
      createdAt: DateTime.parse(createdAt).toLocal(),
      updatedAt: DateTime.parse(updatedAt).toLocal(),
      version: version,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'pageId': pageId,
      'originalPath': originalPath,
      'previewPath': previewPath,
      'thumbnailPath': thumbnailPath,
      'checksum': checksum,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'cropLeft': cropLeft,
      'cropTop': cropTop,
      'cropRight': cropRight,
      'cropBottom': cropBottom,
      'opacity': opacity,
      'isOwnedFile': isOwnedFile,
      'zIndex': zIndex,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'version': version,
    };
  }
}
