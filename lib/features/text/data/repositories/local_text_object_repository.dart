import 'dart:convert';

import '../../../../core/persistence/key_value_store.dart';
import '../../domain/entities/text_object.dart';
import '../../domain/repositories/text_object_repository.dart';
import '../models/text_object_record.dart';

final class LocalTextObjectRepository implements TextObjectRepository {
  const LocalTextObjectRepository({required this.store});

  final KeyValueStore store;

  @override
  Future<List<TextObject>> getObjectsForPage(String pageId) async {
    final objects = await _readAll();

    return objects.where((object) => object.pageId == pageId).toList()
      ..sort((first, second) {
        return first.createdAt.compareTo(second.createdAt);
      });
  }

  @override
  Future<List<TextObject>> search(String query) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final objects = await _readAll();
    final matches = objects.where((object) {
      return object.plainText.toLowerCase().contains(normalizedQuery);
    }).toList();

    matches.sort((first, second) {
      return second.updatedAt.compareTo(first.updatedAt);
    });

    return matches;
  }

  @override
  Future<TextObject?> getById(String objectId) async {
    final objects = await _readAll();

    for (final object in objects) {
      if (object.id == objectId) {
        return object;
      }
    }

    return null;
  }

  @override
  Future<void> save(TextObject object) async {
    await saveAll([object]);
  }

  @override
  Future<void> saveAll(List<TextObject> objects) async {
    final storedObjects = await _readAll();

    for (final object in objects) {
      final existingIndex = storedObjects.indexWhere(
        (item) => item.id == object.id,
      );

      if (existingIndex == -1) {
        storedObjects.add(object);
      } else {
        storedObjects[existingIndex] = object;
      }
    }

    await _writeAll(storedObjects);
  }

  @override
  Future<void> delete(String objectId) async {
    final objects = await _readAll()
      ..removeWhere((object) => object.id == objectId);

    await _writeAll(objects);
  }

  @override
  Future<void> deleteForPage(String pageId) async {
    final objects = await _readAll()
      ..removeWhere((object) => object.pageId == pageId);

    await _writeAll(objects);
  }

  Future<List<TextObject>> _readAll() async {
    final rawValue = await store.readString(PersistenceKey.textObjects);

    if (rawValue == null || rawValue.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawValue);

    if (decoded is! List<Object?>) {
      throw const FormatException('Stored text objects must be a JSON list.');
    }

    return decoded.map((item) {
      if (item is! Map<String, Object?>) {
        throw const FormatException(
          'Stored text object must be a JSON object.',
        );
      }

      return TextObjectRecord.fromJson(item).toDomain();
    }).toList();
  }

  Future<void> _writeAll(List<TextObject> objects) async {
    final records = objects
        .map(TextObjectRecord.fromDomain)
        .map((record) => record.toJson())
        .toList(growable: false);

    await store.writeString(PersistenceKey.textObjects, jsonEncode(records));
  }
}
