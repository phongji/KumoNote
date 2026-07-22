import 'package:flutter/material.dart';

final class InkColorPicker extends StatelessWidget {
  const InkColorPicker({
    required this.selectedColorValue,
    required this.onSelected,
    super.key,
  });

  static const primaryColors = <int>[0xFF263238, 0xFF1565C0, 0xFFC62828];

  static const paletteColors = <int>[
    0xFF263238,
    0xFF616161,
    0xFF6D4C41,
    0xFFC62828,
    0xFFEF6C00,
    0xFFF9A825,
    0xFF2E7D32,
    0xFF00897B,
    0xFF0288D1,
    0xFF1565C0,
    0xFF6A1B9A,
    0xFFAD1457,
  ];

  final int selectedColorValue;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final colorValue in primaryColors)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _ColorButton(
              colorValue: colorValue,
              isSelected: selectedColorValue == colorValue,
              onTap: () {
                onSelected(colorValue);
              },
            ),
          ),
        IconButton(
          onPressed: () {
            _openColorDialog(context);
          },
          icon: const Icon(Icons.palette_outlined),
        ),
      ],
    );
  }

  Future<void> _openColorDialog(BuildContext context) async {
    final selectedColor = await showDialog<int>(
      context: context,
      builder: (context) {
        return _ColorPaletteDialog(initialColorValue: selectedColorValue);
      },
    );

    if (selectedColor != null) {
      onSelected(selectedColor);
    }
  }
}

final class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.colorValue,
    required this.isSelected,
    required this.onTap,
  });

  final int colorValue;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(colorValue),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 17)
            : null,
      ),
    );
  }
}

final class _ColorPaletteDialog extends StatefulWidget {
  const _ColorPaletteDialog({required this.initialColorValue});

  final int initialColorValue;

  @override
  State<_ColorPaletteDialog> createState() {
    return _ColorPaletteDialogState();
  }
}

final class _ColorPaletteDialogState extends State<_ColorPaletteDialog> {
  late int _selectedColorValue;

  @override
  void initState() {
    super.initState();
    _selectedColorValue = widget.initialColorValue;
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = Color(_selectedColorValue);

    return AlertDialog(
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 76,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: InkColorPicker.paletteColors.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final colorValue = InkColorPicker.paletteColors[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _selectedColorValue = colorValue;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedColorValue == colorValue
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              _SpectrumGrid(
                selectedColorValue: _selectedColorValue,
                onSelected: (colorValue) {
                  setState(() {
                    _selectedColorValue = colorValue;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.close),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedColorValue);
          },
          child: const Icon(Icons.check),
        ),
      ],
    );
  }
}

final class _SpectrumGrid extends StatelessWidget {
  const _SpectrumGrid({
    required this.selectedColorValue,
    required this.onSelected,
  });

  static const columnCount = 18;

  static const colorProfiles = <(double, double)>[
    (0.45, 0.28),
    (0.55, 0.40),
    (0.55, 0.55),
    (0.48, 0.72),
    (0.42, 0.90),
    (0.65, 1.00),
    (0.88, 0.88),
    (1.00, 0.62),
  ];

  final int selectedColorValue;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = constraints.maxWidth / columnCount;

        return SizedBox(
          height: cellSize * colorProfiles.length,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: columnCount * colorProfiles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
            ),
            itemBuilder: (context, index) {
              final column = index % columnCount;
              final row = index ~/ columnCount;
              final profile = colorProfiles[row];
              final hue = column * (360 / columnCount);

              final color = HSVColor.fromAHSV(
                1,
                hue,
                profile.$1,
                profile.$2,
              ).toColor();

              final colorValue = color.toARGB32();
              final isSelected = colorValue == selectedColorValue;

              return GestureDetector(
                onTap: () {
                  onSelected(colorValue);
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
