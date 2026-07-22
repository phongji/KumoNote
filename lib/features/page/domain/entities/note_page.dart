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
  });

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

  bool get isDeleted => deletedAt != null;

  NotePage reorder({required int newSortOrder, required DateTime now}) {
    return NotePage(
      id: id,
      notebookId: notebookId,
      sectionId: sectionId,
      createdAt: createdAt,
      updatedAt: now,
      deletedAt: deletedAt,
      version: version + 1,
      sortOrder: newSortOrder,
      orientation: orientation,
      template: template,
      paperColor: paperColor,
      width: width,
      height: height,
      thumbnailPath: thumbnailPath,
    );
  }

  NotePage changeAppearance({
    required PageOrientation newOrientation,
    required PageTemplate newTemplate,
    required PagePaperColor newPaperColor,
    required DateTime now,
  }) {
    final isPortrait = newOrientation == PageOrientation.portrait;

    return NotePage(
      id: id,
      notebookId: notebookId,
      sectionId: sectionId,
      createdAt: createdAt,
      updatedAt: now,
      deletedAt: deletedAt,
      version: version + 1,
      sortOrder: sortOrder,
      orientation: newOrientation,
      template: newTemplate,
      paperColor: newPaperColor,
      width: isPortrait ? 595 : 842,
      height: isPortrait ? 842 : 595,
      thumbnailPath: thumbnailPath,
    );
  }

  NotePage moveToTrash({required DateTime now}) {
    if (isDeleted) {
      return this;
    }

    return NotePage(
      id: id,
      notebookId: notebookId,
      sectionId: sectionId,
      createdAt: createdAt,
      updatedAt: now,
      deletedAt: now,
      version: version + 1,
      sortOrder: sortOrder,
      orientation: orientation,
      template: template,
      paperColor: paperColor,
      width: width,
      height: height,
      thumbnailPath: thumbnailPath,
    );
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
    );
  }
}
