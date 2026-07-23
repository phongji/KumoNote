import 'dart:typed_data';

import '../entities/pdf_document_entity.dart';

abstract interface class PdfDocumentRepository {
  Future<List<PdfDocumentEntity>> getByNotebookId(String notebookId);

  Future<PdfDocumentEntity?> getById(String documentId);

  Future<Uint8List?> readBytes(String storageKey);

  Future<void> save({required PdfDocumentEntity document, Uint8List? bytes});

  Future<void> delete(String documentId);
}
