import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/config_providers.dart';
import '../../core/localization/localization_extensions.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/section_card.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(appConfigProvider);

    return PageFrame(
      storageId: 'settings-about',
      title: l10n.aboutTitle,
      subtitle: l10n.aboutSubtitle,
      trailing: OutlinedButton.icon(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
            return;
          }
          context.go('/settings');
        },
        icon: const Icon(Icons.arrow_back_rounded),
        label: Text(l10n.aboutBackToSettings),
      ),
      children: [
        SectionCard(
          title: l10n.aboutDescriptionTitle,
          icon: Icons.info_outline,
          children: [_DescriptionText(l10n.aboutDescriptionText)],
        ),
        SectionCard(
          title: l10n.aboutVersionTitle,
          icon: Icons.tag_outlined,
          children: [
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                return Column(
                  children: [
                    _InfoRow(
                      label: l10n.aboutAppNameLabel,
                      value: info?.appName ?? l10n.appTitle,
                    ),
                    _InfoRow(
                      label: l10n.aboutPackageLabel,
                      value: info?.packageName ?? 'com.hanekawa.kotoba_kit',
                    ),
                    _InfoRow(
                      label: l10n.aboutVersionLabel,
                      value: info?.version ?? '1.0.0',
                    ),
                    _InfoRow(
                      label: l10n.aboutBuildLabel,
                      value: info?.buildNumber ?? '1',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        SectionCard(
          title: l10n.aboutTechStackTitle,
          icon: Icons.code_outlined,
          children: [
            _InfoRow(label: 'Framework', value: 'Flutter'),
            _InfoRow(label: 'Design', value: 'Material 3'),
            _InfoRow(label: 'State', value: 'Riverpod'),
            _InfoRow(label: 'Routing', value: 'GoRouter'),
            _InfoRow(
              label: 'Platforms',
              value: 'Windows, macOS, Linux, Android, iOS, Web',
            ),
          ],
        ),
        SectionCard(
          title: l10n.aboutEnvironmentTitle,
          icon: Icons.settings_applications_outlined,
          children: [
            _InfoRow(
              label: l10n.aboutEnvironmentLabel,
              value: config.environment.label,
            ),
          ],
        ),
      ],
    );
  }
}

class _DescriptionText extends StatelessWidget {
  const _DescriptionText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
