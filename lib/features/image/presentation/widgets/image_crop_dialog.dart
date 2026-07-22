// Copy all content into image_crop_dialog.dart.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kumo_note/l10n/app_localizations.dart';

import '../../domain/entities/image_object.dart';

Future<ImageCrop?> showImageCropDialog({
  required BuildContext context,
  required ImageObject object,
}) {
  return showDialog<ImageCrop>(
    context: context,
    builder: (context) => _ImageCropDialog(object: object),
  );
}

enum _CropEdge { none, left, top, right, bottom }

final class _ImageCropDialog extends StatefulWidget {
  const _ImageCropDialog({required this.object});

  final ImageObject object;

  @override
  State<_ImageCropDialog> createState() => _ImageCropDialogState();
}

final class _ImageCropDialogState extends State<_ImageCropDialog> {
  static const double _minimumCropSize = 0.08;
  static const double _edgeHitDistance = 24;

  late ImageCrop _crop;
  late Uint8List _imageBytes;
  _CropEdge _activeEdge = _CropEdge.none;

  @override
  void initState() {
    super.initState();
    _crop = widget.object.crop;
    _imageBytes = _decodeDataUrl(widget.object.originalPath);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final aspectRatio =
        widget.object.bounds.width / widget.object.bounds.height;

    return AlertDialog(
      title: Text(strings.cropImage),
      content: SizedBox(
        width: 540,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 380,
              child: Center(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );

                      return Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (event) {
                          _activeEdge = _nearestEdge(
                            position: event.localPosition,
                            size: size,
                          );
                        },
                        onPointerMove: (event) {
                          _updateCrop(
                            position: event.localPosition,
                            size: size,
                          );
                        },
                        onPointerUp: (_) {
                          _activeEdge = _CropEdge.none;
                        },
                        onPointerCancel: (_) {
                          _activeEdge = _CropEdge.none;
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              _imageBytes,
                              fit: BoxFit.fill,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.medium,
                            ),
                            CustomPaint(
                              painter: _CropOverlayPainter(
                                crop: _crop,
                                colorScheme: Theme.of(context).colorScheme,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              strings.cropImage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(strings.resetCrop),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_crop),
          child: Text(strings.applyCrop),
        ),
      ],
    );
  }

  _CropEdge _nearestEdge({required Offset position, required Size size}) {
    final rect = _cropRect(size);
    final distances = <_CropEdge, double>{
      _CropEdge.left: (position.dx - rect.left).abs(),
      _CropEdge.top: (position.dy - rect.top).abs(),
      _CropEdge.right: (position.dx - rect.right).abs(),
      _CropEdge.bottom: (position.dy - rect.bottom).abs(),
    };

    final nearest = distances.entries.reduce((first, second) {
      return first.value <= second.value ? first : second;
    });

    return nearest.value <= _edgeHitDistance ? nearest.key : _CropEdge.none;
  }

  void _updateCrop({required Offset position, required Size size}) {
    if (_activeEdge == _CropEdge.none) {
      return;
    }

    final normalizedX = (position.dx / size.width).clamp(0.0, 1.0).toDouble();
    final normalizedY = (position.dy / size.height).clamp(0.0, 1.0).toDouble();

    var left = _crop.left;
    var top = _crop.top;
    var right = _crop.right;
    var bottom = _crop.bottom;

    switch (_activeEdge) {
      case _CropEdge.left:
        left = normalizedX.clamp(0.0, right - _minimumCropSize).toDouble();
      case _CropEdge.top:
        top = normalizedY.clamp(0.0, bottom - _minimumCropSize).toDouble();
      case _CropEdge.right:
        right = normalizedX.clamp(left + _minimumCropSize, 1.0).toDouble();
      case _CropEdge.bottom:
        bottom = normalizedY.clamp(top + _minimumCropSize, 1.0).toDouble();
      case _CropEdge.none:
        return;
    }

    setState(() {
      _crop = ImageCrop(left: left, top: top, right: right, bottom: bottom);
    });
  }

  Rect _cropRect(Size size) {
    return Rect.fromLTRB(
      _crop.left * size.width,
      _crop.top * size.height,
      _crop.right * size.width,
      _crop.bottom * size.height,
    );
  }

  void _reset() {
    setState(() {
      _crop = const ImageCrop();
    });
  }

  Uint8List _decodeDataUrl(String dataUrl) {
    final separatorIndex = dataUrl.indexOf(',');

    if (separatorIndex == -1 || separatorIndex == dataUrl.length - 1) {
      return Uint8List(0);
    }

    return base64Decode(dataUrl.substring(separatorIndex + 1));
  }
}

final class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({required this.crop, required this.colorScheme});

  final ImageCrop crop;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final cropRect = Rect.fromLTRB(
      crop.left * size.width,
      crop.top * size.height,
      crop.right * size.width,
      crop.bottom * size.height,
    );

    final dimmedArea = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(cropRect);

    canvas.drawPath(
      dimmedArea,
      Paint()..color = Colors.black.withValues(alpha: 0.42),
    );

    canvas.drawRect(
      cropRect,
      Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final handlePaint = Paint()..color = colorScheme.surface;
    final handleBorderPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final point in [
      cropRect.centerLeft,
      cropRect.topCenter,
      cropRect.centerRight,
      cropRect.bottomCenter,
    ]) {
      canvas
        ..drawCircle(point, 7, handlePaint)
        ..drawCircle(point, 7, handleBorderPaint);
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) {
    return oldDelegate.crop.left != crop.left ||
        oldDelegate.crop.top != crop.top ||
        oldDelegate.crop.right != crop.right ||
        oldDelegate.crop.bottom != crop.bottom ||
        oldDelegate.colorScheme != colorScheme;
  }
}
