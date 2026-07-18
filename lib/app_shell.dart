// Mentesana — the phone shell.
// Orchestrates screens, overlays, and the ambient sea. Business logic has
// been extracted into NavigationManager and SeaManager; this layer wires
// them to the widget tree and manages overlay composition (journal editor,
// invite, post-journal prompt, undertow, onboarding, PIN lock).
//
// 1:1 port of showScreen / nav wiring / invite / postJournal / homeWrite /
// startFreeJournal / openEntryForWriting / showEntryDetail from src/main.js.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ai_service.dart';
import 'analysis_engine.dart';
import 'app_store.dart';
import 'archive_screen.dart';
import 'calendar_screen.dart';
import 'core/locator.dart';
import 'core/navigation_manager.dart';
import 'core/sea_manager.dart';
import 'currents_engine.dart';
import 'currents_surfaces.dart';
import 'entry_detail_screen.dart';
import 'home_screen.dart';
import 'insight_screen.dart';
import 'journal_editor.dart';
import 'journal_home_screen.dart';
import 'journal_prompts.dart';
import 'lock_screen.dart';
import 'mood_palette.dart';
import 'mood_selector_screen.dart';
import 'prompt_library_screen.dart';
import 'sea_icons.dart';
import 'sea_painter.dart';
import 'settings_screen.dart';
import 'tide_lab_screen.dart';
import 'welcome_screen.dart';

const _rivaLight = kRivaLight;

class MentesanaShell extends StatefulWidget {
  const MentesanaShell({super.key, required this.store});

  final AppStore store;

  @override
  State<MentesanaShell> createState() => _MentesanaShellState();
}

class _MentesanaShellState extends State<MentesanaShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // -- Injected managers --
  late final NavigationManager _navManager = locate<NavigationManager>();
  late final SeaManager _seaManager = locate<SeaManager>();

  bool _welcomeOpen = false;
  bool _welcomeTesting = false;
  bool _locked = false; // PIN veil at boot (JS pinLockOn boot check)

  String? _note;
  Timer? _noteTimer;
  Timer? _reminderTimer;

  // ---------- journal state (JS journalMode / activeEntry / …) ----------
  bool _journalOpen = false;
  bool _journalClosing = false;
  JournalEditorConfig? _editorConfig;
  bool _journalFromHome = false;
  bool _journalKept = false;
  bool _suppressMoodWriteInvite = false;
  JournalEntry? _activeEntry;
  JournalEntry? _lastKeptEntry;
  Timer? _keptNavTimer;

  // invite (the pop-up page after a kept mood)
  bool _inviteOpen = false;
  String _invitePrompt = '';
  Timer? _inviteTimer;

  // post-journal check-in prompt
  bool _postJournalOpen = false;
  JournalEntry? _postJournalEntry;

  // undertow — a current noticed under a kept page (currents engine)
  bool _undertowOpen = false;
  JournalEntry? _undertowEntry;
  UndertowReading? _undertowReading;

  // check-in plumbing
  (double, double)? _checkinEarlier;
  (double, double)? _checkinRevisit;
  double? _checkinInitialV, _checkinInitialA;
  bool _checkinAfterCheck = false;
  bool _checkinJournaledSubline = false;
  int _checkinNonce = 0;

  // entry detail (JS detailReads — session-only re-reading counter)
  JournalEntry? _detailEntry;
  int _detailNonce = 0;

  // AI daily prompt (JS window._aiCachedPrompt)
  String? _aiCachedPrompt;
  bool _aiPromptPending = false;

  AppStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store.addListener(_onStore);
    // Connect the sea manager to this state's ticker provider.
    _seaManager.attachVsync(this);
    // Boot condition: first visit — not welcomed and nothing kept yet.
    _welcomeOpen = !store.welcomed && store.entries.isEmpty;
    // The sea keeps this, quietly — the PIN veil at boot.
    _locked = store.pinLockOn && store.pinCode.isNotEmpty;
    // In-app reminder loop (30s cadence, like the prototype's interval).
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      for (final msg in store.checkReminders()) {
        _quietNote(msg);
      }
    });
    // Sync the screen state from the navigation manager.
    _navManager.addListener(_onNavChanged);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  void _onNavChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSeaTicker();
  }

  bool get _reduced =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ||
      store.reducedMotionOn;

  void _syncSeaTicker() {
    _seaManager.syncReduced(_reduced);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // A fresh open — the lens invites again (JS visibilitychange).
      setState(() => store.sessionFresh = true);
      _seaManager.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Pause the sea ticker while the app is backgrounded — no point
      // burning GPU cycles on invisible water.
      _seaManager.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    store.removeListener(_onStore);
    _navManager.removeListener(_onNavChanged);
    _reminderTimer?.cancel();
    _noteTimer?.cancel();
    _inviteTimer?.cancel();
    _keptNavTimer?.cancel();
    _seaManager.dispose();
    super.dispose();
  }

  // ---------- quiet notes (toast tone, shell level) ----------
  void _quietNote(String msg) {
    _noteTimer?.cancel();
    setState(() => _note = msg);
    _noteTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _note = null);
    });
  }

  // ---------- navigation (JS showScreen) ----------
  void _show(AppScreen s) {
    _inviteTimer?.cancel();
    setState(() => _inviteOpen = false);
    _navManager.show(s);
    if (s == AppScreen.journalhome || s == AppScreen.promptlibrary) {
      _maybeFetchAiPrompt();
    }
  }

  /// JS homeCheckin — a fresh check-in; today's earlier weather leaves a trace.
  void _homeCheckin() {
    final earlier = store.todaysEntry();
    store.sessionFresh = false;
    _activeEntry = null;
    _suppressMoodWriteInvite = false;
    _journalKept = false;
    _lastKeptEntry = null;
    setState(() {
      _checkinNonce++;
      _checkinEarlier =
          earlier != null && earlier.v != null && earlier.a != null
              ? (earlier.v!, earlier.a!)
              : null;
      _checkinRevisit = null;
      _checkinInitialV = null;
      _checkinInitialA = null;
      _checkinAfterCheck = false;
      _checkinJournaledSubline = false;
    });
    _show(AppScreen.checkin);
  }

  // ---------- keep (JS keep() routing) ----------
  void _onKept(MoodEntry m) {
    final cameFromSavedJournal = _suppressMoodWriteInvite &&
        _activeEntry != null &&
        _activeEntry!.text.isNotEmpty;
    if (cameFromSavedJournal) {
      // The after-writing check updates the page's weather in place.
      final e = _activeEntry!;
      e.v = m.v;
      e.a = m.a;
      e.word = m.word;
      e.edited = m.edited;
      e.moodTs = DateTime.now().millisecondsSinceEpoch;
      store.saveEntries();
      _suppressMoodWriteInvite = false;
      setState(() => _checkinJournaledSubline = true);
      _keptNavTimer?.cancel();
      _keptNavTimer =
          Timer(Duration(milliseconds: _reduced ? 350 : 1200), () {
        if (mounted) _show(AppScreen.home);
      });
      return;
    }
    final entry = JournalEntry(
      ts: m.ts.millisecondsSinceEpoch,
      v: m.v,
      a: m.a,
      word: m.word,
      edited: m.edited,
    );
    store.addEntry(entry);
    _lastKeptEntry = entry;
    // The invite arrives after the ceremony; both exits are costless.
    _inviteTimer?.cancel();
    _inviteTimer =
        Timer(Duration(milliseconds: _reduced ? 700 : 2100), () {
      if (!mounted ||
          _journalKept ||
          _journalOpen ||
          _navManager.screen != AppScreen.checkin) {
        return;
      }
      setState(() {
        _invitePrompt = journalPrompt(entry.v, entry.a, entry.word);
        _inviteOpen = true;
      });
    });
  }

  // ---------- journal editor plumbing ----------
  void _openEditor(JournalEditorConfig config) {
    _inviteTimer?.cancel();
    setState(() {
      _inviteOpen = false;
      _editorConfig = config;
      _journalOpen = true;
    });
  }

  /// JS openJournal on a kept/known mood entry ('say more', invite, edit).
  void _openEditorForEntry(JournalEntry e, {String? mode}) {
    _activeEntry = e;
    _journalKept = false;
    final resolvedMode = mode ?? (e.v != null ? 'mood' : 'free');
    if (e.v != null) {
      _checkinInitialV = e.v;
      _checkinInitialA = e.a;
    }
    _openEditor(JournalEditorConfig(
      mode: resolvedMode,
      activeEntry: e,
      freePrompt: e.prompt.isNotEmpty ? e.prompt : null,
      v: e.v ?? 0,
      a: e.a ?? 0,
      word: e.word,
      initialText: e.text,
      initialTitle: e.title.isNotEmpty ? e.title : e.prompt,
      initialTag: e.tag,
      initialBottle: e.tideLine,
      attachments: [...e.attachments],
    ));
    if (_navManager.screen != AppScreen.checkin) _show(AppScreen.checkin);
  }

  /// JS startFreeJournal(resume, prompt) — a page with no weather required.
  void _startFreeJournal({bool resume = false, String? prompt}) {
    final draft = resume ? store.readJournalDraft() : null;
    final activeEntry = draft?.activeEntryTs != null
        ? store.findByTs(draft!.activeEntryTs!)
        : null;
    final mode = draft?.mode ??
        (activeEntry != null && activeEntry.v != null ? 'mood' : 'free');
    final rawPrompt = draft?.prompt ?? prompt ?? activeEntry?.prompt;
    final bottle = draft != null
        ? draft.bottle
        : (activeEntry?.tideLine ?? '');
    _activeEntry = activeEntry;
    _journalKept = false;
    _openEditor(JournalEditorConfig(
      mode: mode,
      activeEntry: activeEntry,
      freePrompt:
          (rawPrompt == null || rawPrompt.isEmpty) ? null : rawPrompt,
      v: activeEntry?.v ?? 0,
      a: activeEntry?.a ?? 0,
      word: activeEntry?.word,
      initialText: draft?.text ?? '',
      initialTitle: draft?.title ?? '',
      initialTag: draft?.tag ?? '',
      initialBottle: bottle,
      attachments: draft != null ? [...draft.attachments] : [],
    ));
    if (_navManager.screen != AppScreen.checkin) _show(AppScreen.checkin);
  }

  /// JS homeWrite — today's page from the Home button.
  void _homeWrite() {
    _journalFromHome = true;
    final e = store.todaysEntry();
    if (e == null) {
      _startFreeJournal();
      return;
    }
    if (e.v != null) {
      _checkinInitialV = e.v;
      _checkinInitialA = e.a;
    }
    _openEditorForEntry(e, mode: 'mood');
  }

  /// JS duplicateEntry — a fresh page carrying the old one's words.
  void _duplicateEntry(JournalEntry e) {
    _activeEntry = null;
    _journalKept = false;
    _openEditor(JournalEditorConfig(
      mode: 'free',
      freePrompt: e.prompt.isNotEmpty ? e.prompt : null,
      initialText: e.text,
      initialTitle: e.title.isNotEmpty ? e.title : e.prompt,
      initialTag: e.tag,
      attachments: [],
    ));
    if (_navManager.screen != AppScreen.checkin) _show(AppScreen.checkin);
  }

  /// JS closeJournal — fades and settles the page down before the home
  /// screen swaps in, instead of yanking both at once.
  void _closeJournal() {
    if (_journalClosing) return;
    setState(() => _journalClosing = true);
    Timer(Duration(milliseconds: _reduced ? 0 : 260), () {
      if (!mounted) return;
      setState(() {
        _journalOpen = false;
        _journalClosing = false;
        _editorConfig = null;
      });
      if (_journalFromHome) {
        _journalFromHome = false;
        _show(AppScreen.home);
      }
    });
  }

  /// JS keepEntry tail — subline, breath, journal home, post-journal prompt.
  void _onJournalKept(JournalEntry entry) {
    _journalKept = true;
    setState(() => _checkinJournaledSubline = true);
    // The undertow reading happens here — after keeping, never while writing.
    // One quiet thing at a time: when a current is worth naming, it takes
    // the place of the post-journal check-in prompt for this keep. Crisis
    // language is handled by its own calm surfaces and always wins.
    UndertowReading? reading;
    if (store.currentsOn &&
        store.undertowLastDay !=
            dayKeyOf(DateTime.now().millisecondsSinceEpoch) &&
        !containsCrisisLanguage([entry.text])) {
      reading = undertowScan(entry.text);
    }
    Timer(Duration(milliseconds: _reduced ? 250 : 850), () {
      if (!mounted) return;
      _navManager.show(AppScreen.journalhome);
      setState(() {
        _journalOpen = false;
        _editorConfig = null;
        _journalFromHome = false;
        if (reading != null) {
          _undertowEntry = entry;
          _undertowReading = reading;
          _undertowOpen = true;
          store.markUndertowOffered();
        } else {
          _postJournalEntry = entry;
          _postJournalOpen = true;
        }
      });
      _maybeFetchAiPrompt();
    });
  }

  // ---------- entry detail (JS showEntryDetail) ----------
  void _showEntryDetail(JournalEntry entry, AppScreen back) {
    final e = store.findByTs(entry.ts) ?? entry;
    _navManager.recordDetailRead(e.ts);
    setState(() {
      _detailEntry = e;
      _detailNonce++;
    });
    _navManager.show(AppScreen.entrydetail, detailBack: back);
  }

  /// JS 'revisit this weather' — back to the field, visiting.
  void _revisitWeather(JournalEntry e) {
    if (e.v == null || e.a == null) return;
    _activeEntry = null;
    _suppressMoodWriteInvite = false;
    setState(() {
      _checkinNonce++;
      _checkinEarlier = null;
      _checkinRevisit = (e.v!, e.a!);
      _checkinInitialV = null;
      _checkinInitialA = null;
      _checkinAfterCheck = false;
      _checkinJournaledSubline = false;
    });
    _show(AppScreen.checkin);
  }

  // ---------- AI daily prompt (JS _aiCachedPrompt) ----------
  void _maybeFetchAiPrompt() {
    if (!store.aiEnabled || store.entries.length < 2) return;
    if (_aiPromptPending || _aiCachedPrompt != null) return;
    _aiPromptPending = true;
    AIService(store).generateAIDailyPrompt().then((p) {
      _aiPromptPending = false;
      if (p != null && mounted) setState(() => _aiCachedPrompt = p);
    });
  }

  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final reduced = mq.disableAnimations || store.reducedMotionOn;
    final screen = _navManager.screen;
    final depth = _navManager.depth;

    return PopScope(
      canPop: screen == AppScreen.home &&
          !_journalOpen &&
          !_welcomeOpen &&
          !_inviteOpen &&
          !_postJournalOpen &&
          !_locked,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: MediaQuery(
      data: mq.copyWith(
        disableAnimations: reduced,
        textScaler: TextScaler.linear(store.textScale),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: kInkDeep)),
          // The living sea, behind Home (settings and check-in bring their own
          // full backgrounds).
          if (screen == AppScreen.home)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: SeaPainter(
                    model: _seaManager.model,
                    foamX: _seaManager.foamX,
                    foamLayer: _seaManager.foamLayer,
                  ),
                ),
              ),
            ),
          // Deeper screens still sit in the same sea, just quieter and dimmer
          // with depth — continuity instead of a flat backdrop swap.
          if (depth > 0 && screen != AppScreen.settings)
            Positioned.fill(
              child: RepaintBoundary(
                child: Opacity(
                  // #4: keep the living sea clearly present on deep screens,
                  // not a faint ghost — the sea is a character everywhere.
                  opacity: (0.44 - depth * 0.06).clamp(0.18, 0.44),
                  child: CustomPaint(
                    painter: SeaPainter(
                      model: _seaManager.model,
                      foamX: _seaManager.foamX,
                      foamLayer: _seaManager.foamLayer,
                    ),
                  ),
                ),
              ),
            ),
          // Depth ambience — the water darkens as you descend (JS SCREEN_DEPTH).
          if (depth > 0)
            Positioned.fill(
              child: AnimatedContainer(
                duration: Duration(milliseconds: reduced ? 0 : 700),
                decoration: BoxDecoration(
                  // Kept translucent (not opaque) so the mood-tinted sea
                  // underneath still shows through on every screen depth,
                  // not just Home.
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      // #4: lighter scrim so the sea reads through, rather than
                      // being crushed to near-black on deeper screens.
                      const Color(0xFF060B12).withValues(
                          alpha: (depth / 2.25 * .34).clamp(0.0, .34)),
                      const Color(0xFF04080D).withValues(
                          alpha: (depth / 2.25 * .5).clamp(0.0, .5)),
                    ],
                  ),
                ),
              ),
            ),
          // Screens.
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: reduced ? 0 : 360),
              reverseDuration: Duration(milliseconds: reduced ? 0 : 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                return FadeTransition(
                  opacity: curve,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, .025),
                      end: Offset.zero,
                    ).animate(curve),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .985, end: 1.0)
                          .animate(curve),
                      child: child,
                    ),
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(screen),
                child: SafeArea(
                  top: screen != AppScreen.home &&
                      screen != AppScreen.checkin &&
                      screen != AppScreen.settings,
                  bottom: false,
                  child: _screenWidget(),
                ),
              ),
            ),
          ),
          // Bottom navigation — home / journal home / archive / insight /
          // settings only (JS nav visibility).
          if (_navVisible && !_welcomeOpen)
            Positioned(left: 0, right: 0, bottom: 0, child: _nav()),
          // Journal editor overlay (sits over the check-in, as in the web).
          // While closing, it fades and settles down instead of vanishing
          // and yanking the screen beneath it into place all at once.
          if (_journalOpen && _editorConfig != null)
            Positioned.fill(
              child: AnimatedSlide(
                duration: Duration(milliseconds: reduced ? 0 : 260),
                curve: Curves.easeInCubic,
                offset: _journalClosing ? const Offset(0, .05) : Offset.zero,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: reduced ? 0 : 260),
                  curve: Curves.easeInCubic,
                  opacity: _journalClosing ? 0 : 1,
                  child: JournalEditor(
                    key: ValueKey('editor-${_editorConfig.hashCode}'),
                    store: store,
                    config: _editorConfig!,
                    reduced: reduced,
                    onClose: _closeJournal,
                    onKept: _onJournalKept,
                  ),
                ),
              ),
            ),
          // Write invite — asks once, both exits are costless.
          if (_inviteOpen) ..._invite(),
          // Post-journal check-in prompt.
          if (_postJournalOpen) ..._postJournal(),
          // A current under the kept page — the undertow surface.
          if (_undertowOpen &&
              _undertowEntry != null &&
              _undertowReading != null)
            Positioned.fill(
              child: UndertowSurface(
                store: store,
                entry: _undertowEntry!,
                reading: _undertowReading!,
                reduced: reduced,
                onClose: () => setState(() => _undertowOpen = false),
              ),
            ),
          // Onboarding overlay.
          if (_welcomeOpen)
            Positioned.fill(
              child: WelcomeScreen(
                initialPreferences: store.onboardingPreferences,
                testing: _welcomeTesting,
                onClose: (to, prefs) {
                  if (!_welcomeTesting) store.setWelcomed(prefs);
                  setState(() {
                    _welcomeOpen = false;
                    _welcomeTesting = false;
                  });
                  if (to == 'checkin') {
                    store.sessionFresh = false;
                    _navManager.show(AppScreen.checkin);
                  } else {
                    _navManager.show(AppScreen.home);
                  }
                  if (to == 'write') _startFreeJournal();
                },
              ),
            ),
          // Quiet note.
          if (_note != null)
            Positioned(
              left: 26,
              right: 26,
              bottom: 78,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color.fromRGBO(11, 20, 27, .92),
                      border: Border.all(color: ivory(.18)),
                    ),
                    child: Text(
                      _note!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontStyle: FontStyle.italic,
                        fontSize: 12.5,
                        height: 1.55,
                        color: ivory(.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // The sea keeps this, quietly — PIN veil at boot.
          if (_locked)
            Positioned.fill(
              child: LockScreen(
                store: store,
                reduced: reduced,
                onUnlocked: () => setState(() => _locked = false),
              ),
            ),
        ],
      ),
      ),
    ),
    );
  }

  void _handleSystemBack() {
    _navManager.handleBack(
      journalOpen: _journalOpen,
      undertowOpen: _undertowOpen,
      postJournalOpen: _postJournalOpen,
      inviteOpen: _inviteOpen,
      onCloseJournal: _closeJournal,
      onCloseUndertow: () => setState(() => _undertowOpen = false),
      onClosePostJournal: () => setState(() => _postJournalOpen = false),
      onCloseInvite: () => setState(() => _inviteOpen = false),
    );
  }

  bool get _navVisible => !_journalOpen && _navManager.navVisible;

  List<MoodEntry> _recentMoodTrail() {
    final moods = store.entries.where((entry) => entry.isMoodEntry).toList()
      ..sort((left, right) => left.ts.compareTo(right.ts));
    final recent = moods.length > 7 ? moods.sublist(moods.length - 7) : moods;
    return recent
        .map((entry) => MoodEntry(
              ts: entry.date,
              v: entry.v!,
              a: entry.a!,
              word: entry.word!,
              edited: entry.edited,
            ))
        .toList(growable: false);
  }

  Widget _screenWidget() {
    switch (_navManager.screen) {
      case AppScreen.home:
        return HomeScreen(
          store: store,
          onCheckin: _homeCheckin,
          onSettings: () => _show(AppScreen.settings),
          onWrite: _homeWrite,
          onDoor: (door) => _show(door == 'archive'
              ? AppScreen.archive
              : door == 'tideLab'
                  ? AppScreen.tideLab
                  : AppScreen.insight),
        );
      case AppScreen.checkin:
        return Stack(
          children: [
            MoodSelectorScreen(
              key: ValueKey('checkin-$_checkinNonce'),
              onKept: _onKept,
              onSayMore: _checkinAfterCheck
                  ? null
                  : () {
                      final e = _lastKeptEntry;
                      if (e != null) _openEditorForEntry(e, mode: 'mood');
                    },
              afterCheck: _checkinAfterCheck,
              journaledSubline: _checkinJournaledSubline,
              moodTrail: _recentMoodTrail(),
              earlierTrace: _checkinEarlier,
              revisitTarget: _checkinRevisit,
              initialV: _checkinInitialV,
              initialA: _checkinInitialA,
            ),
            // #toHome — overlaid at shell level, exactly like the prototype.
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, left: 12),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _show(AppScreen.home),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text('home',
                          style: TextStyle(
                              fontSize: 9,
                              letterSpacing: .72,
                              color: ivory(.45))),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case AppScreen.settings:
        return SettingsScreen(
          store: store,
          onBackHome: () => _show(AppScreen.home),
          onReplayOnboarding: () => setState(() {
            _welcomeOpen = true;
            _welcomeTesting = true;
          }),
        );
      case AppScreen.journalhome:
        return JournalHomeScreen(
          store: store,
          aiCachedPrompt: _aiCachedPrompt,
          onBack: () => _show(AppScreen.home),
          onCalendar: () => _show(AppScreen.calendar),
          onLibrary: () => _show(AppScreen.promptlibrary),
          onAllPages: () => _show(AppScreen.archive),
          onFreshPage: () => _startFreeJournal(),
          onResumeDraft: () => _startFreeJournal(resume: true),
          onContinueEntry: (e) => _openEditorForEntry(e),
          onOpenEntry: (e) =>
              _showEntryDetail(e, AppScreen.journalhome),
          onWriteFromPrompt: (p) => _startFreeJournal(prompt: p),
        );
      case AppScreen.promptlibrary:
        return PromptLibraryScreen(
          store: store,
          aiCachedPrompt: _aiCachedPrompt,
          onBack: () => _show(AppScreen.journalhome),
          onWriteFromPrompt: (p) => _startFreeJournal(prompt: p),
        );
      case AppScreen.calendar:
        return CalendarScreen(
          store: store,
          onBack: () => _show(AppScreen.journalhome),
          onOpenEntry: (e) => _showEntryDetail(e, AppScreen.calendar),
        );
      case AppScreen.archive:
        return ArchiveScreen(
          store: store,
          onBack: () => _show(AppScreen.home),
          onOpenEntry: (e) => _showEntryDetail(e, AppScreen.archive),
        );
      case AppScreen.entrydetail:
        final e = _detailEntry;
        if (e == null) return const SizedBox.shrink();
        return EntryDetailScreen(
          key: ValueKey('detail-$_detailNonce'),
          store: store,
          entry: e,
          reads: _navManager.detailReads['${e.ts}'] ?? 0,
          reduced: _reduced,
          onBack: () => _navManager.show(_navManager.detailBack),
          onEdit: (x) => _openEditorForEntry(x),
          onDuplicate: _duplicateEntry,
          onRevisitWeather: _revisitWeather,
          onDeleted: () => _navManager.show(_navManager.detailBack),
        );
      case AppScreen.insight:
        return InsightScreen(
          store: store,
          onBack: () => _show(AppScreen.home),
          onOpenEntry: (e) => _showEntryDetail(e, AppScreen.insight),
        );
      case AppScreen.tideLab:
        return TideLabScreen(
          store: store,
          onBack: () => _show(AppScreen.home),
          onOpenEntry: (e) => _showEntryDetail(e, AppScreen.tideLab),
        );
    }
  }

  // ---------- invite (verbatim: #invite — write / not tonight) ----------
  List<Widget> _invite() {
    void skipToHome() {
      setState(() => _inviteOpen = false);
      _show(AppScreen.home);
    }

    return [
      Positioned.fill(
        child: GestureDetector(
          onTap: skipToHome,
          child: Container(color: const Color(0xFF060B12).withValues(alpha: .45)),
        ),
      ),
      Positioned(
        left: 26,
        right: 26,
        bottom: 90,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF0B141B).withValues(alpha: .97),
            border: Border.all(color: ivory(.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                    children: richTextSpans(
                  _invitePrompt,
                  GoogleFonts.alice(
                      fontSize: 17, height: 1.5, color: ivory(.9)),
                  GoogleFonts.alice(
                      fontStyle: FontStyle.italic,
                      fontSize: 17,
                      height: 1.5,
                      color: kOro.withValues(alpha: .92)),
                )),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      final e = _lastKeptEntry;
                      setState(() => _inviteOpen = false);
                      if (e != null) _openEditorForEntry(e, mode: 'mood');
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                kRiva.withValues(alpha: .6)),
                        color: kRiva.withValues(alpha: .12),
                      ),
                      child: const Text('write',
                          style: TextStyle(
                              fontSize: 13, color: _rivaLight)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: skipToHome,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 11),
                      child: Text('not tonight',
                          style: TextStyle(
                              fontSize: 12, color: ivory(.5))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // ---------- post-journal prompt (verbatim: #postJournal) ----------
  List<Widget> _postJournal() {
    void later() {
      setState(() => _postJournalOpen = false);
      _show(AppScreen.journalhome);
    }

    return [
      Positioned.fill(
        child: GestureDetector(
          onTap: later,
          child: Container(color: const Color(0xFF060B12).withValues(alpha: .45)),
        ),
      ),
      Positioned(
        left: 26,
        right: 26,
        bottom: 90,
        child: Semantics(
          label: 'Check in after writing',
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF0B141B).withValues(alpha: .97),
              border: Border.all(color: ivory(.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Would you like to check in now?',
                    style: GoogleFonts.alice(
                        fontSize: 17, height: 1.4, color: ivory(.9))),
                const SizedBox(height: 6),
                Text(
                    'You have already written. This is only a place to notice where you are.',
                    style: TextStyle(
                        fontSize: 12.5, height: 1.55, color: ivory(.6))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        final entry = _postJournalEntry;
                        _suppressMoodWriteInvite = true;
                        _journalKept = false;
                        _activeEntry = entry;
                        setState(() {
                          _postJournalOpen = false;
                          _checkinNonce++;
                          _checkinEarlier = null;
                          _checkinRevisit = null;
                          _checkinInitialV = null;
                          _checkinInitialA = null;
                          _checkinAfterCheck = true;
                          _checkinJournaledSubline = false;
                        });
                        _show(AppScreen.checkin);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: kRiva
                                  .withValues(alpha: .6)),
                          color:
                              kRiva.withValues(alpha: .12),
                        ),
                        child: const Text('check in',
                            style: TextStyle(
                                fontSize: 13, color: _rivaLight)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: later,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 11),
                        child: Text('not now',
                            style: TextStyle(
                                fontSize: 12, color: ivory(.5))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  // ---------- bottom nav: home / write / journal ----------
  Widget _nav() {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) == true ||
        store.reducedMotionOn;
    final active = _navManager.screen == AppScreen.home
        ? 'home'
        : _navManager.screen == AppScreen.journalhome
            ? 'journal'
            : '';
    Widget item(String id, SeaIconData icon, String label, VoidCallback onTap) {
      final activeThis = active == id;
      final color = activeThis ? _rivaLight : ivory(.45);
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: Duration(milliseconds: reduced ? 0 : 220),
            curve: kExhale,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.only(top: 12),
            child: AnimatedScale(
              duration: Duration(milliseconds: reduced ? 0 : 220),
              curve: kExhale,
              scale: activeThis ? 1.04 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: reduced ? 0 : 220),
                    curve: kExhale,
                    padding: EdgeInsets.all(activeThis ? 6 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: activeThis ? color.withValues(alpha: .12) : null,
                    ),
                    child: StrokeIcon(icon,
                        size: 19, color: color, strokeWidth: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: .76,
                          color: color)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final moodGlow = kSea.bilerp(_seaManager.model.visualV, _seaManager.model.visualA)[0];
    // A soft blur behind the bar, plus a graduated (not hard-edged) tint,
    // so the nav reads as part of the scene instead of a pasted-on strip.
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 62 + MediaQuery.of(context).padding.bottom,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .35, 1],
              colors: [
                moodGlow.withValues(
                    alpha: store.moodAtmosphereOn ? .06 : 0),
                const Color(0xFF0B141B).withValues(alpha: .30),
                const Color(0xFF0B141B).withValues(alpha: .46),
              ],
            ),
          ),
          child: Row(
            children: [
              item('home', SeaIcons.navHome, store.t('home'),
                  () => _show(AppScreen.home)),
              item('write', SeaIcons.navWrite, store.t('write'), () {
                _journalFromHome = true;
                _startFreeJournal();
              }),
              item('journal', SeaIcons.navJournal, store.t('journal'),
                  () => _show(AppScreen.journalhome)),
            ],
          ),
        ),
      ),
    );
  }
}

