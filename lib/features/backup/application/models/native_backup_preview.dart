import 'dart:typed_data';

import '../../domain/entities/native_backup_manifest.dart';

final class NativeBackupPreview {
  const NativeBackupPreview({
    required this.fileName,
    required this.packageBytes,
    required this.manifest,
    required this.pageCount,
    required this.strokeCount,
    required this.textObjectCount,
    required this.imageObjectCount,
    required this.pdfDocumentCount,
  });

  final String fileName;
  final Uint8List packageBytes;
  final NativeBackupManifest manifest;
  final int pageCount;
  final int strokeCount;
  final int textObjectCount;
  final int imageObjectCount;
  final int pdfDocumentCount;
}
