// Copy all content into text_object_repository.dart.
import '../entities/text_object.dart';

abstract interface class TextObjectRepository {
  Future<List<TextObject>> getObjectsForPage(String pageId);

  Future<TextObject?> getById(String objectId);

  Future<void> save(TextObject object);

  Future<void> saveAll(List<TextObject> objects);

  Future<void> delete(String objectId);

  Future<void> deleteForPage(String pageId);
}
