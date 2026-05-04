import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ai/llm_config.dart';
import '../../core/ai/llm_factory.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/settings/settings_providers.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../shared/services/app_messenger.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/section_card.dart';

class AiModelPage extends ConsumerStatefulWidget {
  const AiModelPage({super.key});

  @override
  ConsumerState<AiModelPage> createState() => _AiModelPageState();
}

class _AiModelPageState extends ConsumerState<AiModelPage> {
  // Editing state
  bool _showEditor = false;
  String? _editingId;
  late TextEditingController _nameController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _baseUrlController;
  LlmProviderType _provider = LlmProviderType.openai;
  bool _showApiKey = false;
  bool _testing = false;
  List<String> _models = [];
  bool _fetchingModels = false;

  bool get _needsBaseUrl =>
      _provider == LlmProviderType.ollama ||
      _provider == LlmProviderType.openai ||
      _provider == LlmProviderType.anthropic;

  bool get _needsApiKey => _provider != LlmProviderType.ollama;
  bool get _isNew => _editingId == null;

  List<LlmConfig> get _configs {
    final settings = ref.read(appSettingsControllerProvider).asData?.value;
    return settings?.llmConfigs ?? [];
  }

  String? get _activeId {
    final settings = ref.read(appSettingsControllerProvider).asData?.value;
    return settings?.activeLlmConfigId;
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _apiKeyController = TextEditingController();
    _modelController = TextEditingController();
    _baseUrlController = TextEditingController();
  }

  void _startEditing(LlmConfig? config) {
    setState(() {
      _showEditor = true;
      _editingId = config?.id;
      _provider = config?.provider ?? LlmProviderType.openai;
      _nameController.text = config?.name ?? '';
      _apiKeyController.text = config?.apiKey ?? '';
      _modelController.text = config?.model ?? _provider.defaultModel;
      _baseUrlController.text = config?.baseUrl ?? '';
      _showApiKey = false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _showEditor = false;
      _editingId = null;
    });
  }

  void _save() {
    final settingsController = ref.read(appSettingsControllerProvider.notifier);
    final config = LlmConfig(
      id: _editingId ?? '',
      name: _nameController.text.trim(),
      provider: _provider,
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
    );

    if (_isNew) {
      final newConfig = LlmConfig.create(
        name: config.name.isNotEmpty ? config.name : _provider.label,
        provider: config.provider,
        apiKey: config.apiKey,
        model: config.model.isNotEmpty ? config.model : _provider.defaultModel,
        baseUrl: config.baseUrl.isNotEmpty ? config.baseUrl : '',
      );
      settingsController.addLlmConfig(newConfig);
    } else {
      settingsController.updateLlmConfig(config);
    }

    AppMessenger.showSuccess(context, context.l10n.settingsSaved);
    setState(() {
      _showEditor = false;
      _editingId = null;
    });
  }

  void _delete() {
    if (_editingId == null) return;
    ref
        .read(appSettingsControllerProvider.notifier)
        .removeLlmConfig(_editingId!);
    AppMessenger.showSuccess(context, context.l10n.settingsSaved);
    setState(() {
      _showEditor = false;
      _editingId = null;
    });
  }

  void _setActive(String id) {
    ref.read(appSettingsControllerProvider.notifier).setActiveLlmConfig(id);
  }

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    try {
      final config = _buildCurrentConfig();
      if (!config.isConfigured) {
        if (!mounted) return;
        AppMessenger.showError(
          context,
          context.l10n.settingsTestConnectionNoConfig,
        );
        return;
      }
      final provider = LlmFactory.create(config);
      final ok = await provider.testConnection();
      if (!mounted) return;
      if (ok) {
        AppMessenger.showSuccess(
          context,
          context.l10n.settingsTestConnectionSuccess,
        );
      } else {
        AppMessenger.showError(
          context,
          'Connection failed. Check your API key, base URL, and network.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppMessenger.showError(
        context,
        context.l10n.settingsTestConnectionFailed(e.toString()),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _fetchModels() async {
    setState(() => _fetchingModels = true);
    try {
      final config = _buildCurrentConfig();
      if (!config.isConfigured) return;
      final provider = LlmFactory.create(config);
      final models = await provider.listModels();
      if (!mounted) return;
      setState(() => _models = models);
      if (models.isNotEmpty) {
        AppMessenger.showSuccess(context, 'Found ${models.length} models');
      } else {
        AppMessenger.showError(context, context.l10n.settingsAiNoModelsFound);
      }
    } catch (_) {
      if (!mounted) return;
      AppMessenger.showError(context, context.l10n.settingsAiNoModelsFound);
    } finally {
      if (mounted) setState(() => _fetchingModels = false);
    }
  }

  LlmConfig _buildCurrentConfig() {
    return LlmConfig(
      id: '',
      name: '',
      provider: _provider,
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;

    return PageFrame(
      storageId: 'ai-model',
      title: l10n.settingsAiModelTitle,
      subtitle: l10n.settingsAiModelSubtitle,
      trailing: OutlinedButton.icon(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
            return;
          }
          context.go('/settings');
        },
        icon: const Icon(Icons.arrow_back_rounded),
        label: Text(l10n.settingsAiBackToSettings),
      ),
      children: [
        // Config list
        SectionCard(
          title: l10n.settingsAiSelectConfig,
          icon: Icons.smart_toy_outlined,
          children: [
            if (_configs.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.sm),
                child: Text(
                  'No configurations yet. Add one below.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ..._configs.map((config) {
                final isActive = config.id == _activeId;
                return Padding(
                  padding: EdgeInsets.only(bottom: spacing.sm),
                  child: Material(
                    color: isActive
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.42,
                          )
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(theme.radii.lg),
                    child: InkWell(
                      onTap: () => _setActive(config.id),
                      borderRadius: BorderRadius.circular(theme.radii.lg),
                      child: Padding(
                        padding: EdgeInsets.all(spacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        config.name.isNotEmpty
                                            ? config.name
                                            : config.provider.label,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (isActive) ...[
                                        SizedBox(width: spacing.sm),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              theme.radii.sm,
                                            ),
                                          ),
                                          child: Text(
                                            'Active',
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onPrimary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${config.provider.label} · ${config.model}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _startEditing(config),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            SizedBox(height: spacing.sm),
            OutlinedButton.icon(
              onPressed: _showEditor ? null : () => _startEditing(null),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.settingsAiAddConfig),
            ),
          ],
        ),

        // Editor
        if (_showEditor) ...[
          SectionCard(
            title: _isNew ? l10n.settingsAiAddConfig : 'Edit Configuration',
            icon: Icons.settings_outlined,
            children: [
              _SettingBlock(
                title: l10n.settingsAiConfigName,
                subtitle: l10n.settingsAiConfigNameHint,
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'DeepSeek'),
                ),
              ),
              SizedBox(height: spacing.lg),
              _SettingBlock(
                title: l10n.settingsAiProviderLabel,
                subtitle: l10n.settingsAiProviderDesc,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 420) {
                      return DropdownButtonFormField<LlmProviderType>(
                        initialValue: _provider,
                        decoration: const InputDecoration(isDense: true),
                        items: [
                          for (final p in LlmProviderType.values)
                            DropdownMenuItem(value: p, child: Text(p.label)),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _provider = value;
                            _modelController.text = _provider.defaultModel;
                            _baseUrlController.text = _provider.defaultBaseUrl;
                          });
                        },
                      );
                    }
                    return SegmentedButton<LlmProviderType>(
                      segments: [
                        for (final provider in LlmProviderType.values)
                          ButtonSegment(
                            value: provider,
                            label: Text(provider.label),
                          ),
                      ],
                      selected: {_provider},
                      onSelectionChanged: (value) {
                        setState(() {
                          _provider = value.first;
                          _modelController.text = _provider.defaultModel;
                          _baseUrlController.text = _provider.defaultBaseUrl;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          SectionCard(
            title: l10n.settingsAiCredentialsTitle,
            icon: Icons.vpn_key_outlined,
            children: [
              if (_needsApiKey) ...[
                _SettingBlock(
                  title: l10n.settingsAiApiKeyLabel,
                  subtitle: l10n.settingsAiApiKeyDesc,
                  child: TextField(
                    controller: _apiKeyController,
                    obscureText: !_showApiKey,
                    decoration: InputDecoration(
                      hintText: 'sk-...',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showApiKey
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _showApiKey = !_showApiKey),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: spacing.lg),
              ],
              _SettingBlock(
                title: l10n.settingsAiModelLabel,
                subtitle: l10n.settingsAiModelDesc,
                child: Column(
                  children: [
                    if (_models.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: spacing.sm),
                        child: DropdownButtonFormField<String>(
                          initialValue: _models.contains(_modelController.text)
                              ? _modelController.text
                              : null,
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          hint: const Text('Select model...'),
                          items: [
                            for (final m in _models)
                              DropdownMenuItem(
                                value: m,
                                child: Text(
                                  m,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _modelController.text = value;
                            }
                          },
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _modelController,
                            decoration: InputDecoration(
                              hintText: _provider.defaultModel,
                            ),
                          ),
                        ),
                        SizedBox(width: spacing.sm),
                        OutlinedButton(
                          onPressed: _fetchingModels ? null : _fetchModels,
                          child: _fetchingModels
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.settingsAiFetchModels),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_needsBaseUrl) ...[
                SizedBox(height: spacing.lg),
                _SettingBlock(
                  title: l10n.settingsAiBaseUrlLabel,
                  subtitle: l10n.settingsAiBaseUrlDesc,
                  child: TextField(
                    controller: _baseUrlController,
                    decoration: InputDecoration(
                      hintText: _provider.defaultBaseUrl,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SectionCard(
            title: l10n.settingsAiActionsTitle,
            icon: Icons.check_circle_outline,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testing ? null : _testConnection,
                      icon: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_find_outlined),
                      label: Text(l10n.settingsAiTestConnection),
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l10n.settingsAiSave),
                    ),
                  ),
                ],
              ),
              if (!_isNew) ...[
                SizedBox(height: spacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(
                      l10n.settingsAiDeleteConfig,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
              if (!_isNew)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _cancelEditing,
                    child: Text(l10n.commonCancel),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SettingBlock extends StatelessWidget {
  const _SettingBlock({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spacing = theme.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        SizedBox(height: spacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.md),
        child,
      ],
    );
  }
}
