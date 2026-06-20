import 'package:flutter/material.dart';
import '../core/services/audio_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
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

  /// Pause music when backgrounded, resume when foregrounded.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        AudioService.instance.pause();
      case AppLifecycleState.resumed:
        AudioService.instance.resume();
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Arrow Pussal',
      theme: AppTheme.theme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
