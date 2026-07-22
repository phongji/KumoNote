import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Kumo Notes'**
  String get appName;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @captureThought.
  ///
  /// In en, this message translates to:
  /// **'Capture a thought'**
  String get captureThought;

  /// No description provided for @newNotebook.
  ///
  /// In en, this message translates to:
  /// **'New notebook'**
  String get newNotebook;

  /// No description provided for @quickNote.
  ///
  /// In en, this message translates to:
  /// **'Quick note'**
  String get quickNote;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @allNotebooks.
  ///
  /// In en, this message translates to:
  /// **'All notebooks'**
  String get allNotebooks;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @emptyLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your space is ready'**
  String get emptyLibraryTitle;

  /// No description provided for @emptyLibraryBody.
  ///
  /// In en, this message translates to:
  /// **'Create a notebook and begin with one thought.'**
  String get emptyLibraryBody;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @newNotebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a notebook'**
  String get newNotebookTitle;

  /// No description provided for @notebookNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Notebook name'**
  String get notebookNameLabel;

  /// No description provided for @notebookNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example, Meeting notes'**
  String get notebookNameHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @untitledNotebook.
  ///
  /// In en, this message translates to:
  /// **'Untitled notebook'**
  String get untitledNotebook;

  /// No description provided for @loadingNotebooks.
  ///
  /// In en, this message translates to:
  /// **'Opening your library…'**
  String get loadingNotebooks;

  /// No description provided for @libraryErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library could not be opened'**
  String get libraryErrorTitle;

  /// No description provided for @libraryErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Your notes are safe. Please try again.'**
  String get libraryErrorBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @notebookCreated.
  ///
  /// In en, this message translates to:
  /// **'Notebook created'**
  String get notebookCreated;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get favorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @moveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get moveToTrash;

  /// No description provided for @trashEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmptyTitle;

  /// No description provided for @trashEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Notebooks moved here can be restored.'**
  String get trashEmptyBody;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteForever;

  /// No description provided for @deleteForeverTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this notebook forever?'**
  String get deleteForeverTitle;

  /// No description provided for @deleteForeverBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. The notebook and its contents will be permanently removed.'**
  String get deleteForeverBody;

  /// No description provided for @notebookRestored.
  ///
  /// In en, this message translates to:
  /// **'Notebook restored'**
  String get notebookRestored;

  /// No description provided for @chooseYourPaper.
  ///
  /// In en, this message translates to:
  /// **'Choose your paper'**
  String get chooseYourPaper;

  /// No description provided for @paperSetupHint.
  ///
  /// In en, this message translates to:
  /// **'A quiet space for your next thought.'**
  String get paperSetupHint;

  /// No description provided for @pageDirection.
  ///
  /// In en, this message translates to:
  /// **'Page direction'**
  String get pageDirection;

  /// No description provided for @portrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get portrait;

  /// No description provided for @landscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get landscape;

  /// No description provided for @paperStyle.
  ///
  /// In en, this message translates to:
  /// **'Paper style'**
  String get paperStyle;

  /// No description provided for @paperTone.
  ///
  /// In en, this message translates to:
  /// **'Paper tone'**
  String get paperTone;

  /// No description provided for @createPage.
  ///
  /// In en, this message translates to:
  /// **'Create page'**
  String get createPage;

  /// No description provided for @clearTemplate.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearTemplate;

  /// No description provided for @calmLines.
  ///
  /// In en, this message translates to:
  /// **'Calm Lines'**
  String get calmLines;

  /// No description provided for @softGrid.
  ///
  /// In en, this message translates to:
  /// **'Soft Grid'**
  String get softGrid;

  /// No description provided for @gentleDots.
  ///
  /// In en, this message translates to:
  /// **'Gentle Dots'**
  String get gentleDots;

  /// No description provided for @guidedLines.
  ///
  /// In en, this message translates to:
  /// **'Guided Lines'**
  String get guidedLines;

  /// No description provided for @quietFocus.
  ///
  /// In en, this message translates to:
  /// **'Quiet Focus'**
  String get quietFocus;

  /// No description provided for @twinSpace.
  ///
  /// In en, this message translates to:
  /// **'Twin Space'**
  String get twinSpace;

  /// No description provided for @quietChecklist.
  ///
  /// In en, this message translates to:
  /// **'Quiet Checklist'**
  String get quietChecklist;

  /// No description provided for @yourInk.
  ///
  /// In en, this message translates to:
  /// **'Your ink'**
  String get yourInk;

  /// No description provided for @colorPalette.
  ///
  /// In en, this message translates to:
  /// **'Color palette'**
  String get colorPalette;

  /// No description provided for @customColor.
  ///
  /// In en, this message translates to:
  /// **'Choose your own color'**
  String get customColor;

  /// No description provided for @strokeSize.
  ///
  /// In en, this message translates to:
  /// **'Stroke size'**
  String get strokeSize;

  /// No description provided for @pen.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get pen;

  /// No description provided for @pencil.
  ///
  /// In en, this message translates to:
  /// **'Pencil'**
  String get pencil;

  /// No description provided for @highlighter.
  ///
  /// In en, this message translates to:
  /// **'Highlighter'**
  String get highlighter;

  /// No description provided for @eraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get eraser;

  /// No description provided for @partialEraser.
  ///
  /// In en, this message translates to:
  /// **'Erase a small area'**
  String get partialEraser;

  /// No description provided for @wholeStroke.
  ///
  /// In en, this message translates to:
  /// **'Erase the whole stroke'**
  String get wholeStroke;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @selectionTool.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectionTool;

  /// No description provided for @moveSelection.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get moveSelection;

  /// No description provided for @copySelection.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copySelection;

  /// No description provided for @cutSelection.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cutSelection;

  /// No description provided for @pasteSelection.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get pasteSelection;

  /// No description provided for @deleteSelection.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteSelection;

  /// No description provided for @resizeSelection.
  ///
  /// In en, this message translates to:
  /// **'Resize'**
  String get resizeSelection;

  /// No description provided for @rotateSelection.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotateSelection;

  /// No description provided for @changeSelectionColor.
  ///
  /// In en, this message translates to:
  /// **'Change color'**
  String get changeSelectionColor;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
