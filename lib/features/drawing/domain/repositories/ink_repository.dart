import '../entities/ink_stroke.dart';

abstract interface class InkRepository {
  Future<List<InkStroke>> getStrokes(String pageId);

  Future<InkStroke?> getById(String strokeId);

  Future<void> save(InkStroke stroke);

  Future<void> saveAll(List<InkStroke> strokes);

  Future<void> delete(String strokeId);

  Future<void> clearPage(String pageId);
}
