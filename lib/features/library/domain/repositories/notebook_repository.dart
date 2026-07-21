import 'package:kumo_note/features/library/domain/entities/notebook.dart';

abstract interface class NotebookRepository {
  Future<List<Notebook>> getActiveNotebooks();

  Future<List<Notebook>> getDeletedNotebooks();

  Future<Notebook?> getById(String notebookId);

  Future<void> save(Notebook notebook);

  Future<void> purge(String notebookId);
}
