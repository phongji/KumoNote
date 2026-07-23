import 'package:kumo_note/features/page/presentation/screens/notebook_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumo_note/features/drawing/presentation/screens/page_editor_screen.dart';
import 'package:kumo_note/features/library/application/providers/library_providers.dart';
import 'package:kumo_note/features/library/domain/entities/notebook.dart';
import 'package:kumo_note/features/library/presentation/widgets/notebook_card.dart';
import 'package:kumo_note/features/library/presentation/trash_screen.dart';
import 'package:kumo_note/features/pdf/presentation/screens/pdf_document_screen.dart';
import 'package:kumo_note/features/search/application/providers/search_providers.dart';
import 'package:kumo_note/features/search/domain/entities/library_search_result.dart';
import 'package:kumo_note/features/search/domain/entities/pdf_file_search_result.dart';
import 'package:kumo_note/l10n/app_localizations.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final notebooks = ref.watch(notebookListProvider);
    final isWideScreen = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isWideScreen)
              _LibraryNavigation(
                strings: strings,
                extended: MediaQuery.sizeOf(context).width >= 1180,
              ),
            Expanded(
              child: _LibraryContent(
                strings: strings,
                notebooks: notebooks,
                onCreateNotebook: () {
                  _showCreateNotebookDialog(
                    context: context,
                    ref: ref,
                    strings: strings,
                  );
                },
                onRenameNotebook: (notebook) {
                  _showRenameNotebookDialog(
                    context: context,
                    ref: ref,
                    strings: strings,
                    notebook: notebook,
                  );
                },
                onToggleFavorite: (notebook) {
                  _toggleFavorite(
                    context: context,
                    ref: ref,
                    strings: strings,
                    notebook: notebook,
                  );
                },
                onMoveToTrash: (notebook) {
                  _confirmMoveToTrash(
                    context: context,
                    ref: ref,
                    strings: strings,
                    notebook: notebook,
                  );
                },
                onRetry: () {
                  ref.read(notebookListProvider.notifier).reload();
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              selectedIndex: 0,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.auto_stories_outlined),
                  selectedIcon: const Icon(Icons.auto_stories),
                  label: strings.library,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.star_outline_rounded),
                  selectedIcon: const Icon(Icons.star_rounded),
                  label: strings.favorites,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.folder_outlined),
                  selectedIcon: const Icon(Icons.folder_rounded),
                  label: strings.folders,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: strings.settings,
                ),
              ],
            ),
    );
  }

  Future<void> _showCreateNotebookDialog({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations strings,
  }) async {
    final formKey = GlobalKey<FormState>();
    var notebookTitle = '';

    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.newNotebookTitle),
          content: Form(
            key: formKey,
            child: TextFormField(
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: strings.notebookNameLabel,
                hintText: strings.notebookNameHint,
              ),
              onChanged: (value) {
                notebookTitle = value;
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return strings.notebookNameLabel;
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(notebookTitle.trim());
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(notebookTitle.trim());
                }
              },
              child: Text(strings.create),
            ),
          ],
        );
      },
    );

    if (title == null || !context.mounted) {
      return;
    }

    await ref.read(notebookListProvider.notifier).createNotebook(title);

    if (!context.mounted) {
      return;
    }

    if (_showErrorIfNeeded(context, ref, strings)) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.notebookCreated)));
  }

  Future<void> _showRenameNotebookDialog({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations strings,
    required Notebook notebook,
  }) async {
    final formKey = GlobalKey<FormState>();
    var notebookTitle = notebook.title;

    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.rename),
          content: Form(
            key: formKey,
            child: TextFormField(
              initialValue: notebook.title,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: strings.notebookNameLabel),
              onChanged: (value) {
                notebookTitle = value;
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return strings.notebookNameLabel;
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(notebookTitle.trim());
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(notebookTitle.trim());
                }
              },
              child: Text(strings.rename),
            ),
          ],
        );
      },
    );

    if (newTitle == null || !context.mounted) {
      return;
    }

    await ref
        .read(notebookListProvider.notifier)
        .renameNotebook(notebookId: notebook.id, newTitle: newTitle);

    if (!context.mounted) {
      return;
    }

    _showErrorIfNeeded(context, ref, strings);
  }

  Future<void> _toggleFavorite({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations strings,
    required Notebook notebook,
  }) async {
    await ref.read(notebookListProvider.notifier).toggleFavorite(notebook.id);

    if (!context.mounted) {
      return;
    }

    _showErrorIfNeeded(context, ref, strings);
  }

  Future<void> _confirmMoveToTrash({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations strings,
    required Notebook notebook,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.moveToTrash),
          content: Text(notebook.title),
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
              child: Text(strings.moveToTrash),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref.read(notebookListProvider.notifier).moveToTrash(notebook.id);

    if (!context.mounted) {
      return;
    }

    _showErrorIfNeeded(context, ref, strings);
  }

  bool _showErrorIfNeeded(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations strings,
  ) {
    final result = ref.read(notebookListProvider);

    if (!result.hasError) {
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.libraryErrorBody),
        action: SnackBarAction(
          label: strings.tryAgain,
          onPressed: () {
            ref.read(notebookListProvider.notifier).reload();
          },
        ),
      ),
    );

    return true;
  }
}

class _LibraryNavigation extends StatelessWidget {
  const _LibraryNavigation({required this.strings, required this.extended});

  final AppLocalizations strings;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      onDestinationSelected: (index) {
        if (index == 4) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (context) => const TrashScreen()),
          );
        }
      },
      selectedIndex: 0,
      extended: extended,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
        child: _KumoMark(showName: extended),
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.auto_stories_outlined),
          selectedIcon: const Icon(Icons.auto_stories),
          label: Text(strings.library),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.schedule_outlined),
          selectedIcon: const Icon(Icons.schedule),
          label: Text(strings.recent),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.star_outline_rounded),
          selectedIcon: const Icon(Icons.star_rounded),
          label: Text(strings.favorites),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.folder_outlined),
          selectedIcon: const Icon(Icons.folder_rounded),
          label: Text(strings.folders),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.delete_outline_rounded),
          selectedIcon: const Icon(Icons.delete_rounded),
          label: Text(strings.trash),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(strings.settings),
        ),
      ],
    );
  }
}

class _LibraryContent extends ConsumerStatefulWidget {
  const _LibraryContent({
    required this.strings,
    required this.notebooks,
    required this.onCreateNotebook,
    required this.onRenameNotebook,
    required this.onToggleFavorite,
    required this.onMoveToTrash,
    required this.onRetry,
  });

  final AppLocalizations strings;
  final AsyncValue<List<Notebook>> notebooks;
  final VoidCallback onCreateNotebook;
  final ValueChanged<Notebook> onRenameNotebook;
  final ValueChanged<Notebook> onToggleFavorite;
  final ValueChanged<Notebook> onMoveToTrash;
  final VoidCallback onRetry;

  @override
  ConsumerState<_LibraryContent> createState() {
    return _LibraryContentState();
  }
}

class _LibraryContentState extends ConsumerState<_LibraryContent> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth >= 900 ? 48.0 : 20.0;
    final normalizedQuery = _searchQuery.trim();
    final textResults = normalizedQuery.isEmpty
        ? null
        : ref.watch(libraryTextSearchProvider(normalizedQuery));
    final pdfResults = normalizedQuery.isEmpty
        ? null
        : ref.watch(libraryPdfFileSearchProvider(normalizedQuery));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (screenWidth < 900) ...[
                  const _KumoMark(showName: true),
                  const SizedBox(height: 32),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.strings.welcomeBack,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.strings.captureThought,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: widget.strings.settings,
                      onPressed: () {},
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: widget.strings.search,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: widget.strings.cancel,
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                _QuickActions(
                  strings: widget.strings,
                  onCreateNotebook: widget.onCreateNotebook,
                ),
                const SizedBox(height: 40),
                Text(
                  widget.strings.allNotebooks,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            40,
          ),
          sliver: SliverToBoxAdapter(
            child: widget.notebooks.when(
              data: (items) {
                if (items.isEmpty && normalizedQuery.isEmpty) {
                  return _EmptyLibrary(strings: widget.strings);
                }

                final filteredItems = _filterNotebooks(items);

                if (normalizedQuery.isEmpty) {
                  return _NotebookGrid(
                    notebooks: filteredItems,
                    onRenameNotebook: widget.onRenameNotebook,
                    onToggleFavorite: widget.onToggleFavorite,
                    onMoveToTrash: widget.onMoveToTrash,
                  );
                }

                return _CombinedSearchResults(
                  query: normalizedQuery,
                  notebooks: filteredItems,
                  textResults:
                      textResults ??
                      const AsyncData<List<LibrarySearchResult>>([]),
                  pdfResults:
                      pdfResults ??
                      const AsyncData<List<PdfFileSearchResult>>([]),
                  strings: widget.strings,
                  onRenameNotebook: widget.onRenameNotebook,
                  onToggleFavorite: widget.onToggleFavorite,
                  onMoveToTrash: widget.onMoveToTrash,
                );
              },
              loading: () {
                return _LoadingLibrary(strings: widget.strings);
              },
              error: (error, stackTrace) {
                return _LibraryError(
                  strings: widget.strings,
                  onRetry: widget.onRetry,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Notebook> _filterNotebooks(List<Notebook> notebooks) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return notebooks;
    }

    return notebooks
        .where((notebook) {
          return notebook.title.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
  }
}

class _CombinedSearchResults extends StatelessWidget {
  const _CombinedSearchResults({
    required this.query,
    required this.notebooks,
    required this.textResults,
    required this.pdfResults,
    required this.strings,
    required this.onRenameNotebook,
    required this.onToggleFavorite,
    required this.onMoveToTrash,
  });

  final String query;
  final List<Notebook> notebooks;
  final AsyncValue<List<LibrarySearchResult>> textResults;
  final AsyncValue<List<PdfFileSearchResult>> pdfResults;
  final AppLocalizations strings;
  final ValueChanged<Notebook> onRenameNotebook;
  final ValueChanged<Notebook> onToggleFavorite;
  final ValueChanged<Notebook> onMoveToTrash;

  @override
  Widget build(BuildContext context) {
    return textResults.when(
      loading: () => _buildLoading(context),
      error: (_, _) => _buildError(context),
      data: (insideResults) {
        return pdfResults.when(
          loading: () => _buildLoading(context),
          error: (_, _) => _buildError(context),
          data: (pdfFileResults) {
            if (notebooks.isEmpty &&
                insideResults.isEmpty &&
                pdfFileResults.isEmpty) {
              return _EmptySearchResult(
                query: query,
                searchLabel: strings.search,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (notebooks.isNotEmpty)
                  _NotebookGrid(
                    notebooks: notebooks,
                    onRenameNotebook: onRenameNotebook,
                    onToggleFavorite: onToggleFavorite,
                    onMoveToTrash: onMoveToTrash,
                  ),
                if (notebooks.isNotEmpty &&
                    (pdfFileResults.isNotEmpty || insideResults.isNotEmpty))
                  const SizedBox(height: 28),
                if (pdfFileResults.isNotEmpty) ...[
                  _SearchSectionTitle(
                    icon: Icons.picture_as_pdf_outlined,
                    label: strings.pdfDocument,
                  ),
                  const SizedBox(height: 10),
                  for (final result in pdfFileResults)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PdfSearchResultTile(
                        result: result,
                        pageCountLabel: strings.pdfPageCount(result.pageCount),
                      ),
                    ),
                ],
                if (pdfFileResults.isNotEmpty && insideResults.isNotEmpty)
                  const SizedBox(height: 20),
                if (insideResults.isNotEmpty) ...[
                  _SearchSectionTitle(
                    icon: Icons.text_snippet_outlined,
                    label: strings.textTool,
                  ),
                  const SizedBox(height: 10),
                  for (final result in insideResults)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _InsideSearchResultTile(result: result),
                    ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Column(
      children: [
        if (notebooks.isNotEmpty)
          _NotebookGrid(
            notebooks: notebooks,
            onRenameNotebook: onRenameNotebook,
            onToggleFavorite: onToggleFavorite,
            onMoveToTrash: onMoveToTrash,
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: LinearProgressIndicator(),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    if (notebooks.isEmpty) {
      return _EmptySearchResult(query: query, searchLabel: strings.search);
    }

    return _NotebookGrid(
      notebooks: notebooks,
      onRenameNotebook: onRenameNotebook,
      onToggleFavorite: onToggleFavorite,
      onMoveToTrash: onMoveToTrash,
    );
  }
}

class _SearchSectionTitle extends StatelessWidget {
  const _SearchSectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _PdfSearchResultTile extends StatelessWidget {
  const _PdfSearchResultTile({
    required this.result,
    required this.pageCountLabel,
  });

  final PdfFileSearchResult result;
  final String pageCountLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          Icons.picture_as_pdf_outlined,
          color: colorScheme.primary,
        ),
        title: Text(
          result.document.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${result.notebook.title} • $pageCountLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) {
                return PdfDocumentScreen(
                  document: result.document,
                  pages: result.pages,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _InsideSearchResultTile extends StatelessWidget {
  const _InsideSearchResultTile({required this.result});

  final LibrarySearchResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(Icons.notes_rounded, color: colorScheme.primary),
        title: Text(
          result.matchedText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${result.notebook.title} • ${result.pageNumber}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) {
                return PageEditorScreen(
                  page: result.page,
                  pageNumber: result.pageNumber,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult({required this.query, required this.searchLabel});

  final String query;
  final String searchLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: colorScheme.outline),
          const SizedBox(height: 12),
          Text(searchLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '"$query"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.strings, required this.onCreateNotebook});

  final AppLocalizations strings;
  final VoidCallback onCreateNotebook;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: onCreateNotebook,
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.newNotebook),
        ),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.edit_note_rounded),
          label: Text(strings.quickNote),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotebookGrid extends StatelessWidget {
  const _NotebookGrid({
    required this.notebooks,
    required this.onRenameNotebook,
    required this.onToggleFavorite,
    required this.onMoveToTrash,
  });

  final List<Notebook> notebooks;
  final ValueChanged<Notebook> onRenameNotebook;
  final ValueChanged<Notebook> onToggleFavorite;
  final ValueChanged<Notebook> onMoveToTrash;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = switch (constraints.maxWidth) {
          >= 1100 => 4,
          >= 760 => 3,
          >= 480 => 2,
          _ => 1,
        };

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notebooks.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final notebook = notebooks[index];

            return NotebookCard(
              notebook: notebook,
              onOpen: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) {
                      return NotebookScreen(
                        notebookId: notebook.id,
                        notebookName: notebook.title,
                      );
                    },
                  ),
                );
              },
              onRename: () {
                onRenameNotebook(notebook);
              },
              onToggleFavorite: () {
                onToggleFavorite(notebook);
              },
              onMoveToTrash: () {
                onMoveToTrash(notebook);
              },
            );
          },
        );
      },
    );
  }
}

class _LoadingLibrary extends StatelessWidget {
  const _LoadingLibrary({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(strings.loadingNotebooks),
          ],
        ),
      ),
    );
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.strings, required this.onRetry});

  final AppLocalizations strings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            strings.libraryErrorTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            strings.libraryErrorBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRetry, child: Text(strings.tryAgain)),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 52),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 34,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            strings.emptyLibraryTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              strings.emptyLibraryBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _KumoMark extends StatelessWidget {
  const _KumoMark({required this.showName});

  final bool showName;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.cloud_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
        if (showName) ...[
          const SizedBox(width: 12),
          Text('Kumo Notes', style: Theme.of(context).textTheme.titleLarge),
        ],
      ],
    );
  }
}
