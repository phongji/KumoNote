import 'package:flutter/material.dart';

import '../../domain/entities/note_page.dart';
import '../painters/paper_template_painter.dart';

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
              child: ColoredBox(
                color: Color(page.paperColor.colorValue),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: PaperTemplatePainter(
                        template: page.template,
                        lineColor: const Color(
                          0xFF7D8583,
                        ).withValues(alpha: 0.34),
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
