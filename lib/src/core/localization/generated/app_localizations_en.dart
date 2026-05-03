// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kotoba Kit';

  @override
  String get navHome => 'Home';

  @override
  String get navDictionary => 'Dictionary';

  @override
  String get navSettings => 'Settings';

  @override
  String get navComponents => 'Components';

  @override
  String get navAbout => 'About';

  @override
  String get navCollapseSidebar => 'Collapse sidebar';

  @override
  String get navExpandSidebar => 'Expand sidebar';

  @override
  String get homeTitle => 'Kotoba Kit';

  @override
  String get homeSubtitle =>
      'An offline-first Japanese dictionary workspace, with learning tools growing around reliable local lookup.';

  @override
  String get openSettingsTooltip => 'Open settings';

  @override
  String get homeStatusLoading => 'Loading settings';

  @override
  String get homeStatusReady => 'Dictionary core in progress';

  @override
  String get homeStatusDescription =>
      'The first milestone is local MDict import, exact lookup, and stable dictionary management.';

  @override
  String get capabilityCrossPlatformTitle => 'Offline-first base';

  @override
  String get capabilityCrossPlatformDescription =>
      'Imported dictionaries live in the app data directory instead of bundled assets.';

  @override
  String get capabilityThemeTitle => 'Local lookup';

  @override
  String get capabilityThemeDescription =>
      'MDX files are opened locally, with readers cached for repeated searches.';

  @override
  String get capabilityRoutingTitle => 'Dictionary-first route';

  @override
  String get capabilityRoutingDescription =>
      'The app opens directly to the dictionary workspace while the MVP is being built.';

  @override
  String get capabilityExtensionTitle => 'Later learning modules';

  @override
  String get capabilityExtensionDescription =>
      'Sentence practice, TTS, and visual lookup can attach to the same lookup core later.';

  @override
  String get nextStepsTitle => 'Suggested next steps';

  @override
  String get nextStepFeature =>
      'Test real Japanese MDX files against dict_reader compatibility';

  @override
  String get nextStepRepository =>
      'Add dictionary metadata and cached reader lifecycle around imports';

  @override
  String get nextStepDesktop =>
      'Keep file import and search responsive for large dictionaries';

  @override
  String get stateComponentsTitle => 'UI state components';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle =>
      'Only common preferences live here; feature settings can be added by section.';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsThemeModeTitle => 'Theme mode';

  @override
  String get settingsThemeModeSubtitle => 'Follow system, light, or dark mode.';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get settingsThemeColorTitle => 'Theme color';

  @override
  String get settingsThemeColorSubtitle =>
      'Material 3 generates the full palette from the seed color.';

  @override
  String get settingsExperienceTitle => 'Experience';

  @override
  String get settingsPureBlackTitle => 'OLED dark enhancement';

  @override
  String get settingsPureBlackSubtitle =>
      'Use a purer black surface in dark mode.';

  @override
  String get settingsCompactDensityTitle => 'Compact density';

  @override
  String get settingsCompactDensitySubtitle =>
      'Make desktop and information-dense pages more restrained.';

  @override
  String get settingsOtherTitle => 'Other';

  @override
  String get settingsResetAction => 'Reset';

  @override
  String get settingsResetTitle => 'Reset preferences';

  @override
  String get settingsResetMessage =>
      'Theme, color, and experience options will return to the template defaults.';

  @override
  String get settingsResetConfirm => 'Reset';

  @override
  String get settingsResetSuccess => 'Preferences were reset';

  @override
  String settingsSaveFailed(String error) {
    return 'Failed to save settings: $error';
  }

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutSubtitle =>
      'A general, extensible, cross-platform-first Flutter template.';

  @override
  String get aboutBackToSettings => 'Back to settings';

  @override
  String get aboutStructureTitle => 'Project structure';

  @override
  String get aboutCoreLabel => 'core';

  @override
  String get aboutCoreValue =>
      'Routing, theme, settings, and other infrastructure';

  @override
  String get aboutFeaturesLabel => 'features';

  @override
  String get aboutFeaturesValue => 'Pages and state split by feature';

  @override
  String get aboutSharedLabel => 'shared';

  @override
  String get aboutSharedValue => 'Reusable UI shared across features';

  @override
  String get aboutVersionTitle => 'Version';

  @override
  String get aboutAppNameLabel => 'App name';

  @override
  String get aboutPackageLabel => 'Package';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get aboutBuildLabel => 'Build';

  @override
  String get aboutEnvironmentTitle => 'Environment';

  @override
  String get aboutEnvironmentLabel => 'Environment';

  @override
  String get aboutApiBaseUrlLabel => 'API base URL';

  @override
  String get aboutVerboseLogsLabel => 'Verbose logs';

  @override
  String get commonEnabled => 'Enabled';

  @override
  String get commonDisabled => 'Disabled';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get backAgainToExit => 'Press back again to exit';

  @override
  String get commandPaletteSearchHint => 'Search pages or actions';

  @override
  String get commandPaletteNoResults => 'No matching actions';

  @override
  String get commandPaletteExecuted => 'Action executed';

  @override
  String get commandGoHome => 'Go to Home';

  @override
  String get commandGoDictionary => 'Go to Dictionary';

  @override
  String get commandGoSettings => 'Go to Settings';

  @override
  String get commandGoComponents => 'Go to Components';

  @override
  String get commandGoAbout => 'Go to About';

  @override
  String get componentsTitle => 'Components';

  @override
  String get componentsSubtitle =>
      'Preview the template\'s reusable UI states and interaction components across platforms.';

  @override
  String get componentsStatesTitle => 'State views';

  @override
  String get componentsAsyncTitle => 'AsyncValue views';

  @override
  String get componentsAsyncData => 'Data';

  @override
  String get componentsAsyncReady => 'Data state is ready';

  @override
  String get componentsDialogsTitle => 'Confirm dialogs';

  @override
  String get componentsDialogsDescription =>
      'Use this for dangerous actions, exit prompts, deletion prompts, and other explicit choices.';

  @override
  String get componentsDialogTitle => 'Confirm action';

  @override
  String get componentsDialogMessage =>
      'This is a template confirm dialog. Feature code can replace the title, message, and labels.';

  @override
  String get componentsOpenDialog => 'Open dialog';

  @override
  String get componentsFeedbackTitle => 'Feedback messages';

  @override
  String get componentsFeedbackDescription =>
      'Use these for save success, lightweight reminders, and errors through the global ScaffoldMessenger.';

  @override
  String get componentsShowSuccess => 'Show success';

  @override
  String get componentsShowError => 'Show error';

  @override
  String get componentsSuccessToast => 'Action completed';

  @override
  String get componentsErrorToast => 'Action failed. Try again later';

  @override
  String get componentsStyleTitle => 'Control style';

  @override
  String get componentsStyleDescription =>
      'Buttons, inputs, and selectors share one token system so feature UI stays consistent.';

  @override
  String get componentsPrimaryButton => 'Primary';

  @override
  String get componentsTonalButton => 'Tonal';

  @override
  String get componentsOutlineButton => 'Outline';

  @override
  String get componentsSearchLabel => 'Search';

  @override
  String get componentsCompactChoice => 'Compact';

  @override
  String get componentsComfortChoice => 'Comfort';

  @override
  String get stateRetry => 'Retry';

  @override
  String get stateLoading => 'Loading';

  @override
  String get stateEmptyTitle => 'Nothing here yet';

  @override
  String get stateEmptyMessage => 'There is no data to show right now.';

  @override
  String get stateErrorTitle => 'Something went wrong';

  @override
  String get stateErrorMessage =>
      'Try again later or check the current environment configuration.';

  @override
  String get dictionaryTitle => 'Dictionary';

  @override
  String get dictionarySubtitle =>
      'Look up words across local dictionaries and online sources. Manage dictionaries in Settings.';

  @override
  String get dictionarySettingsTitle => 'Dictionaries';

  @override
  String get dictionaryImport => 'Import MDX';

  @override
  String get dictionaryImporting => 'Importing';

  @override
  String get dictionaryUnsupportedTitle => 'Local dictionary unavailable';

  @override
  String get dictionaryUnsupportedMessage =>
      'This platform cannot open local MDict files yet.';

  @override
  String get dictionarySearchTitle => 'Lookup';

  @override
  String get dictionarySearchLabel => 'Word';

  @override
  String get dictionarySearchHint => '食べる';

  @override
  String get dictionarySearchButton => 'Search';

  @override
  String get dictionaryNoEnabledDictionaries =>
      'Import or enable a dictionary before searching.';

  @override
  String get dictionaryInstalledTitle => 'Installed dictionaries';

  @override
  String get dictionaryEmptyTitle => 'No dictionaries imported';

  @override
  String get dictionaryEmptyMessage =>
      'Import an .mdx file to start the compatibility check.';

  @override
  String dictionaryEntryCount(int count) {
    return '$count entries';
  }

  @override
  String get dictionaryDelete => 'Delete dictionary';

  @override
  String get dictionaryResultsTitle => 'Results';

  @override
  String get dictionaryResultsPlaceholder => 'Search results will appear here.';

  @override
  String dictionaryNoResults(String query) {
    return 'No exact match for \"$query\".';
  }

  @override
  String get dictionarySuggestionsTitle => 'Prefix matches';

  @override
  String dictionaryImportSuccess(String name) {
    return 'Imported $name';
  }

  @override
  String dictionaryOperationFailed(String error) {
    return 'Dictionary operation failed: $error';
  }
}
