// Mentesana — entry point.
// Boots the persisted store via DI, then hands the phone to the shell:
// onboarding → home → check-in / settings.

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import 'app_shell.dart';
import 'app_store.dart';
import 'core/locator.dart';
import 'mood_palette.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init services that can start before DI is fully wired.
  await NotificationService.instance.init();

  // Bootstrap dependency injection (async services: SettingsRepository).
  configureDependencies();

  runApp(const MentesanaApp());
}

class MentesanaApp extends WatchingWidget {
  const MentesanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wait for all async registrations (SettingsRepository, AppStore).
    final ready = allReady(
      onReady: (context) {
        // All services ready — no-op; the store is available via di.
      },
    );

    if (!ready) {
      // A quiet ink surface while the store wakes — no spinner.
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(color: kInkDeep),
      );
    }

    final store = locate<AppStore>();

    return MaterialApp(
      title: 'Mentesana',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _PhoneScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kInkDeep,
      ),
      home: MentesanaShell(store: store),
    );
  }
}

// The prototype is a phone in the browser: no scrollbar is ever shown, and
// pages scroll by dragging. Flutter web injects a hover-reactive scrollbar
// over every scrollable by default — a visual deviation, and its hover
// tracking spams mouse-tracker assertions in debug builds. So: no scrollbar,
// and mouse/stylus/trackpad drag like touch.
class _PhoneScrollBehavior extends MaterialScrollBehavior {
  const _PhoneScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  Widget buildScrollbar(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

