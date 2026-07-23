import 'dart:typed_data';

import 'package:idb_shim/idb_browser.dart';

final class WebPdfDataStore {
  WebPdfDataStore();

  static const _databaseName = 'kumo_note_pdf_assets';
  static const _storeName = 'documents';
  static const _databaseVersion = 1;

  Database? _database;

  Future<void> save({
    required String storageKey,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'PDF data cannot be empty.');
    }

    final database = await _openDatabase();
    final transaction = database.transaction(_storeName, idbModeReadWrite);

    await transaction.objectStore(_storeName).put(bytes, storageKey);
    await transaction.completed;
  }

  Future<Uint8List?> read(String storageKey) async {
    final database = await _openDatabase();
    final transaction = database.transaction(_storeName, idbModeReadOnly);
    final value = await transaction
        .objectStore(_storeName)
        .getObject(storageKey);

    await transaction.completed;

    if (value is Uint8List) {
      return value;
    }

    if (value is ByteBuffer) {
      return value.asUint8List();
    }

    if (value is List<int>) {
      return Uint8List.fromList(value);
    }

    return null;
  }

  Future<void> delete(String storageKey) async {
    final database = await _openDatabase();
    final transaction = database.transaction(_storeName, idbModeReadWrite);

    await transaction.objectStore(_storeName).delete(storageKey);
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
