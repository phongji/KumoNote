import 'package:flutter/material.dart';

enum SelectionTransformAction {
  moveLeft,
  moveRight,
  moveUp,
  moveDown,
  shrink,
  enlarge,
}

final class SelectionActionBar extends StatelessWidget {
  const SelectionActionBar({
    required this.hasSelection,
    required this.hasClipboard,
    required this.isSaving,
    required this.moveLabel,
    required this.copyLabel,
    required this.pasteLabel,
    required this.deleteLabel,
    required this.resizeLabel,
    required this.onCopy,
    required this.onPaste,
    required this.onDelete,
    required this.onTransform,
    super.key,
  });

  final bool hasSelection;
  final bool hasClipboard;
  final bool isSaving;
  final String moveLabel;
  final String copyLabel;
  final String pasteLabel;
  final String deleteLabel;
  final String resizeLabel;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onDelete;
  final ValueChanged<SelectionTransformAction> onTransform;

  @override
  Widget build(BuildContext context) {
    if (!hasSelection && !hasClipboard) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSelection)
            PopupMenuButton<SelectionTransformAction>(
              tooltip: '$moveLabel · $resizeLabel',
              enabled: !isSaving,
              icon: const Icon(Icons.open_with_rounded),
              onSelected: onTransform,
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    value: SelectionTransformAction.moveLeft,
                    child: _MenuItem(
                      icon: Icons.arrow_back_rounded,
                      label: moveLabel,
                    ),
                  ),
                  PopupMenuItem(
                    value: SelectionTransformAction.moveRight,
                    child: _MenuItem(
                      icon: Icons.arrow_forward_rounded,
                      label: moveLabel,
                    ),
                  ),
                  PopupMenuItem(
                    value: SelectionTransformAction.moveUp,
                    child: _MenuItem(
                      icon: Icons.arrow_upward_rounded,
                      label: moveLabel,
                    ),
                  ),
                  PopupMenuItem(
                    value: SelectionTransformAction.moveDown,
                    child: _MenuItem(
                      icon: Icons.arrow_downward_rounded,
                      label: moveLabel,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: SelectionTransformAction.shrink,
                    child: _MenuItem(
                      icon: Icons.zoom_in_map_rounded,
                      label: resizeLabel,
                    ),
                  ),
                  PopupMenuItem(
                    value: SelectionTransformAction.enlarge,
                    child: _MenuItem(
                      icon: Icons.zoom_out_map_rounded,
                      label: resizeLabel,
                    ),
                  ),
                ];
              },
            ),
          if (hasSelection)
            IconButton(
              tooltip: copyLabel,
              onPressed: isSaving ? null : onCopy,
              icon: const Icon(Icons.copy_rounded),
            ),
          if (hasClipboard)
            IconButton(
              tooltip: pasteLabel,
              onPressed: isSaving ? null : onPaste,
              icon: const Icon(Icons.content_paste_rounded),
            ),
          if (hasSelection)
            IconButton(
              tooltip: deleteLabel,
              onPressed: isSaving ? null : onDelete,
              color: Theme.of(context).colorScheme.error,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
    );
  }
}

final class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(label)],
    );
  }
}
