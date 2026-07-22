// Copy all content into image_object_view.dart (pointer rotation v7).
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/entities/image_object.dart';

final class ImageObjectView extends StatefulWidget {
  const ImageObjectView({
    required this.object,
    required this.isSelected,
    required this.onSelect,
    required this.onMove,
    required this.onResize,
    required this.onRotate,
    required this.onDelete,
    this.onDuplicate,
    this.onCrop,
    this.onMoveEnd,
    this.onResizeEnd,
    this.onRotateEnd,
    super.key,
  });

  final ImageObject object;
  final bool isSelected;
  final VoidCallback onSelect;
  final void Function(double deltaX, double deltaY) onMove;
  final void Function(double width, double height) onResize;
  final ValueChanged<double> onRotate;
  final VoidCallback onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onCrop;
  final VoidCallback? onMoveEnd;
  final VoidCallback? onResizeEnd;
  final VoidCallback? onRotateEnd;

  @override
  State<ImageObjectView> createState() => _ImageObjectViewState();
}

final class _ImageObjectViewState extends State<ImageObjectView> {
  final GlobalKey _objectKey = GlobalKey();

  late Uint8List _imageBytes;
  Offset? _rotationCenterGlobal;
  Offset? _lastMoveGlobalPosition;
  double? _rotationStartPointerAngle;
  double? _rotationStartObjectAngle;

  @override
  void initState() {
    super.initState();
    _imageBytes = _decodeDataUrl(widget.object.originalPath);
  }

  @override
  void didUpdateWidget(ImageObjectView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.object.originalPath != widget.object.originalPath) {
      _imageBytes = _decodeDataUrl(widget.object.originalPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final object = widget.object;
    final bounds = object.bounds;
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: bounds.x,
      top: bounds.y,
      width: bounds.width,
      height: bounds.height,
      child: Transform.rotate(
        angle: bounds.rotation,
        child: GestureDetector(
          key: _objectKey,
          behavior: HitTestBehavior.opaque,
          onTap: widget.onSelect,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  border: widget.isSelected
                      ? Border.all(color: colorScheme.primary, width: 1.2)
                      : null,
                ),
                child: ClipRect(
                  child: _CroppedImage(
                    imageBytes: _imageBytes,
                    crop: object.crop,
                    opacity: object.opacity,
                  ),
                ),
              ),
              if (widget.isSelected) ...[
                Positioned(
                  left: 0,
                  top: 0,
                  right: 34,
                  height: 30,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) {
                      _lastMoveGlobalPosition = details.globalPosition;
                    },
                    onPanUpdate: (details) {
                      final previousPosition = _lastMoveGlobalPosition;

                      if (previousPosition == null) {
                        _lastMoveGlobalPosition = details.globalPosition;
                        return;
                      }

                      final delta = details.globalPosition - previousPosition;
                      _lastMoveGlobalPosition = details.globalPosition;

                      widget.onMove(delta.dx, delta.dy);
                    },
                    onPanEnd: (_) {
                      _lastMoveGlobalPosition = null;
                      widget.onMoveEnd?.call();
                    },
                    onPanCancel: () {
                      _lastMoveGlobalPosition = null;
                      widget.onMoveEnd?.call();
                    },
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -7,
                  right: -7,
                  child: _RoundHandle(
                    icon: Icons.close_rounded,
                    onTap: widget.onDelete,
                  ),
                ),
                if (widget.onDuplicate != null)
                  Positioned(
                    top: 23,
                    right: -7,
                    child: _RoundHandle(
                      icon: Icons.copy_rounded,
                      onTap: widget.onDuplicate,
                    ),
                  ),
                if (widget.onCrop != null)
                  Positioned(
                    top: 53,
                    right: -7,
                    child: _RoundHandle(
                      icon: Icons.crop_rounded,
                      onTap: widget.onCrop,
                    ),
                  ),
                Positioned(
                  left: -7,
                  bottom: -7,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _beginRotation,
                    onPanUpdate: (details) {
                      _updateRotation(details.globalPosition);
                    },
                    onPanEnd: (_) => _finishRotation(),
                    onPanCancel: _finishRotation,
                    child: const _RoundHandle(icon: Icons.rotate_right),
                  ),
                ),
                Positioned(
                  right: -7,
                  bottom: -7,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      final aspectRatio = bounds.width / bounds.height;
                      final horizontalChange = details.delta.dx;
                      final verticalChange = details.delta.dy * aspectRatio;
                      final widthChange =
                          horizontalChange.abs() >= verticalChange.abs()
                          ? horizontalChange
                          : verticalChange;
                      final newWidth = bounds.width + widthChange;

                      widget.onResize(newWidth, newWidth / aspectRatio);
                    },
                    onPanEnd: (_) => widget.onResizeEnd?.call(),
                    onPanCancel: () => widget.onResizeEnd?.call(),
                    child: const _RoundHandle(icon: Icons.open_in_full_rounded),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _beginRotation(DragStartDetails details) {
    final renderObject =
        _objectKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderObject == null) {
      return;
    }

    final centerGlobal = renderObject.localToGlobal(
      renderObject.size.center(Offset.zero),
    );

    _rotationCenterGlobal = centerGlobal;
    _rotationStartPointerAngle = math.atan2(
      details.globalPosition.dy - centerGlobal.dy,
      details.globalPosition.dx - centerGlobal.dx,
    );
    _rotationStartObjectAngle = widget.object.bounds.rotation;
  }

  void _updateRotation(Offset pointerGlobal) {
    final center = _rotationCenterGlobal;
    final startPointerAngle = _rotationStartPointerAngle;
    final startObjectAngle = _rotationStartObjectAngle;

    if (center == null ||
        startPointerAngle == null ||
        startObjectAngle == null) {
      return;
    }

    final currentPointerAngle = math.atan2(
      pointerGlobal.dy - center.dy,
      pointerGlobal.dx - center.dx,
    );
    var angleDelta = currentPointerAngle - startPointerAngle;

    if (angleDelta > math.pi) {
      angleDelta -= math.pi * 2;
    } else if (angleDelta < -math.pi) {
      angleDelta += math.pi * 2;
    }

    widget.onRotate(startObjectAngle + angleDelta);
  }

  void _finishRotation() {
    _rotationCenterGlobal = null;
    _rotationStartPointerAngle = null;
    _rotationStartObjectAngle = null;
    widget.onRotateEnd?.call();
  }

  Uint8List _decodeDataUrl(String dataUrl) {
    final separatorIndex = dataUrl.indexOf(',');

    if (separatorIndex == -1 || separatorIndex == dataUrl.length - 1) {
      return Uint8List(0);
    }

    return base64Decode(dataUrl.substring(separatorIndex + 1));
  }
}

final class _CroppedImage extends StatelessWidget {
  const _CroppedImage({
    required this.imageBytes,
    required this.crop,
    required this.opacity,
  });

  final Uint8List imageBytes;
  final ImageCrop crop;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final cropWidth = crop.right - crop.left;
    final cropHeight = crop.bottom - crop.top;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final visibleWidth = constraints.maxWidth;
        final visibleHeight = constraints.maxHeight;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -(crop.left / cropWidth) * visibleWidth,
                top: -(crop.top / cropHeight) * visibleHeight,
                width: visibleWidth / cropWidth,
                height: visibleHeight / cropHeight,
                child: Opacity(
                  opacity: opacity,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      return ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _RoundHandle extends StatelessWidget {
  const _RoundHandle({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: CircleBorder(
        side: BorderSide(color: colorScheme.primary, width: 1.2),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 24,
          child: Icon(icon, size: 14, color: colorScheme.primary),
        ),
      ),
    );
  }
}
