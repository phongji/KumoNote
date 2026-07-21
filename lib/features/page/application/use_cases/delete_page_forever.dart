import '../../domain/repositories/page_repository.dart';

final class DeletePageForever {
  const DeletePageForever({required this.repository});

  final PageRepository repository;

  Future<void> call(String pageId) async {
    final normalizedPageId = pageId.trim();

    if (normalizedPageId.isEmpty) {
      throw ArgumentError.value(pageId, 'pageId', 'Page ID must not be empty.');
    }

    final page = await repository.getById(normalizedPageId);

    if (page == null) {
      throw StateError('Page not found.');
    }

    if (page.deletedAt == null) {
      throw StateError(
        'Move the page to trash before deleting it permanently.',
      );
    }

    await repository.purge(normalizedPageId);
  }
}
