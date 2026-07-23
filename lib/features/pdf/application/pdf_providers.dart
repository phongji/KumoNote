import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/application/providers/library_providers.dart';
import '../../page/application/providers/page_providers.dart';
import '../data/repositories/local_pdf_document_repository.dart';
import '../data/repositories/local_pdf_text_index_repository.dart';
import '../data/storage/web_pdf_data_store.dart';
import '../data/storage/web_pdf_text_index_data_store.dart';
import '../domain/entities/pdf_document_entity.dart';
import '../domain/repositories/pdf_document_repository.dart';
import '../domain/repositories/pdf_text_index_repository.dart';
import 'services/pdf_import_service.dart';
import 'services/pdf_text_index_service.dart';
import 'use_cases/import_pdf_to_notebook.dart';

final webPdfDataStoreProvider = Provider<WebPdfDataStore>((ref) {
  return WebPdfDataStore();
});

final webPdfTextIndexDataStoreProvider = Provider<WebPdfTextIndexDataStore>((
  ref,
) {
  return WebPdfTextIndexDataStore();
});

final pdfDocumentRepositoryProvider = Provider<PdfDocumentRepository>((ref) {
  return LocalPdfDocumentRepository(
    store: ref.watch(keyValueStoreProvider),
    pdfDataStore: ref.watch(webPdfDataStoreProvider),
  );
});

final pdfTextIndexRepositoryProvider = Provider<PdfTextIndexRepository>((ref) {
  return LocalPdfTextIndexRepository(
    dataStore: ref.watch(webPdfTextIndexDataStoreProvider),
  );
});

final pdfImportServiceProvider = Provider<PdfImportService>((ref) {
  return const PdfImportService();
});

final pdfTextIndexServiceProvider = Provider<PdfTextIndexService>((ref) {
  return PdfTextIndexService(
    documentRepository: ref.watch(pdfDocumentRepositoryProvider),
    indexRepository: ref.watch(pdfTextIndexRepositoryProvider),
  );
});

final importPdfToNotebookProvider = Provider<ImportPdfToNotebook>((ref) {
  return ImportPdfToNotebook(
    pdfRepository: ref.watch(pdfDocumentRepositoryProvider),
    pageRepository: ref.watch(pageRepositoryProvider),
  );
});

final pdfDocumentListProvider =
    FutureProvider.family<List<PdfDocumentEntity>, String>((ref, notebookId) {
      return ref
          .watch(pdfDocumentRepositoryProvider)
          .getByNotebookId(notebookId);
    });

final pdfDocumentProvider = FutureProvider.family<PdfDocumentEntity?, String>((
  ref,
  documentId,
) {
  return ref.watch(pdfDocumentRepositoryProvider).getById(documentId);
});

final pdfDocumentBytesProvider = FutureProvider.family<Uint8List?, String>((
  ref,
  storageKey,
) {
  return ref.watch(pdfDocumentRepositoryProvider).readBytes(storageKey);
});
