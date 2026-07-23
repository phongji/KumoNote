import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart' as rx;
import 'package:share_plus/share_plus.dart';

import '../../../drawing/domain/entities/ink_stroke.dart';
import '../../../drawing/domain/repositories/ink_repository.dart';
import '../../../drawing/presentation/painters/ink_painter.dart';
import '../../../image/domain/entities/image_object.dart';
import '../../../image/domain/repositories/image_object_repository.dart';
import '../../../page/domain/entities/note_page.dart';
import '../../../page/presentation/painters/paper_template_painter.dart';
import '../../../pdf/domain/repositories/pdf_document_repository.dart';
import '../../../text/domain/entities/text_object.dart';
import '../../../text/domain/repositories/text_object_repository.dart';

final class NotebookPdfExportService {
  const NotebookPdfExportService({
    required this.inkRepository,
    required this.textRepository,
    required this.imageRepository,
    required this.pdfRepository,
  });

  final InkRepository inkRepository;
  final TextObjectRepository textRepository;
  final ImageObjectRepository imageRepository;
  final PdfDocumentRepository pdfRepository;

  Future<void> export({
    required String notebookName,
    required List<NotePage> pages,
    void Function(int completed, int total)? onProgress,
  }) async {
    if (pages.isEmpty) {
      throw StateError('The notebook has no pages to export.');
    }

    final orderedPages = [...pages]
      ..sort((first, second) => first.sortOrder.compareTo(second.sortOrder));
    final snapshots = await _createSnapshots(orderedPages);
    final renderScale = _renderScaleFor(snapshots.length);
    final output = pw.Document(title: notebookName, creator: 'Kumo Notes');
    final pdfCache = _PdfSourceCache(repository: pdfRepository);

    try {
      for (var index = 0; index < snapshots.length; index++) {
        final snapshot = snapshots[index];
        final pagePng = await _renderPage(snapshot, pdfCache, renderScale);
        final page = snapshot.page;

        output.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(page.width, page.height),
            margin: pw.EdgeInsets.zero,
            build: (_) {
              return pw.SizedBox.expand(
                child: pw.Image(pw.MemoryImage(pagePng), fit: pw.BoxFit.fill),
              );
            },
          ),
        );

        onProgress?.call(index + 1, snapshots.length);
        await Future<void>.delayed(Duration.zero);
      }

      final bytes = await output.save();
      final fileName = _safePdfFileName(notebookName);

      await SharePlus.instance.share(
        ShareParams(
          title: fileName,
          files: [
            XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName),
          ],
          fileNameOverrides: [fileName],
          downloadFallbackEnabled: true,
        ),
      );
    } finally {
      await pdfCache.dispose();
    }
  }

  Future<List<_ExportPageSnapshot>> _createSnapshots(
    List<NotePage> pages,
  ) async {
    final pageIds = pages.map((page) => page.id).toSet();
    final values = await Future.wait<Object>([
      inkRepository.getStrokesForPages(pageIds),
      textRepository.getObjectsForPages(pageIds),
      imageRepository.getByPageIds(pageIds),
    ]);
    final strokesByPage = values[0] as Map<String, List<InkStroke>>;
    final textsByPage = values[1] as Map<String, List<TextObject>>;
    final imagesByPage = values[2] as Map<String, List<ImageObject>>;

    return pages
        .map((page) {
          return _ExportPageSnapshot(
            page: page,
            strokes: List<InkStroke>.unmodifiable(
              strokesByPage[page.id] ?? const [],
            ),
            texts: List<TextObject>.unmodifiable(
              textsByPage[page.id] ?? const [],
            ),
            images: List<ImageObject>.unmodifiable(
              imagesByPage[page.id] ?? const [],
            ),
          );
        })
        .toList(growable: false);
  }

  Future<Uint8List> _renderPage(
    _ExportPageSnapshot snapshot,
    _PdfSourceCache pdfCache,
    double renderScale,
  ) async {
    final page = snapshot.page;
    final pixelWidth = math.max(1, (page.width * renderScale).round());
    final pixelHeight = math.max(1, (page.height * renderScale).round());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final pageSize = Size(page.width, page.height);

    canvas.scale(renderScale);
    canvas.drawRect(
      Offset.zero & pageSize,
      Paint()..color = Color(page.paperColor.colorValue),
    );

    if (page.pdfDocumentId != null && page.pdfPageNumber != null) {
      final background = await pdfCache.renderPage(
        documentId: page.pdfDocumentId!,
        pageNumber: page.pdfPageNumber!,
        pixelWidth: pixelWidth,
        pixelHeight: pixelHeight,
      );

      if (background != null) {
        try {
          canvas.drawImageRect(
            background,
            Rect.fromLTWH(
              0,
              0,
              background.width.toDouble(),
              background.height.toDouble(),
            ),
            Offset.zero & pageSize,
            Paint(),
          );
        } finally {
          background.dispose();
        }
      }
    } else {
      PaperTemplatePainter(
        template: page.template,
        lineColor: const Color(0xFF7D8583).withValues(alpha: 0.34),
      ).paint(canvas, pageSize);
    }

    final entries = <_ExportEntry>[
      for (final stroke in snapshot.strokes)
        _ExportEntry(
          zIndex: stroke.zIndex,
          createdAt: stroke.createdAt,
          paint: () {
            InkPainter(
              strokes: [stroke],
              activeStroke: null,
            ).paint(canvas, pageSize);
          },
        ),
      for (final text in snapshot.texts)
        _ExportEntry(
          zIndex: text.zIndex,
          createdAt: text.createdAt,
          paint: () => _paintText(canvas, text),
        ),
      for (final image in snapshot.images)
        _ExportEntry(
          zIndex: image.zIndex,
          createdAt: image.createdAt,
          paintAsync: () => _paintImage(canvas, image),
        ),
    ]..sort(_compareEntries);

    for (final entry in entries) {
      if (entry.paintAsync != null) {
        await entry.paintAsync!();
      } else {
        entry.paint?.call();
      }
    }

    final picture = recorder.endRecording();

    try {
      final renderedImage = await picture.toImage(pixelWidth, pixelHeight);

      try {
        final data = await renderedImage.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (data == null) {
          throw StateError('An exported page could not be encoded.');
        }

        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        renderedImage.dispose();
      }
    } finally {
      picture.dispose();
    }
  }

  void _paintText(Canvas canvas, TextObject object) {
    final bounds = object.bounds;
    final painter = TextPainter(
      text: TextSpan(
        text: object.plainText,
        style: TextStyle(
          color: Color(object.colorValue),
          fontSize: object.fontSize,
          fontWeight: _fontWeight(object.weight),
          height: object.lineHeight,
        ),
      ),
      textAlign: switch (object.alignment) {
        TextObjectAlignment.left => TextAlign.left,
        TextObjectAlignment.center => TextAlign.center,
        TextObjectAlignment.right => TextAlign.right,
        TextObjectAlignment.justify => TextAlign.justify,
      },
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: bounds.width);

    canvas.save();
    canvas.translate(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
    canvas.rotate(bounds.rotationRadians);
    canvas.clipRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: bounds.width,
        height: bounds.height,
      ),
    );
    painter.paint(canvas, Offset(-bounds.width / 2, -bounds.height / 2));
    canvas.restore();
  }

  Future<void> _paintImage(Canvas canvas, ImageObject object) async {
    final bytes = _decodeDataUrl(object.originalPath);

    if (bytes.isEmpty) {
      return;
    }

    final codec = await ui.instantiateImageCodec(bytes);

    try {
      final frame = await codec.getNextFrame();

      try {
        final image = frame.image;
        final crop = object.crop;
        final source = Rect.fromLTRB(
          image.width * crop.left,
          image.height * crop.top,
          image.width * crop.right,
          image.height * crop.bottom,
        );
        final bounds = object.bounds;
        final destination = Rect.fromLTWH(0, 0, bounds.width, bounds.height);

        canvas.save();
        canvas.translate(
          bounds.x + bounds.width / 2,
          bounds.y + bounds.height / 2,
        );
        canvas.rotate(bounds.rotation);
        canvas.translate(-bounds.width / 2, -bounds.height / 2);
        canvas.clipRect(destination);
        canvas.drawImageRect(
          image,
          source,
          destination,
          Paint()
            ..color = Colors.white.withValues(alpha: object.opacity)
            ..filterQuality = FilterQuality.high,
        );
        canvas.restore();
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  Uint8List _decodeDataUrl(String dataUrl) {
    final separatorIndex = dataUrl.indexOf(',');

    if (separatorIndex < 0 || separatorIndex == dataUrl.length - 1) {
      return Uint8List(0);
    }

    return base64Decode(dataUrl.substring(separatorIndex + 1));
  }

  FontWeight _fontWeight(int weight) {
    final index = ((weight / 100).round() - 1).clamp(0, 8).toInt();
    return FontWeight.values[index];
  }

  double _renderScaleFor(int pageCount) {
    if (pageCount <= 20) {
      return 1.5;
    }

    if (pageCount <= 60) {
      return 1.25;
    }

    return 1;
  }

  int _compareEntries(_ExportEntry first, _ExportEntry second) {
    final firstOrder = first.zIndex == 0
        ? first.createdAt.microsecondsSinceEpoch
        : first.zIndex;
    final secondOrder = second.zIndex == 0
        ? second.createdAt.microsecondsSinceEpoch
        : second.zIndex;
    final order = firstOrder.compareTo(secondOrder);

    return order != 0 ? order : first.createdAt.compareTo(second.createdAt);
  }

  String _safePdfFileName(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-')
        .replaceAll(RegExp(r'\s+'), ' ');
    final baseName = normalized.isEmpty ? 'Kumo Notes' : normalized;

    return baseName.toLowerCase().endsWith('.pdf') ? baseName : '$baseName.pdf';
  }
}

final class _ExportPageSnapshot {
  const _ExportPageSnapshot({
    required this.page,
    required this.strokes,
    required this.texts,
    required this.images,
  });

  final NotePage page;
  final List<InkStroke> strokes;
  final List<TextObject> texts;
  final List<ImageObject> images;
}

final class _ExportEntry {
  const _ExportEntry({
    required this.zIndex,
    required this.createdAt,
    this.paint,
    this.paintAsync,
  }) : assert(paint != null || paintAsync != null);

  final int zIndex;
  final DateTime createdAt;
  final VoidCallback? paint;
  final Future<void> Function()? paintAsync;
}

final class _PdfSourceCache {
  _PdfSourceCache({required this.repository});

  final PdfDocumentRepository repository;
  final Map<String, rx.PdfDocument> _documents = {};

  Future<ui.Image?> renderPage({
    required String documentId,
    required int pageNumber,
    required int pixelWidth,
    required int pixelHeight,
  }) async {
    final document = await _open(documentId);

    if (document == null ||
        pageNumber < 1 ||
        pageNumber > document.pages.length) {
      return null;
    }

    final rendered = await document.pages[pageNumber - 1].render(
      fullWidth: pixelWidth.toDouble(),
      fullHeight: pixelHeight.toDouble(),
      width: pixelWidth,
      height: pixelHeight,
      backgroundColor: 0xFFFFFFFF,
    );

    if (rendered == null) {
      return null;
    }

    try {
      return await rendered.createImage();
    } finally {
      rendered.dispose();
    }
  }

  Future<rx.PdfDocument?> _open(String documentId) async {
    final cached = _documents[documentId];

    if (cached != null) {
      return cached;
    }

    final metadata = await repository.getById(documentId);

    if (metadata == null) {
      return null;
    }

    final bytes = await repository.readBytes(metadata.storageKey);

    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    await rx.pdfrxFlutterInitialize();
    final document = await rx.PdfDocument.openData(
      bytes,
      sourceName: metadata.fileName,
      useProgressiveLoading: false,
      allowDataOwnershipTransfer: false,
    );

    _documents[documentId] = document;
    return document;
  }

  Future<void> dispose() async {
    for (final document in _documents.values) {
      await document.dispose();
    }

    _documents.clear();
  }
}
