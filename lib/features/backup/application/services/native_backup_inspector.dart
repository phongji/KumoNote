import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';

import '../../domain/entities/native_backup_manifest.dart';
import '../models/native_backup_preview.dart';

final class NativeBackupInspector {
  const NativeBackupInspector();

  static const int maximumBackupBytes = 1024 * 1024 * 1024;

  Future<NativeBackupPreview?> pickAndInspect() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['kumo'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw StateError('The selected backup could not be read.');
    }

    if (bytes.length > maximumBackupBytes) {
      throw StateError('The selected backup is larger than 1 GB.');
    }

    return inspect(fileName: file.name, bytes: bytes);
  }

  NativeBackupPreview inspect({
    required String fileName,
    required Uint8List bytes,
  }) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final files = <String, Uint8List>{};

    for (final entry in archive.files) {
      if (!entry.isFile) {
        continue;
      }

      _validateEntryPath(entry.name);

      if (files.containsKey(entry.name)) {
        throw const FormatException(
          'The backup contains duplicate file names.',
        );
      }

      files[entry.name] = entry.content;
    }

    final manifestJson = _readJsonObject(files, 'manifest.json');
    final manifest = NativeBackupManifest.fromJson(manifestJson);

    if (!manifest.isSupported) {
      throw const FormatException(
        'This backup version is not supported by this app.',
      );
    }

    _verifyIntegrity(files: files, manifest: manifest);

    final pages = _readJsonList(files, 'data/pages.json');
    final strokes = _readJsonList(files, 'data/strokes.json');
    final texts = _readJsonList(files, 'data/text_objects.json');
    final images = _readJsonList(files, 'data/image_objects.json');
    final pdfDocuments = _readJsonList(files, 'data/pdf_documents.json');
    _readJsonObject(files, 'data/notebook.json');

    return NativeBackupPreview(
      fileName: fileName,
      packageBytes: Uint8List.fromList(bytes),
      manifest: manifest,
      pageCount: pages.length,
      strokeCount: strokes.length,
      textObjectCount: texts.length,
      imageObjectCount: images.length,
      pdfDocumentCount: pdfDocuments.length,
    );
  }

  void _verifyIntegrity({
    required Map<String, Uint8List> files,
    required NativeBackupManifest manifest,
  }) {
    if (manifest.fileChecksums.isEmpty) {
      throw const FormatException(
        'The backup does not contain integrity information.',
      );
    }

    for (final entry in manifest.fileChecksums.entries) {
      final bytes = files[entry.key];

      if (bytes == null) {
        throw FormatException('The backup is missing "${entry.key}".');
      }

      final actualChecksum = sha256.convert(bytes).toString();

      if (actualChecksum != entry.value) {
        throw FormatException(
          'The backup integrity check failed for "${entry.key}".',
        );
      }
    }

    final listedFiles = {...manifest.fileChecksums.keys, 'manifest.json'};
    final unexpectedFiles = files.keys
        .where((path) => !listedFiles.contains(path))
        .toList(growable: false);

    if (unexpectedFiles.isNotEmpty) {
      throw const FormatException('The backup contains unexpected files.');
    }
  }

  Map<String, Object?> _readJsonObject(
    Map<String, Uint8List> files,
    String path,
  ) {
    final decoded = _readJson(files, path);

    if (decoded is! Map) {
      throw FormatException('"$path" must contain a JSON object.');
    }

    return Map<String, Object?>.from(decoded);
  }

  List<Object?> _readJsonList(Map<String, Uint8List> files, String path) {
    final decoded = _readJson(files, path);

    if (decoded is! List) {
      throw FormatException('"$path" must contain a JSON list.');
    }

    return List<Object?>.from(decoded);
  }

  Object? _readJson(Map<String, Uint8List> files, String path) {
    final bytes = files[path];

    if (bytes == null) {
      throw FormatException('The backup is missing "$path".');
    }

    return jsonDecode(utf8.decode(bytes));
  }

  void _validateEntryPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');

    if (path.isEmpty ||
        path.startsWith('/') ||
        path.contains('\\') ||
        segments.any((segment) => segment == '..' || segment.isEmpty)) {
      throw const FormatException('The backup contains an unsafe file path.');
    }
  }
}
