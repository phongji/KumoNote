import 'page_trash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/page_controller.dart';
import '../../application/providers/page_providers.dart';
import '../widgets/page_card.dart';

final class NotebookScreen extends ConsumerWidget {
  const NotebookScreen({
    required this.notebookId,
    required this.notebookName,
    super.key,
  });

  final String notebookId;
  final String notebookName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(activePageListProvider(notebookId));
    final controller = ref.read(pageControllerProvider(notebookId));

    return Scaffold(
      appBar: AppBar(
        title: Text(notebookName),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return PageTrashScreen(notebookId: notebookId);
                  },
                ),
              );
            },
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            onPressed: controller.createPage,
            icon: const Icon(Icons.note_add_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: pages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: IconButton.filledTonal(
            onPressed: controller.reload,
            icon: const Icon(Icons.refresh),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: IconButton.filled(
                onPressed: controller.createPage,
                iconSize: 36,
                padding: const EdgeInsets.all(24),
                icon: const Icon(Icons.note_add_outlined),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = switch (constraints.maxWidth) {
                >= 1200 => 5,
                >= 900 => 4,
                >= 600 => 3,
                >= 360 => 2,
                _ => 1,
              };

              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.72,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final page = items[index];
                  final pageNumber = page.sortOrder ~/ 1000;

                  return PageCard(
                    key: ValueKey(page.id),
                    page: page,
                    pageNumber: pageNumber,
                    onOpen: () {},
                    onMoveToTrash: () {
                      controller.moveToTrash(page.id);
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.createPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}
