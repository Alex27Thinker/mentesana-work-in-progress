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

import '_shared/widgets/sea_atmosphere.dart';
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
import 'features/home/home_to_checkin_shell.dart';
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
import 'theme.dart';
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

  // v2 — cached atmosphere for the ambient sea (recomputed on store
  // changes, read by the sea ticker every frame at zero cost).
  MoodAtmosphere _atmo = (valence: 0.0, arousal: 0.0);

  // v2 — navigation direction through the water column, for descend /
  // ascend screen transitions.
  double _lastNavDepth = 0;
  bool _navDescending = true;

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

  // v3 — the unified home <-> check-in shell. The shell holds the
  // whole experience (home cluster + lens + check-in field) as a
  // single screen; the host flips between its idle and check-in
  // states via the controller, never by swapping the screen.
  final GlobalKey<HomeToCheckinShellState> _homeShellKey =
      GlobalKey<HomeToCheckinShellState>();
  bool _checkinOpen = false;

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
    // v2 — the ambient sea wears the day's kept weather, everywhere.
    // (The old private no-op in SeaManager silently dropped this coupling.)
    _refreshAtmosphere();
    _seaManager.moodSource = () => _atmo;
    _seaManager.setDepth(_navManager.depth / 2.25);
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
    _refreshAtmosphere();
    if (mounted) setState(() {});
  }

  void _onNavChanged() {
    // v2 — navigating is descending/ascending the one water column: the
    // manager eases the global depth, and the screen transition slides in
    // the direction of travel.
    final d = _navManager.depth / 2.25;
    _navDescending = d >= _lastNavDepth;
    _lastNavDepth = d;
    _seaManager.setDepth(d);
    if (mounted) setState(() {});
  }

  /// v2 — the atmosphere the ambient sea wears: the most recent kept
  /// weather, fading over three days. The sea remembers, gently, and lets
  /// go. Weather, never a verdict — and off with one switch in settings.
  void _refreshAtmosphere() {
    if (!store.moodAtmosphereOn) {
      _atmo = (valence: 0.0, arousal: 0.0);
      return;
    }
    JournalEntry? last;
    for (final e in store.entries) {
      if (e.v == null || e.a == null) continue;
      if (last == null || e.ts > last.ts) last = e;
    }
    if (last == null) {
      _atmo = (valence: 0.0, arousal: 0.0);
      return;
    }
    final ageDays =
        (DateTime.now().millisecondsSinceEpoch - last.ts) / 86400000.0;
    final memory = ageDays <= 1
        ? 1.0
        : ageDays <= 2
            ? .55
            : ageDays <= 3
                ? .28
                : 0.0;
    _atmo = (valence: last.v! * memory, arousal: last.a! * memory);
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
  void _startHomeCheckin() {
    final earlier = store.todaysEntry();
    store.sessionFresh = false;
    _activeEntry = null;
    _suppressMoodWriteInvite = false;
    _journalKept = false;
    _lastKeptEntry = null;
    setState(() {
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
    _openCheckinField();
  }

  /// v3 — open the check-in field over the unified shell WITHOUT
  /// navigating the AnimatedSwitcher to AppScreen.checkin. Both the
  /// home and checkin cases build HomeToCheckinShell with the same
  /// GlobalKey, so a home -> checkin switch would cross-fade two live
  /// copies of that key and trip the framework's
  /// _elements.contains(element) assertion. Seed the _checkin* context
  /// fields BEFORE calling this.
  void _openCheckinField() {
    setState(() => _checkinOpen = true);
    if (_navManager.screen == AppScreen.home ||
        _navManager.screen == AppScreen.checkin) {
      _homeShellKey.currentState?.ignite();
    } else {
      // Not on the unified shell — travel home; the shell mounts with
      // initialOpen true and arrives already in the field state.
      _show(AppScreen.home);
    }
  }

  /// v3 — called by the unified shell's "home" chip and by the system
  /// back handler. Reverses the transition and hands the sea back to
  /// its ambient source.
  void _releaseToHome() {
    if (!_checkinOpen) return;
    setState(() => _checkinOpen = false);
    _seaManager.releaseSea();
    _homeShellKey.currentState?.release();
  }

  // ---------- keep (JS keep() routing) ----------
  void _onKept(MoodEntry m) {
    // v2 — keeping a mood sends a wave through the ambient sea, so the
    // ceremony is felt on the water you return to.
    final keepSize = MediaQuery.of(context).size;
    _seaManager.ripple(Offset(keepSize.width * .5, keepSize.height * .58));
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
      _keptNavTimer = Timer(Duration(milliseconds: _reduced ? 350 : 1200), () {
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
    _inviteTimer = Timer(Duration(milliseconds: _reduced ? 700 : 2100), () {
      if (!mounted || _journalKept || _journalOpen || !_checkinOpen) {
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
    final bottle = draft != null ? draft.bottle : (activeEntry?.tideLine ?? '');
    _activeEntry = activeEntry;
    _journalKept = false;
    _openEditor(JournalEditorConfig(
      mode: mode,
      activeEntry: activeEntry,
      freePrompt: (rawPrompt == null || rawPrompt.isEmpty) ? null : rawPrompt,
      v: activeEntry?.v ?? 0,
      a: activeEntry?.a ?? 0,
      word: activeEntry?.word,
      initialText: draft?.text ?? '',
      initialTitle: draft?.title ?? '',
      initialTag: draft?.tag ?? '',
      initialBottle: bottle,
      attachments: draft != null ? [...draft.attachments] : [],
    ));
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
      _checkinEarlier = null;
      _checkinRevisit = (e.v!, e.a!);
      _checkinInitialV = null;
      _checkinInitialA = null;
      _checkinAfterCheck = false;
      _checkinJournaledSubline = false;
    });
    _openCheckinField();
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

    return PopScope(
      canPop: screen == AppScreen.home &&
          !_checkinOpen &&
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
              // v2 — ONE persistent living sea under every screen. The same
              // water is continuously visible everywhere: it recedes as you
              // descend (eased frame-by-frame by SeaManager, never swapped
              // per navigation) and wears the day's kept weather at every
              // depth. The check-in screen still carries its own inner
              // field (the one the dot rides).
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _seaManager,
                    builder: (context, child) => Opacity(
                      opacity:
                          (1 - _seaManager.depth * .62).clamp(0.30, 1.0),
                      child: child,
                    ),
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
              // v2 — the water darkens continuously as you descend, moving
              // with the eased depth instead of a one-shot 700ms tween.
              Positioned.fill(child: DepthVeil(manager: _seaManager)),
              // Screens.
              // v2 — one global scroll coupler: any scrolling surface on
              // any screen nudges the living sea beneath it, so the water
              // and the content always move together.
              Positioned.fill(
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: (n) {
                    _seaManager.scrollDrift(n.scrollDelta ?? 0);
                    return false;
                  },
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: reduced ? 0 : 360),
                    reverseDuration:
                        Duration(milliseconds: reduced ? 0 : 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) {
                      final curve = CurvedAnimation(
                          parent: anim, curve: Curves.easeOutCubic);
                      return FadeTransition(
                        opacity: curve,
                        child: SlideTransition(
                          // v2 — screens arrive from the direction of travel
                          // through the water column: descending pulls the
                          // new screen up from below; ascending lets it
                          // settle down from above.
                          position: Tween<Offset>(
                            begin: Offset(0, _navDescending ? .035 : -.035),
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
                      key: ValueKey(
                          screen == AppScreen.checkin ? AppScreen.home : screen),
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
                    offset:
                        _journalClosing ? const Offset(0, .05) : Offset.zero,
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
                        _navManager.show(AppScreen.home);
                        _startHomeCheckin();
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
                            horizontal: s16, vertical: s8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color.fromRGBO(11, 20, 27, .92),
                          border: Border.all(color: ivory(.18)),
                        ),
                        child: Text(
                          _note!,
                          textAlign: TextAlign.center,
                          style: MenteType.bodySerif.copyWith(
                            fontStyle: FontStyle.italic,
                            color: textSecondary,
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
    if (_checkinOpen) {
      _releaseToHome();
      return;
    }
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

  // v3 — the check-in field has its own chrome (the "home" chip), so
  // the bottom nav must hide while the field is open; _navManager
  // stays on AppScreen.home during a check-in and can no longer make
  // that call on its own.
  bool get _navVisible =>
      !_journalOpen && !_checkinOpen && _navManager.navVisible;

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
      case AppScreen.checkin:
        // v3 — one screen, two states. The host flips the open state
        // via _homeShellKey.currentState.ignite() / .release() and
        // _navManager stays on AppScreen.home throughout; the only
        // time _navManager.screen is AppScreen.checkin is when the
        // field is shown as a destination (a back-resume or external
        // deep link) — initialOpen then seeds the right state on
        // first build.
        final openedViaNav = _navManager.screen == AppScreen.checkin;
        return HomeToCheckinShell(
          key: _homeShellKey,
          store: store,
          initialOpen: _checkinOpen || openedViaNav,
          checkinEarlier: _checkinEarlier,
          checkinRevisit: _checkinRevisit,
          checkinInitialV: _checkinInitialV,
          checkinInitialA: _checkinInitialA,
          checkinAfterCheck: _checkinAfterCheck,
          checkinJournaledSubline: _checkinJournaledSubline,
          moodTrail: _recentMoodTrail(),
          onKept: _onKept,
          onSteer: (va) => _seaManager.tintSea(va.$1, va.$2),
          onSayMore: _checkinAfterCheck
              ? null
              : () {
                  final e = _lastKeptEntry;
                  if (e != null) _openEditorForEntry(e, mode: 'mood');
                },
          onCheckinIntent: _startHomeCheckin,
          onWrite: _homeWrite,
          onDoor: (door) {
            // Leaving the unified shell for a deeper screen tears
            // down the field. Hand the sea back to the ambient source
            // and let the AnimatedSwitcher swap to the new screen.
            if (_checkinOpen) _releaseToHome();
            _show(door == 'archive'
                ? AppScreen.archive
                : door == 'tideLab'
                    ? AppScreen.tideLab
                    : AppScreen.insight);
          },
          onSettings: () {
            if (_checkinOpen) _releaseToHome();
            _show(AppScreen.settings);
          },
          onRelease: _releaseToHome,
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
          onOpenEntry: (e) => _showEntryDetail(e, AppScreen.journalhome),
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
          child:
              Container(color: const Color(0xFF060B12).withValues(alpha: .45)),
        ),
      ),
      Positioned(
        left: 26,
        right: 26,
        bottom: 90,
        child: Container(
          padding: const EdgeInsets.fromLTRB(s24, s24, s24, s16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
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
                  MenteType.bodySerif.copyWith(height: 1.5),
                  MenteType.bodySerif.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      color: kOro.withValues(alpha: .92)),
                )),
              ),
              const SizedBox(height: s16),
              Row(
                children: [
                  MenteButtons.primary(
                      label: 'write',
                      onTap: () {
                        final e = _lastKeptEntry;
                        setState(() => _inviteOpen = false);
                        if (e != null) _openEditorForEntry(e, mode: 'mood');
                      }),
                  const SizedBox(width: s12),
                  MenteButtons.quiet(label: 'not tonight', onTap: skipToHome),
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
          child:
              Container(color: const Color(0xFF060B12).withValues(alpha: .45)),
        ),
      ),
      Positioned(
        left: 26,
        right: 26,
        bottom: 90,
        child: Semantics(
          label: 'Check in after writing',
          child: Container(
            padding: const EdgeInsets.fromLTRB(s24, s24, s24, s16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r),
              color: const Color(0xFF0B141B).withValues(alpha: .97),
              border: Border.all(color: ivory(.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Would you like to check in now?',
                    style: MenteType.bodySerif.copyWith(height: 1.4)),
                const SizedBox(height: s8),
                Text(
                    'You have already written. This is only a place to notice where you are.',
                    style: MenteType.bodySerif
                        .copyWith(height: 1.55, color: textSecondary)),
                const SizedBox(height: s16),
                Row(
                  children: [
                    MenteButtons.primary(
                      label: 'check in',
                      onTap: () {
                        final entry = _postJournalEntry;
                        _suppressMoodWriteInvite = true;
                        _journalKept = false;
                        _activeEntry = entry;
                        setState(() {
                          _postJournalOpen = false;
                          _checkinEarlier = null;
                          _checkinRevisit = null;
                          _checkinInitialV = null;
                          _checkinInitialA = null;
                          _checkinAfterCheck = true;
                          _checkinJournaledSubline = false;
                        });
                        _openCheckinField();
                      },
                    ),
                    const SizedBox(width: s12),
                    MenteButtons.quiet(label: 'not now', onTap: later),
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
            padding: const EdgeInsets.only(top: 6),
            child: AnimatedScale(
              duration: Duration(milliseconds: reduced ? 0 : 220),
              curve: kExhale,
              scale: activeThis ? 1.04 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fixed 32x32 icon slot: the active pill paints inside
                  // it instead of padding the layout, so the item's height
                  // never changes and the bar cannot overflow.
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: reduced ? 0 : 220),
                      curve: kExhale,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color:
                            activeThis ? color.withValues(alpha: .12) : null,
                      ),
                      child: Center(
                        child:
                            StrokeIcon(icon, color: color, strokeWidth: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: s4),
                  Text(label,
                      style: MenteType.eyebrow
                          .copyWith(letterSpacing: .76, color: color)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final moodGlow =
        kSea.bilerp(_seaManager.model.visualV, _seaManager.model.visualA)[0];
    // A soft blur behind the bar with a gradient fade at the top so the nav
    // reads as part of the scene instead of a pasted-on strip.
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gradient fade — no blur, so content shows through naturally.
        SizedBox(
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0B141B).withValues(alpha: 0),
                  moodGlow.withValues(
                      alpha: store.moodAtmosphereOn ? .06 : 0),
                ],
              ),
            ),
          ),
        ),
        // Blur applies only to the bar itself, not the fade zone above.
        ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: SizedBox(
              height: 62 + bottomPad,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            moodGlow.withValues(
                                alpha: store.moodAtmosphereOn ? .06 : 0),
                            const Color(0xFF0B141B).withValues(alpha: .30),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 62 + bottomPad,
                    padding: EdgeInsets.only(bottom: bottomPad),
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
                        () {
                      if (_checkinOpen) _releaseToHome();
                      _show(AppScreen.home);
                    }),
                    item('write', SeaIcons.navWrite, store.t('write'), () {
                      if (_checkinOpen) _releaseToHome();
                      _journalFromHome = true;
                      _startFreeJournal();
                    }),
                    item('journal', SeaIcons.navJournal, store.t('journal'),
                        () {
                      if (_checkinOpen) _releaseToHome();
                      _show(AppScreen.journalhome);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    ],
  );
}
}
