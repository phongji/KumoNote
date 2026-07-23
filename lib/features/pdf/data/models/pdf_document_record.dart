import '../../domain/entities/pdf_document_entity.dart';

final class PdfDocumentRecord {
  const PdfDocumentRecord({
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
  });

  final String id;
  final String notebookId;
  final String fileName;
  final String storageKey;
  final String checksum;
  final int byteLength;
  final int pageCount;
  final String createdAt;
  final String updatedAt;
  final int version;

  factory PdfDocumentRecord.fromDomain(PdfDocumentEntity document) {
    return PdfDocumentRecord(
      id: document.id,
      notebookId: document.notebookId,
      fileName: document.fileName,
      storageKey: document.storageKey,
      checksum: document.checksum,
      byteLength: document.byteLength,
      pageCount: document.pageCount,
      createdAt: document.createdAt.toUtc().toIso8601String(),
      updatedAt: document.updatedAt.toUtc().toIso8601String(),
      version: document.version,
    );
  }

  factory PdfDocumentRecord.fromJson(Map<String, Object?> json) {
    return PdfDocumentRecord(
      id: json['id']! as String,
      notebookId: json['notebookId']! as String,
      fileName: json['fileName']! as String,
      storageKey: json['storageKey']! as String,
      checksum: json['checksum']! as String,
      byteLength: (json['byteLength']! as num).toInt(),
      pageCount: (json['pageCount']! as num).toInt(),
      createdAt: json['createdAt']! as String,
      updatedAt: json['updatedAt']! as String,
      version: (json['version']! as num).toInt(),
    );
  }

  PdfDocumentEntity toDomain() {
    return PdfDocumentEntity(
      id: id,
      notebookId: notebookId,
      fileName: fileName,
      storageKey: storageKey,
      checksum: checksum,
      byteLength: byteLength,
      pageCount: pageCount,
      createdAt: DateTime.parse(createdAt).toLocal(),
      updatedAt: DateTime.parse(updatedAt).toLocal(),
      version: version,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'notebookId': notebookId,
      'fileName': fileName,
      'storageKey': storageKey,
      'checksum': checksum,
      'byteLength': byteLength,
      'pageCount': pageCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'version': version,
    };
  }
}
