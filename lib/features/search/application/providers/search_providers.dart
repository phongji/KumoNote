import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/application/providers/library_providers.dart';
import '../../../library/domain/entities/notebook.dart';
import '../../../page/application/providers/page_providers.dart';
import '../../../page/domain/entities/note_page.dart';
import '../../../pdf/application/pdf_providers.dart';
import '../../../pdf/domain/entities/pdf_document_entity.dart';
import '../../../text/application/providers/text_providers.dart';
import '../../domain/entities/library_search_result.dart';
import '../../domain/entities/pdf_file_search_result.dart';

final libraryTextSearchProvider = FutureProvider.autoDispose
    .family<List<LibrarySearchResult>, String>((ref, query) async {
      final normalizedQuery = query.trim();

      if (normalizedQuery.isEmpty) {
        return const [];
      }

      final textRepository = ref.watch(textObjectRepositoryProvider);
      final pageRepository = ref.watch(pageRepositoryProvider);
      final notebookRepository = ref.watch(notebookRepositoryProvider);

      final textMatches = await textRepository.search(normalizedQuery);
      final pageCache = <String, NotePage?>{};
      final notebookCache = <String, Notebook?>{};
      final results = <LibrarySearchResult>[];

      for (final textObject in textMatches) {
        final page = pageCache.containsKey(textObject.pageId)
            ? pageCache[textObject.pageId]
            : await pageRepository.getById(textObject.pageId);

        pageCache[textObject.pageId] = page;

        if (page == null || page.isDeleted) {
          continue;
        }

        final notebook = notebookCache.containsKey(page.notebookId)
            ? notebookCache[page.notebookId]
            : await notebookRepository.getById(page.notebookId);

        notebookCache[page.notebookId] = notebook;

        if (notebook == null || notebook.isDeleted) {
          continue;
        }

        results.add(
          LibrarySearchResult(
            id: textObject.id,
            type: LibrarySearchResultType.typedText,
            notebook: notebook,
            page: page,
            matchedText: _createExcerpt(
              text: textObject.plainText,
              query: normalizedQuery,
            ),
            updatedAt: textObject.updatedAt,
          ),
        );
      }

      results.sort((first, second) {
        return second.updatedAt.compareTo(first.updatedAt);
      });

      return List.unmodifiable(results);
    });

final libraryPdfFileSearchProvider = FutureProvider.autoDispose
    .family<List<PdfFileSearchResult>, String>((ref, query) async {
      final normalizedQuery = query.trim();

      if (normalizedQuery.isEmpty) {
        return const [];
      }

      final pdfRepository = ref.watch(pdfDocumentRepositoryProvider);
      final pageRepository = ref.watch(pageRepositoryProvider);
      final notebookRepository = ref.watch(notebookRepositoryProvider);

      final documents = await pdfRepository.searchByFileName(normalizedQuery);
      final notebookCache = <String, Notebook?>{};
      final pageCache = <String, List<NotePage>>{};
      final results = <PdfFileSearchResult>[];

      for (final document in documents) {
        final notebook = notebookCache.containsKey(document.notebookId)
            ? notebookCache[document.notebookId]
            : await notebookRepository.getById(document.notebookId);

        notebookCache[document.notebookId] = notebook;

        if (notebook == null || notebook.isDeleted) {
          continue;
        }

        final notebookPages = pageCache.containsKey(document.notebookId)
            ? pageCache[document.notebookId]!
            : await pageRepository.getActivePages(document.notebookId);

        pageCache[document.notebookId] = notebookPages;

        final documentPages = notebookPages
            .where((page) => page.pdfDocumentId == document.id)
            .toList();

        if (documentPages.isEmpty) {
          continue;
        }

        documentPages.sort((first, second) {
          return (first.pdfPageNumber ?? 0).compareTo(
            second.pdfPageNumber ?? 0,
          );
        });

        results.add(
          PdfFileSearchResult(
            document: document,
            notebook: notebook,
            pages: List.unmodifiable(documentPages),
          ),
        );
      }

      return List.unmodifiable(results);
    });

final libraryPdfTextSearchProvider = FutureProvider.autoDispose
    .family<List<LibrarySearchResult>, String>((ref, query) async {
      final normalizedQuery = query.trim();

      if (normalizedQuery.isEmpty) {
        return const [];
      }

      final indexRepository = ref.watch(pdfTextIndexRepositoryProvider);
      final pdfRepository = ref.watch(pdfDocumentRepositoryProvider);
      final pageRepository = ref.watch(pageRepositoryProvider);
      final notebookRepository = ref.watch(notebookRepositoryProvider);

      final matches = await indexRepository.search(normalizedQuery);
      final documentCache = <String, PdfDocumentEntity?>{};
      final notebookCache = <String, Notebook?>{};
      final pageCache = <String, List<NotePage>>{};
      final results = <LibrarySearchResult>[];

      for (final match in matches) {
        final document = documentCache.containsKey(match.documentId)
            ? documentCache[match.documentId]
            : await pdfRepository.getById(match.documentId);

        documentCache[match.documentId] = document;

        if (document == null) {
          continue;
        }

        final notebook = notebookCache.containsKey(document.notebookId)
            ? notebookCache[document.notebookId]
            : await notebookRepository.getById(document.notebookId);

        notebookCache[document.notebookId] = notebook;

        if (notebook == null || notebook.isDeleted) {
          continue;
        }

        final notebookPages = pageCache.containsKey(document.notebookId)
            ? pageCache[document.notebookId]!
            : await pageRepository.getActivePages(document.notebookId);

        pageCache[document.notebookId] = notebookPages;

        final page = _findPdfPage(
          pages: notebookPages,
          documentId: document.id,
          pageNumber: match.pageNumber,
        );

        if (page == null) {
          continue;
        }

        results.add(
          LibrarySearchResult(
            id: match.id,
            type: LibrarySearchResultType.pdfText,
            notebook: notebook,
            page: page,
            matchedText: _createExcerpt(
              text: match.text,
              query: normalizedQuery,
            ),
            updatedAt: match.indexedAt,
          ),
        );
      }

      return List.unmodifiable(results);
    });

NotePage? _findPdfPage({
  required List<NotePage> pages,
  required String documentId,
  required int pageNumber,
}) {
  for (final page in pages) {
    if (page.pdfDocumentId == documentId && page.pdfPageNumber == pageNumber) {
      return page;
    }
  }

  return null;
}

String _createExcerpt({required String text, required String query}) {
  final cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  if (cleanText.isEmpty) {
    return '';
  }

  final normalizedText = cleanText.toLowerCase();
  final normalizedQuery = query.toLowerCase();
  final matchIndex = normalizedText.indexOf(normalizedQuery);

  if (matchIndex == -1) {
    return cleanText;
  }

  const surroundingCharacters = 42;
  final start = math.max(0, matchIndex - surroundingCharacters);
  final end = math.min(
    cleanText.length,
    matchIndex + normalizedQuery.length + surroundingCharacters,
  );
  final prefix = start > 0 ? '…' : '';
  final suffix = end < cleanText.length ? '…' : '';

  return '$prefix${cleanText.substring(start, end)}$suffix';
}
