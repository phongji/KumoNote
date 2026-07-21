import 'dart:convert';

import 'package:kumo_note/core/persistence/key_value_store.dart';
import 'package:kumo_note/features/library/data/models/notebook_record.dart';
import 'package:kumo_note/features/library/domain/entities/notebook.dart';
import 'package:kumo_note/features/library/domain/repositories/notebook_repository.dart';

final class LocalNotebookRepository implements NotebookRepository {
  const LocalNotebookRepository({required this.store});

  final KeyValueStore store;

  @override
  Future<List<Notebook>> getActiveNotebooks() async {
    final notebooks = await _readAll();

    return notebooks.where((notebook) => !notebook.isDeleted).toList()
      ..sort(_compareNotebooks);
  }

  @override
  Future<List<Notebook>> getDeletedNotebooks() async {
    final notebooks = await _readAll();

    return notebooks.where((notebook) => notebook.isDeleted).toList()
      ..sort((first, second) {
        return second.deletedAt!.compareTo(first.deletedAt!);
      });
  }

  @override
  Future<Notebook?> getById(String notebookId) async {
    final notebooks = await _readAll();

    for (final notebook in notebooks) {
      if (notebook.id == notebookId) {
        return notebook;
      }
    }

    return null;
  }

  @override
  Future<void> save(Notebook notebook) async {
    final notebooks = await _readAll();
    final existingIndex = notebooks.indexWhere(
      (item) => item.id == notebook.id,
    );

    if (existingIndex == -1) {
      notebooks.add(notebook);
    } else {
      notebooks[existingIndex] = notebook;
    }

    await _writeAll(notebooks);
  }

  @override
  Future<void> purge(String notebookId) async {
    final notebooks = await _readAll()
      ..removeWhere((notebook) => notebook.id == notebookId);

    await _writeAll(notebooks);
  }

  Future<List<Notebook>> _readAll() async {
    final rawValue = await store.readString(PersistenceKey.notebooks);

    if (rawValue == null || rawValue.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawValue);

    if (decoded is! List<Object?>) {
      throw const FormatException('Stored notebooks must be a JSON list.');
    }

    return decoded.map((item) {
      if (item is! Map<String, Object?>) {
        throw const FormatException('Stored notebook must be a JSON object.');
      }

      return NotebookRecord.fromJson(item).toDomain();
    }).toList();
  }

  Future<void> _writeAll(List<Notebook> notebooks) async {
    final records = notebooks
        .map(NotebookRecord.fromDomain)
        .map((record) => record.toJson())
        .toList(growable: false);

    await store.writeString(PersistenceKey.notebooks, jsonEncode(records));
  }

  int _compareNotebooks(Notebook first, Notebook second) {
    final orderComparison = first.sortOrder.compareTo(second.sortOrder);

    if (orderComparison != 0) {
      return orderComparison;
    }

    return second.updatedAt.compareTo(first.updatedAt);
  }
}
