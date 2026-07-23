import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../drawing/presentation/screens/page_editor_screen.dart';
import '../../../pdf/domain/entities/pdf_document_entity.dart';
import '../../../pdf/presentation/screens/pdf_document_screen.dart';
import '../../application/controllers/page_controller.dart' as page_app;
import '../../domain/entities/note_page.dart';
import 'page_card.dart';
import 'pdf_document_card.dart';

final class NotebookContents extends StatelessWidget {
  const NotebookContents({
    required this.pages,
    required this.documents,
    required this.controller,
    required this.onCreatePage,
    required this.onImportPdf,
    required this.isImportingPdf,
    super.key,
  });

  final AsyncValue<List<NotePage>> pages;
  final AsyncValue<List<PdfDocumentEntity>> documents;
  final page_app.PageController controller;
  final VoidCallback onCreatePage;
  final VoidCallback onImportPdf;
  final bool isImportingPdf;

  @override
  Widget build(BuildContext context) {
    return pages.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _ReloadButton(onPressed: controller.reload),
      data: (pageItems) {
        return documents.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ReloadButton(onPressed: controller.reload),
          data: (documentItems) {
            final entries = _createEntries(
              pages: pageItems,
              documents: documentItems,
            );

            if (entries.isEmpty) {
              return _EmptyNotebook(
                onCreatePage: onCreatePage,
                onImportPdf: onImportPdf,
                isImportingPdf: isImportingPdf,
              );
            }

            return _NotebookGrid(entries: entries, controller: controller);
          },
        );
      },
    );
  }

  List<_NotebookEntry> _createEntries({
    required List<NotePage> pages,
    required List<PdfDocumentEntity> documents,
  }) {
    final entries = <_NotebookEntry>[];
    final pagesByDocument = <String, List<NotePage>>{};

    for (final page in pages) {
      final documentId = page.pdfDocumentId;

      if (documentId == null) {
        entries.add(_NotebookEntry.page(page));
        continue;
      }

      pagesByDocument.putIfAbsent(documentId, () => []).add(page);
    }

    for (final document in documents) {
      final documentPages = pagesByDocument[document.id];

      if (documentPages == null || documentPages.isEmpty) {
        continue;
      }

      documentPages.sort((first, second) {
        return (first.pdfPageNumber ?? 0).compareTo(second.pdfPageNumber ?? 0);
      });

      entries.add(
        _NotebookEntry.pdf(
          document: document,
          pages: List.unmodifiable(documentPages),
        ),
      );
    }

    entries.sort(
      (first, second) => first.sortOrder.compareTo(second.sortOrder),
    );

    return entries;
  }
}

final class _NotebookGrid extends StatelessWidget {
  const _NotebookGrid({required this.entries, required this.controller});

  final List<_NotebookEntry> entries;
  final page_app.PageController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = switch (constraints.maxWidth) {
          >= 1200 => 5,
          >= 900 => 4,
          >= 600 => 3,
          >= 360 => 2,
          _ => 1,
        };

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.72,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final page = entry.page;

            if (page != null) {
              final pageNumber = page.sortOrder ~/ 1000;

              return PageCard(
                key: ValueKey(page.id),
                page: page,
                pageNumber: pageNumber,
                onOpen: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) {
                        return PageEditorScreen(
                          page: page,
                          pageNumber: pageNumber,
                        );
                      },
                    ),
                  );
                },
                onMoveToTrash: () {
                  controller.moveToTrash(page.id);
                },
              );
            }

            final document = entry.document!;

            return PdfDocumentCard(
              key: ValueKey(document.id),
              document: document,
              onOpen: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) {
                      return PdfDocumentScreen(
                        document: document,
                        pages: entry.pdfPages,
                      );
                    },
                  ),
                );
              },
              onMoveToTrash: () {
                controller.movePdfToTrash(document.id);
              },
            );
          },
        );
      },
    );
  }
}

final class _EmptyNotebook extends StatelessWidget {
  const _EmptyNotebook({
    required this.onCreatePage,
    required this.onImportPdf,
    required this.isImportingPdf,
  });

  final VoidCallback onCreatePage;
  final VoidCallback onImportPdf;
  final bool isImportingPdf;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(
            tooltip: strings.createPage,
            onPressed: onCreatePage,
            iconSize: 36,
            padding: const EdgeInsets.all(24),
            icon: const Icon(Icons.note_add_outlined),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: isImportingPdf ? null : onImportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(
              isImportingPdf ? strings.importingPdf : strings.importPdf,
            ),
          ),
        ],
      ),
    );
  }
}

final class _ReloadButton extends StatelessWidget {
  const _ReloadButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return Center(
      child: IconButton.filledTonal(
        tooltip: strings.tryAgain,
        onPressed: onPressed,
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}

final class _NotebookEntry {
  const _NotebookEntry._({
    required this.sortOrder,
    this.page,
    this.document,
    this.pdfPages = const [],
  });

  factory _NotebookEntry.page(NotePage page) {
    return _NotebookEntry._(sortOrder: page.sortOrder, page: page);
  }

  factory _NotebookEntry.pdf({
    required PdfDocumentEntity document,
    required List<NotePage> pages,
  }) {
    return _NotebookEntry._(
      sortOrder: pages.first.sortOrder,
      document: document,
      pdfPages: pages,
    );
  }

  final int sortOrder;
  final NotePage? page;
  final PdfDocumentEntity? document;
  final List<NotePage> pdfPages;
}
