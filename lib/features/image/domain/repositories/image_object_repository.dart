import '../entities/image_object.dart';

abstract interface class ImageObjectRepository {
  Future<List<ImageObject>> getByPageId(String pageId);

  Future<Map<String, List<ImageObject>>> getByPageIds(Set<String> pageIds);

  Future<ImageObject?> getById(String objectId);

  Future<void> save(ImageObject object);

  Future<void> saveAll(List<ImageObject> objects);

  Future<void> delete(String objectId);

  Future<void> clearPage(String pageId);
}
