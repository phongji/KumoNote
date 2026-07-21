import 'package:flutter/material.dart';
import 'package:kumo_note/l10n/app_localizations.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
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
            Expanded(child: _LibraryContent(strings: strings)),
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
}

class _LibraryNavigation extends StatelessWidget {
  const _LibraryNavigation({required this.strings, required this.extended});

  final AppLocalizations strings;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
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

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth >= 900 ? 48.0 : 20.0;

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
                            strings.welcomeBack,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.captureThought,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: strings.settings,
                      onPressed: () {},
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                TextField(
                  decoration: InputDecoration(
                    hintText: strings.search,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                _QuickActions(strings: strings),
                const SizedBox(height: 40),
                Text(strings.allNotebooks, style: theme.textTheme.titleLarge),
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
          sliver: SliverToBoxAdapter(child: _EmptyLibrary(strings: strings)),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.newNotebook),
        ),
        OutlinedButton.icon(
          onPressed: () {},
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
