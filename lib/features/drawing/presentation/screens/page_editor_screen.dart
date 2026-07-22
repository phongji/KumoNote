import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumo_note/l10n/app_localizations.dart';

import '../../../page/domain/entities/note_page.dart';
import '../../application/controllers/drawing_controller.dart';
import '../../application/state/drawing_state.dart';
import '../../domain/entities/ink_stroke.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/eraser_mode_picker.dart';
import '../widgets/ink_color_picker.dart';
import '../widgets/selection_action_bar.dart';
import '../widgets/stroke_width_picker.dart';

final class PageEditorScreen extends ConsumerWidget {
  const PageEditorScreen({
    required this.page,
    required this.pageNumber,
    super.key,
  });

  final NotePage page;
  final int pageNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final drawing = ref.watch(drawingControllerProvider(page.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('$pageNumber'),
        actions: [
          drawing.maybeWhen(
            data: (state) {
              final controller = ref.read(
                drawingControllerProvider(page.id).notifier,
              );

              return Row(
                children: [
                  IconButton(
                    tooltip: strings.undo,
                    onPressed: state.canUndo ? controller.undo : null,
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    tooltip: strings.redo,
                    onPressed: state.canRedo ? controller.redo : null,
                    icon: const Icon(Icons.redo),
                  ),
                  if (state.isSaving)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          drawing.maybeWhen(
            data: (state) {
              final controller = ref.read(
                drawingControllerProvider(page.id).notifier,
              );

              final colorScheme = Theme.of(context).colorScheme;

              final selectedButtonStyle = ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.primaryContainer;
                  }

                  return null;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.onPrimaryContainer;
                  }

                  return null;
                }),
              );

              return Material(
                color: colorScheme.surfaceContainerLowest,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _ToolGroup(
                        children: [
                          IconButton(
                            tooltip: strings.pen,
                            style: selectedButtonStyle,
                            isSelected:
                                !state.isLassoMode &&
                                state.selectedTool == InkTool.pen,
                            onPressed: () {
                              controller.selectTool(InkTool.pen);
                            },
                            icon: const Icon(Icons.edit_outlined),
                            selectedIcon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            tooltip: strings.pencil,
                            style: selectedButtonStyle,
                            isSelected:
                                !state.isLassoMode &&
                                state.selectedTool == InkTool.pencil,
                            onPressed: () {
                              controller.selectTool(InkTool.pencil);
                            },
                            icon: const Icon(Icons.create_outlined),
                            selectedIcon: const Icon(Icons.create),
                          ),
                          IconButton(
                            tooltip: strings.highlighter,
                            style: selectedButtonStyle,
                            isSelected:
                                !state.isLassoMode &&
                                state.selectedTool == InkTool.highlighter,
                            onPressed: () {
                              controller.selectTool(InkTool.highlighter);
                            },
                            icon: const Icon(Icons.border_color_outlined),
                            selectedIcon: const Icon(Icons.border_color),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      _ToolGroup(
                        children: [
                          EraserModePicker(
                            selectedMode: state.eraserMode,
                            isEraserSelected:
                                !state.isLassoMode &&
                                state.selectedTool == InkTool.eraser,
                            onSelectEraser: () {
                              controller.selectTool(InkTool.eraser);
                            },
                            onModeSelected: (mode) {
                              controller.setEraserMode(mode);
                              controller.selectTool(InkTool.eraser);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      _ToolGroup(
                        children: [
                          IconButton(
                            tooltip: strings.selectionTool,
                            style: selectedButtonStyle,
                            isSelected: state.isLassoMode,
                            onPressed: () {
                              controller.setInteractionMode(
                                state.isLassoMode
                                    ? CanvasInteractionMode.ink
                                    : CanvasInteractionMode.lasso,
                              );
                            },
                            icon: const Icon(Icons.gesture_outlined),
                            selectedIcon: const Icon(Icons.gesture),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      _ToolGroup(
                        children: [
                          StrokeWidthPicker(
                            selectedWidth: state.strokeWidth,
                            onSelected: controller.setStrokeWidth,
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      _ToolGroup(
                        children: [
                          InkColorPicker(
                            selectedColorValue: state.colorValue,
                            onSelected: controller.setColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox(height: 68),
          ),
          drawing.maybeWhen(
            data: (state) {
              final controller = ref.read(
                drawingControllerProvider(page.id).notifier,
              );

              return Align(
                alignment: Alignment.centerLeft,
                child: SelectionActionBar(
                  hasSelection: state.hasSelection,
                  hasClipboard: state.hasClipboard,
                  isSaving: state.isSaving,
                  moveLabel: strings.moveSelection,
                  copyLabel: strings.copySelection,
                  pasteLabel: strings.pasteSelection,
                  deleteLabel: strings.deleteSelection,
                  resizeLabel: strings.resizeSelection,
                  onCopy: controller.copySelection,
                  onPaste: controller.pasteSelection,
                  onDelete: controller.deleteSelection,
                  onTransform: (action) {
                    switch (action) {
                      case SelectionTransformAction.moveLeft:
                        controller.moveSelection(deltaX: -12, deltaY: 0);
                      case SelectionTransformAction.moveRight:
                        controller.moveSelection(deltaX: 12, deltaY: 0);
                      case SelectionTransformAction.moveUp:
                        controller.moveSelection(deltaX: 0, deltaY: -12);
                      case SelectionTransformAction.moveDown:
                        controller.moveSelection(deltaX: 0, deltaY: 12);
                      case SelectionTransformAction.shrink:
                        controller.scaleSelection(0.9);
                      case SelectionTransformAction.enlarge:
                        controller.scaleSelection(1.1);
                    }
                  },
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Material(
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: page.width,
                      height: page.height,
                      child: DrawingCanvas(
                        pageId: page.id,
                        template: page.template,
                        paperColor: page.paperColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _ToolGroup extends StatelessWidget {
  const _ToolGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
