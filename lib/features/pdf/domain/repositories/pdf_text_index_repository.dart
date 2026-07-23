import '../entities/pdf_page_text_index.dart';

abstract interface class PdfTextIndexRepository {
  Future<List<PdfPageTextIndex>> getForDocument(String documentId);

  Future<List<PdfPageTextIndex>> search(String query);

  Future<bool> isCurrent({
    required String documentId,
    required String documentChecksum,
    required int pageCount,
  });

  Future<void> saveAll(List<PdfPageTextIndex> indexes);

  Future<void> deleteForDocument(String documentId);
}
