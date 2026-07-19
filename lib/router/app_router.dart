import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/home_page.dart';
import '../presentation/pages/lock_screen.dart';
import '../presentation/pages/lock_setup_page.dart';
import '../presentation/pages/onboarding_page.dart';
import '../presentation/pages/settings_page.dart';
import '../presentation/pages/statistics_page.dart';
import '../presentation/pages/task_detail_page.dart';
import '../presentation/providers/app_settings_provider.dart';
import '../presentation/providers/lock_provider.dart';

/// Application router built with go_router.
///
/// Redirect logic:
/// 1. Onboarding not seen → `/onboarding`.
/// 2. Lock enabled + `_shouldLock` flag set (by lifecycle manager) → `/lock`.
/// 3. Root `/` → `/home`.
final appRouterProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(appSettingsProvider);
  // Read the lock repo so we can check isLockEnabled in the redirect.
  final lockRepo = ref.watch(lockRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final onboardingDone = settings.onboardingSeen;
      final lockEnabled = lockRepo.isLockEnabled;

      // 1. Onboarding not seen → force onboarding.
      if (!onboardingDone && path != '/onboarding') {
        return '/onboarding';
      }
      if (onboardingDone && path == '/onboarding') {
        return lockEnabled && _shouldLock ? '/lock' : '/home';
      }
      // 2. Lock enabled and should-lock flag set → lock screen.
      //    BUT: don't redirect if user is in the middle of setting up a lock
      //    (lock-setup page) or already on the lock screen.
      if (lockEnabled && _shouldLock &&
          path != '/lock' && path != '/onboarding' &&
          path != '/lock-setup' && path != '/settings') {
        _shouldLock = false;
        return '/lock';
      }
      // 3. Root → home.
      if (path == '/') {
        return lockEnabled && _shouldLock ? '/lock' : '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/lock',
        name: 'lock',
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        path: '/lock-setup',
        name: 'lockSetup',
        builder: (context, state) => const LockSetupPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsPage(),
      ),
      GoRoute(
        path: '/task/:id',
        name: 'taskDetail',
        builder: (context, state) =>
            TaskDetailPage(taskId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Set to `true` by [AppLifecycleManager] when the app is resumed from
/// background, so the router redirect can force the lock screen.
bool _shouldLock = true;

/// Marks that the next router redirect should send the user to the lock
/// screen. Called on app startup and on app resume (when app lock is on).
void markShouldLock() => _shouldLock = true;

/// Clears the should-lock flag (e.g. after a successful unlock).
void clearShouldLock() => _shouldLock = false;
