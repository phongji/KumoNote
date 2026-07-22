import 'package:idb_shim/idb_browser.dart';

final class WebImageDataStore {
  WebImageDataStore();

  static const _databaseName = 'kumo_note_assets';
  static const _storeName = 'images';
  static const _databaseVersion = 1;

  Database? _database;

  Future<void> save({required String imageId, required String dataUrl}) async {
    final database = await _openDatabase();
    final transaction = database.transaction(_storeName, idbModeReadWrite);

    await transaction.objectStore(_storeName).put(dataUrl, imageId);
    await transaction.completed;
  }

  Future<String?> read(String imageId) async {
    final database = await _openDatabase();
    final transaction = database.transaction(_storeName, idbModeReadOnly);
    final value = await transaction.objectStore(_storeName).getObject(imageId);

    await transaction.completed;

    return value is String ? value : null;
  }

  Future<void> delete(String imageId) async {
    final database = await _openDatabase();
    final transaction = database.transaction(_storeName, idbModeReadWrite);

    await transaction.objectStore(_storeName).delete(imageId);
    await transaction.completed;
  }

  Future<Database> _openDatabase() async {
    final existingDatabase = _database;

    if (existingDatabase != null) {
      return existingDatabase;
    }

    final database = await idbFactoryBrowser.open(
      _databaseName,
      version: _databaseVersion,
      onUpgradeNeeded: (event) {
        final database = event.database;

        if (!database.objectStoreNames.contains(_storeName)) {
          database.createObjectStore(_storeName);
        }
      },
    );

    _database = database;
    return database;
  }
}
