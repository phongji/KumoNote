import '../../domain/entities/pdf_page_text_index.dart';

final class PdfPageTextIndexRecord {
  const PdfPageTextIndexRecord({
    required this.documentId,
    required this.documentChecksum,
    required this.pageNumber,
    required this.text,
    required this.indexedAt,
  });

  final String documentId;
  final String documentChecksum;
  final int pageNumber;
  final String text;
  final String indexedAt;

  factory PdfPageTextIndexRecord.fromDomain(PdfPageTextIndex index) {
    return PdfPageTextIndexRecord(
      documentId: index.documentId,
      documentChecksum: index.documentChecksum,
      pageNumber: index.pageNumber,
      text: index.text,
      indexedAt: index.indexedAt.toUtc().toIso8601String(),
    );
  }

  factory PdfPageTextIndexRecord.fromJson(Map<String, Object?> json) {
    return PdfPageTextIndexRecord(
      documentId: json['documentId']! as String,
      documentChecksum: json['documentChecksum']! as String,
      pageNumber: (json['pageNumber']! as num).toInt(),
      text: json['text']! as String,
      indexedAt: json['indexedAt']! as String,
    );
  }

  PdfPageTextIndex toDomain() {
    return PdfPageTextIndex(
      documentId: documentId,
      documentChecksum: documentChecksum,
      pageNumber: pageNumber,
      text: text,
      indexedAt: DateTime.parse(indexedAt).toUtc(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'documentId': documentId,
      'documentChecksum': documentChecksum,
      'pageNumber': pageNumber,
      'text': text,
      'indexedAt': indexedAt,
    };
  }
}
