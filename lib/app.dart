import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/services/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'router/app_router.dart';

/// Root widget for the Todo application.
///
/// Observes the user's theme preference and app lifecycle. Uses
/// [SessionManager] to decide whether to show the lock screen — the session
/// manager is the SINGLE SOURCE OF TRUTH for authentication state, surviving
/// Activity recreation and BiometricPrompt lifecycle events.
class TodoApp extends ConsumerStatefulWidget {
  const TodoApp({super.key});

  @override
  ConsumerState<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends ConsumerState<TodoApp> with WidgetsBindingObserver {
  StreamSubscription<void>? _sessionSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen to session changes so the router re-evaluates the redirect
    // whenever the user authenticates or the session is invalidated.
    _sessionSub = SessionManager.instance.onSessionChange.listen((_) {
      // Trigger a router refresh — the redirect will check isSessionValid().
      if (mounted) ref.read(appRouterProvider).refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Delegate to SessionManager — it knows whether to suppress the
    // background event (biometric prompt showing, enrollment flow, etc.).
    switch (state) {
      case AppLifecycleState.resumed:
        SessionManager.instance.onAppComingToForeground();
        // Re-evaluate lock state — if session was invalidated, router will
        // redirect to /lock.
        ref.read(appRouterProvider).refresh();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        SessionManager.instance.onAppGoingToBackground();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final goRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Taskflow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: goRouter,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.textScalerOf(context).scale(1).clamp(0.85, 1.3),
            ),
          ),
          child: DefaultTextStyle.merge(
            style: GoogleFonts.inter(
              textStyle: DefaultTextStyle.of(context).style,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
