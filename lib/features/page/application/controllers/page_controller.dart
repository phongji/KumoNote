import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pdf/application/pdf_providers.dart';
import '../../../pdf/application/use_cases/import_pdf_to_notebook.dart';
import '../../../pdf/domain/entities/pdf_document_entity.dart';
import '../../domain/entities/note_page.dart';
import '../providers/page_providers.dart';

final pageControllerProvider = Provider.family<PageController, String>((
  ref,
  notebookId,
) {
  return PageController(ref: ref, notebookId: notebookId);
});

final class PageController {
  const PageController({required this._ref, required this.notebookId});

  final Ref _ref;
  final String notebookId;

  Future<NotePage> createPage({
    PageOrientation orientation = PageOrientation.portrait,
    PageTemplate template = PageTemplate.blank,
    PagePaperColor paperColor = PagePaperColor.paperWhite,
  }) async {
    final page = await _ref
        .read(createPageProvider)
        .call(
          notebookId: notebookId,
          orientation: orientation,
          template: template,
          paperColor: paperColor,
        );

    _refreshLists();

    return page;
  }

  Future<PdfNotebookImportResult?> importPdf() async {
    final importedPdf = await _ref.read(pdfImportServiceProvider).pickPdf();

    if (importedPdf == null) {
      return null;
    }

    final result = await _ref
        .read(importPdfToNotebookProvider)
        .call(notebookId: notebookId, importedPdf: importedPdf);

    _ref.invalidate(pdfDocumentListProvider(notebookId));
    _refreshLists();

    unawaited(_indexPdfQuietly(result.document));

    return result;
  }

  Future<void> moveToTrash(String pageId) async {
    await _ref.read(movePageToTrashProvider).call(pageId);
    _refreshLists();
  }

  Future<void> movePdfToTrash(String documentId) async {
    final repository = _ref.read(pageRepositoryProvider);
    final activePages = await repository.getActivePages(notebookId);
    final now = DateTime.now().toUtc();
    final pdfPages = activePages
        .where((page) => page.pdfDocumentId == documentId)
        .map((page) => page.moveToTrash(now: now))
        .toList(growable: false);

    if (pdfPages.isEmpty) {
      return;
    }

    await repository.saveAll(pdfPages);
    _refreshLists();
  }

  Future<void> restore(String pageId) async {
    await _ref.read(restorePageProvider).call(pageId);
    _refreshLists();
  }

  Future<void> restorePdf(String documentId) async {
    final repository = _ref.read(pageRepositoryProvider);
    final deletedPages = await repository.getDeletedPages(notebookId);
    final now = DateTime.now().toUtc();
    final restoredPages = deletedPages
        .where((page) => page.pdfDocumentId == documentId)
        .map((page) => page.restore(now: now))
        .toList(growable: false);

    if (restoredPages.isEmpty) {
      return;
    }

    await repository.saveAll(restoredPages);
    _refreshLists();
  }

  Future<void> deleteForever(String pageId) async {
    await _ref.read(deletePageForeverProvider).call(pageId);
    _refreshLists();
  }

  Future<void> deletePdfForever(String documentId) async {
    final pageRepository = _ref.read(pageRepositoryProvider);
    final deletedPages = await pageRepository.getDeletedPages(notebookId);
    final pageIds = deletedPages
        .where((page) => page.pdfDocumentId == documentId)
        .map((page) => page.id)
        .toList(growable: false);

    for (final pageId in pageIds) {
      await pageRepository.purge(pageId);
    }

    await _ref.read(pdfDocumentRepositoryProvider).delete(documentId);

    await _ref.read(pdfTextIndexServiceProvider).deleteIndex(documentId);

    _ref.invalidate(pdfDocumentListProvider(notebookId));
    _refreshLists();
  }

  void reload() {
    _ref.invalidate(pdfDocumentListProvider(notebookId));
    _refreshLists();
  }

  Future<void> _indexPdfQuietly(PdfDocumentEntity document) async {
    try {
      await _ref.read(pdfTextIndexServiceProvider).ensureIndexed(document);
    } catch (_) {
      // PDF import remains usable even when text extraction is unavailable.
    }
  }

  void _refreshLists() {
    _ref.invalidate(activePageListProvider(notebookId));
    _ref.invalidate(deletedPageListProvider(notebookId));
  }
}
