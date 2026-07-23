import 'package:uuid/uuid.dart';

import '../../../page/domain/entities/note_page.dart';
import '../../../page/domain/repositories/page_repository.dart';
import '../../domain/entities/pdf_document_entity.dart';
import '../../domain/repositories/pdf_document_repository.dart';
import '../services/pdf_import_service.dart';

final class PdfNotebookImportResult {
  const PdfNotebookImportResult({required this.document, required this.pages});

  final PdfDocumentEntity document;
  final List<NotePage> pages;
}

final class ImportPdfToNotebook {
  ImportPdfToNotebook({
    required this.pdfRepository,
    required this.pageRepository,
    this.uuid = const Uuid(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PdfDocumentRepository pdfRepository;
  final PageRepository pageRepository;
  final Uuid uuid;
  final DateTime Function() _now;

  Future<PdfNotebookImportResult> call({
    required String notebookId,
    required ImportedPdfData importedPdf,
  }) async {
    final normalizedNotebookId = notebookId.trim();

    if (normalizedNotebookId.isEmpty) {
      throw ArgumentError.value(
        notebookId,
        'notebookId',
        'Notebook ID must not be empty.',
      );
    }

    if (importedPdf.pages.isEmpty) {
      throw ArgumentError.value(
        importedPdf.pages,
        'importedPdf',
        'The PDF must contain at least one page.',
      );
    }

    final existingPages = await pageRepository.getActivePages(
      normalizedNotebookId,
    );
    var highestSortOrder = 0;

    for (final page in existingPages) {
      if (page.sortOrder > highestSortOrder) {
        highestSortOrder = page.sortOrder;
      }
    }

    final documentId = uuid.v4();
    final createdAt = _now().toUtc();
    final document = PdfDocumentEntity(
      id: documentId,
      notebookId: normalizedNotebookId,
      fileName: importedPdf.fileName,
      storageKey: documentId,
      checksum: importedPdf.checksum,
      byteLength: importedPdf.byteLength,
      pageCount: importedPdf.pageCount,
      createdAt: createdAt,
      updatedAt: createdAt,
      version: 1,
    );

    final pages = <NotePage>[];

    for (var index = 0; index < importedPdf.pages.length; index++) {
      final importedPage = importedPdf.pages[index];
      final isPortrait = importedPage.height >= importedPage.width;

      pages.add(
        NotePage(
          id: uuid.v4(),
          notebookId: normalizedNotebookId,
          createdAt: createdAt,
          updatedAt: createdAt,
          version: 1,
          sortOrder: highestSortOrder + ((index + 1) * 1000),
          orientation: isPortrait
              ? PageOrientation.portrait
              : PageOrientation.landscape,
          template: PageTemplate.blank,
          paperColor: PagePaperColor.paperWhite,
          width: importedPage.width,
          height: importedPage.height,
          pdfDocumentId: document.id,
          pdfPageNumber: importedPage.pageNumber,
        ),
      );
    }

    await pdfRepository.save(document: document, bytes: importedPdf.bytes);

    try {
      await pageRepository.saveAll(pages);
    } catch (error, stackTrace) {
      try {
        await pdfRepository.delete(document.id);
      } catch (_) {
        // Preserve the original page-save failure.
      }

      Error.throwWithStackTrace(error, stackTrace);
    }

    return PdfNotebookImportResult(
      document: document,
      pages: List.unmodifiable(pages),
    );
  }
}
