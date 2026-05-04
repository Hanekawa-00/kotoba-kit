import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/about_page.dart';
// import '../../features/components/component_gallery_page.dart';
import '../../features/dictionary/dictionary_page.dart';
import '../../features/home/home_page.dart';
import '../../features/practice/practice_page.dart';
import '../../features/practice/widgets/grammar_browse_page.dart';
import '../../features/practice/widgets/history_browse_page.dart';
import '../../features/settings/ai_model_page.dart';
import '../../features/settings/settings_page.dart';
import '../../shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dictionary',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            location: state.uri.path,
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/practice',
                name: 'practice',
                builder: (context, state) => const PracticePage(),
                routes: [
                  GoRoute(
                    path: 'grammar',
                    name: 'practice-grammar',
                    builder: (context, state) => const GrammarBrowsePage(),
                  ),
                  GoRoute(
                    path: 'history',
                    name: 'practice-history',
                    builder: (context, state) => const HistoryBrowsePage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dictionary',
                name: 'dictionary',
                builder: (context, state) => const DictionaryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'about',
                    name: 'settings-about',
                    builder: (context, state) => const AboutPage(),
                  ),
                  GoRoute(
                    path: 'ai-model',
                    name: 'settings-ai-model',
                    builder: (context, state) => const AiModelPage(),
                  ),
                ],
              ),
            ],
          ),
          // Components gallery removed — see template code at
          // lib/src/features/components/component_gallery_page.dart
          // StatefulShellBranch(
          //   routes: [
          //     GoRoute(
          //       path: '/components',
          //       name: 'components',
          //       builder: (context, state) => const ComponentGalleryPage(),
          //     ),
          //   ],
          // ),
        ],
      ),
    ],
  );
});
