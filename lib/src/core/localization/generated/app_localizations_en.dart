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
  String get navDictionary => 'Lookup';

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
      'An offline-first Japanese dictionary and learning toolkit.';

  @override
  String get aboutBackToSettings => 'Back to settings';

  @override
  String get aboutDescriptionTitle => 'About Kotoba Kit';

  @override
  String get aboutDescriptionText =>
      'Kotoba Kit is an offline-first Japanese dictionary and learning toolkit built with Flutter, targeting all major platforms. It features local MDict dictionary lookup, AI-powered sentence practice with multi-provider LLM support, a comprehensive JLPT grammar library, and practice history tracking.';

  @override
  String get aboutTechStackTitle => 'Tech Stack';

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
  String get commandGoDictionary => 'Go to Lookup';

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
  String get dictionaryTitle => 'Lookup';

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
  String get dictionaryHistoryTitle => 'Lookup history';

  @override
  String dictionarySourceFailed(String source, String error) {
    return '$source is temporarily unavailable: $error';
  }

  @override
  String dictionaryImportSuccess(String name) {
    return 'Imported $name';
  }

  @override
  String dictionaryOperationFailed(String error) {
    return 'Dictionary operation failed: $error';
  }

  @override
  String get settingsAiServiceTitle => 'AI Service';

  @override
  String get settingsAiModelTitle => 'AI Model';

  @override
  String get settingsAiModelSubtitle =>
      'Configure the LLM provider and model for practice features.';

  @override
  String get settingsAiProviderTitle => 'Provider';

  @override
  String get settingsAiProviderLabel => 'LLM Provider';

  @override
  String get settingsAiProviderDesc =>
      'Select which AI provider to use for sentence practice.';

  @override
  String get settingsAiCredentialsTitle => 'Credentials';

  @override
  String get settingsAiApiKeyLabel => 'API Key';

  @override
  String get settingsAiApiKeyDesc =>
      'Your API key is stored locally and never sent anywhere except to the provider\'s API.';

  @override
  String get settingsAiModelLabel => 'Model';

  @override
  String get settingsAiModelDesc =>
      'The model name to use for generation and evaluation.';

  @override
  String get settingsAiBaseUrlLabel => 'Base URL';

  @override
  String get settingsAiBaseUrlDesc =>
      'Custom endpoint URL for self-hosted or compatible APIs.';

  @override
  String get settingsAiActionsTitle => 'Actions';

  @override
  String get settingsAiTestConnection => 'Test Connection';

  @override
  String get settingsAiSave => 'Save';

  @override
  String get settingsTestConnectionSuccess => 'Configuration looks valid.';

  @override
  String settingsTestConnectionFailed(String error) {
    return 'Connection test failed: $error';
  }

  @override
  String get settingsTestConnectionNoConfig =>
      'Please enter an API key or configure a local endpoint.';

  @override
  String get settingsSaved => 'Settings saved.';

  @override
  String get navPractice => 'Practice';

  @override
  String get commandGoPractice => 'Go to Practice';

  @override
  String get practiceTitle => 'Sentence Practice';

  @override
  String get practiceSubtitle =>
      'Practice Japanese sentence construction with AI feedback.';

  @override
  String get practiceModeTranslation => 'Translation';

  @override
  String get practiceModeTranslationDesc =>
      'Read Chinese, write Japanese, get scored.';

  @override
  String get practiceModeMultipleChoice => 'Multiple Choice';

  @override
  String get practiceModeMultipleChoiceDesc =>
      'Pick the correct Japanese translation.';

  @override
  String get practiceModeSentenceCheck => 'Free Sentence Check';

  @override
  String get practiceModeSentenceCheckDesc =>
      'Write freely in Japanese and get grammar feedback.';

  @override
  String get practiceDifficulty => 'Difficulty';

  @override
  String get practiceSentenceLength => 'Sentence Length';

  @override
  String get practiceStartButton => 'Start Practice';

  @override
  String get practiceNoApiKey => 'Configure an AI model in Settings first.';

  @override
  String get practiceSubmit => 'Submit';

  @override
  String get practiceNextTask => 'Next Task';

  @override
  String get practiceTryAgain => 'Try Again';

  @override
  String get practiceBackToMenu => 'Back to Menu';

  @override
  String get practiceScore => 'Score';

  @override
  String get practiceEvaluation => 'Evaluation';

  @override
  String get practiceCorrectedSentence => 'Corrected Sentence';

  @override
  String get practiceExplanation => 'Explanation';

  @override
  String get practiceYourTranslation => 'Your translation';

  @override
  String get practiceGenerating => 'Generating exercise...';

  @override
  String get practiceEvaluating => 'Evaluating...';

  @override
  String get practiceNoGrammarPoints => 'No grammar points for this level.';

  @override
  String get practiceGrammarTitle => 'Grammar Library';

  @override
  String get practiceGrammarBrowse => 'Grammar Library';

  @override
  String get practiceHistoryTitle => 'Practice History';

  @override
  String get practiceHistoryEmpty => 'No practice history yet.';

  @override
  String practiceHistoryScore(int score) {
    return 'Score: $score';
  }

  @override
  String get practiceHistoryDeleteConfirm => 'Delete this record?';

  @override
  String get practiceSentenceLengthShort => 'Short';

  @override
  String get practiceSentenceLengthMedium => 'Medium';

  @override
  String get practiceSentenceLengthLong => 'Long';

  @override
  String get practiceModeLabel => 'Practice Mode';

  @override
  String get practiceChineseOriginal => 'Chinese Original';

  @override
  String get practiceJapaneseInputHint =>
      'Enter your Japanese translation here';

  @override
  String get practiceSentenceCheckInstruction =>
      'Enter Japanese below and AI will check grammar and naturalness.';

  @override
  String get practiceSentenceCheckInputHint => 'Enter Japanese freely here';

  @override
  String get practiceFeedbackTitle => 'Practice Result';

  @override
  String get practiceGrammarSubtitle => 'Browse JLPT N5-N1 grammar points';

  @override
  String get practiceMultipleChoiceContinue => 'Continue';

  @override
  String get practiceMultipleChoiceViewExplanation => 'View Explanation';

  @override
  String get settingsAiBackToSettings => 'Back to settings';

  @override
  String get settingsAiFetchModels => 'Fetch Models';

  @override
  String get settingsAiFetchingModels => 'Fetching models...';

  @override
  String get settingsAiNoModelsFound => 'No models found';

  @override
  String get settingsAiAddConfig => 'Add Configuration';

  @override
  String get settingsAiDeleteConfig => 'Delete Configuration';

  @override
  String get settingsAiConfigName => 'Configuration Name';

  @override
  String get settingsAiConfigNameHint => 'e.g. DeepSeek, OpenAI Official';

  @override
  String get settingsAiSelectConfig => 'Select Configuration';

  @override
  String get practiceNotSure => 'I\'m not sure';

  @override
  String get practiceSelectOption => 'Select an option';
}
