import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/app_settings_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'router/app_router.dart';

/// Root widget for the Todo application.
///
/// Observes the user's theme preference (light / dark / system) and applies
/// the corresponding Material 3 theme. Routing is delegated to [appRouter].
/// An [AppLifecycleManager] watches app pause/resume so the app-lock screen
/// can be re-shown when the user returns to a locked app.
class TodoApp extends ConsumerStatefulWidget {
  const TodoApp({super.key});

  @override
  ConsumerState<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends ConsumerState<TodoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is resumed from background and app-lock is enabled,
    // mark that the router should redirect to /lock on the next navigation.
    if (state == AppLifecycleState.resumed) {
      final settings = ref.read(appSettingsProvider);
      if (settings.appLockEnabled) {
        markShouldLock();
        // Trigger a re-redirect by refreshing the router. The router's
        // redirect will send the user to /lock.
        ref.read(appRouterProvider).refresh();
      }
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
          // Ensure text scales but cap it for consistent layout.
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
