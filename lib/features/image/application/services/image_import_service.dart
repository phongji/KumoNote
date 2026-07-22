// Copy all content into image_import_service.dart.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';

final class ImportedImageData {
  const ImportedImageData({
    required this.fileName,
    required this.dataUrl,
    required this.checksum,
    required this.width,
    required this.height,
    required this.byteLength,
  });

  final String fileName;
  final String dataUrl;
  final String checksum;
  final double width;
  final double height;
  final int byteLength;
}

final class ImageImportService {
  const ImageImportService();

  static const int maximumFileBytes = 15 * 1024 * 1024;

  Future<ImportedImageData?> pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw StateError('The selected image could not be read.');
    }

    if (bytes.length > maximumFileBytes) {
      throw StateError('The selected image is larger than 15 MB.');
    }

    final dimensions = await _readDimensions(bytes);
    final mimeType = _mimeTypeFor(file.extension);
    final encoded = base64Encode(bytes);

    return ImportedImageData(
      fileName: file.name,
      dataUrl: 'data:$mimeType;base64,$encoded',
      checksum: sha256.convert(bytes).toString(),
      width: dimensions.width,
      height: dimensions.height,
      byteLength: bytes.length,
    );
  }

  Future<({double width, double height})> _readDimensions(
    Uint8List bytes,
  ) async {
    final codec = await ui.instantiateImageCodec(bytes);

    try {
      final frame = await codec.getNextFrame();

      try {
        return (
          width: frame.image.width.toDouble(),
          height: frame.image.height.toDouble(),
        );
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  String _mimeTypeFor(String? extension) {
    return switch (extension?.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'bmp' => 'image/bmp',
      _ => 'image/png',
    };
  }
}
