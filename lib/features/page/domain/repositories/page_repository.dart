import 'package:kumo_note/features/page/domain/entities/note_page.dart';

abstract interface class PageRepository {
  Future<List<NotePage>> getActivePages(String notebookId);

  Future<List<NotePage>> getDeletedPages(String notebookId);

  Future<NotePage?> getById(String pageId);

  Future<void> save(NotePage page);

  Future<void> saveAll(List<NotePage> pages);

  Future<void> purge(String pageId);
}