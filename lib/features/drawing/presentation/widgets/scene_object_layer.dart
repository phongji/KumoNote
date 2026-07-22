import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../image/application/controllers/image_object_controller.dart';
import '../../../image/domain/entities/image_object.dart';
import '../../../image/presentation/widgets/image_crop_dialog.dart';
import '../../../image/presentation/widgets/image_object_view.dart';
import '../../../text/application/controllers/text_object_controller.dart';
import '../../../text/domain/entities/text_object.dart';
import '../../../text/presentation/widgets/text_object_view.dart';
import '../../application/controllers/drawing_controller.dart';
import '../../application/state/drawing_state.dart';
import '../../domain/entities/ink_stroke.dart';
import '../painters/ink_painter.dart';

final class SceneObjectLayer extends ConsumerStatefulWidget {
  const SceneObjectLayer({
    required this.pageId,
    required this.strokes,
    required this.interactionMode,
    super.key,
  });

  final String pageId;
  final List<InkStroke> strokes;
  final CanvasInteractionMode interactionMode;

  @override
  ConsumerState<SceneObjectLayer> createState() => _SceneObjectLayerState();
}

final class _SceneObjectLayerState extends ConsumerState<SceneObjectLayer> {
  String? _selectedImageId;
  String? _selectedTextId;

  bool get _isImageMode {
    return widget.interactionMode == CanvasInteractionMode.image;
  }

  bool get _isTextMode {
    return widget.interactionMode == CanvasInteractionMode.text;
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(imageObjectControllerProvider(widget.pageId));
    final texts = ref.watch(textObjectControllerProvider(widget.pageId));
    final imageItems = images.asData?.value ?? const <ImageObject>[];
    final textItems = texts.asData?.value ?? const <TextObject>[];
    final imageController = ref.read(
      imageObjectControllerProvider(widget.pageId).notifier,
    );
    final textController = ref.read(
      textObjectControllerProvider(widget.pageId).notifier,
    );
    final drawingController = ref.read(
      drawingControllerProvider(widget.pageId).notifier,
    );

    final entries = <_SceneEntry>[
      for (final stroke in widget.strokes)
        _SceneEntry(
          id: stroke.id,
          kind: _SceneKind.stroke,
          zIndex: stroke.zIndex,
          createdAt: stroke.createdAt,
          child: Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: InkPainter(strokes: [stroke], activeStroke: null),
              ),
            ),
          ),
        ),
      for (final image in imageItems)
        _SceneEntry(
          id: image.id,
          kind: _SceneKind.image,
          zIndex: image.zIndex,
          createdAt: image.createdAt,
          child: Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isImageMode,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  ImageObjectView(
                    key: ValueKey(image.id),
                    object: image,
                    isSelected: _isImageMode && _selectedImageId == image.id,
                    onSelect: () {
                      setState(() {
                        _selectedImageId = image.id;
                        _selectedTextId = null;
                      });
                    },
                    onMove: (deltaX, deltaY) {
                      imageController.previewMoveImage(
                        objectId: image.id,
                        deltaX: deltaX,
                        deltaY: deltaY,
                      );
                    },
                    onMoveEnd: () {
                      unawaited(imageController.commitImageTransform(image.id));
                    },
                    onResize: (width, height) {
                      imageController.previewResizeImage(
                        objectId: image.id,
                        width: width,
                        height: height,
                      );
                    },
                    onResizeEnd: () {
                      unawaited(imageController.commitImageTransform(image.id));
                    },
                    onRotate: (rotation) {
                      imageController.previewRotateImage(
                        objectId: image.id,
                        rotation: rotation,
                      );
                    },
                    onRotateEnd: () {
                      unawaited(imageController.commitImageTransform(image.id));
                    },
                    onDuplicate: () {
                      unawaited(imageController.duplicateImage(image.id));
                    },
                    onCrop: () async {
                      final crop = await showImageCropDialog(
                        context: context,
                        object: image,
                      );

                      if (!mounted || crop == null) {
                        return;
                      }

                      await imageController.setCrop(
                        objectId: image.id,
                        crop: crop,
                      );
                    },
                    onDelete: () {
                      setState(() {
                        _selectedImageId = null;
                      });
                      unawaited(imageController.deleteImage(image.id));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      for (final text in textItems)
        _SceneEntry(
          id: text.id,
          kind: _SceneKind.text,
          zIndex: text.zIndex,
          createdAt: text.createdAt,
          child: Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isTextMode,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  TextObjectView(
                    key: ValueKey(text.id),
                    object: text,
                    isSelected: _isTextMode && _selectedTextId == text.id,
                    onSelect: () {
                      setState(() {
                        _selectedTextId = text.id;
                        _selectedImageId = null;
                      });
                    },
                    onTextCommitted: (plainText) {
                      unawaited(
                        textController.editText(
                          objectId: text.id,
                          plainText: plainText,
                        ),
                      );
                    },
                    onMove: (deltaX, deltaY) {
                      unawaited(
                        textController.moveText(
                          objectId: text.id,
                          deltaX: deltaX,
                          deltaY: deltaY,
                        ),
                      );
                    },
                    onResize: (width, height) {
                      unawaited(
                        textController.resizeText(
                          objectId: text.id,
                          width: width.clamp(80, 1200).toDouble(),
                          height: height.clamp(48, 1600).toDouble(),
                        ),
                      );
                    },
                    onDelete: () {
                      setState(() {
                        _selectedTextId = null;
                      });
                      unawaited(textController.deleteText(text.id));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
    ]..sort(_compareEntries);

    final selectedEntry = _findSelectedEntry(entries);

    return IgnorePointer(
      ignoring: !_isImageMode && !_isTextMode,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_selectedImageId == null && _selectedTextId == null) {
                return;
              }

              setState(() {
                _selectedImageId = null;
                _selectedTextId = null;
              });
            },
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: entries.map((entry) => entry.child).toList(),
            ),
          ),
          if (selectedEntry != null)
            Positioned(
              left: 12,
              top: 12,
              child: Material(
                elevation: 3,
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Send to back',
                        icon: const Icon(Icons.vertical_align_bottom_rounded),
                        onPressed: () {
                          unawaited(
                            _moveToEdge(
                              entry: selectedEntry,
                              entries: entries,
                              moveToFront: false,
                              imageController: imageController,
                              textController: textController,
                              drawingController: drawingController,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Bring to front',
                        icon: const Icon(Icons.vertical_align_top_rounded),
                        onPressed: () {
                          unawaited(
                            _moveToEdge(
                              entry: selectedEntry,
                              entries: entries,
                              moveToFront: true,
                              imageController: imageController,
                              textController: textController,
                              drawingController: drawingController,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  _SceneEntry? _findSelectedEntry(List<_SceneEntry> entries) {
    for (final entry in entries) {
      final isSelected = switch (entry.kind) {
        _SceneKind.image => entry.id == _selectedImageId,
        _SceneKind.text => entry.id == _selectedTextId,
        _SceneKind.stroke => false,
      };

      if (isSelected) {
        return entry;
      }
    }

    return null;
  }

  Future<void> _moveToEdge({
    required _SceneEntry entry,
    required List<_SceneEntry> entries,
    required bool moveToFront,
    required ImageObjectController imageController,
    required TextObjectController textController,
    required DrawingController drawingController,
  }) async {
    if (entries.length < 2) {
      return;
    }

    final edgeOrder = _entryOrder(moveToFront ? entries.last : entries.first);
    final newOrder = moveToFront ? edgeOrder + 1 : edgeOrder - 1;

    await _setEntryOrder(
      entry: entry,
      zIndex: newOrder,
      imageController: imageController,
      textController: textController,
      drawingController: drawingController,
    );
  }

  Future<void> _setEntryOrder({
    required _SceneEntry entry,
    required int zIndex,
    required ImageObjectController imageController,
    required TextObjectController textController,
    required DrawingController drawingController,
  }) async {
    switch (entry.kind) {
      case _SceneKind.image:
        await imageController.reorderImage(objectId: entry.id, zIndex: zIndex);
      case _SceneKind.text:
        await textController.reorderText(objectId: entry.id, zIndex: zIndex);
      case _SceneKind.stroke:
        await drawingController.reorderStroke(
          strokeId: entry.id,
          zIndex: zIndex,
        );
    }
  }

  int _compareEntries(_SceneEntry first, _SceneEntry second) {
    final orderComparison = _entryOrder(first).compareTo(_entryOrder(second));

    if (orderComparison != 0) {
      return orderComparison;
    }

    return first.createdAt.compareTo(second.createdAt);
  }

  int _entryOrder(_SceneEntry entry) {
    return entry.zIndex == 0
        ? entry.createdAt.microsecondsSinceEpoch
        : entry.zIndex;
  }
}

enum _SceneKind { stroke, image, text }

final class _SceneEntry {
  const _SceneEntry({
    required this.id,
    required this.kind,
    required this.zIndex,
    required this.createdAt,
    required this.child,
  });

  final String id;
  final _SceneKind kind;
  final int zIndex;
  final DateTime createdAt;
  final Widget child;
}
