import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/audio_service.dart';
import '../core/services/connectivity_service.dart';
import '../core/widget/no_internet_screen.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late bool _isOnline;
  StreamSubscription<bool>? _connectSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isOnline = ConnectivityService.instance.isOnline;
    _connectSub = ConnectivityService.instance.onChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _connectSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
      title: 'ArrowX',
      theme: AppTheme.theme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Overlay the no-internet screen on top of everything when offline.
        if (!_isOnline) return const NoInternetScreen();
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
