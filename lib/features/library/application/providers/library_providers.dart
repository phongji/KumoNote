import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumo_note/core/persistence/key_value_store.dart';
import 'package:kumo_note/core/persistence/shared_preferences_store.dart';
import 'package:kumo_note/features/library/application/use_cases/create_notebook.dart';
import 'package:kumo_note/features/library/data/repositories/local_notebook_repository.dart';
import 'package:kumo_note/features/library/domain/entities/notebook.dart';
import 'package:kumo_note/features/library/domain/repositories/notebook_repository.dart';

final keyValueStoreProvider = Provider<KeyValueStore>((ref) {
  return SharedPreferencesStore();
});

final notebookRepositoryProvider = Provider<NotebookRepository>((ref) {
  return LocalNotebookRepository(store: ref.watch(keyValueStoreProvider));
});

final createNotebookProvider = Provider<CreateNotebook>((ref) {
  return CreateNotebook(repository: ref.watch(notebookRepositoryProvider));
});

final notebookListProvider =
    AsyncNotifierProvider<NotebookListController, List<Notebook>>(
      NotebookListController.new,
    );

final class NotebookListController extends AsyncNotifier<List<Notebook>> {
  NotebookRepository get _repository {
    return ref.read(notebookRepositoryProvider);
  }

  @override
  Future<List<Notebook>> build() {
    return _repository.getActiveNotebooks();
  }

  Future<void> createNotebook(String title) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(createNotebookProvider).call(title);
      return _repository.getActiveNotebooks();
    });
  }

  Future<void> renameNotebook({
    required String notebookId,
    required String newTitle,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final notebook = await _requireNotebook(notebookId);
      final renamedNotebook = notebook.rename(
        newTitle: newTitle,
        now: DateTime.now(),
      );

      await _repository.save(renamedNotebook);
      return _repository.getActiveNotebooks();
    });
  }

  Future<void> toggleFavorite(String notebookId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final notebook = await _requireNotebook(notebookId);
      final updatedNotebook = notebook.toggleFavorite(now: DateTime.now());

      await _repository.save(updatedNotebook);
      return _repository.getActiveNotebooks();
    });
  }

  Future<void> moveToTrash(String notebookId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final notebook = await _requireNotebook(notebookId);
      final deletedNotebook = notebook.moveToTrash(now: DateTime.now());

      await _repository.save(deletedNotebook);
      return _repository.getActiveNotebooks();
    });
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getActiveNotebooks);
  }

  Future<Notebook> _requireNotebook(String notebookId) async {
    final notebook = await _repository.getById(notebookId);

    if (notebook == null) {
      throw StateError('Notebook was not found.');
    }

    return notebook;
  }
}
