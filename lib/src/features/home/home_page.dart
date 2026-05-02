import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/settings_providers.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/section_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    return PageFrame(
      title: 'Flutter Template',
      subtitle: '跨平台应用模板，保留通用能力，业务功能从这里继续生长。',
      trailing: IconButton.filledTonal(
        tooltip: '打开设置',
        onPressed: () => context.go('/settings'),
        icon: const Icon(Icons.tune),
      ),
      children: [
        _StatusPanel(isLoading: settings.isLoading),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 720;
            final cards = [
              _CapabilityCard(
                icon: Icons.devices_rounded,
                title: '跨平台基线',
                description: 'Android、iOS、Web、Windows、macOS、Linux 平台目录已生成。',
              ),
              _CapabilityCard(
                icon: Icons.palette_outlined,
                title: '主题系统',
                description: '支持系统/浅色/深色、种子色、OLED 深色和紧凑密度。',
              ),
              _CapabilityCard(
                icon: Icons.route_outlined,
                title: '路由骨架',
                description: 'go_router Shell 已接好，移动端底栏，宽屏侧边导航。',
              ),
              _CapabilityCard(
                icon: Icons.extension_outlined,
                title: '扩展边界',
                description: 'core、features、shared 分层，便于后续拆模块和接业务。',
              ),
            ];

            if (!twoColumns) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    if (card != cards.last) const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              children: cards,
            );
          },
        ),
        SectionCard(
          title: '推荐下一步',
          icon: Icons.checklist_rounded,
          children: [
            _NextStepTile(
              color: scheme.primary,
              label: '把第一个业务页面放到 lib/src/features/<feature_name>',
            ),
            _NextStepTile(
              color: scheme.tertiary,
              label: '为数据源新增 repository，并在 Riverpod provider 中注入',
            ),
            _NextStepTile(
              color: scheme.secondary,
              label: '需要复杂桌面能力时，再按需引入窗口、托盘或热键插件',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLoading ? Icons.sync_rounded : Icons.layers_rounded,
              color: scheme.primary,
              size: 34,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading ? '正在加载设置' : '模板已就绪',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '这里刻意不放业务假数据，只展示模板当前已经具备的通用能力。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStepTile extends StatelessWidget {
  const _NextStepTile({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(Icons.radio_button_checked, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
