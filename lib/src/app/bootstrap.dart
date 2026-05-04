import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../core/config/config_providers.dart';
import '../core/localization/generated/app_localizations.dart';
import '../core/routing/app_router.dart';
import '../core/settings/app_settings.dart';
import '../core/settings/settings_providers.dart';
import '../core/theme/app_theme.dart';
import '../features/practice/models/history_item.dart';
import '../shared/services/app_messenger.dart';
import '../shared/widgets/app_command_palette.dart';
import '../shared/widgets/desktop_window_frame.dart';

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(appRouterProvider);
    final settings =
        ref.watch(appSettingsControllerProvider).asData?.value ??
        AppSettings.defaults();

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      locale: null,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      themeMode: settings.themeMode,
      theme: AppTheme.light(settings),
      darkTheme: AppTheme.dark(settings),
      routerConfig: router,
      scaffoldMessengerKey: AppMessenger.scaffoldMessengerKey,
      builder: (context, child) {
        return _HiveInitWidget(
          child: DesktopWindowFrame(
            child: AppCommandPalette(
              router: router,
              child: _AppScrollBehavior(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HiveInitWidget extends StatefulWidget {
  const _HiveInitWidget({required this.child});

  final Widget child;

  @override
  State<_HiveInitWidget> createState() => _HiveInitWidgetState();
}

class _HiveInitWidgetState extends State<_HiveInitWidget> {
  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(HistoryItemAdapter());
    await Hive.openBox<HistoryItem>('practiceHistory');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _AppScrollBehavior extends StatelessWidget {
  const _AppScrollBehavior({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
      child: child,
    );
  }
}
