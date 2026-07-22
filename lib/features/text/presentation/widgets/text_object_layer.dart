// Copy all content into text_object_layer.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/text_object_controller.dart';
import 'text_object_view.dart';

final class TextObjectLayer extends ConsumerStatefulWidget {
  const TextObjectLayer({
    required this.pageId,
    required this.interactionEnabled,
    super.key,
  });

  final String pageId;
  final bool interactionEnabled;

  @override
  ConsumerState<TextObjectLayer> createState() {
    return _TextObjectLayerState();
  }
}

final class _TextObjectLayerState extends ConsumerState<TextObjectLayer> {
  String? _selectedObjectId;

  @override
  Widget build(BuildContext context) {
    final objects = ref.watch(textObjectControllerProvider(widget.pageId));
    final controller = ref.read(
      textObjectControllerProvider(widget.pageId).notifier,
    );

    return IgnorePointer(
      ignoring: !widget.interactionEnabled,
      child: objects.when(
        loading: () => const SizedBox.expand(),
        error: (_, _) => Align(
          alignment: Alignment.topRight,
          child: IconButton.filledTonal(
            tooltip: 'Retry',
            onPressed: controller.reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        data: (items) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _selectedObjectId = null;
              });
            },
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                for (final object in items)
                  TextObjectView(
                    key: ValueKey(object.id),
                    object: object,
                    isSelected: _selectedObjectId == object.id,
                    onSelect: () {
                      setState(() {
                        _selectedObjectId = object.id;
                      });
                    },
                    onTextCommitted: (plainText) {
                      controller.editText(
                        objectId: object.id,
                        plainText: plainText,
                      );
                    },
                    onMove: (deltaX, deltaY) {
                      controller.moveText(
                        objectId: object.id,
                        deltaX: deltaX,
                        deltaY: deltaY,
                      );
                    },
                    onResize: (width, height) {
                      controller.resizeText(
                        objectId: object.id,
                        width: width.clamp(80, 1200).toDouble(),
                        height: height.clamp(48, 1600).toDouble(),
                      );
                    },
                    onDelete: () {
                      setState(() {
                        _selectedObjectId = null;
                      });
                      controller.deleteText(object.id);
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
