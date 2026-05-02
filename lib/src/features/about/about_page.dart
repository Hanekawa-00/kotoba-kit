import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/section_card.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: '关于',
      subtitle: '一个偏通用、可扩展、跨平台优先的 Flutter 模板。',
      children: [
        SectionCard(
          title: '项目结构',
          icon: Icons.account_tree_outlined,
          children: const [
            _InfoRow(label: 'core', value: '路由、主题、设置等基础设施'),
            _InfoRow(label: 'features', value: '按业务功能拆分页面与状态'),
            _InfoRow(label: 'shared', value: '跨功能复用的通用组件'),
          ],
        ),
        SectionCard(
          title: '版本',
          icon: Icons.info_outline,
          children: [
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final info = snapshot.data;

                return Column(
                  children: [
                    _InfoRow(
                      label: '应用名',
                      value: info?.appName ?? 'Flutter Template',
                    ),
                    _InfoRow(
                      label: '包名',
                      value:
                          info?.packageName ?? 'com.example.flutter_template',
                    ),
                    _InfoRow(label: '版本', value: info?.version ?? '1.0.0'),
                    _InfoRow(label: '构建号', value: info?.buildNumber ?? '1'),
                  ],
                );
              },
            ),
          ],
        ),
      ],
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
