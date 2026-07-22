import 'package:uuid/uuid.dart';

import '../../domain/entities/note_page.dart';
import '../../domain/repositories/page_repository.dart';

final class CreatePage {
  CreatePage({
    required this.repository,
    this.uuid = const Uuid(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PageRepository repository;
  final Uuid uuid;
  final DateTime Function() _now;

  Future<NotePage> call({
    required String notebookId,
    String? sectionId,
    PageOrientation orientation = PageOrientation.portrait,
    PageTemplate template = PageTemplate.blank,
    PagePaperColor paperColor = PagePaperColor.paperWhite,
  }) async {
    final normalizedNotebookId = notebookId.trim();

    if (normalizedNotebookId.isEmpty) {
      throw ArgumentError.value(
        notebookId,
        'notebookId',
        'Notebook ID must not be empty.',
      );
    }

    final existingPages = await repository.getActivePages(normalizedNotebookId);

    var highestSortOrder = 0;

    for (final page in existingPages) {
      if (page.sortOrder > highestSortOrder) {
        highestSortOrder = page.sortOrder;
      }
    }

    final createdAt = _now().toUtc();
    final isPortrait = orientation == PageOrientation.portrait;

    final page = NotePage(
      id: uuid.v4(),
      notebookId: normalizedNotebookId,
      sectionId: sectionId,
      createdAt: createdAt,
      updatedAt: createdAt,
      deletedAt: null,
      version: 1,
      sortOrder: highestSortOrder + 1000,
      orientation: orientation,
      template: template,
      paperColor: paperColor,
      width: isPortrait ? 595 : 842,
      height: isPortrait ? 842 : 595,
      thumbnailPath: null,
    );

    await repository.save(page);

    return page;
  }
}
