// Mentesana — the unified Home <-> Check-in shell.
//
// One surface, two states, one continuous water. Tapping the lens on
// home ignites a parallel choreography: the home cluster dissolves
// (fade + small slide) while the check-in field fades in (fade + small
// rise) — the dot is steering the *same* SeaManager the shell is
// painting underneath, so the water visibly responds to the user's
// hand the moment it appears. Tapping "home" reverses the move and
// hands the sea back to its ambient source.
//
// Replaces the older AnimatedSwitcher that swapped HomeScreen and
// MoodSelectorScreen by key. The screen identity never changes; only
// the out / in progress values change.

import 'package:flutter/material.dart';

import '../../app_store.dart';
import '../../home_screen.dart';
import '../../mood_selector_screen.dart';
import 'checkin_overlay_chrome.dart';

/// v3 — a single screen that hosts both home and check-in. Driven by
/// [_out] (home cluster fade) and [_in] (check-in field reveal). The
/// host widget rebuilds every animation frame via the [ListenableBuilder]
/// at the bottom.
class HomeToCheckinShell extends StatefulWidget {
  const HomeToCheckinShell({
    super.key,
    required this.store,
    required this.initialOpen,
    required this.checkinEarlier,
    required this.checkinRevisit,
    required this.checkinInitialV,
    required this.checkinInitialA,
    required this.checkinAfterCheck,
    required this.checkinJournaledSubline,
    required this.moodTrail,
    required this.onKept,
    required this.onSteer,
    required this.onSayMore,
    required this.onCheckinIntent,
    required this.onWrite,
    required this.onDoor,
    required this.onSettings,
    required this.onRelease,
  });

  final AppStore store;

  /// True if the screen should arrive already in check-in state (e.g.
  /// from a system back-resume into the field).
  final bool initialOpen;

  final (double, double)? checkinEarlier;
  final (double, double)? checkinRevisit;
  final double? checkinInitialV;
  final double? checkinInitialA;
  final bool checkinAfterCheck;
  final bool checkinJournaledSubline;
  final List<MoodEntry> moodTrail;

  final ValueChanged<MoodEntry> onKept;

  /// v3 — pushed by the field whenever the dot's (v, a) changes. The
  /// shell forwards this to SeaManager.tintSea() so the ambient water
  /// becomes the same water the dot is stirring.
  final ValueChanged<(double, double)> onSteer;

  /// v3 — 'say more' door, opened by the host on the most recent kept
  /// entry. Null after a check-in that doesn't allow follow-up writing
  /// (e.g. the post-journal weather update).
  final VoidCallback? onSayMore;

  /// v3 — fired by the home lens tap, BEFORE the shell ignites. The
  /// host uses this to seed the check-in context (earlier trace,
  /// revisit target, journaled subline, etc.) so the field mounts
  /// with the right initial state.
  final VoidCallback onCheckinIntent;

  final VoidCallback onWrite;
  final ValueChanged<String> onDoor;
  final VoidCallback onSettings;

  /// v3 — fired when the user taps "home". The host releases the
  /// shared sea (SeaManager.releaseSea()) so it relaxes back toward
  /// the day's atmosphere.
  final VoidCallback onRelease;

  @override
  State<HomeToCheckinShell> createState() => HomeToCheckinShellState();
}

class HomeToCheckinShellState extends State<HomeToCheckinShell>
    with TickerProviderStateMixin {
  late final AnimationController _out;
  late final AnimationController _in;
  late final ValueNotifier<double> _outValue;
  late final ValueNotifier<double> _inValue;
  bool _isOpen = false;
  int _fieldNonce = 0;
  bool _suppressFutureIgnites = false;

  // Tunes
  static const _igniteHomeMs = 520;
  static const _igniteFieldMs = 480;
  static const _igniteHomeDelayMs = 60;
  static const _releaseFieldMs = 360;
  static const _releaseHomeMs = 460;
  static const _releaseHomeDelayMs = 60;

  bool get _reduced {
    final mq = MediaQuery.maybeOf(context);
    final byOs = mq?.disableAnimations ?? false;
    return byOs || widget.store.reducedMotionOn;
  }

  @override
  void initState() {
    super.initState();
    _isOpen = widget.initialOpen;
    _outValue = ValueNotifier<double>(_isOpen ? 1.0 : 0.0);
    _inValue = ValueNotifier<double>(_isOpen ? 1.0 : 0.0);
    // v3 — initState runs before dependencies are registered, so we
    // cannot read MediaQuery here. Use the store's setting only; a
    // post-frame sync (in didChangeDependencies) reconciles the OS-level
    // disableAnimations preference once it becomes available.
    final reducedInit = widget.store.reducedMotionOn;
    _out = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: reducedInit ? 0 : _igniteHomeMs),
        value: _isOpen ? 1.0 : 0.0);
    _in = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: reducedInit ? 0 : _igniteFieldMs),
        value: _isOpen ? 1.0 : 0.0);
    _out.addListener(() => _outValue.value = _out.value);
    _in.addListener(() => _inValue.value = _in.value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now MediaQuery is available; if reduced motion was requested by
    // the OS, snap the controllers to their reduced durations so the
    // transition is instant from this point on.
    if (_reduced) {
      _out.duration = Duration.zero;
      _in.duration = Duration.zero;
    }
  }

  @override
  void didUpdateWidget(covariant HomeToCheckinShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the host (app_shell) flips initialOpen after we've already
    // animated into the requested state, no-op.
  }

  @override
  void dispose() {
    _out.dispose();
    _in.dispose();
    _outValue.dispose();
    _inValue.dispose();
    super.dispose();
  }

  // The home lens tap — ask the host to seed the check-in context
  // (earlier trace, revisit, subline, etc.); the host then calls
  // ignite() once the context is ready.
  void _lensCheckin() {
    if (_isOpen || _suppressFutureIgnites) return;
    widget.onCheckinIntent();
  }

  // Public — called by the host AFTER it has seeded the check-in
  // context. Only runs the in-animation; it never calls back into the
  // host, so the host can invoke it from onCheckinIntent without
  // recursing.
  void ignite() {
    if (_isOpen || _suppressFutureIgnites) return;
    setState(() {
      _isOpen = true;
      _fieldNonce++;
    });
    if (_reduced) {
      _out.value = 1;
      _in.value = 1;
      return;
    }
    _out.forward(from: _out.value);
    Future.delayed(
        const Duration(milliseconds: _igniteHomeDelayMs), () {
      if (mounted) _in.forward(from: _in.value);
    });
  }

  // Public — called by the host when the user taps "home" (chip in
  // the check-in chrome) or system back returns to home.
  void release() {
    if (!_isOpen || _suppressFutureIgnites) return;
    setState(() {
      _isOpen = false;
    });
    if (_reduced) {
      _out.value = 0;
      _in.value = 0;
      _suppressFutureIgnites = false;
      return;
    }
    // Field goes first (it sits on top), then the home cluster
    // returns. _releaseFieldMs < _releaseHomeMs so the field clears
    // the stage before the home is fully back.
    _in.duration =
        Duration(milliseconds: _reduced ? 0 : _releaseFieldMs);
    _in.reverse(from: _in.value).whenComplete(() {
      if (!mounted) return;
      Future.delayed(
          const Duration(milliseconds: _releaseHomeDelayMs), () {
        if (!mounted) return;
        _out.duration =
            Duration(milliseconds: _reduced ? 0 : _releaseHomeMs);
        _out.reverse(from: _out.value).whenComplete(() {
          if (mounted) _suppressFutureIgnites = false;
        });
      });
    });
  }

  // Public — used when the host navigates AWAY from this screen (e.g.
  // into the archive or the journal). The state machine should reset
  // so a future return starts cleanly.
  void reset() {
    _suppressFutureIgnites = true;
    _isOpen = false;
    _out.stop();
    _in.stop();
    _out.value = 0;
    _in.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Home layer: the home cluster + lens, faded by [_out].
        ListenableBuilder(
          listenable: _outValue,
          builder: (context, _) {
            final p = _outValue.value;
            if (p >= 1) return const SizedBox.shrink();
            return IgnorePointer(
              ignoring: p > 0.05,
              child: Opacity(
                opacity: (1 - p).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 18.0 * p),
                  child: HomeScreen(
                    store: widget.store,
                    onCheckin: _lensCheckin,
                    onSettings: widget.onSettings,
                    onWrite: widget.onWrite,
                    onDoor: widget.onDoor,
                    outProgress: _outValue.value,
                  ),
                ),
              ),
            );
          },
        ),
        // Check-in layer: the field UI, faded in by [_in].
        ListenableBuilder(
          listenable: _inValue,
          builder: (context, _) {
            final p = _inValue.value;
            if (p <= 0) return const SizedBox.shrink();
            return IgnorePointer(
              ignoring: p < 0.95,
              child: Opacity(
                opacity: p.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 16.0 * (1 - p)),
                  child: MoodSelectorScreen(
                    key: ValueKey('field-$_fieldNonce'),
                    onKept: widget.onKept,
                    onSayMore:
                        widget.checkinAfterCheck ? null : widget.onSayMore,
                    afterCheck: widget.checkinAfterCheck,
                    journaledSubline: widget.checkinJournaledSubline,
                    moodTrail: widget.moodTrail,
                    earlierTrace: widget.checkinEarlier,
                    revisitTarget: widget.checkinRevisit,
                    initialV: widget.checkinInitialV,
                    initialA: widget.checkinInitialA,
                    onSteer: widget.onSteer,
                  ),
                ),
              ),
            );
          },
        ),
        // The "home" back chip + reset / tools row, faded in with the
        // check-in field. Hosted at this layer so it sits at shell z
        // order above the field UI.
        ListenableBuilder(
          listenable: _inValue,
          builder: (context, _) {
            final p = _inValue.value;
            return IgnorePointer(
              ignoring: p < 0.95,
              child: Opacity(
                opacity: p.clamp(0.0, 1.0),
                child: CheckinOverlayChrome(
                  onHome: () {
                    widget.onRelease();
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
