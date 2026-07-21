import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumo_note/app/theme/kumo_theme.dart';
import 'package:kumo_note/features/library/presentation/library_screen.dart';
import 'package:kumo_note/l10n/app_localizations.dart';

class KumoApp extends ConsumerWidget {
  const KumoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) {
        return AppLocalizations.of(context)!.appName;
      },
      theme: KumoTheme.light,
      darkTheme: KumoTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LibraryScreen(),
    );
  }
}
