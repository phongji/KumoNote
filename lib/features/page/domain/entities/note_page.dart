enum PageOrientation { portrait, landscape }

enum PageTemplate {
  blank,
  ruled,
  grid,
  dotted,
  guideRuled,
  focusHeader,
  twinNotes,
  quietChecklist,
}

enum PagePaperColor {
  paperWhite(0xFFFFFFFF),
  warmIvory(0xFFFAF8F2),
  unbleachedBeige(0xFFF3EBDD),
  mistGray(0xFFF1F2EF),
  paleSage(0xFFEEF3EC),
  hazeBlue(0xFFEEF3F5),
  quietLavender(0xFFF1EFF4),
  coolMint(0xFFEDF4F1);

  const PagePaperColor(this.colorValue);

  final int colorValue;
}

final class NotePage {
  const NotePage({
    required this.id,
    required this.notebookId,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.sortOrder,
    required this.orientation,
    required this.template,
    required this.width,
    required this.height,
    this.paperColor = PagePaperColor.paperWhite,
    this.sectionId,
    this.deletedAt,
    this.thumbnailPath,
    this.pdfDocumentId,
    this.pdfPageNumber,
  }) : assert(
         (pdfDocumentId == null && pdfPageNumber == null) ||
             (pdfDocumentId != null &&
                 pdfPageNumber != null &&
                 pdfPageNumber > 0),
       );

  final String id;
  final String notebookId;
  final String? sectionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final int sortOrder;
  final PageOrientation orientation;
  final PageTemplate template;
  final PagePaperColor paperColor;
  final double width;
  final double height;
  final String? thumbnailPath;
  final String? pdfDocumentId;
  final int? pdfPageNumber;

  bool get isDeleted => deletedAt != null;

  bool get isPdfPage => pdfDocumentId != null && pdfPageNumber != null;

  NotePage reorder({required int newSortOrder, required DateTime now}) {
    return _copy(updatedAt: now, version: version + 1, sortOrder: newSortOrder);
  }

  NotePage changeAppearance({
    required PageOrientation newOrientation,
    required PageTemplate newTemplate,
    required PagePaperColor newPaperColor,
    required DateTime now,
  }) {
    final isPortrait = newOrientation == PageOrientation.portrait;

    return _copy(
      updatedAt: now,
      version: version + 1,
      orientation: newOrientation,
      template: newTemplate,
      paperColor: newPaperColor,
      width: isPdfPage ? width : (isPortrait ? 595 : 842),
      height: isPdfPage ? height : (isPortrait ? 842 : 595),
    );
  }

  NotePage moveToTrash({required DateTime now}) {
    if (isDeleted) {
      return this;
    }

    return _copy(updatedAt: now, deletedAt: now, version: version + 1);
  }

  NotePage restore({required DateTime now}) {
    if (!isDeleted) {
      return this;
    }

    return NotePage(
      id: id,
      notebookId: notebookId,
      sectionId: sectionId,
      createdAt: createdAt,
      updatedAt: now,
      version: version + 1,
      sortOrder: sortOrder,
      orientation: orientation,
      template: template,
      paperColor: paperColor,
      width: width,
      height: height,
      thumbnailPath: thumbnailPath,
      pdfDocumentId: pdfDocumentId,
      pdfPageNumber: pdfPageNumber,
    );
  }

  NotePage _copy({
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
    int? sortOrder,
    PageOrientation? orientation,
    PageTemplate? template,
    PagePaperColor? paperColor,
    double? width,
    double? height,
  }) {
    return NotePage(
      id: id,
      notebookId: notebookId,
      sectionId: sectionId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
      sortOrder: sortOrder ?? this.sortOrder,
      orientation: orientation ?? this.orientation,
      template: template ?? this.template,
      paperColor: paperColor ?? this.paperColor,
      width: width ?? this.width,
      height: height ?? this.height,
      thumbnailPath: thumbnailPath,
      pdfDocumentId: pdfDocumentId,
      pdfPageNumber: pdfPageNumber,
    );
  }
}
