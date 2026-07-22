// Copy all content into image_object_layer.dart (smooth gestures v3).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/image_object_controller.dart';
import 'image_crop_dialog.dart';
import 'image_object_view.dart';

final class ImageObjectLayer extends ConsumerStatefulWidget {
  const ImageObjectLayer({
    required this.pageId,
    required this.isInteractionEnabled,
    super.key,
  });

  final String pageId;
  final bool isInteractionEnabled;

  @override
  ConsumerState<ImageObjectLayer> createState() => _ImageObjectLayerState();
}

final class _ImageObjectLayerState extends ConsumerState<ImageObjectLayer> {
  String? _selectedObjectId;

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(imageObjectControllerProvider(widget.pageId));

    return IgnorePointer(
      ignoring: !widget.isInteractionEnabled,
      child: images.when(
        loading: () => const SizedBox.expand(),
        error: (_, _) => Center(
          child: IconButton.filledTonal(
            tooltip: 'Reload images',
            onPressed: () {
              unawaited(
                ref
                    .read(imageObjectControllerProvider(widget.pageId).notifier)
                    .reload(),
              );
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        data: (objects) {
          final controller = ref.read(
            imageObjectControllerProvider(widget.pageId).notifier,
          );

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_selectedObjectId == null) {
                return;
              }

              setState(() {
                _selectedObjectId = null;
              });
            },
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                for (final object in objects)
                  ImageObjectView(
                    key: ValueKey(object.id),
                    object: object,
                    isSelected: _selectedObjectId == object.id,
                    onSelect: () {
                      setState(() {
                        _selectedObjectId = object.id;
                      });
                    },
                    onMove: (deltaX, deltaY) {
                      controller.previewMoveImage(
                        objectId: object.id,
                        deltaX: deltaX,
                        deltaY: deltaY,
                      );
                    },
                    onMoveEnd: () {
                      unawaited(controller.commitImageTransform(object.id));
                    },
                    onResize: (width, height) {
                      controller.previewResizeImage(
                        objectId: object.id,
                        width: width,
                        height: height,
                      );
                    },
                    onResizeEnd: () {
                      unawaited(controller.commitImageTransform(object.id));
                    },
                    onRotate: (rotation) {
                      controller.previewRotateImage(
                        objectId: object.id,
                        rotation: rotation,
                      );
                    },
                    onRotateEnd: () {
                      unawaited(controller.commitImageTransform(object.id));
                    },
                    onDuplicate: () {
                      unawaited(controller.duplicateImage(object.id));
                    },
                    onCrop: () async {
                      final crop = await showImageCropDialog(
                        context: context,
                        object: object,
                      );

                      if (!mounted || crop == null) {
                        return;
                      }

                      await controller.setCrop(objectId: object.id, crop: crop);
                    },
                    onDelete: () {
                      setState(() {
                        _selectedObjectId = null;
                      });

                      unawaited(controller.deleteImage(object.id));
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}