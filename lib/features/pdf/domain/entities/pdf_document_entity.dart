final class PdfDocumentEntity {
  const PdfDocumentEntity({
    required this.id,
    required this.notebookId,
    required this.fileName,
    required this.storageKey,
    required this.checksum,
    required this.byteLength,
    required this.pageCount,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  }) : assert(byteLength > 0),
       assert(pageCount > 0),
       assert(version > 0);

  final String id;
  final String notebookId;
  final String fileName;
  final String storageKey;
  final String checksum;
  final int byteLength;
  final int pageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  PdfDocumentEntity rename({
    required String newFileName,
    required DateTime now,
  }) {
    final normalizedName = newFileName.trim();

    if (normalizedName.isEmpty || normalizedName == fileName) {
      return this;
    }

    return copyWith(
      fileName: normalizedName,
      updatedAt: now,
      version: version + 1,
    );
  }

  PdfDocumentEntity copyWith({
    String? fileName,
    String? storageKey,
    String? checksum,
    int? byteLength,
    int? pageCount,
    DateTime? updatedAt,
    int? version,
  }) {
    return PdfDocumentEntity(
      id: id,
      notebookId: notebookId,
      fileName: fileName ?? this.fileName,
      storageKey: storageKey ?? this.storageKey,
      checksum: checksum ?? this.checksum,
      byteLength: byteLength ?? this.byteLength,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}
