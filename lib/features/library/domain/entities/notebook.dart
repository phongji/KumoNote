final class Notebook {
  const Notebook({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.sortOrder,
    required this.isFavorite,
    required this.coverColorValue,
    this.folderId,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final int sortOrder;
  final bool isFavorite;
  final int coverColorValue;

  bool get isDeleted => deletedAt != null;

  Notebook rename({required String newTitle, required DateTime now}) {
    final cleanTitle = newTitle.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError.value(
        newTitle,
        'newTitle',
        'Notebook title cannot be empty.',
      );
    }

    return Notebook(
      id: id,
      title: cleanTitle,
      folderId: folderId,
      createdAt: createdAt,
      updatedAt: now,
      deletedAt: deletedAt,
      version: version + 1,
      sortOrder: sortOrder,
      isFavorite: isFavorite,
      coverColorValue: coverColorValue,
    );
  }

  Notebook toggleFavorite({required DateTime now}) {
    return Notebook(
      id: id,
      title: title,
      folderId: folderId,
      createdAt: createdAt,
      updatedAt: now,
      deletedAt: deletedAt,
      version: version + 1,
      sortOrder: sortOrder,
      isFavorite: !isFavorite,
      coverColorValue: coverColorValue,
    );
  }

  Notebook moveToTrash({required DateTime now}) {
    if (isDeleted) {
      return this;
    }

    return Notebook(
      id: id,
      title: title,
      folderId: folderId,
      createdAt: createdAt,
      updatedAt: now,
      deletedAt: now,
      version: version + 1,
      sortOrder: sortOrder,
      isFavorite: isFavorite,
      coverColorValue: coverColorValue,
    );
  }

  Notebook restore({required DateTime now}) {
    if (!isDeleted) {
      return this;
    }

    return Notebook(
      id: id,
      title: title,
      folderId: folderId,
      createdAt: createdAt,
      updatedAt: now,
      version: version + 1,
      sortOrder: sortOrder,
      isFavorite: isFavorite,
      coverColorValue: coverColorValue,
    );
  }
}
