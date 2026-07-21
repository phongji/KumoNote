import '../../domain/entities/note_page.dart';
import '../../domain/repositories/page_repository.dart';

final class RestorePage {
  RestorePage({required this.repository, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final PageRepository repository;
  final DateTime Function() _now;

  Future<NotePage> call(String pageId) async {
    final normalizedPageId = pageId.trim();

    if (normalizedPageId.isEmpty) {
      throw ArgumentError.value(pageId, 'pageId', 'Page ID must not be empty.');
    }

    final page = await repository.getById(normalizedPageId);

    if (page == null) {
      throw StateError('Page not found.');
    }

    final restoredPage = page.restore(now: _now().toUtc());

    await repository.save(restoredPage);

    return restoredPage;
  }
}
