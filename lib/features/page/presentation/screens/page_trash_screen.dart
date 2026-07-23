import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pdf/application/pdf_providers.dart';
import '../../../pdf/domain/entities/pdf_document_entity.dart';
import '../../application/controllers/page_controller.dart';
import '../../application/providers/page_providers.dart';
import '../../domain/entities/note_page.dart';

final class PageTrashScreen extends ConsumerWidget {
  const PageTrashScreen({required this.notebookId, super.key});

  final String notebookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final pages = ref.watch(deletedPageListProvider(notebookId));
    final documents = ref.watch(pdfDocumentListProvider(notebookId));
    final controller = ref.read(pageControllerProvider(notebookId));

    return Scaffold(
      appBar: AppBar(title: Text(strings.trash)),
      body: pages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: IconButton.filledTonal(
            onPressed: controller.reload,
            icon: const Icon(Icons.refresh),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Icon(Icons.delete_outline, size: 64));
          }

          final documentMap = {
            for (final document
                in documents.asData?.value ?? const <PdfDocumentEntity>[])
              document.id: document,
          };
          final entries = _buildEntries(items, documentMap);

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];

              return Card(
                child: ListTile(
                  leading: Icon(
                    entry.isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.description_outlined,
                  ),
                  title: Text(entry.title),
                  subtitle: entry.subtitle == null
                      ? null
                      : Text(entry.subtitle!),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: strings.restore,
                        onPressed: () {
                          final documentId = entry.pdfDocumentId;

                          if (documentId != null) {
                            unawaited(controller.restorePdf(documentId));
                          } else {
                            unawaited(controller.restore(entry.page.id));
                          }
                        },
                        icon: const Icon(Icons.restore),
                      ),
                      IconButton(
                        tooltip: strings.deleteForever,
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () {
                          final documentId = entry.pdfDocumentId;

                          if (documentId != null) {
                            unawaited(controller.deletePdfForever(documentId));
                          } else {
                            unawaited(controller.deleteForever(entry.page.id));
                          }
                        },
                        icon: const Icon(Icons.delete_forever_outlined),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<_TrashEntry> _buildEntries(
    List<NotePage> pages,
    Map<String, PdfDocumentEntity> documents,
  ) {
    final entries = <_TrashEntry>[];
    final pdfGroups = <String, List<NotePage>>{};

    for (final page in pages) {
      final documentId = page.pdfDocumentId;

      if (documentId == null) {
        entries.add(
          _TrashEntry(page: page, title: '${page.sortOrder ~/ 1000}'),
        );
        continue;
      }

      pdfGroups.putIfAbsent(documentId, () => []).add(page);
    }

    for (final group in pdfGroups.entries) {
      final groupedPages = group.value
        ..sort((first, second) {
          return (first.pdfPageNumber ?? 0).compareTo(
            second.pdfPageNumber ?? 0,
          );
        });
      final document = documents[group.key];

      entries.add(
        _TrashEntry(
          page: groupedPages.first,
          pdfDocumentId: group.key,
          title: document?.fileName ?? 'PDF document',
          subtitle: '${groupedPages.length} pages',
        ),
      );
    }

    entries.sort((first, second) {
      final firstDate = first.page.deletedAt ?? first.page.updatedAt;
      final secondDate = second.page.deletedAt ?? second.page.updatedAt;

      return secondDate.compareTo(firstDate);
    });

    return entries;
  }
}

final class _TrashEntry {
  const _TrashEntry({
    required this.page,
    required this.title,
    this.subtitle,
    this.pdfDocumentId,
  });

  final NotePage page;
  final String title;
  final String? subtitle;
  final String? pdfDocumentId;

  bool get isPdf => pdfDocumentId != null;
}
