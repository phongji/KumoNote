import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';

import '../../../drawing/data/models/ink_stroke_record.dart';
import '../../../drawing/domain/repositories/ink_repository.dart';
import '../../../image/data/models/image_object_record.dart';
import '../../../image/domain/repositories/image_object_repository.dart';
import '../../../library/data/models/notebook_record.dart';
import '../../../library/domain/entities/notebook.dart';
import '../../../library/domain/repositories/notebook_repository.dart';
import '../../../page/data/models/page_record.dart';
import '../../../page/domain/repositories/page_repository.dart';
import '../../../pdf/data/models/pdf_document_record.dart';
import '../../../pdf/domain/entities/pdf_document_entity.dart';
import '../../../pdf/domain/repositories/pdf_document_repository.dart';
import '../../../text/data/models/text_object_record.dart';
import '../../../text/domain/repositories/text_object_repository.dart';
import '../models/native_backup_preview.dart';
import 'native_backup_inspector.dart';

final class NativeRestoreService {
  const NativeRestoreService({
    required this.notebookRepository,
    required this.pageRepository,
    required this.inkRepository,
    required this.textRepository,
    required this.imageRepository,
    required this.pdfRepository,
    this.uuid = const Uuid(),
  });

  final NotebookRepository notebookRepository;
  final PageRepository pageRepository;
  final InkRepository inkRepository;
  final TextObjectRepository textRepository;
  final ImageObjectRepository imageRepository;
  final PdfDocumentRepository pdfRepository;
  final Uuid uuid;

  Future<Notebook> restoreAsCopy({
    required NativeBackupPreview preview,
    required String restoredTitle,
    void Function(String stage)? onStageChanged,
  }) async {
    onStageChanged?.call('verify');

    final verifiedPreview = const NativeBackupInspector().inspect(
      fileName: preview.fileName,
      bytes: preview.packageBytes,
    );
    final files = _readArchiveFiles(verifiedPreview.packageBytes);
    final now = DateTime.now().toUtc();

    onStageChanged?.call('prepare');

    final activeNotebooks = await notebookRepository.getActiveNotebooks();
    var highestSortOrder = 0;

    for (final notebook in activeNotebooks) {
      if (notebook.sortOrder > highestSortOrder) {
        highestSortOrder = notebook.sortOrder;
      }
    }

    final notebookJson = _readJsonObject(files, 'data/notebook.json');
    final newNotebookId = uuid.v4();

    notebookJson
      ..['id'] = newNotebookId
      ..['title'] = restoredTitle.trim().isEmpty
          ? '${verifiedPreview.manifest.notebookTitle} (Restored)'
          : restoredTitle.trim()
      ..['folderId'] = null
      ..['createdAt'] = now.toIso8601String()
      ..['updatedAt'] = now.toIso8601String()
      ..['deletedAt'] = null
      ..['version'] = 1
      ..['sortOrder'] = highestSortOrder + 1000;

    final restoredNotebook = NotebookRecord.fromJson(notebookJson).toDomain();
    final pageJsonItems = _readJsonObjectList(files, 'data/pages.json');
    final pdfJsonItems = _readJsonObjectList(files, 'data/pdf_documents.json');
    final pageIdMap = <String, String>{
      for (final json in pageJsonItems) json['id']! as String: uuid.v4(),
    };
    final pdfIdMap = <String, String>{
      for (final json in pdfJsonItems) json['id']! as String: uuid.v4(),
    };
    final restoredPages = pageJsonItems
        .map((json) {
          final oldPageId = json['id']! as String;
          final oldPdfDocumentId = json['pdfDocumentId'] as String?;

          json
            ..['id'] = pageIdMap[oldPageId]
            ..['notebookId'] = newNotebookId
            ..['sectionId'] = null
            ..['createdAt'] = now.toIso8601String()
            ..['updatedAt'] = now.toIso8601String()
            ..['version'] = 1;

          if (oldPdfDocumentId != null) {
            final newPdfDocumentId = pdfIdMap[oldPdfDocumentId];

            if (newPdfDocumentId == null) {
              throw const FormatException(
                'A restored page refers to a missing PDF document.',
              );
            }

            json['pdfDocumentId'] = newPdfDocumentId;
          }

          return PageRecord.fromJson(json).toDomain();
        })
        .toList(growable: false);
    final restoredPdfAssets = pdfJsonItems
        .map((json) {
          final oldDocumentId = json['id']! as String;
          final newDocumentId = pdfIdMap[oldDocumentId]!;
          final assetPath = json['backupAssetPath'] as String?;

          if (assetPath == null) {
            throw const FormatException(
              'A PDF document is missing its backup asset path.',
            );
          }

          final bytes = files[assetPath];

          if (bytes == null || bytes.isEmpty) {
            throw FormatException(
              'The backup is missing PDF asset "$assetPath".',
            );
          }

          json
            ..['id'] = newDocumentId
            ..['notebookId'] = newNotebookId
            ..['storageKey'] = 'pdf:$newDocumentId'
            ..['createdAt'] = now.toIso8601String()
            ..['updatedAt'] = now.toIso8601String()
            ..['version'] = 1
            ..remove('backupAssetPath');

          return _RestoredPdfAsset(
            document: PdfDocumentRecord.fromJson(json).toDomain(),
            bytes: bytes,
          );
        })
        .toList(growable: false);
    final restoredStrokes = _readJsonObjectList(files, 'data/strokes.json')
        .map((json) {
          final oldPageId = json['pageId']! as String;
          final newPageId = pageIdMap[oldPageId];

          if (newPageId == null) {
            throw const FormatException('A stroke refers to a missing page.');
          }

          json
            ..['id'] = uuid.v4()
            ..['pageId'] = newPageId;

          return InkStrokeRecord.fromJson(json).toDomain();
        })
        .toList(growable: false);
    final restoredTexts = _readJsonObjectList(files, 'data/text_objects.json')
        .map((json) {
          final oldPageId = json['pageId']! as String;
          final newPageId = pageIdMap[oldPageId];

          if (newPageId == null) {
            throw const FormatException(
              'A text object refers to a missing page.',
            );
          }

          json
            ..['id'] = uuid.v4()
            ..['pageId'] = newPageId
            ..['updatedAt'] = now.toIso8601String()
            ..['version'] = 1;

          return TextObjectRecord.fromJson(json).toDomain();
        })
        .toList(growable: false);
    final restoredImages = _readJsonObjectList(files, 'data/image_objects.json')
        .map((json) {
          final oldPageId = json['pageId']! as String;
          final newPageId = pageIdMap[oldPageId];
          final originalPath = json['originalPath'] as String?;
          final dataUrlPrefix = json['backupDataUrlPrefix'] as String?;

          if (newPageId == null) {
            throw const FormatException(
              'An image object refers to a missing page.',
            );
          }

          if (originalPath == null ||
              !originalPath.startsWith('backup:') ||
              dataUrlPrefix == null) {
            throw const FormatException(
              'An image object is missing its backup asset.',
            );
          }

          final assetPath = originalPath.substring('backup:'.length);
          final assetBytes = files[assetPath];

          if (assetBytes == null || assetBytes.isEmpty) {
            throw FormatException(
              'The backup is missing image asset "$assetPath".',
            );
          }

          json
            ..['id'] = uuid.v4()
            ..['pageId'] = newPageId
            ..['originalPath'] = '$dataUrlPrefix${base64Encode(assetBytes)}'
            ..['updatedAt'] = now.toIso8601String()
            ..['version'] = 1
            ..remove('backupDataUrlPrefix');

          return ImageObjectRecord.fromJson(json).toDomain();
        })
        .toList(growable: false);

    onStageChanged?.call('restore');

    final createdPageIds = <String>[];
    final createdStrokeIds = <String>[];
    final createdTextIds = <String>[];
    final createdImageIds = <String>[];
    final createdPdfIds = <String>[];
    var notebookWasSaved = false;

    try {
      await notebookRepository.save(restoredNotebook);
      notebookWasSaved = true;

      for (final asset in restoredPdfAssets) {
        await pdfRepository.save(document: asset.document, bytes: asset.bytes);
        createdPdfIds.add(asset.document.id);
      }

      await pageRepository.saveAll(restoredPages);
      createdPageIds.addAll(restoredPages.map((page) => page.id));

      if (restoredStrokes.isNotEmpty) {
        await inkRepository.saveAll(restoredStrokes);
        createdStrokeIds.addAll(restoredStrokes.map((stroke) => stroke.id));
      }

      if (restoredTexts.isNotEmpty) {
        await textRepository.saveAll(restoredTexts);
        createdTextIds.addAll(restoredTexts.map((text) => text.id));
      }

      if (restoredImages.isNotEmpty) {
        await imageRepository.saveAll(restoredImages);
        createdImageIds.addAll(restoredImages.map((image) => image.id));
      }
    } catch (error, stackTrace) {
      await _rollback(
        notebookId: notebookWasSaved ? newNotebookId : null,
        pageIds: createdPageIds,
        strokeIds: createdStrokeIds,
        textIds: createdTextIds,
        imageIds: createdImageIds,
        pdfIds: createdPdfIds,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }

    onStageChanged?.call('complete');
    return restoredNotebook;
  }

  Map<String, Uint8List> _readArchiveFiles(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    return {
      for (final entry in archive.files)
        if (entry.isFile) entry.name: entry.content,
    };
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

  List<Map<String, Object?>> _readJsonObjectList(
    Map<String, Uint8List> files,
    String path,
  ) {
    final decoded = _readJson(files, path);

    if (decoded is! List) {
      throw FormatException('"$path" must contain a JSON list.');
    }

    return decoded
        .map((item) {
          if (item is! Map) {
            throw FormatException('"$path" contains an invalid record.');
          }

          return Map<String, Object?>.from(item);
        })
        .toList(growable: false);
  }

  Object? _readJson(Map<String, Uint8List> files, String path) {
    final bytes = files[path];

    if (bytes == null) {
      throw FormatException('The backup is missing "$path".');
    }

    return jsonDecode(utf8.decode(bytes));
  }

  Future<void> _rollback({
    required String? notebookId,
    required List<String> pageIds,
    required List<String> strokeIds,
    required List<String> textIds,
    required List<String> imageIds,
    required List<String> pdfIds,
  }) async {
    for (final imageId in imageIds.reversed) {
      await _ignoreFailure(() => imageRepository.delete(imageId));
    }

    for (final textId in textIds.reversed) {
      await _ignoreFailure(() => textRepository.delete(textId));
    }

    for (final strokeId in strokeIds.reversed) {
      await _ignoreFailure(() => inkRepository.delete(strokeId));
    }

    for (final pageId in pageIds.reversed) {
      await _ignoreFailure(() => pageRepository.purge(pageId));
    }

    for (final pdfId in pdfIds.reversed) {
      await _ignoreFailure(() => pdfRepository.delete(pdfId));
    }

    if (notebookId != null) {
      await _ignoreFailure(() => notebookRepository.purge(notebookId));
    }
  }

  Future<void> _ignoreFailure(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Continue rollback for the remaining records.
    }
  }
}

final class _RestoredPdfAsset {
  const _RestoredPdfAsset({required this.document, required this.bytes});

  final PdfDocumentEntity document;
  final Uint8List bytes;
}
