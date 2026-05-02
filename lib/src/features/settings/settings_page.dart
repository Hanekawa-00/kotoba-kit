import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_providers.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/section_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(appSettingsControllerProvider);
    final settings = asyncSettings.asData?.value ?? AppSettings.defaults();
    final controller = ref.read(appSettingsControllerProvider.notifier);

    return PageFrame(
      title: '设置',
      subtitle: '模板只保留通用偏好，后续业务设置可以继续按分组追加。',
      children: [
        if (asyncSettings.hasError)
          _ErrorBanner(error: asyncSettings.error.toString()),
        SectionCard(
          title: '外观',
          icon: Icons.palette_outlined,
          children: [
            _SettingBlock(
              title: '主题模式',
              subtitle: '跟随系统、浅色或深色。',
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('系统'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('浅色'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('深色'),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (value) {
                  controller.setThemeMode(value.first);
                },
              ),
            ),
            const SizedBox(height: 20),
            _SettingBlock(
              title: '主题色',
              subtitle: 'Material 3 会用种子色生成完整配色。',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final preset in AppColorPreset.values)
                    _ColorPresetButton(
                      preset: preset,
                      selected: settings.colorPreset == preset,
                      onSelected: () => controller.setColorPreset(preset),
                    ),
                ],
              ),
            ),
          ],
        ),
        SectionCard(
          title: '体验',
          icon: Icons.tune_outlined,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('OLED 深色增强'),
              subtitle: const Text('深色模式下使用更纯的黑色 surface。'),
              value: settings.pureBlackDarkMode,
              onChanged: controller.setPureBlackDarkMode,
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('紧凑密度'),
              subtitle: const Text('让桌面端和信息密集页面更克制。'),
              value: settings.compactDensity,
              onChanged: controller.setCompactDensity,
            ),
          ],
        ),
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ColorPresetButton extends StatelessWidget {
  const _ColorPresetButton({
    required this.preset,
    required this.selected,
    required this.onSelected,
  });

  final AppColorPreset preset;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: preset.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: preset.seedColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.onSurface : Colors.transparent,
              width: 3,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: preset.seedColor.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: selected
              ? Icon(Icons.check, color: scheme.onPrimary)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '设置保存失败：$error',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
