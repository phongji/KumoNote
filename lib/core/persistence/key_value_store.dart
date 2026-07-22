// Copy all content into key_value_store.dart.
enum PersistenceKey {
  notebooks,
  pages,
  strokes,
  textObjects,
  imageObjects,
  folders,
  settings,
  lastSession,
  recoveryJournal,
}

abstract interface class KeyValueStore {
  Future<String?> readString(PersistenceKey key);

  Future<void> writeString(PersistenceKey key, String value);

  Future<void> remove(PersistenceKey key);

  Future<bool> contains(PersistenceKey key);
}
