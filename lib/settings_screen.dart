// Mentesana — Settings.
// 1:1 Flutter port of the prototype's settings screen: the icon-led menu,
// nine detail sections (rows, toggles, segments, time fields, selects),
// the quiet toast, and the About sub-content — all copy verbatim.
//
// Documented deviations (see README): exports copy to the clipboard instead
// of downloading files; import-from-file and PDF export are not yet ported;
// the web prototype's native <input type=time>/<select> become an inline
// text field and a tap-to-cycle value (no native dialogs, per the doctrine).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_store.dart';
import 'currents_engine.dart';
import 'currents_surfaces.dart';
import 'currents_test_seeder.dart';
import 'mood_palette.dart';
import 'sea_icons.dart';
import 'theme.dart';

const _riva = kRiva;
const _latte = Color(0xFFFCFAF5);
const _carta = Color(0xFFF7F4EE);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.store,
    required this.onBackHome,
    required this.onReplayOnboarding,
  });

  final AppStore store;
  final VoidCallback onBackHome;
  final VoidCallback onReplayOnboarding;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _section;
  String? _aboutOpen;
  bool _resetArmed = false;
  Timer? _resetTimer;
  String? _toast;
  Timer? _toastTimer;

  late final TextEditingController _nameCtl =
      TextEditingController(text: widget.store.profileName);
  late final TextEditingController _pinCtl = TextEditingController();
  late final TextEditingController _remTimeCtl =
      TextEditingController(text: widget.store.reminderAt);
  late final TextEditingController _qStartCtl =
      TextEditingController(text: widget.store.quietHoursStart);
  late final TextEditingController _qEndCtl =
      TextEditingController(text: widget.store.quietHoursEnd);

  AppStore get store => widget.store;
  bool get _day => store.effectiveRoom == 'day';

  // Ink in the day room, ivory in the night room.
  Color _tx(double o) => _day ? Color.fromRGBO(27, 42, 56, o) : ivory(o);

  // Text colours that snap to the four opacity tokens, respecting day/night.
  Color get _tPrimary => _day ? const Color(0xFF1B2A38) : textPrimary;
  Color get _tSecondary =>
      _day ? const Color.fromRGBO(27, 42, 56, .65) : textSecondary;
  Color get _tFaint => _day ? const Color.fromRGBO(27, 42, 56, .42) : textFaint;

  TextStyle get _serif => GoogleFonts.alice(color: _tPrimary, fontSize: 15);

  @override
  void dispose() {
    _resetTimer?.cancel();
    _toastTimer?.cancel();
    _nameCtl.dispose();
    _pinCtl.dispose();
    _remTimeCtl.dispose();
    _qStartCtl.dispose();
    _qEndCtl.dispose();
    super.dispose();
  }

  /// The settings toast: italic serif, 2600ms, like the prototype.
  void _showToast(String msg) {
    _toastTimer?.cancel();
    setState(() => _toast = msg);
    _toastTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  /// A small dark-themed text prompt used for backup/restore, since this
  /// build copies through the clipboard rather than opening a file picker.
  Future<String?> _askText(
      {required String title, required String hint, bool obscure = false}) {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .45),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1C2A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title,
                  style: GoogleFonts.alice(
                      fontStyle: FontStyle.italic,
                      fontSize: 15,
                      color: const Color(0xFFF3ECE0))),
              const SizedBox(height: s12),
              TextField(
                controller: ctl,
                autofocus: true,
                obscureText: obscure,
                minLines: 1,
                maxLines: obscure ? 1 : 4,
                style: const TextStyle(color: Color(0xFFF3ECE0), fontSize: 13),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                      color: const Color(0xFFF3ECE0).withValues(alpha: .28),
                      fontSize: 13),
                  enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0x55F3ECE0))),
                  focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: _riva)),
                ),
              ),
              const SizedBox(height: s16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('cancel',
                        style: TextStyle(
                            color: const Color(0xFFF3ECE0)
                                .withValues(alpha: .65))),
                  ),
                  const SizedBox(width: s8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, ctl.text),
                    child: const Text('done', style: TextStyle(color: _riva)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _day
          ? const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_latte, _carta],
              ),
            )
          : const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2D3D43), Color(0xFF232E36)],
              ),
            ),
      child: Stack(
        children: [
          // The warm Oro breath in the upper right corner (night room).
          if (!_day)
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(.64, -1.08),
                      radius: 1.1,
                      colors: [
                        Color.fromRGBO(232, 179, 106, .05),
                        Color.fromRGBO(232, 179, 106, 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _head(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                            s24, s4, s24, kBottomNavPad),
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(_section ?? 'menu'),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 500),
                          curve: kExhale,
                          builder: (context, t, child) {
                            return Opacity(
                              opacity: t,
                              child: Transform.translate(
                                offset: Offset(0, 12 * (1 - t)),
                                child: child,
                              ),
                            );
                          },
                          child:
                              _section == null ? _menu() : _detail(_section!),
                        ),
                      ),
                    ),
                  ],
                ),
                // backlink
                Positioned(top: 14, left: 14, child: _backlink()),
                // toast
                if (_toast != null)
                  Positioned(
                    left: 26,
                    right: 26,
                    bottom: 18 + kBottomNavPad,
                    child: IgnorePointer(
                      child: Center(
                        child: Text(_toast!,
                            textAlign: TextAlign.center,
                            style: _serif.copyWith(
                                fontStyle: FontStyle.italic,
                                color: _tSecondary)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const kBottomNavPad = 92.0;

  Widget _head() {
    final title =
        _section == null ? store.t('settings') : _sectionTitle(_section!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(s24, s24, s24, s12),
      child: Center(
        child: Text(title, style: _serif.copyWith(color: _tSecondary)),
      ),
    );
  }

  Widget _backlink() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_section != null) {
          setState(() {
            _section = null;
            _aboutOpen = null;
          });
        } else {
          widget.onBackHome();
        }
      },
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _tx(.22)),
        ),
        child: StrokeIcon(SeaIcons.back,
            size: 15, color: _tSecondary, strokeWidth: 1.65),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Menu — the icon-led cards, in the prototype's order and grouping.
  // ---------------------------------------------------------------------

  String _sectionTitle(String s) => switch (s) {
        'notifications' => store.t('notifications'),
        'appearance' => store.t('appearance'),
        'privacy' => store.t('privacy'),
        'data' => store.t('yourPages'),
        'account' => store.t('thisDevice'),
        'journal' => store.t('journalPreferences'),
        'ai' => 'deeper reflection',
        'about' => store.t('about'),
        _ => s,
      };

  Widget _menu() {
    Widget card(String section, SeaIconData icon, String title, String sub,
        {VoidCallback? onTap}) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? () => setState(() => _section = section),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: kExhale,
          margin: const EdgeInsets.only(bottom: s8),
          padding: const EdgeInsets.all(s16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: _tx(.12)),
            color: _tx(.03),
          ),
          child: Row(
            children: [
              StrokeIcon(icon, color: _riva),
              const SizedBox(width: s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _serif.copyWith(color: _tPrimary)),
                    const SizedBox(height: s4),
                    Text(sub,
                        style: MenteType.eyebrow
                            .copyWith(letterSpacing: .45, color: _tFaint)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget groupStart() => Padding(
          padding: const EdgeInsets.only(top: s8, bottom: s16),
          child: WaveDivider(color: _tx(.18), alpha: 1),
        );

    return Column(
      children: [
        card('notifications', SeaIcons.notifications, store.t('notifications'),
            store.t('yourQuietReminder')),
        card('appearance', SeaIcons.appearance, store.t('appearance'),
            store.t('readingRooms')),
        card('privacy', SeaIcons.privacy, store.t('privacy'),
            store.t('yourPagesProtected')),
        card('data', SeaIcons.data, store.t('yourPages'),
            store.t('exportAndArchive')),
        card('account', SeaIcons.device, store.t('thisDevice'),
            store.t('whereEntriesLive')),
        groupStart(),
        card('replay', SeaIcons.replay, store.t('revisitBeginning'),
            'test the onboarding without changing your pages',
            onTap: widget.onReplayOnboarding),
        card('journal', SeaIcons.journal, store.t('journalPreferences'),
            store.t('howPagesBegin')),
        card('ai', SeaIcons.ai, 'deeper reflection',
            'AI-enhanced insights, opt in'),
        groupStart(),
        card('about', SeaIcons.about, store.t('about'),
            store.t('howMentesanaWorks')),
        if (kDebugMode)
          card('debug', SeaIcons.device, 'currents test data',
              'seed, clear, and test undertow fixtures'),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Detail sections — markup ported row for row.
  // ---------------------------------------------------------------------

  Widget _detail(String section) {
    switch (section) {
      case 'notifications':
        return _sectionColumn('notifications', [
          _row('daily reminder',
              sub: 'a quiet nudge, once a day',
              trailing: _toggle(store.reminderOn,
                  () => store.setReminder(!store.reminderOn))),
          _row('time',
              trailing: _timeField(_remTimeCtl, (v) {
                store.setReminderTime(v);
              })),
          _row('weekly reflection',
              sub: 'a gentle nudge each Sunday',
              trailing: _toggle(store.weeklyReminderOn, () {
                store.setWeeklyReminder(!store.weeklyReminderOn);
                _showToast(store.weeklyReminderOn
                    ? 'weekly reflection on.'
                    : 'weekly reflection off.');
              })),
          _row('day',
              trailing: _select(
                const [
                  'Sunday',
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday'
                ],
                store.weeklyReminderDay,
                (i) => store.setWeeklyReminderDay(i),
              )),
          _row('quiet hours',
              sub: 'no reminders during these times',
              trailing: _toggle(store.quietHoursOn, () {
                store.setQuietHours(!store.quietHoursOn);
                _showToast(store.quietHoursOn
                    ? 'quiet hours on.'
                    : 'quiet hours off.');
              })),
          if (store.quietHoursOn) ...[
            _row('from',
                trailing: _timeField(_qStartCtl, store.setQuietHoursStart)),
            _row('until',
                trailing: _timeField(_qEndCtl, store.setQuietHoursEnd)),
          ],
          _note(
              'reminders now arrive as notifications from your device, even when Mentesana is closed.'),
        ]);

      case 'appearance':
        return _sectionColumn('appearance', [
          _row('reading rooms',
              sub: 'archive & letters, lit for day or night',
              trailing: _segment(
                const [('night', 'night'), ('day', 'day')],
                store.room,
                store.setRoom,
              )),
          _row('auto day / night',
              sub: 'follow the time of day automatically',
              trailing: _toggle(store.autoRoomOn, () {
                store.setAutoRoom(!store.autoRoomOn);
                _showToast(store.autoRoomOn
                    ? 'rooms will follow the time of day.'
                    : 'manual room selection.');
              })),
          _row('let the pages follow the weather',
              sub: 'a quiet tint from your latest check-in',
              trailing: _toggle(store.moodAtmosphereOn, () {
                store.setMoodAtmosphere(!store.moodAtmosphereOn);
                _showToast(store.moodAtmosphereOn
                    ? 'pages will follow the weather.'
                    : 'pages are resting in neutral light.');
              })),
          _row('text size',
              sub: 'reading comfort',
              trailing: _segment(
                const [
                  ('small', 'small'),
                  ('regular', 'regular'),
                  ('large', 'large')
                ],
                store.textSize,
                store.setTextSize,
              )),
          _row('reduced motion',
              sub: 'calmer transitions, less animation',
              trailing: _toggle(store.reducedMotionOn, () {
                store.setReducedMotion(!store.reducedMotionOn);
                _showToast(store.reducedMotionOn
                    ? 'motion calmed.'
                    : 'full motion restored.');
              })),
          _note(
              'the sea keeps its own light, always — this only changes the rooms you read in.'),
        ]);

      case 'account':
        return _sectionColumn('account', [
          _row('your name',
              sub: 'used in greetings',
              trailing: _textInput(_nameCtl, 'your name', 24, (v) {
                store.setProfileName(v);
              })),
          _row('language',
              sub: 'interface language',
              trailing: _segment(
                const [('en', 'English'), ('it', 'Italiano')],
                store.language,
                (v) {
                  store.setLanguage(v);
                  _showToast(v == 'it'
                      ? 'lingua impostata su Italiano.'
                      : 'language set to English.');
                },
              )),
          _row('this device', sub: 'entries are kept here only, for now'),
          _row('sync across devices', sub: 'coming later', muted: true),
        ]);

      case 'privacy':
        return _sectionColumn('privacy', [
          _row('lock this journal',
              sub: 'ask for a pin when opening',
              trailing: _toggle(store.pinLockOn, () {
                final turningOn = !store.pinLockOn;
                store.setPinLock(turningOn);
                if (turningOn) {
                  _showToast(store.pinCode.length == 4
                      ? 'journal locked.'
                      : 'set a 4-digit pin to finish.');
                } else {
                  _showToast('journal unlocked.');
                }
              })),
          _row('pin', trailing: _pinInput()),
          if (store.pinLockOn)
            _row('auto-lock',
                sub: 'lock after a period of inactivity',
                trailing: _select(
                  const [
                    'never',
                    '30 seconds',
                    '1 minute',
                    '2 minutes',
                    '5 minutes'
                  ],
                  const [0, 30, 60, 120, 300]
                      .indexWhere((value) => value == store.autoLockSeconds),
                  (i) => store.setAutoLock(const [0, 30, 60, 120, 300][i]),
                )),
          _row('biometric unlock', sub: 'coming later', muted: true),
          _privacyNote(
              'Mentesana keeps your pages on this device only. No account, no cloud sync, no analytics, no tracking. Your entries never leave this phone.'),
        ]);

      case 'data':
        final n = store.entries.length;
        final bytes = store.storageBytes();
        final pct = (bytes / (5 * 1024 * 1024) * 100).clamp(0, 100).toDouble();
        return _sectionColumn('data', [
          _row('kept so far',
              sub: n == 0
                  ? '0 pages — sample archive shown'
                  : '$n page${n == 1 ? '' : 's'}'),
          _row('storage used',
              sub:
                  '${(bytes / 1024).toStringAsFixed(1)} KB · ${pct.toStringAsFixed(1)}% of ~5 MB'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: Stack(children: [
                  Container(color: _tx(.1)),
                  FractionallySizedBox(
                      widthFactor: pct / 100, child: Container(color: _riva)),
                ]),
              ),
            ),
          ),
          _link('export as text', () async {
            if (store.entries.isEmpty) return _showToast('nothing kept yet.');
            await Clipboard.setData(ClipboardData(text: store.exportText()));
            _showToast('exported.');
          }),
          _link('export as JSON', () async {
            if (store.entries.isEmpty) return _showToast('nothing kept yet.');
            await Clipboard.setData(ClipboardData(text: store.exportJson()));
            _showToast('exported JSON.');
          }),
          _link('restore from JSON', () async {
            final raw = await _askText(
                title: 'restore from JSON', hint: 'paste a JSON backup');
            if (raw == null || raw.trim().isEmpty) return;
            final n = store.importJson(raw);
            _showToast(n == null
                ? 'that backup could not be read.'
                : 'restored — $n page${n == 1 ? '' : 's'} now kept.');
          }),
          _link('encrypted backup', () async {
            if (store.entries.isEmpty) return _showToast('nothing kept yet.');
            final pass = await _askText(
                title: 'encrypted backup',
                hint: 'a passphrase to lock it',
                obscure: true);
            if (pass == null || pass.trim().isEmpty) return;
            await Clipboard.setData(
                ClipboardData(text: store.exportEncrypted(pass.trim())));
            _showToast('encrypted backup copied — keep the passphrase safe.');
          }),
          _link('restore encrypted backup', () async {
            final blob = await _askText(
                title: 'restore encrypted backup',
                hint: 'paste the encrypted backup');
            if (blob == null || blob.trim().isEmpty) return;
            final pass = await _askText(
                title: 'passphrase',
                hint: 'the passphrase you locked it with',
                obscure: true);
            if (pass == null || pass.trim().isEmpty) return;
            final n = store.importEncrypted(blob.trim(), pass.trim());
            _showToast(n == null
                ? 'wrong passphrase, or that backup could not be read.'
                : 'restored — $n page${n == 1 ? '' : 's'} now kept.');
          }),
          _link('export as PDF', () {
            _showToast('pdf export arrives with a later part of the port.');
          }),
          _link(_resetArmed ? 'sure? tap again' : 'reset all entries', () {
            if (store.entries.isEmpty) {
              return _showToast('nothing to reset yet.');
            }
            if (!_resetArmed) {
              setState(() => _resetArmed = true);
              _resetTimer?.cancel();
              _resetTimer = Timer(const Duration(milliseconds: 4000), () {
                if (mounted) setState(() => _resetArmed = false);
              });
              _showToast('sure? tap again');
              return;
            }
            _resetTimer?.cancel();
            setState(() => _resetArmed = false);
            store.resetEntries();
            _showToast('entries cleared.');
          }, danger: true),
        ]);

      case 'journal':
        return _sectionColumn('journal preferences', [
          _row('default prompt style',
              sub: 'how pages begin',
              trailing: _segment(
                const [
                  ('question', 'question'),
                  ('free', 'free'),
                  ('naming', 'naming')
                ],
                store.promptStyle,
                (v) {
                  store.setPromptStyle(v);
                  _showToast('default prompt style saved.');
                },
              )),
          _row('tide line default',
              sub: 'let a line return to you later',
              trailing: _toggle(store.tideLineDefault, () {
                store.setTideLineDefault(!store.tideLineDefault);
                _showToast(store.tideLineDefault
                    ? 'tide lines on by default.'
                    : 'tide lines off by default.');
              })),
          _row('currents beneath your pages',
              sub: 'a gentle observation after some pages',
              trailing: _toggle(store.currentsOn, () {
                store.setCurrentsOn(!store.currentsOn);
                _showToast(store.currentsOn
                    ? 'the water will speak up — gently, and rarely.'
                    : 'pages will rest exactly as they are.');
              })),
          _row('the almanac',
              sub: 'your own weather patterns, on home',
              trailing: _toggle(store.almanacOn, () {
                store.setAlmanacOn(!store.almanacOn);
                _showToast(store.almanacOn
                    ? 'the almanac is open.'
                    : 'the almanac is closed.');
              })),
          _row('attachment limit', sub: '${store.attachmentCap} per page'),
        ]);

      case 'ai':
        return _sectionColumn('deeper reflection', [
          _row('AI-enhanced insights & prompts',
              sub: 'opt in to richer, personalized reflections',
              trailing: _toggle(store.aiEnabled, () {
                store.setAiEnabled(!store.aiEnabled);
                _showToast(store.aiEnabled
                    ? 'deeper reflection on — the sea will listen more closely.'
                    : 'deeper reflection off — the local engine remains.');
              })),
          if (store.aiEnabled)
            _privacyNote(
                "When enabled, a summary of your recent journal entries and mood data is sent through Mentesana's own server to generate richer reflections — there's no key to enter and nothing else to set up. The local analysis engine always runs first and remains the default. You can turn this off at any time — your pages stay on this device regardless."),
        ]);

      case 'about':
        return _sectionColumn('about', [
          Padding(
            padding: const EdgeInsets.only(bottom: s8),
            child: Text(
                'mentesana keeps the weather, not the score. one honest word at a time, a place to write past it, and a letter each sunday that never counts.',
                style: MenteType.bodySerif
                    .copyWith(fontStyle: FontStyle.italic, color: _tSecondary)),
          ),
          _subLink('crisis & support resources', 'crisis'),
          if (_aboutOpen == 'crisis') _aboutContent(_crisisContent()),
          _subLink('evidence base & design principles', 'evidence'),
          if (_aboutOpen == 'evidence') _aboutContent(_evidenceContent()),
          _subLink('open source licenses', 'licenses'),
          if (_aboutOpen == 'licenses') _aboutContent(_licensesContent()),
          Padding(
            padding: const EdgeInsets.only(top: s16),
            child: Text('prototype v0.6.2 — saved-mood boot fix',
                style: MenteType.eyebrow
                    .copyWith(letterSpacing: 1.33, color: _tFaint)),
          ),
        ]);
      case 'debug':
        return _debugSection();
    }
    return const SizedBox.shrink();
  }

  // ---------------------------------------------------------------------
  // Row & control primitives (set-heading / set-row / set-toggle / …).
  // ---------------------------------------------------------------------

  Widget _sectionColumn(String heading, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: s4, bottom: s8),
          child: Text(heading,
              style: MenteType.eyebrow
                  .copyWith(letterSpacing: .8, color: _tFaint)),
        ),
        ...rows,
      ],
    );
  }

  Widget _row(String label,
      {String? sub, Widget? trailing, bool muted = false}) {
    return Opacity(
      opacity: muted ? .45 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: s12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _tx(.08))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _serif.copyWith(color: _tPrimary)),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: s4),
                      child: Text(sub,
                          style: MenteType.eyebrow
                              .copyWith(letterSpacing: .45, color: _tFaint)),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: s12), trailing],
          ],
        ),
      ),
    );
  }

  Widget _toggle(bool on, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: on ? const Color.fromRGBO(127, 168, 155, .32) : _tx(.06),
          border:
              Border.all(color: on ? _riva.withValues(alpha: .75) : _tx(.28)),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _day ? const Color(0xFF1B2A38) : ivory(.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _segment(List<(String, String)> options, String current,
      ValueChanged<String> onPick) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (value, label) in options)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onPick(value),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: current == value ? _riva : Colors.transparent,
                  ),
                ),
              ),
              child: Text(label,
                  style: _serif.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      color: current == value ? _tx(1) : _tx(.45))),
            ),
          ),
      ],
    );
  }

  /// The web `<select>` becomes a quiet tap-to-cycle value (no native menus).
  Widget _select(
      List<String> options, int currentIndex, ValueChanged<int> onPick) {
    final i = currentIndex.clamp(0, options.length - 1);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onPick((i + 1) % options.length),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _tx(.28))),
        ),
        child: Text(options[i],
            style: _serif.copyWith(
                fontStyle: FontStyle.italic, fontSize: 14, color: _tx(.9))),
      ),
    );
  }

  /// The web `<input type=time>` becomes an inline HH:MM field.
  Widget _timeField(TextEditingController ctl, ValueChanged<String> onSave) {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: ctl,
        keyboardType: TextInputType.datetime,
        textAlign: TextAlign.center,
        maxLength: 5,
        style: _serif.copyWith(fontSize: 14, color: _tx(.9)),
        decoration: InputDecoration(
          isDense: true,
          counterText: '',
          hintText: 'hh:mm',
          hintStyle: TextStyle(color: _tx(.35), fontSize: 12),
          enabledBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: _tx(.28))),
          focusedBorder:
              const UnderlineInputBorder(borderSide: BorderSide(color: _riva)),
        ),
        onSubmitted: (v) => _saveTime(ctl, v, onSave),
        onTapOutside: (_) {
          _saveTime(ctl, ctl.text, onSave);
          FocusManager.instance.primaryFocus?.unfocus();
        },
      ),
    );
  }

  void _saveTime(
      TextEditingController ctl, String v, ValueChanged<String> onSave) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(v.trim());
    if (m == null) return;
    final h = int.parse(m.group(1)!), min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) return;
    final norm =
        '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
    ctl.text = norm;
    onSave(norm);
  }

  Widget _textInput(TextEditingController ctl, String placeholder,
      int maxLength, ValueChanged<String> onSave) {
    return SizedBox(
      width: 130,
      child: TextField(
        controller: ctl,
        maxLength: maxLength,
        textAlign: TextAlign.right,
        style: _serif.copyWith(fontSize: 14, color: _tx(.9)),
        decoration: InputDecoration(
          isDense: true,
          counterText: '',
          hintText: placeholder,
          hintStyle: TextStyle(color: _tx(.35), fontSize: 12),
          enabledBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: _tx(.28))),
          focusedBorder:
              const UnderlineInputBorder(borderSide: BorderSide(color: _riva)),
        ),
        onSubmitted: onSave,
        onTapOutside: (_) {
          onSave(ctl.text);
          FocusManager.instance.primaryFocus?.unfocus();
        },
      ),
    );
  }

  Widget _pinInput() {
    return SizedBox(
      width: 76,
      child: TextField(
        controller: _pinCtl,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 4,
        textAlign: TextAlign.center,
        style: _serif.copyWith(fontSize: 14, color: _tx(.9)),
        decoration: InputDecoration(
          isDense: true,
          counterText: '',
          hintText: '4 digits',
          hintStyle: TextStyle(color: _tx(.35), fontSize: 12),
          enabledBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: _tx(.28))),
          focusedBorder:
              const UnderlineInputBorder(borderSide: BorderSide(color: _riva)),
        ),
        onChanged: (v) {
          if (v.length == 4) {
            store.setPin(v);
            _showToast('pin set.');
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
      ),
    );
  }

  Widget _link(String label, VoidCallback onTap, {bool danger = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: s8),
        child: Text(label,
            style: MenteType.eyebrow.copyWith(
                letterSpacing: 1.43,
                color: danger ? const Color(0xFFCF8B7B) : _tSecondary)),
      ),
    );
  }

  Widget _subLink(String label, String section) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          setState(() => _aboutOpen = _aboutOpen == section ? null : section),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: s12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _tx(.08))),
        ),
        child: Row(children: [
          Expanded(
              child: Text(label, style: _serif.copyWith(color: _tPrimary))),
          Text(_aboutOpen == section ? '−' : '+',
              style: MenteType.caption.copyWith(color: _tFaint)),
        ]),
      ),
    );
  }

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.only(top: s12),
        child: Text(text,
            style: MenteType.bodySerif
                .copyWith(fontStyle: FontStyle.italic, color: _tSecondary)),
      );

  Widget _privacyNote(String text) => Padding(
        padding: const EdgeInsets.only(top: s12),
        child: Text(text,
            style: MenteType.bodySerif.copyWith(
                fontStyle: FontStyle.italic, height: 1.6, color: _tSecondary)),
      );

  // ---------------------------------------------------------------------
  // About sub-content — ported verbatim from main.js toggleAboutContent().
  // ---------------------------------------------------------------------

  Widget _aboutContent(List<InlineSpan> spans) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: s12),
      child: Text.rich(
        TextSpan(children: spans),
        style: MenteType.bodySerif.copyWith(
            fontStyle: FontStyle.italic, height: 1.6, color: _tSecondary),
      ),
    );
  }

  TextSpan _strong(String text) => TextSpan(
      text: text,
      style: TextStyle(fontStyle: FontStyle.normal, color: _tPrimary));

  TextSpan _small(String text) => TextSpan(
      text: text,
      style: MenteType.eyebrow.copyWith(
          fontStyle: FontStyle.normal, letterSpacing: 0, color: _tFaint));

  List<InlineSpan> _crisisContent() => [
        const TextSpan(
            text:
                'If you are in crisis or need urgent support, please contact your local emergency services or a crisis line.\n\n'),
        _strong('Ireland:'),
        const TextSpan(
            text: ' Pieta House 1800 247 247 · Samaritans 116 123\n'),
        _strong('UK:'),
        const TextSpan(text: ' Samaritans 116 123 · Shout 85258\n'),
        _strong('Italy:'),
        const TextSpan(
            text: ' Telefono Amico 02 2327 2327 · 114 (emergenze)\n\n'),
        const TextSpan(
            text:
                'You are not alone. These lines are free, confidential, and available 24/7.\n\n'),
        _small(
            'Mentesana is not a crisis service. If you are in immediate danger, call your local emergency number.'),
      ];

  List<InlineSpan> _evidenceContent() => [
        const TextSpan(
            text: 'Mentesana draws on three bodies of research:\n\n'),
        _strong('Expressive writing'),
        const TextSpan(
            text:
                ' — Pennebaker & Beall (1986) and subsequent studies found that writing about emotional experiences can improve wellbeing. Mentesana uses this as a design principle, not a treatment protocol.\n\n'),
        _strong('Emotional labeling'),
        const TextSpan(
            text:
                ' — Lieberman et al. (2007) showed that naming feelings reduces amygdala response. The check-in invites naming without forcing it.\n\n'),
        _strong('Reflective distance'),
        const TextSpan(
            text:
                ' — Kross & Ayduk (2011) found that writing about experiences in a distanced way helps regulation. The "read at a distance" feature draws on this.\n\n'),
        const TextSpan(
            text:
                'These are evidence-informed design principles, not treatment promises. Mentesana never claims that one event caused a feeling.'),
      ];

  List<InlineSpan> _licensesContent() => [
        const TextSpan(text: 'Mentesana is a prototype built with:\n\n'),
        const TextSpan(
            text: '· No external JavaScript libraries (vanilla JS)\n'),
        const TextSpan(text: '· No external CSS frameworks\n'),
        const TextSpan(text: '· No tracking or analytics SDKs\n'),
        const TextSpan(text: '· No cloud services or third-party APIs\n\n'),
        const TextSpan(
            text:
                'All code is original. The prototype runs entirely in the browser with no server dependencies.\n\n'),
        _small('© 2026 Mentesana. Open-source license pending.'),
      ];

  // ---------------------------------------------------------------------
  // Debug section — visible only in kDebugMode.
  // ---------------------------------------------------------------------

  Widget _debugSection() {
    // Store references to avoid capturing widget with mounted checks.
    final store = this.store;
    final showToast = _showToast;

    Widget debugPill(String label, VoidCallback onTap, {bool primary = false}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minWidth: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: primary ? kRiva.withValues(alpha: .55) : _tx(.16)),
            color: primary ? kRiva.withValues(alpha: .10) : null,
          ),
          child: Text(label,
              style: MenteType.eyebrow.copyWith(
                  letterSpacing: .05 * 11,
                  color: primary ? kRivaLight : _tSecondary)),
        ),
      );
    }

    return _sectionColumn('currents test data', [
      _row('Seed currents test data',
          sub: 'Generate 14+ days of realistic mood and journal data',
          trailing: debugPill('seed', () {
            final count = CurrentsTestSeeder.seedTestData(store);
            showToast('seeded $count test entries.');
          }, primary: true)),
      _row('Clear currents test data',
          sub: 'Remove only generated synthetic records',
          trailing: debugPill('clear', () {
            final count = CurrentsTestSeeder.clearTestData(store);
            showToast('cleared $count test entries.');
          })),
      _note(
          'These actions only affect synthetic test data. Never real entries.'),
      const SizedBox(height: 16),
      _row('Test undertow: brooding',
          sub: 'Show UndertowSurface for the brooding fixture',
          trailing: debugPill('test', () {
            _showUndertowForKind('brooding');
          }, primary: true)),
      _row('Test undertow: worry',
          sub: 'Show UndertowSurface for the worry fixture',
          trailing: debugPill('test', () {
            _showUndertowForKind('worry');
          }, primary: true)),
      _row('Test undertow: self-critique',
          sub: 'Show UndertowSurface for the self-critique fixture',
          trailing: debugPill('test', () {
            _showUndertowForKind('selfCritique');
          }, primary: true)),
      _note(
          'Tapping a test button opens the existing UndertowSurface for the chosen fixture entry.'),
    ]);
  }

  void _showUndertowForKind(String kind) {
    final store = this.store;
    // Find the fixture entry with matching title pattern.
    JournalEntry? entry;
    for (final e in store.entries) {
      if (e.title.contains('[TEST]') &&
          e.title.toLowerCase().contains(kind
              .toLowerCase()
              .replaceFirst('selfcritique', 'self-critique'))) {
        entry = e;
        break;
      }
    }
    if (entry == null) {
      _showToast('No fixture found for $kind. Seed test data first.');
      return;
    }

    // Check if the entry passes undertowScan.
    final reading = undertowScan(entry.text);
    if (reading == null) {
      _showToast('The $kind fixture does not pass undertowScan.');
      return;
    }

    // Show the UndertowSurface as a full-screen dialog overlay.
    // The Material ancestor satisfies InkWell requirements, and the
    // SizedBox.expand gives proper layout constraints to Positioned.fill
    // inside UndertowSurface.
    final reduced =
        store.reducedMotionOn || (MediaQuery.of(context).disableAnimations);
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: SizedBox.expand(
          child: UndertowSurface(
            store: store,
            entry: entry!,
            reading: reading,
            reduced: reduced,
            onClose: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }
}
