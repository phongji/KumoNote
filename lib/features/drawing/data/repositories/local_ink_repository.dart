import 'dart:convert';

import 'package:kumo_note/core/persistence/key_value_store.dart';
import 'package:kumo_note/features/drawing/data/models/ink_stroke_record.dart';
import 'package:kumo_note/features/drawing/domain/entities/ink_stroke.dart';
import 'package:kumo_note/features/drawing/domain/repositories/ink_repository.dart';

final class LocalInkRepository implements InkRepository {
  const LocalInkRepository({required this.store});

  final KeyValueStore store;

  @override
  Future<List<InkStroke>> getStrokes(String pageId) async {
    final strokes = await _readAll();

    return strokes.where((stroke) => stroke.pageId == pageId).toList()
      ..sort((first, second) {
        return first.createdAt.compareTo(second.createdAt);
      });
  }

  @override
  Future<InkStroke?> getById(String strokeId) async {
    final strokes = await _readAll();

    for (final stroke in strokes) {
      if (stroke.id == strokeId) {
        return stroke;
      }
    }

    return null;
  }

  @override
  Future<void> save(InkStroke stroke) async {
    await saveAll([stroke]);
  }

  @override
  Future<void> saveAll(List<InkStroke> strokes) async {
    final storedStrokes = await _readAll();

    for (final stroke in strokes) {
      final existingIndex = storedStrokes.indexWhere(
        (item) => item.id == stroke.id,
      );

      if (existingIndex == -1) {
        storedStrokes.add(stroke);
      } else {
        storedStrokes[existingIndex] = stroke;
      }
    }

    await _writeAll(storedStrokes);
  }

  @override
  Future<void> delete(String strokeId) async {
    final strokes = await _readAll()
      ..removeWhere((stroke) => stroke.id == strokeId);

    await _writeAll(strokes);
  }

  @override
  Future<void> clearPage(String pageId) async {
    final strokes = await _readAll()
      ..removeWhere((stroke) => stroke.pageId == pageId);

    await _writeAll(strokes);
  }

  Future<List<InkStroke>> _readAll() async {
    final rawValue = await store.readString(PersistenceKey.strokes);

    if (rawValue == null || rawValue.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawValue);

    if (decoded is! List<Object?>) {
      throw const FormatException('Stored strokes must be a JSON list.');
    }

    return decoded.map((item) {
      if (item is! Map<String, Object?>) {
        throw const FormatException('Stored stroke must be a JSON object.');
      }

      return InkStrokeRecord.fromJson(item).toDomain();
    }).toList();
  }

  Future<void> _writeAll(List<InkStroke> strokes) async {
    final records = strokes
        .map(InkStrokeRecord.fromDomain)
        .map((record) => record.toJson())
        .toList(growable: false);

    await store.writeString(PersistenceKey.strokes, jsonEncode(records));
  }
}
