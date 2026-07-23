import 'dart:convert';
import 'dart:typed_data';

import 'package:kumo_note/core/persistence/key_value_store.dart';

import '../../domain/entities/pdf_document_entity.dart';
import '../../domain/repositories/pdf_document_repository.dart';
import '../models/pdf_document_record.dart';
import '../storage/web_pdf_data_store.dart';

final class LocalPdfDocumentRepository implements PdfDocumentRepository {
  const LocalPdfDocumentRepository({
    required this.store,
    required this.pdfDataStore,
  });

  final KeyValueStore store;
  final WebPdfDataStore pdfDataStore;

  @override
  Future<List<PdfDocumentEntity>> getByNotebookId(String notebookId) async {
    final documents = await _readAll();

    return documents
        .where((document) => document.notebookId == notebookId)
        .toList()
      ..sort((first, second) {
        return first.createdAt.compareTo(second.createdAt);
      });
  }

  @override
  Future<List<PdfDocumentEntity>> searchByFileName(String query) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final documents = await _readAll();
    final matches = documents.where((document) {
      return document.fileName.toLowerCase().contains(normalizedQuery);
    }).toList();

    matches.sort((first, second) {
      return second.updatedAt.compareTo(first.updatedAt);
    });

    return matches;
  }

  @override
  Future<PdfDocumentEntity?> getById(String documentId) async {
    final documents = await _readAll();

    for (final document in documents) {
      if (document.id == documentId) {
        return document;
      }
    }

    return null;
  }

  @override
  Future<Uint8List?> readBytes(String storageKey) {
    return pdfDataStore.read(storageKey);
  }

  @override
  Future<void> save({
    required PdfDocumentEntity document,
    Uint8List? bytes,
  }) async {
    if (bytes != null) {
      await pdfDataStore.save(storageKey: document.storageKey, bytes: bytes);
    }

    final documents = await _readAll();
    final existingIndex = documents.indexWhere(
      (storedDocument) => storedDocument.id == document.id,
    );

    if (existingIndex == -1) {
      documents.add(document);
    } else {
      documents[existingIndex] = document;
    }

    await _writeAll(documents);
  }

  @override
  Future<void> delete(String documentId) async {
    final documents = await _readAll();
    PdfDocumentEntity? removedDocument;

    for (final document in documents) {
      if (document.id == documentId) {
        removedDocument = document;
        break;
      }
    }

    if (removedDocument == null) {
      return;
    }

    documents.removeWhere((document) => document.id == documentId);

    await _writeAll(documents);
    await pdfDataStore.delete(removedDocument.storageKey);
  }

  Future<List<PdfDocumentEntity>> _readAll() async {
    final rawValue = await store.readString(PersistenceKey.pdfDocuments);

    if (rawValue == null || rawValue.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawValue);

    if (decoded is! List<Object?>) {
      throw const FormatException('Stored PDF metadata must be a JSON list.');
    }

    return decoded.map((item) {
      if (item is! Map<String, Object?>) {
        throw const FormatException(
          'Stored PDF metadata must be a JSON object.',
        );
      }

      return PdfDocumentRecord.fromJson(item).toDomain();
    }).toList();
  }

  Future<void> _writeAll(List<PdfDocumentEntity> documents) async {
    final records = documents
        .map(PdfDocumentRecord.fromDomain)
        .map((record) => record.toJson())
        .toList(growable: false);

    await store.writeString(PersistenceKey.pdfDocuments, jsonEncode(records));
  }
}
