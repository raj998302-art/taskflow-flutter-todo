import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'router/app_router.dart';

/// Root widget for the Todo application.
///
/// Observes the user's theme preference (light / dark / system) and applies
/// the corresponding Material 3 theme. Routing is delegated to [appRouter].
class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
