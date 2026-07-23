import 'package:pdfrx/pdfrx.dart';

import '../../domain/entities/pdf_document_entity.dart';
import '../../domain/entities/pdf_page_text_index.dart';
import '../../domain/repositories/pdf_document_repository.dart';
import '../../domain/repositories/pdf_text_index_repository.dart';

final class PdfTextIndexService {
  const PdfTextIndexService({
    required this.documentRepository,
    required this.indexRepository,
  });

  final PdfDocumentRepository documentRepository;
  final PdfTextIndexRepository indexRepository;

  Future<void> ensureIndexed(PdfDocumentEntity document) async {
    final isCurrent = await indexRepository.isCurrent(
      documentId: document.id,
      documentChecksum: document.checksum,
      pageCount: document.pageCount,
    );

    if (isCurrent) {
      return;
    }

    final bytes = await documentRepository.readBytes(document.storageKey);

    if (bytes == null || bytes.isEmpty) {
      throw StateError('PDF data could not be read for indexing.');
    }

    await pdfrxFlutterInitialize();

    final pdfDocument = await PdfDocument.openData(
      bytes,
      sourceName: document.fileName,
      useProgressiveLoading: false,
      allowDataOwnershipTransfer: false,
    );

    try {
      final now = DateTime.now().toUtc();
      final indexes = <PdfPageTextIndex>[];

      for (final page in pdfDocument.pages) {
        final rawText = await page.loadText();
        final text = _normalizeText(rawText?.fullText ?? '');

        indexes.add(
          PdfPageTextIndex(
            documentId: document.id,
            documentChecksum: document.checksum,
            pageNumber: page.pageNumber,
            text: text,
            indexedAt: now,
          ),
        );
      }

      await indexRepository.saveAll(indexes);
    } finally {
      await pdfDocument.dispose();
    }
  }

  Future<void> deleteIndex(String documentId) {
    return indexRepository.deleteForDocument(documentId);
  }

  String _normalizeText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
