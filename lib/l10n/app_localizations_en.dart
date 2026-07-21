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

  @override
  String get newNotebookTitle => 'Create a notebook';

  @override
  String get notebookNameLabel => 'Notebook name';

  @override
  String get notebookNameHint => 'For example, Meeting notes';

  @override
  String get create => 'Create';

  @override
  String get cancel => 'Cancel';

  @override
  String get untitledNotebook => 'Untitled notebook';

  @override
  String get loadingNotebooks => 'Opening your library…';

  @override
  String get libraryErrorTitle => 'Your library could not be opened';

  @override
  String get libraryErrorBody => 'Your notes are safe. Please try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get notebookCreated => 'Notebook created';

  @override
  String get moreActions => 'More actions';

  @override
  String get favorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get rename => 'Rename';

  @override
  String get moveToTrash => 'Move to trash';

  @override
  String get trashEmptyTitle => 'Trash is empty';

  @override
  String get trashEmptyBody => 'Notebooks moved here can be restored.';

  @override
  String get restore => 'Restore';

  @override
  String get deleteForever => 'Delete forever';

  @override
  String get deleteForeverTitle => 'Delete this notebook forever?';

  @override
  String get deleteForeverBody =>
      'This cannot be undone. The notebook and its contents will be permanently removed.';

  @override
  String get notebookRestored => 'Notebook restored';
}
