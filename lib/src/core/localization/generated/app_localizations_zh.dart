// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Kotoba Kit';

  @override
  String get navHome => '首页';

  @override
  String get navDictionary => '查词';

  @override
  String get navSettings => '设置';

  @override
  String get navComponents => '组件';

  @override
  String get navAbout => '关于';

  @override
  String get navCollapseSidebar => '折叠侧边栏';

  @override
  String get navExpandSidebar => '展开侧边栏';

  @override
  String get homeTitle => 'Kotoba Kit';

  @override
  String get homeSubtitle => '离线优先的日语字典工作台，先把可靠本地查词做稳，再向学习工具扩展。';

  @override
  String get openSettingsTooltip => '打开设置';

  @override
  String get homeStatusLoading => '正在加载设置';

  @override
  String get homeStatusReady => '字典核心开发中';

  @override
  String get homeStatusDescription => '第一阶段专注本地 MDict 导入、精确查词和稳定的词典管理。';

  @override
  String get capabilityCrossPlatformTitle => '离线优先基线';

  @override
  String get capabilityCrossPlatformDescription =>
      '导入的词典放在应用数据目录，而不是打进 assets。';

  @override
  String get capabilityThemeTitle => '本地查词';

  @override
  String get capabilityThemeDescription => 'MDX 文件在本地打开，Reader 会缓存以支持重复查询。';

  @override
  String get capabilityRoutingTitle => '字典优先入口';

  @override
  String get capabilityRoutingDescription => 'MVP 阶段应用会直接进入字典工作台。';

  @override
  String get capabilityExtensionTitle => '后续学习模块';

  @override
  String get capabilityExtensionDescription => '造句、TTS 和拍照识词以后都可以复用这条查词核心。';

  @override
  String get nextStepsTitle => '推荐下一步';

  @override
  String get nextStepFeature => '用真实日语 MDX 文件验证 dict_reader 兼容性';

  @override
  String get nextStepRepository => '围绕导入结果补词典元数据和 Reader 生命周期';

  @override
  String get nextStepDesktop => '确保大词典导入和查询时界面不被卡住';

  @override
  String get stateComponentsTitle => 'UI 状态组件';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '模板只保留通用偏好，后续业务设置可以继续按分组追加。';

  @override
  String get settingsAppearanceTitle => '外观';

  @override
  String get settingsThemeModeTitle => '主题模式';

  @override
  String get settingsThemeModeSubtitle => '跟随系统、浅色或深色。';

  @override
  String get themeModeSystem => '系统';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeDark => '深色';

  @override
  String get settingsThemeColorTitle => '主题色';

  @override
  String get settingsThemeColorSubtitle => 'Material 3 会用种子色生成完整配色。';

  @override
  String get settingsExperienceTitle => '体验';

  @override
  String get settingsPureBlackTitle => 'OLED 深色增强';

  @override
  String get settingsPureBlackSubtitle => '深色模式下使用更纯的黑色 surface。';

  @override
  String get settingsCompactDensityTitle => '紧凑密度';

  @override
  String get settingsCompactDensitySubtitle => '让桌面端和信息密集页面更克制。';

  @override
  String get settingsOtherTitle => '其他';

  @override
  String get settingsResetAction => '重置';

  @override
  String get settingsResetTitle => '重置偏好设置';

  @override
  String get settingsResetMessage => '主题、颜色和体验选项会恢复为模板默认值。';

  @override
  String get settingsResetConfirm => '重置';

  @override
  String get settingsResetSuccess => '偏好设置已重置';

  @override
  String settingsSaveFailed(String error) {
    return '设置保存失败：$error';
  }

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutSubtitle => '一款离线优先的日语字典与学习工具集。';

  @override
  String get aboutBackToSettings => '返回设置';

  @override
  String get aboutDescriptionTitle => '关于 Kotoba Kit';

  @override
  String get aboutDescriptionText =>
      'Kotoba Kit 是一款离线优先的日语字典与学习工具集，基于 Flutter 构建，覆盖所有主流平台。支持本地 MDict 词典查询、AI 辅助造句练习（多提供商 LLM 支持）、完整的 JLPT 语法库以及练习历史记录。';

  @override
  String get aboutTechStackTitle => '技术栈';

  @override
  String get aboutVersionTitle => '版本';

  @override
  String get aboutAppNameLabel => '应用名';

  @override
  String get aboutPackageLabel => '包名';

  @override
  String get aboutVersionLabel => '版本';

  @override
  String get aboutBuildLabel => '构建号';

  @override
  String get aboutEnvironmentTitle => '环境配置';

  @override
  String get aboutEnvironmentLabel => '环境';

  @override
  String get commonEnabled => '启用';

  @override
  String get commonDisabled => '关闭';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonCancel => '取消';

  @override
  String get backAgainToExit => '再按一次返回退出应用';

  @override
  String get commandPaletteSearchHint => '搜索页面或操作';

  @override
  String get commandPaletteNoResults => '没有匹配的操作';

  @override
  String get commandPaletteExecuted => '已执行操作';

  @override
  String get commandGoHome => '前往首页';

  @override
  String get commandGoDictionary => '前往查词';

  @override
  String get commandGoSettings => '前往设置';

  @override
  String get commandGoComponents => '前往组件';

  @override
  String get commandGoAbout => '前往关于';

  @override
  String get componentsTitle => '组件';

  @override
  String get componentsSubtitle => '跨平台预览模板内置的通用 UI 状态和交互组件。';

  @override
  String get componentsStatesTitle => '状态视图';

  @override
  String get componentsAsyncTitle => 'AsyncValue 视图';

  @override
  String get componentsAsyncData => '数据';

  @override
  String get componentsAsyncReady => '数据状态已就绪';

  @override
  String get componentsDialogsTitle => '确认弹窗';

  @override
  String get componentsDialogsDescription => '用于危险操作、退出确认、删除确认等需要明确选择的场景。';

  @override
  String get componentsDialogTitle => '确认操作';

  @override
  String get componentsDialogMessage => '这是一个模板确认弹窗，业务侧可以替换标题、正文和按钮。';

  @override
  String get componentsOpenDialog => '打开弹窗';

  @override
  String get componentsFeedbackTitle => '反馈提示';

  @override
  String get componentsFeedbackDescription =>
      '用于保存成功、轻量提醒和错误提示，默认走全局 ScaffoldMessenger。';

  @override
  String get componentsShowSuccess => '成功提示';

  @override
  String get componentsShowError => '错误提示';

  @override
  String get componentsSuccessToast => '操作已完成';

  @override
  String get componentsErrorToast => '操作失败，请稍后重试';

  @override
  String get componentsStyleTitle => '控件样式';

  @override
  String get componentsStyleDescription => '按钮、输入框和选择器使用统一 token，便于业务组件保持一致。';

  @override
  String get componentsPrimaryButton => '主要';

  @override
  String get componentsTonalButton => '次要';

  @override
  String get componentsOutlineButton => '描边';

  @override
  String get componentsSearchLabel => '搜索';

  @override
  String get componentsCompactChoice => '紧凑';

  @override
  String get componentsComfortChoice => '舒适';

  @override
  String get stateRetry => '重试';

  @override
  String get stateLoading => '正在加载';

  @override
  String get stateEmptyTitle => '暂无内容';

  @override
  String get stateEmptyMessage => '这里还没有可以展示的数据。';

  @override
  String get stateErrorTitle => '出了点问题';

  @override
  String get stateErrorMessage => '请稍后重试，或检查当前环境配置。';

  @override
  String get dictionaryTitle => '查词';

  @override
  String get dictionarySubtitle => '跨本地词典和在线源查词。在设置中管理词典。';

  @override
  String get dictionarySettingsTitle => '词典管理';

  @override
  String get dictionaryImport => '导入 MDX';

  @override
  String get dictionaryImporting => '导入中';

  @override
  String get dictionaryUnsupportedTitle => '当前平台暂不可用';

  @override
  String get dictionaryUnsupportedMessage => '这个平台暂时不能打开本地 MDict 文件。';

  @override
  String get dictionarySearchTitle => '查词';

  @override
  String get dictionarySearchLabel => '单词';

  @override
  String get dictionarySearchHint => '食べる';

  @override
  String get dictionarySearchButton => '查询';

  @override
  String get dictionaryNoEnabledDictionaries => '请先导入或启用一本词典。';

  @override
  String get dictionaryInstalledTitle => '已导入词典';

  @override
  String get dictionaryEmptyTitle => '还没有导入词典';

  @override
  String get dictionaryEmptyMessage => '导入 .mdx 文件后会立即做兼容性检查。';

  @override
  String dictionaryEntryCount(int count) {
    return '$count 个词条';
  }

  @override
  String get dictionaryDelete => '删除词典';

  @override
  String get dictionaryResultsTitle => '查询结果';

  @override
  String get dictionaryResultsPlaceholder => '查询结果会显示在这里。';

  @override
  String dictionaryNoResults(String query) {
    return '没有找到“$query”的精确匹配。';
  }

  @override
  String get dictionarySuggestionsTitle => '前缀匹配';

  @override
  String get dictionaryHistoryTitle => '检索历史';

  @override
  String dictionarySourceFailed(String source, String error) {
    return '$source 暂时不可用：$error';
  }

  @override
  String dictionaryImportSuccess(String name) {
    return '已导入 $name';
  }

  @override
  String dictionaryOperationFailed(String error) {
    return '字典操作失败：$error';
  }

  @override
  String get settingsAiServiceTitle => 'AI 服务';

  @override
  String get settingsAiModelTitle => 'AI 模型';

  @override
  String get settingsAiModelSubtitle => '配置造句练习使用的 LLM 提供商和模型。';

  @override
  String get settingsAiProviderTitle => '提供商';

  @override
  String get settingsAiProviderLabel => 'LLM 提供商';

  @override
  String get settingsAiProviderDesc => '选择用于造句练习的 AI 提供商。';

  @override
  String get settingsAiCredentialsTitle => '凭证';

  @override
  String get settingsAiApiKeyLabel => 'API 密钥';

  @override
  String get settingsAiApiKeyDesc => 'API 密钥仅存储在本地，只发送到所选提供商的 API。';

  @override
  String get settingsAiModelLabel => '模型';

  @override
  String get settingsAiModelDesc => '用于生成和评估的模型名称。';

  @override
  String get settingsAiBaseUrlLabel => '基础 URL';

  @override
  String get settingsAiBaseUrlDesc => '自托管或兼容 API 的自定义端点 URL。';

  @override
  String get settingsAiActionsTitle => '操作';

  @override
  String get settingsAiTestConnection => '测试连接';

  @override
  String get settingsAiSave => '保存';

  @override
  String get settingsTestConnectionSuccess => '配置看起来有效。';

  @override
  String settingsTestConnectionFailed(String error) {
    return '连接测试失败：$error';
  }

  @override
  String get settingsTestConnectionNoConfig => '请输入 API 密钥或配置本地端点。';

  @override
  String get settingsSaved => '设置已保存。';

  @override
  String get navPractice => '练习';

  @override
  String get commandGoPractice => '前往练习';

  @override
  String get practiceTitle => '造句练习';

  @override
  String get practiceSubtitle => '使用 AI 反馈练习日语句子构造。';

  @override
  String get practiceModeTranslation => '翻译造句';

  @override
  String get practiceModeTranslationDesc => '阅读中文，写出日语，获取评分。';

  @override
  String get practiceModeMultipleChoice => '选择题';

  @override
  String get practiceModeMultipleChoiceDesc => '选择正确的日语翻译。';

  @override
  String get practiceModeSentenceCheck => '自由造句';

  @override
  String get practiceModeSentenceCheckDesc => '自由输入日语，获取语法反馈。';

  @override
  String get practiceDifficulty => '难度';

  @override
  String get practiceSentenceLength => '句子长度';

  @override
  String get practiceStartButton => '开始练习';

  @override
  String get practiceNoApiKey => '请先在设置中配置 AI 模型。';

  @override
  String get practiceSubmit => '提交';

  @override
  String get practiceNextTask => '下一题';

  @override
  String get practiceTryAgain => '再试一次';

  @override
  String get practiceBackToMenu => '返回菜单';

  @override
  String get practiceScore => '评分';

  @override
  String get practiceEvaluation => '评价';

  @override
  String get practiceCorrectedSentence => '修正后的句子';

  @override
  String get practiceExplanation => '详细解释';

  @override
  String get practiceYourTranslation => '你的翻译';

  @override
  String get practiceGenerating => '正在生成练习...';

  @override
  String get practiceEvaluating => '正在评估...';

  @override
  String get practiceNoGrammarPoints => '此等级暂无语法点。';

  @override
  String get practiceGrammarTitle => '语法库';

  @override
  String get practiceGrammarBrowse => '语法库';

  @override
  String get practiceHistoryTitle => '练习历史';

  @override
  String get practiceHistoryEmpty => '暂无练习记录。';

  @override
  String practiceHistoryScore(int score) {
    return '评分：$score';
  }

  @override
  String get practiceHistoryDeleteConfirm => '删除这条记录？';

  @override
  String get practiceSentenceLengthShort => '短';

  @override
  String get practiceSentenceLengthMedium => '中';

  @override
  String get practiceSentenceLengthLong => '长';

  @override
  String get practiceModeLabel => '练习模式';

  @override
  String get practiceChineseOriginal => '中文原文';

  @override
  String get practiceJapaneseInputHint => '在这里输入你的日语翻译';

  @override
  String get practiceSentenceCheckInstruction => '在下方自由输入日语，AI 会检查语法和自然度。';

  @override
  String get practiceSentenceCheckInputHint => '在这里自由输入日语';

  @override
  String get practiceFeedbackTitle => '练习结果';

  @override
  String get practiceGrammarSubtitle => '浏览 JLPT N5-N1 语法点';

  @override
  String get practiceMultipleChoiceContinue => '继续';

  @override
  String get practiceMultipleChoiceViewExplanation => '查看解释';

  @override
  String get settingsAiBackToSettings => '返回设置';

  @override
  String get settingsAiFetchModels => '获取模型列表';

  @override
  String get settingsAiFetchingModels => '正在获取模型列表...';

  @override
  String get settingsAiNoModelsFound => '未找到模型';

  @override
  String get settingsAiAddConfig => '添加配置';

  @override
  String get settingsAiDeleteConfig => '删除配置';

  @override
  String get settingsAiConfigName => '配置名称';

  @override
  String get settingsAiConfigNameHint => '例如：DeepSeek、OpenAI 官方';

  @override
  String get settingsAiSelectConfig => '选择配置';

  @override
  String get practiceNotSure => '不确定';

  @override
  String get practiceSelectOption => '请选择一个选项';
}
