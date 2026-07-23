final class PdfPageTextIndex {
  const PdfPageTextIndex({
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
  final DateTime indexedAt;

  String get id => '$documentId:$pageNumber';

  bool get hasText => text.trim().isNotEmpty;
}
