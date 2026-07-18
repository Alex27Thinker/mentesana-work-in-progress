// Mentesana — Navigation Manager.
// Extracted from the monolithic AppShell: owns screen state, depth routing,
// back-handling, and bottom-navigation visibility. Screens are represented
// by the AppScreen enum; transitions are managed at the shell level.

import 'package:flutter/foundation.dart';

/// The set of screens the shell can show.
/// Mirrors the JS showScreen() routes 1:1.
enum AppScreen {
  home,
  checkin,
  settings,
  journalhome,
  promptlibrary,
  calendar,
  archive,
  entrydetail,
  insight,
  tideLab,
}

/// JS SCREEN_DEPTH — how far below the surface each screen sits.
const Map<AppScreen, double> kScreenDepth = {
  AppScreen.home: 0,
  AppScreen.checkin: 0,
  AppScreen.journalhome: 1,
  AppScreen.promptlibrary: 1.15,
  AppScreen.calendar: 1.45,
  AppScreen.settings: 1.35,
  AppScreen.insight: .75,
  AppScreen.tideLab: .9,
  AppScreen.entrydetail: 1.8,
  AppScreen.archive: 2.25,
};

/// Managed navigation state for the app shell.
/// Encapsulates screen transitions, back-stack semantics, and
/// navigation-visibility rules — extracted from MentesanaShell.
class NavigationManager extends ChangeNotifier {
  AppScreen _screen = AppScreen.home;
  AppScreen _detailBack = AppScreen.archive;

  /// Session-level read counter for entry details (JS detailReads).
  final Map<String, int> detailReads = {};

  AppScreen get screen => _screen;
  AppScreen get detailBack => _detailBack;
  double get depth => kScreenDepth[_screen] ?? 0;

  /// The bottom nav is visible only for full-screen content screens.
  bool get navVisible =>
      _screen == AppScreen.home ||
      _screen == AppScreen.journalhome ||
      _screen == AppScreen.archive ||
      _screen == AppScreen.insight ||
      _screen == AppScreen.tideLab ||
      _screen == AppScreen.settings;

  /// Navigate to a screen, cancelling any pending invite timers.
  void show(AppScreen screen, {AppScreen? detailBack}) {
    _screen = screen;
    if (detailBack != null) _detailBack = detailBack;
    notifyListeners();
  }

  /// Record a read of an entry detail (JS detailReads).
  int recordDetailRead(int entryTs) {
    final key = '$entryTs';
    detailReads[key] = (detailReads[key] ?? 0) + 1;
    return detailReads[key]!;
  }

  /// Handle system back button — returns true if handled.
  /// Mirrors JS back-button / gesture-navigation logic.
  bool handleBack({
    required bool journalOpen,
    required bool undertowOpen,
    required bool postJournalOpen,
    required bool inviteOpen,
    required VoidCallback onCloseJournal,
    required VoidCallback onCloseUndertow,
    required VoidCallback onClosePostJournal,
    required VoidCallback onCloseInvite,
  }) {
    if (journalOpen) {
      onCloseJournal();
      return true;
    }
    if (undertowOpen) {
      onCloseUndertow();
      return true;
    }
    if (postJournalOpen) {
      onClosePostJournal();
      show(AppScreen.journalhome);
      return true;
    }
    if (inviteOpen) {
      onCloseInvite();
      show(AppScreen.home);
      return true;
    }
    switch (_screen) {
      case AppScreen.checkin:
      case AppScreen.settings:
      case AppScreen.journalhome:
      case AppScreen.archive:
      case AppScreen.insight:
      case AppScreen.tideLab:
        show(AppScreen.home);
        return true;
      case AppScreen.promptlibrary:
      case AppScreen.calendar:
        show(AppScreen.journalhome);
        return true;
      case AppScreen.entrydetail:
        show(_detailBack);
        return true;
      case AppScreen.home:
        return false;
    }
  }
}
