import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_pussal/features/splash/widget/splash_screen.dart';

void main() {
  testWidgets('Splash screen shows app name', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/level-map',
          builder: (context, state) => const Scaffold(body: Text('Level Map Mock')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('Arrow Pussal'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
