import 'package:kumo_note/features/library/domain/entities/notebook.dart';
import 'package:kumo_note/features/library/domain/repositories/notebook_repository.dart';
import 'package:uuid/uuid.dart';

final class CreateNotebook {
  CreateNotebook({
    required this.repository,
    this.uuid = const Uuid(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const int _orderingGap = 1000;
  static const int _defaultCoverColor = 0xFF708C98;

  final NotebookRepository repository;
  final Uuid uuid;
  final DateTime Function() _now;

  Future<Notebook> call(String title) async {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Notebook title cannot be empty.',
      );
    }

    final existingNotebooks = await repository.getActiveNotebooks();
    final lastSortOrder = existingNotebooks.fold<int>(0, (
      currentMaximum,
      notebook,
    ) {
      return notebook.sortOrder > currentMaximum
          ? notebook.sortOrder
          : currentMaximum;
    });

    final timestamp = _now();

    final notebook = Notebook(
      id: uuid.v4(),
      title: cleanTitle,
      createdAt: timestamp,
      updatedAt: timestamp,
      version: 1,
      sortOrder: lastSortOrder + _orderingGap,
      isFavorite: false,
      coverColorValue: _defaultCoverColor,
    );

    await repository.save(notebook);

    return notebook;
  }
}
