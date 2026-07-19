import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/session_manager.dart';
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
/// Redirect logic (session-based):
/// 1. Onboarding not seen → `/onboarding`.
/// 2. Lock enabled but session not valid → `/lock`.
/// 3. Root `/` → `/home`.
///
/// The session check uses [SessionManager.isSessionValid] which survives
/// Activity recreation and accounts for biometric-prompt / enrollment flows.
final appRouterProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final lockRepo = ref.watch(lockRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final onboardingDone = settings.onboardingSeen;
      final lockEnabled = lockRepo.isLockEnabled;
      final sessionValid = SessionManager.instance.isSessionValid();
      final needsLock = lockEnabled && !sessionValid;

      // 1. Onboarding not seen → force onboarding.
      if (!onboardingDone && path != '/onboarding') {
        return '/onboarding';
      }
      if (onboardingDone && path == '/onboarding') {
        return needsLock ? '/lock' : '/home';
      }

      // 2. Don't redirect if user is in lock setup or already on lock screen.
      //    This lets the user configure locks without being interrupted.
      if (path == '/lock-setup' || path == '/settings') {
        return null;
      }

      // 3. If lock is needed and user is not on the lock screen → lock.
      if (needsLock && path != '/lock') {
        return '/lock';
      }

      // 4. If on lock screen but session is valid (already unlocked) → home.
      if (path == '/lock' && !needsLock) {
        return '/home';
      }

      // 5. Root → home.
      if (path == '/') {
        return needsLock ? '/lock' : '/home';
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
