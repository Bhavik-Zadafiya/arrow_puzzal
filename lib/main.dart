import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/audio_service.dart';
import 'core/services/daily_service.dart';
import 'core/services/progress_service.dart';
import 'core/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init persistence first so cubits and services can read synchronously.
  await ProgressService.instance.init();
  await DailyService.instance.init();
  await SettingsService.instance.init();

  // Music starts as soon as the asset is decoded (fire-and-forget after init).
  AudioService.instance.init();

  runApp(const App());
}
