import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/controllers/page_controller.dart';
import '../../application/providers/page_providers.dart';

final class PageTrashScreen extends ConsumerWidget {
  const PageTrashScreen({required this.notebookId, super.key});

  final String notebookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final pages = ref.watch(deletedPageListProvider(notebookId));
    final controller = ref.read(pageControllerProvider(notebookId));

    return Scaffold(
      appBar: AppBar(title: Text(strings.trash)),
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
            return const Center(child: Icon(Icons.delete_outline, size: 64));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final page = items[index];
              final originalPageNumber = page.sortOrder ~/ 1000;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text('$originalPageNumber'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: strings.restore,
                        onPressed: () {
                          controller.restore(page.id);
                        },
                        icon: const Icon(Icons.restore),
                      ),
                      IconButton(
                        tooltip: strings.deleteForever,
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () {
                          controller.deleteForever(page.id);
                        },
                        icon: const Icon(Icons.delete_forever_outlined),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
