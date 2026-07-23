import '../../domain/entities/pdf_page_text_index.dart';
import '../../domain/repositories/pdf_text_index_repository.dart';
import '../models/pdf_page_text_index_record.dart';
import '../storage/web_pdf_text_index_data_store.dart';

final class LocalPdfTextIndexRepository implements PdfTextIndexRepository {
  const LocalPdfTextIndexRepository({required this.dataStore});

  final WebPdfTextIndexDataStore dataStore;

  @override
  Future<List<PdfPageTextIndex>> getForDocument(String documentId) async {
    final indexes = await _readAll();

    return indexes.where((index) => index.documentId == documentId).toList()
      ..sort((first, second) {
        return first.pageNumber.compareTo(second.pageNumber);
      });
  }

  @override
  Future<List<PdfPageTextIndex>> search(String query) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final indexes = await _readAll();
    final matches = indexes.where((index) {
      return index.hasText &&
          index.text.toLowerCase().contains(normalizedQuery);
    }).toList();

    matches.sort((first, second) {
      final documentComparison = first.documentId.compareTo(second.documentId);

      if (documentComparison != 0) {
        return documentComparison;
      }

      return first.pageNumber.compareTo(second.pageNumber);
    });

    return matches;
  }

  @override
  Future<bool> isCurrent({
    required String documentId,
    required String documentChecksum,
    required int pageCount,
  }) async {
    final indexes = await getForDocument(documentId);

    if (indexes.length != pageCount) {
      return false;
    }

    return indexes.every((index) {
      return index.documentChecksum == documentChecksum;
    });
  }

  @override
  Future<void> saveAll(List<PdfPageTextIndex> indexes) async {
    if (indexes.isEmpty) {
      return;
    }

    final indexesByDocument = <String, List<PdfPageTextIndex>>{};

    for (final index in indexes) {
      indexesByDocument.putIfAbsent(index.documentId, () => []).add(index);
    }

    for (final entry in indexesByDocument.entries) {
      final records = entry.value
          .map(PdfPageTextIndexRecord.fromDomain)
          .toList(growable: false);

      await dataStore.replaceForDocument(
        documentId: entry.key,
        records: records,
      );
    }
  }

  @override
  Future<void> deleteForDocument(String documentId) {
    return dataStore.deleteForDocument(documentId);
  }

  Future<List<PdfPageTextIndex>> _readAll() async {
    final records = await dataStore.readAll();

    return records.map((record) => record.toDomain()).toList(growable: false);
  }
}
