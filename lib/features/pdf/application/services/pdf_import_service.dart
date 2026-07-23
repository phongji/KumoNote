import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';

final class ImportedPdfPage {
  const ImportedPdfPage({
    required this.pageNumber,
    required this.width,
    required this.height,
  });

  final int pageNumber;
  final double width;
  final double height;
}

final class ImportedPdfData {
  const ImportedPdfData({
    required this.fileName,
    required this.bytes,
    required this.checksum,
    required this.byteLength,
    required this.pages,
  });

  final String fileName;
  final Uint8List bytes;
  final String checksum;
  final int byteLength;
  final List<ImportedPdfPage> pages;

  int get pageCount => pages.length;
}

final class PdfImportService {
  const PdfImportService();

  static const int maximumFileBytes = 200 * 1024 * 1024;

  Future<ImportedPdfData?> pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw StateError('The selected PDF could not be read.');
    }

    if (bytes.length > maximumFileBytes) {
      throw StateError('The selected PDF is larger than 200 MB.');
    }

    if (!_hasPdfSignature(bytes)) {
      throw const FormatException('The selected file is not a valid PDF.');
    }

    await pdfrxFlutterInitialize();

    final document = await PdfDocument.openData(
      bytes,
      sourceName: file.name,
      useProgressiveLoading: false,
      allowDataOwnershipTransfer: false,
    );

    try {
      if (document.pages.isEmpty) {
        throw const FormatException('The selected PDF has no pages.');
      }

      final pages = document.pages
          .map((page) {
            return ImportedPdfPage(
              pageNumber: page.pageNumber,
              width: page.width,
              height: page.height,
            );
          })
          .toList(growable: false);

      return ImportedPdfData(
        fileName: file.name,
        bytes: bytes,
        checksum: sha256.convert(bytes).toString(),
        byteLength: bytes.length,
        pages: pages,
      );
    } finally {
      await document.dispose();
    }
  }

  bool _hasPdfSignature(Uint8List bytes) {
    if (bytes.length < 5) {
      return false;
    }

    return ascii.decode(bytes.sublist(0, 5), allowInvalid: true) == '%PDF-';
  }
}
