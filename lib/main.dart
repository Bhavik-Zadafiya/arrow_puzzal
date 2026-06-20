import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/audio_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Fire-and-forget — music starts as soon as the asset is decoded.
  AudioService.instance.init();

  runApp(const App());
}
