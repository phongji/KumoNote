import 'package:kumo_note/features/page/domain/entities/note_page.dart';

final class PageRecord {
  const PageRecord({
    required this.id,
    required this.notebookId,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.sortOrder,
    required this.orientation,
    required this.template,
    required this.paperColor,
    required this.width,
    required this.height,
    this.sectionId,
    this.deletedAt,
    this.thumbnailPath,
    this.pdfDocumentId,
    this.pdfPageNumber,
  });

  final String id;
  final String notebookId;
  final String? sectionId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final int version;
  final int sortOrder;
  final String orientation;
  final String template;
  final String paperColor;
  final double width;
  final double height;
  final String? thumbnailPath;
  final String? pdfDocumentId;
  final int? pdfPageNumber;

  factory PageRecord.fromDomain(NotePage page) {
    return PageRecord(
      id: page.id,
      notebookId: page.notebookId,
      sectionId: page.sectionId,
      createdAt: page.createdAt.toUtc().toIso8601String(),
      updatedAt: page.updatedAt.toUtc().toIso8601String(),
      deletedAt: page.deletedAt?.toUtc().toIso8601String(),
      version: page.version,
      sortOrder: page.sortOrder,
      orientation: page.orientation.name,
      template: page.template.name,
      paperColor: page.paperColor.name,
      width: page.width,
      height: page.height,
      thumbnailPath: page.thumbnailPath,
      pdfDocumentId: page.pdfDocumentId,
      pdfPageNumber: page.pdfPageNumber,
    );
  }

  factory PageRecord.fromJson(Map<String, Object?> json) {
    return PageRecord(
      id: json['id']! as String,
      notebookId: json['notebookId']! as String,
      sectionId: json['sectionId'] as String?,
      createdAt: json['createdAt']! as String,
      updatedAt: json['updatedAt']! as String,
      deletedAt: json['deletedAt'] as String?,
      version: (json['version']! as num).toInt(),
      sortOrder: (json['sortOrder']! as num).toInt(),
      orientation: json['orientation']! as String,
      template: json['template']! as String,
      paperColor:
          json['paperColor'] as String? ?? PagePaperColor.paperWhite.name,
      width: (json['width']! as num).toDouble(),
      height: (json['height']! as num).toDouble(),
      thumbnailPath: json['thumbnailPath'] as String?,
      pdfDocumentId: json['pdfDocumentId'] as String?,
      pdfPageNumber: (json['pdfPageNumber'] as num?)?.toInt(),
    );
  }

  NotePage toDomain() {
    return NotePage(
      id: id,
      notebookId: notebookId,
      sectionId: sectionId,
      createdAt: DateTime.parse(createdAt).toLocal(),
      updatedAt: DateTime.parse(updatedAt).toLocal(),
      deletedAt: deletedAt == null
          ? null
          : DateTime.parse(deletedAt!).toLocal(),
      version: version,
      sortOrder: sortOrder,
      orientation: PageOrientation.values.byName(orientation),
      template: PageTemplate.values.byName(template),
      paperColor: PagePaperColor.values.byName(paperColor),
      width: width,
      height: height,
      thumbnailPath: thumbnailPath,
      pdfDocumentId: pdfDocumentId,
      pdfPageNumber: pdfPageNumber,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'notebookId': notebookId,
      'sectionId': sectionId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
      'version': version,
      'sortOrder': sortOrder,
      'orientation': orientation,
      'template': template,
      'paperColor': paperColor,
      'width': width,
      'height': height,
      'thumbnailPath': thumbnailPath,
      'pdfDocumentId': pdfDocumentId,
      'pdfPageNumber': pdfPageNumber,
    };
  }
}
