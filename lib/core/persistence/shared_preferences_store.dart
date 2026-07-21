import 'package:kumo_note/core/persistence/key_value_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SharedPreferencesStore implements KeyValueStore {
  static const String _keyPrefix = 'kumo.';

  String _storageKey(PersistenceKey key) {
    return '$_keyPrefix${key.name}';
  }

  Future<SharedPreferences> get _preferences {
    return SharedPreferences.getInstance();
  }

  @override
  Future<String?> readString(PersistenceKey key) async {
    final preferences = await _preferences;
    return preferences.getString(_storageKey(key));
  }

  @override
  Future<void> writeString(PersistenceKey key, String value) async {
    final preferences = await _preferences;
    final didSave = await preferences.setString(_storageKey(key), value);

    if (!didSave) {
      throw StateError('Unable to persist value.');
    }
  }

  @override
  Future<void> remove(PersistenceKey key) async {
    final preferences = await _preferences;
    final didRemove = await preferences.remove(_storageKey(key));

    if (!didRemove && preferences.containsKey(_storageKey(key))) {
      throw StateError('Unable to remove persisted value.');
    }
  }

  @override
  Future<bool> contains(PersistenceKey key) async {
    final preferences = await _preferences;
    return preferences.containsKey(_storageKey(key));
  }
}
