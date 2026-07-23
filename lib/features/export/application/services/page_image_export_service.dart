import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

final class PageImageExportService {
  const PageImageExportService();

  Future<void> exportPng({
    required GlobalKey boundaryKey,
    required String fileName,
    double pixelRatio = 2,
  }) async {
    if (pixelRatio <= 0) {
      throw ArgumentError.value(
        pixelRatio,
        'pixelRatio',
        'Pixel ratio must be greater than zero.',
      );
    }

    await WidgetsBinding.instance.endOfFrame;

    final boundaryContext = boundaryKey.currentContext;
    final renderObject = boundaryContext?.findRenderObject();

    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('The page is not ready to export.');
    }

    if (renderObject.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
    }

    final image = await renderObject.toImage(pixelRatio: pixelRatio);

    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw StateError('The page image could not be created.');
      }

      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      await _sharePng(bytes: bytes, fileName: _safeFileName(fileName));
    } finally {
      image.dispose();
    }
  }

  Future<void> _sharePng({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        title: fileName,
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: [fileName],
        downloadFallbackEnabled: true,
      ),
    );

    if (result.status == ShareResultStatus.unavailable) {
      throw StateError('Sharing is not available on this device.');
    }
  }

  String _safeFileName(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-')
        .replaceAll(RegExp(r'\s+'), ' ');
    final baseName = normalized.isEmpty ? 'Kumo Note' : normalized;

    return baseName.toLowerCase().endsWith('.png') ? baseName : '$baseName.png';
  }
}
