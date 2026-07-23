import 'package:flutter/material.dart';

import '../../domain/entities/note_page.dart';
import 'page_content_preview.dart';

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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: PageContentPreview(page: page)),
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
