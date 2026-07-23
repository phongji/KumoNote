import 'dart:convert';

import 'package:kumo_note/core/persistence/key_value_store.dart';

import '../../domain/entities/image_object.dart';
import '../../domain/repositories/image_object_repository.dart';
import '../models/image_object_record.dart';
import '../storage/web_image_data_store.dart';

final class LocalImageObjectRepository implements ImageObjectRepository {
  const LocalImageObjectRepository({
    required this.store,
    required this.imageDataStore,
  });

  static const _indexedDbPrefix = 'indexeddb:';

  final KeyValueStore store;
  final WebImageDataStore imageDataStore;

  @override
  Future<List<ImageObject>> getByPageId(String pageId) async {
    final objects = await _readAll();

    return objects.where((object) => object.pageId == pageId).toList()
      ..sort((first, second) {
        return first.createdAt.compareTo(second.createdAt);
      });
  }

  @override
  Future<Map<String, List<ImageObject>>> getByPageIds(
    Set<String> pageIds,
  ) async {
    final grouped = <String, List<ImageObject>>{
      for (final pageId in pageIds) pageId: <ImageObject>[],
    };

    if (pageIds.isEmpty) {
      return grouped;
    }

    final objects = await _readAll();

    for (final object in objects) {
      grouped[object.pageId]?.add(object);
    }

    for (final pageObjects in grouped.values) {
      pageObjects.sort(
        (first, second) => first.createdAt.compareTo(second.createdAt),
      );
    }

    return grouped;
  }

  @override
  Future<ImageObject?> getById(String objectId) async {
    final objects = await _readAll();

    for (final object in objects) {
      if (object.id == objectId) {
        return object;
      }
    }

    return null;
  }

  @override
  Future<void> save(ImageObject object) async {
    await saveAll([object]);
  }

  @override
  Future<void> saveAll(List<ImageObject> objects) async {
    final storedObjects = await _readAll();

    for (final object in objects) {
      final existingIndex = storedObjects.indexWhere(
        (storedObject) => storedObject.id == object.id,
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
    await imageDataStore.delete(objectId);
  }

  @override
  Future<void> clearPage(String pageId) async {
    final objects = await _readAll();
    final removedIds = objects
        .where((object) => object.pageId == pageId)
        .map((object) => object.id)
        .toList(growable: false);

    objects.removeWhere((object) => object.pageId == pageId);
    await _writeAll(objects);

    for (final objectId in removedIds) {
      await imageDataStore.delete(objectId);
    }
  }

  Future<List<ImageObject>> _readAll() async {
    final rawValue = await store.readString(PersistenceKey.imageObjects);

    if (rawValue == null || rawValue.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawValue);

    if (decoded is! List<Object?>) {
      throw const FormatException('Stored images must be a JSON list.');
    }

    final objects = <ImageObject>[];

    for (final item in decoded) {
      if (item is! Map<String, Object?>) {
        throw const FormatException('Stored image must be a JSON object.');
      }

      final json = Map<String, Object?>.from(item);
      final originalPath = json['originalPath'];

      if (originalPath is String && originalPath.startsWith(_indexedDbPrefix)) {
        final imageId = originalPath.substring(_indexedDbPrefix.length);
        final dataUrl = await imageDataStore.read(imageId);

        if (dataUrl == null || dataUrl.isEmpty) {
          continue;
        }

        json['originalPath'] = dataUrl;
      }

      objects.add(ImageObjectRecord.fromJson(json).toDomain());
    }

    return objects;
  }

  Future<void> _writeAll(List<ImageObject> objects) async {
    final jsonObjects = <Map<String, Object?>>[];

    for (final object in objects) {
      final json = ImageObjectRecord.fromDomain(object).toJson();

      if (object.originalPath.startsWith('data:')) {
        await imageDataStore.save(
          imageId: object.id,
          dataUrl: object.originalPath,
        );
        json['originalPath'] = '$_indexedDbPrefix${object.id}';
      }

      jsonObjects.add(json);
    }

    await store.writeString(
      PersistenceKey.imageObjects,
      jsonEncode(jsonObjects),
    );
  }
}
