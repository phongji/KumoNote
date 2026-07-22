import 'package:flutter/material.dart';

final class SelectionActionBar extends StatelessWidget {
  const SelectionActionBar({
    required this.hasSelection,
    required this.hasClipboard,
    required this.isSaving,
    required this.copyLabel,
    required this.cutLabel,
    required this.pasteLabel,
    required this.deleteLabel,
    required this.bringToFrontLabel,
    required this.sendToBackLabel,
    required this.onCopy,
    required this.onCut,
    required this.onPaste,
    required this.onDelete,
    required this.onBringToFront,
    required this.onSendToBack,
    super.key,
  });

  final bool hasSelection;
  final bool hasClipboard;
  final bool isSaving;
  final String copyLabel;
  final String cutLabel;
  final String pasteLabel;
  final String deleteLabel;
  final String bringToFrontLabel;
  final String sendToBackLabel;
  final VoidCallback onCopy;
  final VoidCallback onCut;
  final VoidCallback onPaste;
  final VoidCallback onDelete;
  final VoidCallback onBringToFront;
  final VoidCallback onSendToBack;

  @override
  Widget build(BuildContext context) {
    if (!hasSelection && !hasClipboard) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasSelection)
              IconButton(
                tooltip: sendToBackLabel,
                onPressed: isSaving ? null : onSendToBack,
                icon: const Icon(Icons.vertical_align_bottom_rounded),
              ),
            if (hasSelection)
              IconButton(
                tooltip: bringToFrontLabel,
                onPressed: isSaving ? null : onBringToFront,
                icon: const Icon(Icons.vertical_align_top_rounded),
              ),
            if (hasSelection)
              IconButton(
                tooltip: copyLabel,
                onPressed: isSaving ? null : onCopy,
                icon: const Icon(Icons.copy_rounded),
              ),
            if (hasSelection)
              IconButton(
                tooltip: cutLabel,
                onPressed: isSaving ? null : onCut,
                icon: const Icon(Icons.content_cut_rounded),
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
                color: colorScheme.error,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
