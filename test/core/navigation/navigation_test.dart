import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/core/navigation_manager.dart';

void main() {
  group('NavigationManager', () {
    late NavigationManager nav;

    setUp(() {
      nav = NavigationManager();
    });

    test('starts at home', () {
      expect(nav.screen, AppScreen.home);
      expect(nav.depth, 0);
      expect(nav.navVisible, isTrue);
    });

    test('show navigates to screen', () {
      nav.show(AppScreen.settings);
      expect(nav.screen, AppScreen.settings);
    });

    test('show with detailBack sets back target', () {
      nav.show(AppScreen.entrydetail, detailBack: AppScreen.archive);
      expect(nav.screen, AppScreen.entrydetail);
      expect(nav.detailBack, AppScreen.archive);
    });

    test('navVisible returns correct visibility', () {
      final visible = {AppScreen.home, AppScreen.journalhome, AppScreen.archive, AppScreen.insight, AppScreen.tideLab, AppScreen.settings};
      final notVisible = {AppScreen.checkin, AppScreen.promptlibrary, AppScreen.calendar, AppScreen.entrydetail};

      for (final screen in visible) {
        nav.show(screen);
        expect(nav.navVisible, isTrue, reason: '$screen should have nav visible');
      }
      for (final screen in notVisible) {
        nav.show(screen);
        expect(nav.navVisible, isFalse, reason: '$screen should not have nav visible');
      }
    });

    test('depth returns correct value', () {
      nav.show(AppScreen.home);
      expect(nav.depth, 0);
      nav.show(AppScreen.archive);
      expect(nav.depth, 2.25);
    });

    test('recordDetailRead increments counter', () {
      expect(nav.recordDetailRead(1000), 1);
      expect(nav.recordDetailRead(1000), 2);
      expect(nav.recordDetailRead(2000), 1);
    });

    group('handleBack', () {
      late bool journalClosed, undertowClosed;

      setUp(() {
        journalClosed = false;
        undertowClosed = false;
      });

      test('closes journal overlay first', () {
        final handled = nav.handleBack(
          journalOpen: true,
          undertowOpen: false,
          postJournalOpen: false,
          inviteOpen: false,
          onCloseJournal: () => journalClosed = true,
          onCloseUndertow: () {},
          onClosePostJournal: () {},
          onCloseInvite: () {},
        );
        expect(handled, isTrue);
        expect(journalClosed, isTrue);
      });

      test('closes undertow second', () {
        final handled = nav.handleBack(
          journalOpen: false,
          undertowOpen: true,
          postJournalOpen: false,
          inviteOpen: false,
          onCloseJournal: () {},
          onCloseUndertow: () => undertowClosed = true,
          onClosePostJournal: () {},
          onCloseInvite: () {},
        );
        expect(handled, isTrue);
        expect(undertowClosed, isTrue);
      });

      test('home exit returns false', () {
        final handled = nav.handleBack(
          journalOpen: false,
          undertowOpen: false,
          postJournalOpen: false,
          inviteOpen: false,
          onCloseJournal: () {},
          onCloseUndertow: () {},
          onClosePostJournal: () {},
          onCloseInvite: () {},
        );
        expect(handled, isFalse);
      });

      test('navigates back from sub-screens to home', () {
        nav.show(AppScreen.settings);
        nav.handleBack(
          journalOpen: false,
          undertowOpen: false,
          postJournalOpen: false,
          inviteOpen: false,
          onCloseJournal: () {},
          onCloseUndertow: () {},
          onClosePostJournal: () {},
          onCloseInvite: () {},
        );
        expect(nav.screen, AppScreen.home);
      });
    });
  });
}
