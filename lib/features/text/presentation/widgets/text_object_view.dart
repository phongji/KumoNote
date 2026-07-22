// Copy all content into text_object_view.dart.
import 'package:flutter/material.dart';

import '../../domain/entities/text_object.dart';

final class TextObjectView extends StatefulWidget {
  const TextObjectView({
    required this.object,
    required this.isSelected,
    required this.onSelect,
    required this.onTextCommitted,
    required this.onMove,
    required this.onResize,
    required this.onDelete,
    super.key,
  });

  final TextObject object;
  final bool isSelected;
  final VoidCallback onSelect;
  final ValueChanged<String> onTextCommitted;
  final void Function(double deltaX, double deltaY) onMove;
  final void Function(double width, double height) onResize;
  final VoidCallback onDelete;

  @override
  State<TextObjectView> createState() => _TextObjectViewState();
}

final class _TextObjectViewState extends State<TextObjectView> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.object.plainText);
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(TextObjectView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_focusNode.hasFocus &&
        oldWidget.object.plainText != widget.object.plainText) {
      _textController.text = widget.object.plainText;
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final object = widget.object;
    final bounds = object.bounds;
    final accent = Theme.of(context).colorScheme.primary;

    return Positioned(
      left: bounds.x,
      top: bounds.y,
      width: bounds.width,
      height: bounds.height,
      child: Transform.rotate(
        angle: bounds.rotationRadians,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onSelect,
          onDoubleTap: () {
            widget.onSelect();
            _focusNode.requestFocus();
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: widget.isSelected
                  ? Border.all(color: accent, width: 1.2)
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      widget.isSelected ? 25 : 5,
                      8,
                      6,
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlign: _textAlign(object.alignment),
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        fontFamily: _fontFamily(object.fontFamilyToken),
                        fontSize: object.fontSize,
                        fontWeight: _fontWeight(object.weight),
                        color: Color(object.colorValue),
                        height: object.lineHeight,
                      ),
                      decoration: const InputDecoration(
                        filled: false,
                        fillColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: widget.onSelect,
                      onSubmitted: (_) => _commitText(),
                    ),
                  ),
                ),
                if (widget.isSelected) ...[
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 30,
                    height: 24,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        widget.onMove(details.delta.dx, details.delta.dy);
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          size: 19,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: IconButton(
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  Positioned(
                    right: -7,
                    bottom: -7,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        widget.onResize(
                          bounds.width + details.delta.dx,
                          bounds.height + details.delta.dy,
                        );
                      },
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: accent, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitText();
    }
  }

  void _commitText() {
    if (_textController.text == widget.object.plainText) {
      return;
    }

    widget.onTextCommitted(_textController.text);
  }

  String? _fontFamily(String token) {
    return switch (token) {
      'serif' => 'serif',
      'monospace' => 'monospace',
      _ => null,
    };
  }

  FontWeight _fontWeight(int weight) {
    return switch (weight) {
      <= 100 => FontWeight.w100,
      <= 200 => FontWeight.w200,
      <= 300 => FontWeight.w300,
      <= 400 => FontWeight.w400,
      <= 500 => FontWeight.w500,
      <= 600 => FontWeight.w600,
      <= 700 => FontWeight.w700,
      <= 800 => FontWeight.w800,
      _ => FontWeight.w900,
    };
  }

  TextAlign _textAlign(TextObjectAlignment alignment) {
    return switch (alignment) {
      TextObjectAlignment.left => TextAlign.left,
      TextObjectAlignment.center => TextAlign.center,
      TextObjectAlignment.right => TextAlign.right,
      TextObjectAlignment.justify => TextAlign.justify,
    };
  }
}
