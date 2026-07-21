enum PageOrientation {
  portrait,
  landscape,
}

enum PageTemplate {
  blank,
  ruled,
  grid,
  dotted,
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
  final double width;
  final double height;
  final String? thumbnailPath;

  bool get isDeleted => deletedAt != null;

  NotePage reorder({
    required int newSortOrder,
    required DateTime now,
  }) {
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
      width: width,
      height: height,
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
      width: width,
      height: height,
      thumbnailPath: thumbnailPath,
    );
  }
}