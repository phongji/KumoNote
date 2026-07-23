import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pdf/application/pdf_providers.dart';
import '../../../pdf/application/use_cases/import_pdf_to_notebook.dart';
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

  Future<void> deleteForever(String pageId) async {
    await _ref.read(deletePageForeverProvider).call(pageId);
    _refreshLists();
  }

  void reload() {
    _refreshLists();
  }

  void _refreshLists() {
    _ref.invalidate(activePageListProvider(notebookId));
    _ref.invalidate(deletedPageListProvider(notebookId));
  }
}
