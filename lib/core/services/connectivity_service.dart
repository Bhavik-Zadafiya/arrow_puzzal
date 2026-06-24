import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Watches network connectivity and exposes a stream + sync getter.
/// Call [init] once at startup before using anything else.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();
  late StreamController<bool> _controller;

  Stream<bool> get onChanged => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> init() async {
    _controller = StreamController<bool>.broadcast();

    // Seed with current state.
    final results = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(results);

    // Listen for changes.
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = _hasConnection(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
      }
    });
  }

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn);

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
