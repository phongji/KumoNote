import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumo_note/features/library/application/providers/library_providers.dart';
import 'package:kumo_note/features/library/domain/entities/notebook.dart';
import 'package:kumo_note/l10n/app_localizations.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final deletedNotebooks = ref.watch(deletedNotebookListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.trash)),
      body: SafeArea(
        child: deletedNotebooks.when(
          data: (notebooks) {
            if (notebooks.isEmpty) {
              return _EmptyTrash(strings: strings);
            }

            return _TrashList(
              notebooks: notebooks,
              onRestore: (notebook) {
                _restoreNotebook(
                  context: context,
                  ref: ref,
                  strings: strings,
                  notebook: notebook,
                );
              },
              onDeleteForever: (notebook) {
                _confirmDeleteForever(
                  context: context,
                  ref: ref,
                  strings: strings,
                  notebook: notebook,
                );
              },
            );
          },
          loading: () {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(strings.loadingNotebooks),
                ],
              ),
            );
          },
          error: (error, stackTrace) {
            return _TrashError(
              strings: strings,
              onRetry: () {
                ref.invalidate(deletedNotebookListProvider);
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _restoreNotebook({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations strings,
    required Notebook notebook,
  }) async {
    await ref.read(notebookListProvider.notifier).restoreNotebook(notebook.id);

    if (!context.mounted) {
      return;
    }

    final result = ref.read(notebookListProvider);

    if (result.hasError) {
      _showError(context, strings);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.notebookRestored)));
  }

  Future<void> _confirmDeleteForever({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations strings,
    required Notebook notebook,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.deleteForeverTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notebook.title),
              const SizedBox(height: 12),
              Text(strings.deleteForeverBody),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(strings.deleteForever),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref.read(notebookListProvider.notifier).purgeNotebook(notebook.id);

    if (!context.mounted) {
      return;
    }

    final result = ref.read(notebookListProvider);

    if (result.hasError) {
      _showError(context, strings);
    }
  }

  void _showError(BuildContext context, AppLocalizations strings) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.libraryErrorBody)));
  }
}

class _TrashList extends StatelessWidget {
  const _TrashList({
    required this.notebooks,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final List<Notebook> notebooks;
  final ValueChanged<Notebook> onRestore;
  final ValueChanged<Notebook> onDeleteForever;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: notebooks.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final notebook = notebooks[index];

        return _TrashNotebookTile(
          notebook: notebook,
          onRestore: () {
            onRestore(notebook);
          },
          onDeleteForever: () {
            onDeleteForever(notebook);
          },
        );
      },
    );
  }
}

class _TrashNotebookTile extends StatelessWidget {
  const _TrashNotebookTile({
    required this.notebook,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final Notebook notebook;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 72,
              decoration: BoxDecoration(
                color: Color(notebook.coverColorValue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                notebook.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(onPressed: onRestore, child: Text(strings.restore)),
            const SizedBox(width: 8),
            IconButton(
              tooltip: strings.deleteForever,
              onPressed: onDeleteForever,
              color: theme.colorScheme.error,
              icon: const Icon(Icons.delete_forever_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTrash extends StatelessWidget {
  const _EmptyTrash({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 54,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              strings.trashEmptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              strings.trashEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrashError extends StatelessWidget {
  const _TrashError({required this.strings, required this.onRetry});

  final AppLocalizations strings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 18),
            Text(
              strings.libraryErrorTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(strings.libraryErrorBody, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: Text(strings.tryAgain)),
          ],
        ),
      ),
    );
  }
}
