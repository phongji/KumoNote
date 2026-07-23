import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../drawing/data/models/ink_stroke_record.dart';
import '../../../drawing/domain/entities/ink_stroke.dart';
import '../../../drawing/domain/repositories/ink_repository.dart';
import '../../../image/data/models/image_object_record.dart';
import '../../../image/domain/entities/image_object.dart';
import '../../../image/domain/repositories/image_object_repository.dart';
import '../../../library/data/models/notebook_record.dart';
import '../../../library/domain/repositories/notebook_repository.dart';
import '../../../page/data/models/page_record.dart';
import '../../../page/domain/entities/note_page.dart';
import '../../../page/domain/repositories/page_repository.dart';
import '../../../pdf/data/models/pdf_document_record.dart';
import '../../../pdf/domain/entities/pdf_document_entity.dart';
import '../../../pdf/domain/repositories/pdf_document_repository.dart';
import '../../../text/data/models/text_object_record.dart';
import '../../../text/domain/entities/text_object.dart';
import '../../../text/domain/repositories/text_object_repository.dart';
import '../../domain/entities/native_backup_manifest.dart';

final class NativeBackupService {
  const NativeBackupService({
    required this.notebookRepository,
    required this.pageRepository,
    required this.inkRepository,
    required this.textRepository,
    required this.imageRepository,
    required this.pdfRepository,
  });

  final NotebookRepository notebookRepository;
  final PageRepository pageRepository;
  final InkRepository inkRepository;
  final TextObjectRepository textRepository;
  final ImageObjectRepository imageRepository;
  final PdfDocumentRepository pdfRepository;

  Future<void> createNotebookBackup({
    required String notebookId,
    void Function(String stage)? onStageChanged,
  }) async {
    onStageChanged?.call('snapshot');

    final notebook = await notebookRepository.getById(notebookId);

    if (notebook == null || notebook.isDeleted) {
      throw StateError('The notebook was not found.');
    }

    final pageGroups = await Future.wait([
      pageRepository.getActivePages(notebookId),
      pageRepository.getDeletedPages(notebookId),
    ]);
    final pages = <NotePage>[...pageGroups[0], ...pageGroups[1]]
      ..sort((first, second) => first.sortOrder.compareTo(second.sortOrder));
    final pageIds = pages.map((page) => page.id).toSet();
    final objectGroups = await Future.wait<Object>([
      inkRepository.getStrokesForPages(pageIds),
      textRepository.getObjectsForPages(pageIds),
      imageRepository.getByPageIds(pageIds),
      pdfRepository.getByNotebookId(notebookId),
    ]);
    final strokesByPage = objectGroups[0] as Map<String, List<InkStroke>>;
    final textsByPage = objectGroups[1] as Map<String, List<TextObject>>;
    final imagesByPage = objectGroups[2] as Map<String, List<ImageObject>>;
    final pdfDocuments = objectGroups[3] as List<PdfDocumentEntity>;
    final files = <String, Uint8List>{};

    files['data/notebook.json'] = _jsonBytes(
      NotebookRecord.fromDomain(notebook).toJson(),
    );
    files['data/pages.json'] = _jsonBytes(
      pages
          .map(PageRecord.fromDomain)
          .map((record) => record.toJson())
          .toList(),
    );

    final strokeRecords = <Map<String, Object?>>[];
    final textRecords = <Map<String, Object?>>[];
    final imageRecords = <Map<String, Object?>>[];

    for (final page in pages) {
      for (final stroke in strokesByPage[page.id] ?? const []) {
        strokeRecords.add(InkStrokeRecord.fromDomain(stroke).toJson());
      }

      for (final text in textsByPage[page.id] ?? const []) {
        textRecords.add(TextObjectRecord.fromDomain(text).toJson());
      }

      for (final image in imagesByPage[page.id] ?? const []) {
        final record = ImageObjectRecord.fromDomain(image).toJson();
        final dataUrl = image.originalPath;
        final decoded = _decodeDataUrl(dataUrl);
        final assetPath = 'assets/images/${image.id}.bin';

        files[assetPath] = decoded.bytes;
        record['originalPath'] = 'backup:$assetPath';
        record['backupDataUrlPrefix'] = decoded.prefix;
        imageRecords.add(record);
      }
    }

    files['data/strokes.json'] = _jsonBytes(strokeRecords);
    files['data/text_objects.json'] = _jsonBytes(textRecords);
    files['data/image_objects.json'] = _jsonBytes(imageRecords);

    onStageChanged?.call('assets');

    final pdfRecords = <Map<String, Object?>>[];

    for (final document in pdfDocuments) {
      final record = PdfDocumentRecord.fromDomain(document).toJson();
      final bytes = await pdfRepository.readBytes(document.storageKey);

      if (bytes == null || bytes.isEmpty) {
        throw StateError(
          'The original PDF "${document.fileName}" could not be read.',
        );
      }

      final assetPath = 'assets/pdfs/${document.id}.pdf';
      files[assetPath] = bytes;
      record['backupAssetPath'] = assetPath;
      pdfRecords.add(record);
    }

    files['data/pdf_documents.json'] = _jsonBytes(pdfRecords);

    onStageChanged?.call('integrity');

    final checksums = <String, String>{
      for (final entry in files.entries)
        entry.key: sha256.convert(entry.value).toString(),
    };
    final manifest = NativeBackupManifest(
      format: NativeBackupManifest.currentFormat,
      schemaVersion: NativeBackupManifest.currentSchemaVersion,
      backupId: const Uuid().v4(),
      createdAt: DateTime.now().toUtc(),
      notebookId: notebook.id,
      notebookTitle: notebook.title,
      fileChecksums: checksums,
    );

    files['manifest.json'] = _jsonBytes(manifest.toJson());

    onStageChanged?.call('archive');

    final archive = Archive();

    for (final entry in files.entries) {
      archive.addFile(ArchiveFile.bytes(entry.key, entry.value));
    }

    final encoded = Uint8List.fromList(ZipEncoder().encode(archive));

    if (encoded.isEmpty) {
      throw StateError('The backup package could not be created.');
    }

    final fileName = _safeBackupFileName(notebook.title);

    onStageChanged?.call('share');

    await SharePlus.instance.share(
      ShareParams(
        title: fileName,
        files: [
          XFile.fromData(
            encoded,
            mimeType: 'application/octet-stream',
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
        downloadFallbackEnabled: true,
      ),
    );
  }

  Uint8List _jsonBytes(Object? value) {
    return Uint8List.fromList(utf8.encode(jsonEncode(value)));
  }

  ({String prefix, Uint8List bytes}) _decodeDataUrl(String dataUrl) {
    final separatorIndex = dataUrl.indexOf(',');

    if (separatorIndex < 0 || separatorIndex == dataUrl.length - 1) {
      throw const FormatException('An image in the notebook is invalid.');
    }

    return (
      prefix: dataUrl.substring(0, separatorIndex + 1),
      bytes: base64Decode(dataUrl.substring(separatorIndex + 1)),
    );
  }

  String _safeBackupFileName(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-')
        .replaceAll(RegExp(r'\s+'), ' ');
    final baseName = normalized.isEmpty ? 'Kumo Notes' : normalized;

    return '$baseName-${_dateStamp(DateTime.now())}.kumo';
  }

  String _dateStamp(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$year$month$day-$hour$minute';
  }
}
