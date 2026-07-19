import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/home_page.dart';
import '../presentation/pages/lock_page.dart';
import '../presentation/pages/onboarding_page.dart';
import '../presentation/pages/settings_page.dart';
import '../presentation/pages/statistics_page.dart';
import '../presentation/pages/task_detail_page.dart';
import '../presentation/providers/app_settings_provider.dart';

/// Application router built with go_router.
///
/// Uses a [redirect] to send the user to `/onboarding` on first launch, or to
/// `/lock` when the app-lock feature is enabled and the app is being resumed
/// (the lock state is tracked by [AppLifecycleManager]).
final appRouterProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(appSettingsProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final onboardingDone = settings.onboardingSeen;
      final lockEnabled = settings.appLockEnabled;

      // 1. Onboarding not seen → force onboarding (unless already there).
      if (!onboardingDone && path != '/onboarding') {
        return '/onboarding';
      }
      // 2. Onboarding done but on onboarding route → go home (or lock).
      if (onboardingDone && path == '/onboarding') {
        return lockEnabled ? '/lock' : '/home';
      }
      // 3. App lock enabled and user is at root or lock-unrelated route →
      //    send to lock (the lock page itself navigates to /home on success).
      //    We only force lock on the *initial* app open, tracked via the
      //    _shouldLock flag set by the lifecycle manager.
      if (lockEnabled && _shouldLock && path != '/lock' && path != '/onboarding') {
        _shouldLock = false;
        return '/lock';
      }
      // 4. Root '/' → home (or lock if enabled).
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
        builder: (context, state) => const LockPage(),
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

/// Resets the lock flag — called on app startup so the very first launch (with
/// app lock on) still shows the lock screen.
void markShouldLock() => _shouldLock = true;
