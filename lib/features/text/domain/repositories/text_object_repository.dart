import '../entities/text_object.dart';

abstract interface class TextObjectRepository {
  Future<List<TextObject>> getObjectsForPage(String pageId);

  Future<List<TextObject>> search(String query);

  Future<TextObject?> getById(String objectId);

  Future<void> save(TextObject object);

  Future<void> saveAll(List<TextObject> objects);

  Future<void> delete(String objectId);

  Future<void> deleteForPage(String pageId);
}
