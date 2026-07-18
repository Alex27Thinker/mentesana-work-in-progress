// Mentesana — mood selector (check-in) screen.
// Flutter port of the check-in surface from the Vite prototype
// (index.html markup + src/main.js logic + src/styles/main.css styling).
//
// Russell Affect Grid: horizontal = unpleasant ↔ pleasant;
// vertical = sleepiness ↔ high arousal.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mood_palette.dart';
import 'sea_icons.dart';
import 'sea_painter.dart';

/// One kept check-in record (the archive shape from the prototype).
class MoodEntry {
  const MoodEntry({
    required this.ts,
    required this.v,
    required this.a,
    required this.word,
    required this.edited,
  });

  final DateTime ts;
  final double v;
  final double a;
  final String word;
  final bool edited;
}

class _OwnWord {
  const _OwnWord(this.w, this.v, this.a);
  final String w;
  final double v;
  final double a;
}

class MoodSelectorScreen extends StatefulWidget {
  const MoodSelectorScreen({
    super.key,
    this.onKept,
    this.onSayMore,
    this.afterCheck = false,
    this.journaledSubline = false,
    this.moodTrail = const [],
    this.earlierTrace,
    this.revisitTarget,
    this.initialV,
    this.initialA,
  });

  /// Called when the mood is kept — the integration point for the archive.
  final ValueChanged<MoodEntry>? onKept;

  /// 'say more' after keeping — the door into the journal (JS sayMore).
  final VoidCallback? onSayMore;

  /// Post-journal weather check: softer captions, 'keep this change'.
  final bool afterCheck;

  /// The kept subline mentions the words when a page was written.
  final bool journaledSubline;

  /// Up to seven recent moods, oldest first, drawn as a fading path.
  final List<MoodEntry> moodTrail;

  /// A faint dot where today's earlier weather sat (JS placeEarlierTrace).
  final (double, double)? earlierTrace;

  /// Drift to a kept mood on arrival — 'this is where you were — visiting'.
  final (double, double)? revisitTarget;

  /// Start the field at a given mood (when reopening a kept day).
  final double? initialV;
  final double? initialA;

  @override
  State<MoodSelectorScreen> createState() => _MoodSelectorScreenState();
}

class _MoodSelectorScreenState extends State<MoodSelectorScreen>
    with TickerProviderStateMixin {
  // ---------- field geometry (JS FIELD) ----------
  static const _fieldTop = .19, _fieldBottom = .58, _fieldInset = 40.0;

  // ---------- state ----------
  double v = 0, a = 0; // target valence / arousal
  bool _locked = false;
  bool _kept = false;
  bool _edited = false; // user renamed the state
  String? _editedWord; // their word, if so
  bool _editing = false, _typing = false;
  bool _dragging = false, _uncertain = false, _settling = false;
  double _coreScale = 1; // selector-settle keyframe
  double _wordPop = 1; // brief pop when a mood is kept
  String? _currentWord;
  int _feltIndex = 0;
  bool _reduced = false;

  // Words the user has coined outrank the app's vocabulary near where they
  // coined them. In-memory for this standalone port (localStorage parity TODO).
  final List<_OwnWord> _ownWords = [];

  // bloom + ripples
  bool _bloomGo = false, _bloomFade = false;
  double _bloomTop = 0, _bloomScale = 1;
  Color _bloomTint = Colors.transparent;
  final List<int> _ripples = [];
  int _rippleId = 0;

  Timer? _hesitationTimer, _settleTimer, _keepTimer;
  AnimationController? _moveCtrl; // JS moveToMood
  String? _captionOverride;
  final GlobalKey _keepKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  final TextEditingController _wordInput = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  late final Ticker _ticker;
  final SeaFieldModel _model = SeaFieldModel();
  late final AnimationController _breathCtrl;

  final math.Random _rand = math.Random();
  late final List<double> _foamX = List.generate(
      60, (i) => (i + .5 + (_rand.nextDouble() - .5) * .8) / 60);
  late final List<int> _foamLayer = List.generate(60, (_) => _rand.nextInt(5));

  @override
  void initState() {
    super.initState();
    if (widget.initialV != null) v = widget.initialV!;
    if (widget.initialA != null) a = widget.initialA!;
    _model.visualV = v;
    _model.visualA = a;
    _breathCtrl = AnimationController(vsync: this, duration: kBreath);
    _ticker = createTicker(_onTick);
    _updateWord(silent: true);
    if (widget.revisitTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        moveToMood(widget.revisitTarget!.$1, widget.revisitTarget!.$2,
            duration: 1400,
            caption: 'this is where you were — visiting');
      });
    }
    _inputFocus.addListener(() {
      if (!_inputFocus.hasFocus && _typing) _submitOwnWord();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced != _reduced) {
      _reduced = reduced;
      _model.reduced = reduced;
    }
    // Reduced motion: no animation loop; a single settled frame is drawn.
    if (_reduced) {
      if (_ticker.isActive) _ticker.stop();
      _model
        ..visualV = v
        ..visualA = a
        ..bump();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _breathCtrl.dispose();
    _hesitationTimer?.cancel();
    _settleTimer?.cancel();
    _keepTimer?.cancel();
    _moveCtrl?.dispose();
    _wordInput.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    // The visual field follows the cursor with soft inertia, preserving a
    // continuous gradient. On the selector the sea follows the pointer live —
    // that immediate feedback is the point.
    const follow = .085;
    _model
      ..t = elapsed.inMicroseconds / 1e6
      ..visualV = _model.visualV + (v - _model.visualV) * follow
      ..visualA = _model.visualA + (a - _model.visualA) * follow
      ..bump();
  }

  // ---------- words (with hysteresis so it never flickers) ----------
  (String, double) _nearestWord() {
    String best = kWords.first.word;
    double bd = 1e9;
    for (final w in kWords) {
      final d = hypot(v - w.v, a - w.a);
      if (d < bd) {
        bd = d;
        best = w.word;
      }
    }
    return (best, bd);
  }

  double _distTo(String word) {
    for (final w in kWords) {
      if (w.word == word) return hypot(v - w.v, a - w.a);
    }
    return 1e9;
  }

  void _updateWord({bool silent = false}) {
    final (w, d) = _nearestWord();
    if (_currentWord != null && w != _currentWord) {
      if (d > _distTo(_currentWord!) - .08) return; // keep current unless clearly closer
    }
    if (_currentWord != w) {
      _currentWord = w;
      if (!silent) setState(() {});
    }
  }

  // ---------- editable word: neighbors first, then your own ----------
  void _rememberOwnWord(String w) {
    if (kWords.any((x) => x.word == w) || kShades.containsKey(w)) return;
    _ownWords.removeWhere((x) => x.w == w);
    _ownWords.add(_OwnWord(w, v, a));
    if (_ownWords.length > 8) _ownWords.removeAt(0);
  }

  List<String> _neighborWords([int n = 3]) {
    final shown = _editedWord ?? _currentWord;
    final base = kShades.containsKey(shown) ? shown! : _nearestWord().$1;
    final yours = _ownWords
        .where((o) => o.w != shown && hypot(v - o.v, a - o.a) < .55)
        .map((o) => o.w)
        .toList()
        .reversed
        .toList();
    final shades = (kShades[base] ?? const <String>[])
        .where((w) => w != shown && !yours.contains(w))
        .toList();
    return [...yours, ...shades].take(n).toList();
  }

  void _openEditor() {
    if (_locked) return;
    setState(() {
      _editing = true;
      _typing = false;
    });
  }

  void _closeEditor() {
    setState(() {
      _editing = false;
      _typing = false;
    });
  }

  void _commitWord(String w) {
    _edited = true;
    _editedWord = w;
    _rememberOwnWord(w);
    _closeEditor();
  }

  void _submitOwnWord() {
    final w = _wordInput.text.trim().toLowerCase();
    if (w.isNotEmpty) {
      _commitWord(w);
    } else {
      _closeEditor();
    }
  }

  void _clearEdit() {
    // moving the dot resumes suggestions; the user's word stands until then
    if (_edited) {
      _edited = false;
      _editedWord = null;
      _currentWord = null;
    }
    if (_editing || _typing) _closeEditor();
  }

  // ---------- layout ----------
  Rect _fieldRect(Size size) => Rect.fromLTRB(_fieldInset,
      size.height * _fieldTop, size.width - _fieldInset, size.height * _fieldBottom);

  Offset _dotCenter(Size size) {
    final f = _fieldRect(size);
    return Offset(
      f.left + (v + 1) / 2 * f.width,
      f.bottom - (a + 1) / 2 * f.height,
    );
  }

  Offset _traceCenter(Size size) {
    final f = _fieldRect(size);
    final t = widget.earlierTrace!;
    return Offset(
      f.left + (t.$1 + 1) / 2 * f.width,
      f.bottom - (t.$2 + 1) / 2 * f.height,
    );
  }

  void _setFromPoint(Offset p, Size size) {
    final f = _fieldRect(size);
    v = ((p.dx - f.left) / f.width * 2 - 1).clamp(-1.0, 1.0);
    a = ((f.bottom - p.dy) / f.height * 2 - 1).clamp(-1.0, 1.0);
    _captionOverride = null;
    _clearEdit();
    _feltIndex = 0;
    _updateWord(silent: true);
    if (_reduced) {
      _model
        ..visualV = v
        ..visualA = a
        ..bump();
    }
    setState(() {});
  }

  // ---------- interaction ----------
  void _settleSea() {
    setState(() {
      _dragging = false;
      _uncertain = false;
      _settling = true;
    });
    if (!_reduced) {
      // selector-settle: 1 → 1.22 → 1 over .8s
      setState(() => _coreScale = 1.22);
      Timer(const Duration(milliseconds: 270),
          () => mounted ? setState(() => _coreScale = 1) : null);
    }
    _settleTimer?.cancel();
    _settleTimer = Timer(Duration(milliseconds: _reduced ? 0 : 820), () {
      if (mounted) setState(() => _settling = false);
    });
  }

  void _onPointerDown(PointerDownEvent e, Size size) {
    if (_locked) return;
    if (e.localPosition.dy > size.height * _fieldBottom + 40) {
      return; // leave the footer alone
    }
    _dragging = true;
    _hesitationTimer?.cancel();
    _hesitationTimer = Timer(const Duration(milliseconds: 520), () {
      if (_dragging && mounted) setState(() => _uncertain = true);
    });
    _setFromPoint(e.localPosition, size);
  }

  void _onPointerMove(PointerMoveEvent e, Size size) {
    if (_dragging) _setFromPoint(e.localPosition, size);
  }

  void _onPointerUp(PointerUpEvent e) {
    if (!_dragging) return;
    _hesitationTimer?.cancel();
    _settleSea();
  }

  KeyEventResult _onDotKey(FocusNode node, KeyEvent event) {
    if (_locked || event is KeyUpEvent) return KeyEventResult.ignored;
    const step = .08;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        v = (v - step).clamp(-1.0, 1.0);
      case LogicalKeyboardKey.arrowRight:
        v = (v + step).clamp(-1.0, 1.0);
      case LogicalKeyboardKey.arrowUp:
        a = (a + step).clamp(-1.0, 1.0);
      case LogicalKeyboardKey.arrowDown:
        a = (a - step).clamp(-1.0, 1.0);
      default:
        return KeyEventResult.ignored;
    }
    _clearEdit();
    _feltIndex = 0;
    _updateWord(silent: true);
    _settleSea();
    if (_reduced) {
      _model
        ..visualV = v
        ..visualA = a
        ..bump();
    }
    setState(() {});
    return KeyEventResult.handled;
  }

  // ---------- keep: the bloom that locks it in ----------
  void _keep() {
    if (_locked) return;
    _locked = true;
    _closeEditor();
    // The sea takes on this mood now — the moment it is saved, not while it
    // was being dragged. (In this standalone port the selector is always the
    // active surface, so the live field already matches.)
    final keptWord = _edited ? _editedWord! : (_currentWord ?? 'steady');

    final stackBox =
        _stackKey.currentContext!.findRenderObject()! as RenderBox;
    final size = stackBox.size;

    // bloom veil rises from the button, tinted with the current horizon light
    final skyNow = kSky.bilerp(v, a);
    final keepBox =
        _keepKey.currentContext!.findRenderObject()! as RenderBox;
    final keepPos =
        keepBox.localToGlobal(Offset.zero, ancestor: stackBox);
    _bloomTop = keepPos.dy + keepBox.size.height / 2 - 39;
    _bloomTint = skyNow[1].withOpacity(.55);
    _bloomScale =
        (2 * hypot(size.width / 2, size.height) / 78).ceilToDouble() + 1;

    setState(() => _bloomGo = true);

    // two slow ripples from the dot — the heartbeat, visualized
    if (!_reduced) {
      for (final delay in const [0, 850]) {
        Timer(Duration(milliseconds: delay), () {
          if (!mounted) return;
          setState(() => _ripples.add(_rippleId++));
        });
      }
    }

    _keepTimer = Timer(Duration(milliseconds: _reduced ? 300 : 1450), () {
      if (!mounted) return;
      setState(() {
        _kept = true;
        _bloomFade = true;
      });
      _breathCtrl.repeat(reverse: true);
      widget.onKept?.call(MoodEntry(
        ts: DateTime.now(),
        v: v,
        a: a,
        word: keptWord,
        edited: _edited,
      ));
      if (!_reduced) {
        setState(() => _wordPop = 1.14);
        Timer(const Duration(milliseconds: 260), () {
          if (mounted) setState(() => _wordPop = 1);
        });
      }
    });
  }

  /// JS moveToMood — drift the dot to a kept mood; ease 1-(1-p)^3.
  void moveToMood(double nextV, double nextA,
      {int duration = 1250, String? caption}) {
    _moveCtrl?.dispose();
    _moveCtrl = null;
    setState(() => _captionOverride = caption);
    if (_reduced) {
      v = nextV;
      a = nextA;
      _updateWord(silent: true);
      _model
        ..visualV = v
        ..visualA = a
        ..bump();
      setState(() {});
      _settleSea();
      return;
    }
    final fromV = v, fromA = a;
    final ctrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: duration));
    _moveCtrl = ctrl;
    ctrl.addListener(() {
      final p = Curves.easeOutCubic.transform(ctrl.value);
      v = fromV + (nextV - fromV) * p;
      a = fromA + (nextA - fromA) * p;
      _updateWord(silent: true);
      setState(() {});
    });
    ctrl.forward().whenComplete(() {
      if (mounted && _moveCtrl == ctrl) _settleSea();
    });
  }

  void _reset() {
    _hesitationTimer?.cancel();
    _settleTimer?.cancel();
    _keepTimer?.cancel();
    _breathCtrl.stop();
    _breathCtrl.reset();
    setState(() {
      v = 0;
      a = 0;
      _locked = false;
      _kept = false;
      _edited = false;
      _editedWord = null;
      _editing = _typing = false;
      _dragging = _uncertain = _settling = false;
      _currentWord = null;
      _feltIndex = 0;
      _bloomGo = _bloomFade = false;
      _ripples.clear();
      _wordPop = 1;
    });
    _updateWord(silent: true);
  }

  // ---------- text styles ----------
  TextStyle get _serifItalic =>
      GoogleFonts.alice(fontStyle: FontStyle.italic, color: kIvory);
  TextStyle get _serif => GoogleFonts.alice(color: kIvory);

  String get _caption {
    if (_kept) {
      return widget.afterCheck ? 'the page has landed' : 'kept — this felt';
    }
    if (_editing || _typing) return 'call it what it is';
    if (_settling && !_locked && _captionOverride == null) {
      return 'letting the sea settle';
    }
    if (_captionOverride != null) return _captionOverride!;
    return widget.afterCheck ? 'after writing, this feels' : 'this feels';
  }

  String get _shownWord => _editedWord ?? _currentWord ?? 'steady';

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final dotC = _dotCenter(size);
      final fieldMidY =
          (size.height * _fieldTop + size.height * _fieldBottom) / 2;
      final safeBottom = MediaQuery.paddingOf(context).bottom;
      final felt = feltOptions(v, a);

      return Listener(
        onPointerDown: (e) => _onPointerDown(e, size),
        onPointerMove: (e) => _onPointerMove(e, size),
        onPointerUp: _onPointerUp,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          key: _stackKey,
          clipBehavior: Clip.hardEdge,
          children: [
            // the inner water field
            Positioned.fill(
              child: CustomPaint(
                painter: SeaPainter(
                  model: _model,
                  foamX: _foamX,
                  foamLayer: _foamLayer,
                ),
              ),
            ),

            // header
            Positioned(
              top: 58,
              left: 34,
              right: 34,
              child: IgnorePointer(
                child: Text(
                  'How\u2019s the weather in your mind?',
                  textAlign: TextAlign.center,
                  style: _serifItalic.copyWith(
                    fontSize: 17,
                    color: kIvory.withOpacity(.92),
                  ),
                ),
              ),
            ),

            // reset — icon-only now, quieter than a persistent text button.
            Positioned(
              top: 26,
              right: 14,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _reset,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: StrokeIcon(
                    SeaIcons.replay,
                    size: 15,
                    color: ivory(.32),
                    strokeWidth: 1.3,
                  ),
                ),
              ),
            ),

            // axis phrases
            _axis(top: size.height * .15, centerX: true, size: size, text: 'wide awake'),
            _axis(
              top: math.min(size.height * .58, size.height - 296),
              centerX: true,
              size: size,
              text: 'running low',
            ),
            _axis(top: fieldMidY, left: 16, size: size, text: 'hard to be in'),
            _axis(top: fieldMidY, right: 16, size: size, text: 'easy to be in'),

            // the dot
            Positioned(
              left: dotC.dx - 28,
              top: dotC.dy - 28,
              child: Focus(
                onKeyEvent: _onDotKey,
                child: Semantics(
                  label: 'Mood position',
                  value: _shownWord,
                  slider: true,
                  child: IgnorePointer(
                    ignoring: _locked,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          ivory(.16),
                          ivory(.05),
                          ivory(0),
                        ], stops: const [0, .55, .7]),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // dragging / uncertain ring
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 350),
                            opacity: _uncertain ? .3 : (_dragging ? .42 : 0),
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 700),
                              scale: _uncertain ? 1.36 : (_dragging ? 1 : .7),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: ivory(.3)),
                                ),
                              ),
                            ),
                          ),
                          // core
                          AnimatedScale(
                            duration: const Duration(milliseconds: 270),
                            curve: kExhale,
                            scale: _locked ? .86 : _coreScale,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kIvory,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF060B12)
                                        .withOpacity(.4),
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // earlier today — a faint trace of the day's first weather
            if (widget.earlierTrace != null && !_kept)
              Positioned(
                left: _traceCenter(size).dx - 5,
                top: _traceCenter(size).dy - 5,
                child: IgnorePointer(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ivory(.4)),
                      color: ivory(.12),
                    ),
                  ),
                ),
              ),

            // ripples (from the dot, on keep)
            for (final id in _ripples)
              Positioned(
                left: dotC.dx - 65,
                top: dotC.dy - 65,
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('ripple-$id'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 2600),
                    curve: kExhale,
                    onEnd: () => setState(() => _ripples.remove(id)),
                    builder: (context, p, _) => Opacity(
                      opacity: (.7 * (1 - p)).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: .2 + 2.4 * p,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: ivory(.5)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // bloom veil
            if (_bloomGo)
              Positioned(
                top: _bloomTop,
                left: size.width / 2 - 39,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: _bloomFade ? 1300 : 500),
                    opacity: _bloomFade ? 0 : .97,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 1700),
                      curve: kExhale,
                      scale: _bloomScale,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _bloomTint,
                            const Color(0xFF10141E).withOpacity(.66),
                          ], stops: const [0, .68]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // footer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(34, 0, 34, 30 + safeBottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // caption
                    Text(
                      _caption,
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 3.6,
                        color: ivory(.7),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // the word / editor / own-word input
                    if (_typing)
                      SizedBox(
                        width: 230,
                        child: TextField(
                          controller: _wordInput,
                          focusNode: _inputFocus,
                          autofocus: true,
                          maxLength: 24,
                          textAlign: TextAlign.center,
                          style: _serif.copyWith(fontSize: 28),
                          cursorColor: kIvory,
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'your word',
                            hintStyle:
                                _serif.copyWith(fontSize: 28, color: ivory(.45)),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: ivory(.45)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: ivory(.45)),
                            ),
                          ),
                          onSubmitted: (_) => _submitOwnWord(),
                        ),
                      )
                    else if (_editing)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final w in _neighborWords())
                              _chip(w, onTap: () => _commitWord(w)),
                            _ownChip(),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _locked ? null : _openEditor,
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: _reduced ? 0 : 500),
                          child: Container(
                            key: ValueKey(_shownWord),
                            padding: const EdgeInsets.only(bottom: 1),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _locked
                                      ? Colors.transparent
                                      : ivory(.28),
                                ),
                              ),
                            ),
                            child: AnimatedScale(
                              scale: _wordPop,
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                              child: Text(
                                _shownWord,
                                style: _serif.copyWith(
                                  fontSize: 37,
                                  height: 1.25,
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFF060B12)
                                          .withOpacity(.35),
                                      offset: const Offset(0, 1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // felt phrase — tap cycles nearby interpretations
                    if (!_editing && !_typing)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: GestureDetector(
                          onTap: _locked
                              ? null
                              : () => setState(() => _feltIndex++),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 255),
                            child: Text(
                              '${felt[_feltIndex % felt.length]} \u00b7',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.45,
                                letterSpacing: .33,
                                color: ivory(.7),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // subline
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 900),
                      opacity: _kept ? 1 : 0,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          widget.journaledSubline
                              ? 'Added to your archive, with your words.'
                              : 'Added to your archive.',
                          style: TextStyle(
                            fontSize: 12.5,
                            letterSpacing: .25,
                            color: ivory(.7),
                          ),
                        ),
                      ),
                    ),

                    // say more — the door into the journal
                    if (_kept && widget.onSayMore != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: GestureDetector(
                          onTap: widget.onSayMore,
                          child: Text(
                            'say more',
                            style: _serifItalic.copyWith(
                              fontSize: 13.5,
                              color: ivory(.75),
                              decoration: TextDecoration.underline,
                              decorationColor: ivory(.4),
                            ),
                          ),
                        ),
                      ),

                    // keep
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _keepButton(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _axis({
    required double top,
    required Size size,
    required String text,
    double? left,
    double? right,
    bool centerX = false,
  }) {
    final label = IgnorePointer(
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 3.5,
          color: ivory(.34),
        ),
      ),
    );
    if (centerX) {
      return Positioned(
        top: top - 7,
        left: 0,
        right: 0,
        child: Center(child: label),
      );
    }
    return Positioned(top: top - 7, left: left, right: right, child: label);
  }

  Widget _chip(String w, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 8, 3, 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: ivory(.28))),
        ),
        child: Text(
          w,
          style: _serifItalic.copyWith(fontSize: 16.5, color: ivory(.7)),
        ),
      ),
    );
  }

  Widget _ownChip() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _typing = true;
          _wordInput.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 8, 3, 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ivory(.28), style: BorderStyle.solid),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+ ',
              style: TextStyle(
                fontSize: 10.5,
                color: ivory(.45),
              ),
            ),
            Text(
              'your own word',
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.47,
                color: ivory(.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _keepButton() {
    return Semantics(
      button: true,
      label: _kept ? 'Mood kept' : 'Keep this mood',
      child: GestureDetector(
        key: _keepKey,
        onTap: _keep,
        child: AnimatedBuilder(
          animation: _breathCtrl,
          builder: (context, child) {
            // breathe: Oro glow swells mid-exhale, on the shared rhythm
            final glow = _kept
                ? Curves.easeInOut.transform(_breathCtrl.value) * .16
                : 0.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              width: 74,
              height: 74,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kept
                    ? kOro.withOpacity(.16)
                    : const Color(0xFF2D3D43).withOpacity(.55),
                border: Border.all(
                  color: _kept
                      ? kOro.withOpacity(.75)
                      : const Color(0xFFD2DEE2).withOpacity(.4),
                ),
                boxShadow: [
                  if (glow > 0)
                    BoxShadow(
                      color: kOro.withOpacity(glow),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Text(
                _kept
                    ? 'kept'
                    : widget.afterCheck
                        ? 'keep this change'
                        : 'keep',
                textAlign: TextAlign.center,
                style: _serifItalic.copyWith(
                    fontSize: widget.afterCheck && !_kept ? 12 : 15.5),
              ),
            );
          },
        ),
      ),
    );
  }
}

