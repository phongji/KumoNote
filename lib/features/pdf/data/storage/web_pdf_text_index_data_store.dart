import 'package:idb_shim/idb_browser.dart';

import '../models/pdf_page_text_index_record.dart';

final class WebPdfTextIndexDataStore {
  WebPdfTextIndexDataStore();

  static const _databaseName = 'kumo_note_pdf_text_index';
  static const _storeName = 'pages';
  static const _databaseVersion = 1;

  Database? _database;

  Future<List<PdfPageTextIndexRecord>> readAll() async {
    final entries = await _readEntries();

    return entries
        .map((entry) {
          return PdfPageTextIndexRecord.fromJson(entry.value);
        })
        .toList(growable: false);
  }

  Future<void> replaceForDocument({
    required String documentId,
    required List<PdfPageTextIndexRecord> records,
  }) async {
    final existingEntries = await _readEntries();
    final database = await _openDatabase();
    final transaction = database.transaction(_storeName, idbModeReadWrite);
    final store = transaction.objectStore(_storeName);

    for (final entry in existingEntries) {
      if (entry.value['documentId'] == documentId) {
        await store.delete(entry.key);
      }
    }

    for (final record in records) {
      final key = '${record.documentId}:${record.pageNumber}';

      await store.put(record.toJson(), key);
    }

    await transaction.completed;
  }

  Future<void> deleteForDocument(String documentId) async {
    await replaceForDocument(documentId: documentId, records: const []);
  }

  Future<List<({Object key, Map<String, Object?> value})>>
  _readEntries() async {
    final database = await _openDatabase();
    final transaction = database.transaction(_storeName, idbModeReadOnly);
    final store = transaction.objectStore(_storeName);
    final valuesFuture = store.getAll();
    final keysFuture = store.getAllKeys();
    final results = await Future.wait([valuesFuture, keysFuture]);

    await transaction.completed;

    final values = results[0];
    final keys = results[1];
    final entries = <({Object key, Map<String, Object?> value})>[];

    for (var index = 0; index < values.length; index++) {
      final value = values[index];

      if (value is! Map) {
        continue;
      }

      entries.add((key: keys[index], value: Map<String, Object?>.from(value)));
    }

    return entries;
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
