import 'package:flutter/material.dart';
import 'package:kumo_note/features/library/domain/entities/notebook.dart';
import 'package:kumo_note/l10n/app_localizations.dart';

enum NotebookAction { rename, toggleFavorite, moveToTrash }

class NotebookCard extends StatelessWidget {
  const NotebookCard({
    required this.notebook,
    required this.onRename,
    required this.onToggleFavorite,
    required this.onMoveToTrash,
    this.onOpen,
    super.key,
  });

  final Notebook notebook;
  final VoidCallback onRename;
  final VoidCallback onToggleFavorite;
  final VoidCallback onMoveToTrash;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context)!;
    final coverColor = Color(notebook.coverColorValue);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: coverColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      notebook.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (notebook.isFavorite)
                    Icon(
                      Icons.star_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  PopupMenuButton<NotebookAction>(
                    tooltip: strings.moreActions,
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) {
                      switch (action) {
                        case NotebookAction.rename:
                          onRename();
                        case NotebookAction.toggleFavorite:
                          onToggleFavorite();
                        case NotebookAction.moveToTrash:
                          onMoveToTrash();
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          value: NotebookAction.rename,
                          child: ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: Text(strings.rename),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: NotebookAction.toggleFavorite,
                          child: ListTile(
                            leading: Icon(
                              notebook.isFavorite
                                  ? Icons.star_outline_rounded
                                  : Icons.star_rounded,
                            ),
                            title: Text(
                              notebook.isFavorite
                                  ? strings.removeFavorite
                                  : strings.favorite,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: NotebookAction.moveToTrash,
                          child: ListTile(
                            leading: const Icon(Icons.delete_outline_rounded),
                            title: Text(strings.moveToTrash),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
