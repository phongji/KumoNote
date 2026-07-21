import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/application/providers/library_providers.dart';
import '../../data/repositories/local_page_repository.dart';
import '../../domain/entities/note_page.dart';
import '../../domain/repositories/page_repository.dart';
import '../use_cases/create_page.dart';
import '../use_cases/delete_page_forever.dart';
import '../use_cases/move_page_to_trash.dart';
import '../use_cases/restore_page.dart';

final pageRepositoryProvider = Provider<PageRepository>((ref) {
  final store = ref.watch(keyValueStoreProvider);

  return LocalPageRepository(store: store);
});

final createPageProvider = Provider<CreatePage>((ref) {
  return CreatePage(repository: ref.watch(pageRepositoryProvider));
});

final movePageToTrashProvider = Provider<MovePageToTrash>((ref) {
  return MovePageToTrash(repository: ref.watch(pageRepositoryProvider));
});

final restorePageProvider = Provider<RestorePage>((ref) {
  return RestorePage(repository: ref.watch(pageRepositoryProvider));
});

final deletePageForeverProvider = Provider<DeletePageForever>((ref) {
  return DeletePageForever(repository: ref.watch(pageRepositoryProvider));
});

final activePageListProvider = FutureProvider.family<List<NotePage>, String>((
  ref,
  notebookId,
) {
  return ref.watch(pageRepositoryProvider).getActivePages(notebookId);
});

final deletedPageListProvider = FutureProvider.family<List<NotePage>, String>((
  ref,
  notebookId,
) {
  return ref.watch(pageRepositoryProvider).getDeletedPages(notebookId);
});
