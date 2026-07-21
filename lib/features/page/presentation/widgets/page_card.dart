import 'package:flutter/material.dart';

import '../../domain/entities/note_page.dart';

final class PageCard extends StatelessWidget {
  const PageCard({
    required this.page,
    required this.pageNumber,
    required this.onOpen,
    required this.onMoveToTrash,
    super.key,
  });

  final NotePage page;
  final int pageNumber;
  final VoidCallback onOpen;
  final VoidCallback onMoveToTrash;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: colorScheme.surface,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PageTemplatePainter(
                          template: page.template,
                          lineColor: colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.description_outlined,
                        size: 42,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$pageNumber',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: onMoveToTrash,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PageTemplatePainter extends CustomPainter {
  const _PageTemplatePainter({required this.template, required this.lineColor});

  final PageTemplate template;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    switch (template) {
      case PageTemplate.blank:
        return;

      case PageTemplate.ruled:
        for (double y = 28; y < size.height; y += 24) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        break;

      case PageTemplate.grid:
        for (double y = 24; y < size.height; y += 24) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }

        for (double x = 24; x < size.width; x += 24) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        break;

      case PageTemplate.dotted:
        for (double y = 20; y < size.height; y += 20) {
          for (double x = 20; x < size.width; x += 20) {
            canvas.drawCircle(Offset(x, y), 1.2, paint);
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PageTemplatePainter oldDelegate) {
    return template != oldDelegate.template ||
        lineColor != oldDelegate.lineColor;
  }
}
