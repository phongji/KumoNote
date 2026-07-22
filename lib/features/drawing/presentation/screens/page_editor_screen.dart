import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumo_note/l10n/app_localizations.dart';

import '../../../page/domain/entities/note_page.dart';
import '../../application/controllers/drawing_controller.dart';
import '../../application/state/drawing_state.dart';
import '../../domain/entities/ink_stroke.dart';
import '../widgets/canvas_viewport.dart';
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
                                state.isInkMode &&
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
                                state.isInkMode &&
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
                                state.isInkMode &&
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
                                state.isInkMode &&
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
                          IconButton(
                            tooltip: strings.moveSelection,
                            style: selectedButtonStyle,
                            isSelected: state.isNavigationMode,
                            onPressed: () {
                              controller.setInteractionMode(
                                state.isNavigationMode
                                    ? CanvasInteractionMode.ink
                                    : CanvasInteractionMode.navigation,
                              );
                            },
                            icon: const Icon(Icons.pan_tool_outlined),
                            selectedIcon: const Icon(Icons.pan_tool),
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
                            onSelected: (colorValue) {
                              if (state.hasSelection) {
                                controller.recolorSelection(colorValue);
                                return;
                              }

                              controller.setColor(colorValue);
                            },
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
                  copyLabel: strings.copySelection,
                  cutLabel: strings.cutSelection,
                  pasteLabel: strings.pasteSelection,
                  deleteLabel: strings.deleteSelection,
                  onCopy: controller.copySelection,
                  onCut: controller.cutSelection,
                  onPaste: controller.pasteSelection,
                  onDelete: controller.deleteSelection,
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: drawing.maybeWhen(
                data: (state) {
                  return CanvasViewport(
                    navigationEnabled: state.isNavigationMode,
                    child: Padding(
                      padding: const EdgeInsets.all(72),
                      child: Material(
                        elevation: 4,
                        surfaceTintColor: Colors.transparent,
                        shadowColor: const Color(
                          0xFF4F4A43,
                        ).withValues(alpha: 0.16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: const BorderSide(
                            color: Color(0xFFD8D4CA),
                            width: 1,
                          ),
                        ),
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
                  );
                },
                orElse: () => const Center(child: CircularProgressIndicator()),
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
