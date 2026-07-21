// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kumo Notes';

  @override
  String get library => 'Library';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get captureThought => 'Capture a thought';

  @override
  String get newNotebook => 'New notebook';

  @override
  String get quickNote => 'Quick note';

  @override
  String get recent => 'Recent';

  @override
  String get favorites => 'Favorites';

  @override
  String get folders => 'Folders';

  @override
  String get allNotebooks => 'All notebooks';

  @override
  String get trash => 'Trash';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String get emptyLibraryTitle => 'Your space is ready';

  @override
  String get emptyLibraryBody =>
      'Create a notebook and begin with one thought.';

  @override
  String get saved => 'Saved';
}
