import 'package:flutter/material.dart';

final class StrokeWidthPicker extends StatelessWidget {
  const StrokeWidthPicker({
    required this.selectedWidth,
    required this.onSelected,
    super.key,
  });

  static const widths = <double>[1, 1.5, 2.5, 4, 6, 10, 14, 20];

  final double selectedWidth;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<double>(
      initialValue: selectedWidth,
      onSelected: onSelected,
      icon: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Container(
            width: 26,
            height: selectedWidth.clamp(1, 20),
            decoration: BoxDecoration(
              color: colorScheme.onSurface,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      itemBuilder: (context) {
        return widths.map((width) {
          final isSelected = width == selectedWidth;

          return PopupMenuItem<double>(
            value: width,
            child: SizedBox(
              width: 160,
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        height: width,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (isSelected)
                    Icon(Icons.check, color: colorScheme.primary)
                  else
                    const SizedBox(width: 24),
                ],
              ),
            ),
          );
        }).toList();
      },
    );
  }
}
