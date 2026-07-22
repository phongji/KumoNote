import 'package:flutter/material.dart';
import 'package:kumo_note/l10n/app_localizations.dart';

import '../../application/state/drawing_state.dart';

final class EraserModePicker extends StatelessWidget {
  const EraserModePicker({
    required this.selectedMode,
    required this.isEraserSelected,
    required this.onSelectEraser,
    required this.onModeSelected,
    super.key,
  });

  final EraserMode selectedMode;
  final bool isEraserSelected;
  final VoidCallback onSelectEraser;
  final ValueChanged<EraserMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: strings.eraser,
          isSelected: isEraserSelected,
          onPressed: onSelectEraser,
          icon: const Icon(Icons.cleaning_services_outlined),
          selectedIcon: const Icon(Icons.cleaning_services),
        ),
        PopupMenuButton<EraserMode>(
          tooltip: strings.moreActions,
          initialValue: selectedMode,
          onSelected: onModeSelected,
          icon: const Icon(Icons.arrow_drop_down),
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                value: EraserMode.partial,
                child: Row(
                  children: [
                    const Icon(Icons.blur_circular_outlined),
                    const SizedBox(width: 12),
                    Expanded(child: Text(strings.partialEraser)),
                    if (selectedMode == EraserMode.partial)
                      const Icon(Icons.check),
                  ],
                ),
              ),
              PopupMenuItem(
                value: EraserMode.wholeStroke,
                child: Row(
                  children: [
                    const Icon(Icons.gesture),
                    const SizedBox(width: 12),
                    Expanded(child: Text(strings.wholeStroke)),
                    if (selectedMode == EraserMode.wholeStroke)
                      const Icon(Icons.check),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }
}
