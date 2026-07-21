import 'dart:convert';

import 'package:kumo_note/core/persistence/key_value_store.dart';
import 'package:kumo_note/features/page/data/models/page_record.dart';
import 'package:kumo_note/features/page/domain/entities/note_page.dart';
import 'package:kumo_note/features/page/domain/repositories/page_repository.dart';

final class LocalPageRepository implements PageRepository {
  const LocalPageRepository({
    required this.store,
  });

  final KeyValueStore store;

  @override
  Future<List<NotePage>> getActivePages(String notebookId) async {
    final pages = await _readAll();

    return pages
        .where(
          (page) => page.notebookId == notebookId && !page.isDeleted,
        )
        .toList()
      ..sort(_comparePages);
  }

  @override
  Future<List<NotePage>> getDeletedPages(String notebookId) async {
    final pages = await _readAll();

    return pages
        .where(
          (page) => page.notebookId == notebookId && page.isDeleted,
        )
        .toList()
      ..sort((first, second) {
        return second.deletedAt!.compareTo(first.deletedAt!);
      });
  }

  @override
  Future<NotePage?> getById(String pageId) async {
    final pages = await _readAll();

    for (final page in pages) {
      if (page.id == pageId) {
        return page;
      }
    }

    return null;
  }

  @override
  Future<void> save(NotePage page) async {
    await saveAll([page]);
  }

  @override
  Future<void> saveAll(List<NotePage> pages) async {
    final storedPages = await _readAll();

    for (final page in pages) {
      final existingIndex = storedPages.indexWhere(
        (item) => item.id == page.id,
      );

      if (existingIndex == -1) {
        storedPages.add(page);
      } else {
        storedPages[existingIndex] = page;
      }
    }

    await _writeAll(storedPages);
  }

  @override
  Future<void> purge(String pageId) async {
    final pages = await _readAll()
      ..removeWhere((page) => page.id == pageId);

    await _writeAll(pages);
  }

  Future<List<NotePage>> _readAll() async {
    final rawValue = await store.readString(
      PersistenceKey.pages,
    );

    if (rawValue == null || rawValue.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawValue);

    if (decoded is! List<Object?>) {
      throw const FormatException(
        'Stored pages must be a JSON list.',
      );
    }

    return decoded.map((item) {
      if (item is! Map<String, Object?>) {
        throw const FormatException(
          'Stored page must be a JSON object.',
        );
      }

      return PageRecord.fromJson(item).toDomain();
    }).toList();
  }

  Future<void> _writeAll(List<NotePage> pages) async {
    final records = pages
        .map(PageRecord.fromDomain)
        .map((record) => record.toJson())
        .toList(growable: false);

    await store.writeString(
      PersistenceKey.pages,
      jsonEncode(records),
    );
  }

  int _comparePages(NotePage first, NotePage second) {
    final orderComparison = first.sortOrder.compareTo(
      second.sortOrder,
    );

    if (orderComparison != 0) {
      return orderComparison;
    }

    return first.createdAt.compareTo(second.createdAt);
  }
}