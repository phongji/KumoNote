enum PersistenceKey {
  notebooks,
  pages,
  folders,
  settings,
  lastSession,
  recoveryJournal,
}

abstract interface class KeyValueStore {
  Future<String?> readString(PersistenceKey key);

  Future<void> writeString(
    PersistenceKey key,
    String value,
  );

  Future<void> remove(PersistenceKey key);

  Future<bool> contains(PersistenceKey key);
}