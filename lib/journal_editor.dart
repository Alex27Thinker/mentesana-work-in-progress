// Mentesana — the journal editor overlay.
// Structural screen: typography on the sea. No cards, no boxes.
// - Title hint and body text use textPrimary/textSecondary for readability
// - Shelf tools are bare stroke icons (48px targets)
// - Keep button unchanged (ritual circle); on keep, fire sea ripple from its position

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '_shared/services/attachment_service.dart';
import 'analysis_engine.dart';
import 'app_store.dart';
import 'core/locator.dart';
import 'core/sea_manager.dart';
import 'journal_prompts.dart'
    show stripTags, journalPrompt, stepPrompt, hhmm, jDateLine, kSafetyText;
import 'mood_palette.dart';
import 'sea_icons.dart';
import 'theme.dart';
import 'voice_transcription_service.dart';

class JournalEditorConfig {
  JournalEditorConfig({
    required this.mode,
    this.activeEntry,
    this.freePrompt,
    this.v = 0,
    this.a = 0,
    this.word,
    this.initialText = '',
    this.initialTitle = '',
    this.initialTag = '',
    this.initialBottle = '',
    List<Attachment>? attachments,
  }) : attachments = attachments ?? [];

  final String mode;
  final JournalEntry? activeEntry;
  final String? freePrompt;
  final double v;
  final double a;
  final String? word;
  final String initialText;
  final String initialTitle;
  final String initialTag;
  final String initialBottle;
  final List<Attachment> attachments;
}

class JournalEditor extends StatefulWidget {
  const JournalEditor({
    super.key,
    required this.store,
    required this.config,
    required this.reduced,
    required this.onClose,
    required this.onKept,
  });

  final AppStore store;
  final JournalEditorConfig config;
  final bool reduced;
  final VoidCallback onClose;
  final ValueChanged<JournalEntry> onKept;

  @override
  State<JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends State<JournalEditor> {
  late final TextEditingController _text;
  late final TextEditingController _title;
  late final TextEditingController _tag;
  late final TextEditingController _bottle;
  final _textFocus = FocusNode();
  final _titleFocus = FocusNode();
  final _bottleFocus = FocusNode();
  final _tagFocus = FocusNode();

  late List<Attachment> _pending;
  bool _kept = false;
  String _journalStep = 'event';
  bool _stepChosen = false;
  String? _openPanel;
  String _heldText = 'held quietly';
  bool _heldSaving = false;
  Timer? _heldTimer;
  String _recStatus = '';
  Timer? _recStatusClear;
  bool _writing = false;
  Timer? _writeTimer;
  late final VoiceTranscriptionService _voice;
  bool _recording = false;
  bool _transcribing = false;
  Timer? _recTicker;
  Duration _recElapsed = Duration.zero;
  String? _pendingAudioPath;
  int? _voiceTargetEntryTs;

  JournalEntry? get _activeEntry => widget.config.activeEntry;
  double get _v => widget.config.v;
  double get _a => widget.config.a;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.config.initialText);
    _title = TextEditingController(text: widget.config.initialTitle);
    _tag = TextEditingController(text: widget.config.initialTag);
    _bottle = TextEditingController(text: widget.config.initialBottle);
    _pending = List.of(widget.config.attachments);
    _voice = VoiceTranscriptionService();
    if (_title.text.trim().isEmpty && (_activeEntry?.title ?? '').isNotEmpty) {
      _title.text = _activeEntry!.title;
    }
    Timer(Duration(milliseconds: widget.reduced ? 0 : 500), () {
      if (mounted) _textFocus.requestFocus();
    });
    _text.addListener(_onTextChanged);
    _title.addListener(_onFieldChanged);
    _tag.addListener(_onFieldChanged);
    _bottle.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _heldTimer?.cancel();
    _recStatusClear?.cancel();
    _writeTimer?.cancel();
    _recTicker?.cancel();
    if (_recording) {
      _voice.stopRecording();
    }
    _voice.dispose();
    _text.dispose();
    _title.dispose();
    _tag.dispose();
    _bottle.dispose();
    _textFocus.dispose();
    _titleFocus.dispose();
    _bottleFocus.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  String get _promptText => widget.config.mode == 'free'
      ? (widget.config.freePrompt ??
          'a page for whatever is here — no weather required.')
      : stripTags(journalPrompt(_v, _a, widget.config.word));

  String get _dateLine {
    final when = _activeEntry != null ? _activeEntry!.date : DateTime.now();
    return '${jDateLine(when)} · ${hhmm(when)}';
  }

  String get _keepLabel {
    if (_kept) return 'kept';
    return (_activeEntry?.text.isNotEmpty ?? false) ? 'keep changes' : 'keep';
  }

  void _flashSavedNote() {
    setState(() {
      _heldText = 'holding';
      _heldSaving = true;
    });
    _heldTimer?.cancel();
    _heldTimer = Timer(Duration(milliseconds: widget.reduced ? 450 : 900), () {
      if (!mounted) return;
      setState(() {
        _heldText = 'held quietly';
        _heldSaving = false;
      });
    });
  }

  void _saveDraft() {
    final hasAnything = _text.text.trim().isNotEmpty ||
        _title.text.trim().isNotEmpty ||
        _tag.text.trim().isNotEmpty ||
        _bottle.text.trim().isNotEmpty ||
        _pending.isNotEmpty;
    if (!hasAnything) {
      widget.store.clearJournalDraft();
      return;
    }
    final ok = widget.store.saveJournalDraft(JournalDraft(
      text: _text.text,
      title: _title.text,
      tag: _tag.text,
      bottle: _bottle.text,
      mode: widget.config.mode,
      prompt: widget.config.freePrompt,
      ts: DateTime.now().millisecondsSinceEpoch,
      activeEntryTs: _activeEntry?.ts,
      attachments: _pending,
      v: _activeEntry?.v,
      a: _activeEntry?.a,
      word: _activeEntry?.word,
    ));
    if (ok) {
      _flashSavedNote();
    } else {
      setState(() => _heldText = 'storage is full');
    }
  }

  void _markWriting() {
    if (widget.reduced) return;
    setState(() => _writing = true);
    _writeTimer?.cancel();
    _writeTimer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _writing = false);
    });
  }

  void _onTextChanged() {
    _saveDraft();
    _markWriting();
    setState(() {});
  }

  void _onFieldChanged() {
    _saveDraft();
    setState(() {});
  }

  void _keepEntry() {
    if (_kept) return;
    if (_text.text.trim().isEmpty) {
      widget.onClose();
      return;
    }
    setState(() => _kept = true);
    final store = widget.store;
    final current =
        _activeEntry ?? JournalEntry(ts: DateTime.now().millisecondsSinceEpoch);
    if (!store.entries.contains(current)) store.entries.add(current);
    final nextText = _text.text.trim();
    final nextTitle = _title.text.trim().isNotEmpty
        ? _title.text.trim()
        : (titleFromPage(nextText).isNotEmpty
            ? titleFromPage(nextText)
            : 'a page from this day');
    if (_activeEntry != null &&
        _activeEntry!.text.isNotEmpty &&
        (_activeEntry!.text != nextText || _activeEntry!.title != nextTitle)) {
      current.versions = [
        ...current.versions,
        EntryVersion(
          editedAt: DateTime.now().millisecondsSinceEpoch,
          text: _activeEntry!.text,
          title: _activeEntry!.title.isNotEmpty
              ? _activeEntry!.title
              : titleFromPage(_activeEntry!.text),
          tag: _activeEntry!.tag,
          tideLine: _activeEntry!.tideLine,
        ),
      ];
      if (current.versions.length > 5) {
        current.versions =
            current.versions.sublist(current.versions.length - 5);
      }
    }
    current.text = nextText;
    current.title = nextTitle;
    current.prompt = _promptText;
    current.wordCount =
        nextText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final tg = _tag.text.trim().toLowerCase();
    if (tg.isNotEmpty) {
      current.tag = tg.length > 18 ? tg.substring(0, 18) : tg;
    }
    current.attachments = _pending;
    final tideLine = _bottle.text.trim();
    if (tideLine.isNotEmpty) {
      current.tideLine = tideLine;
      current.tideAt =
          DateTime.now().millisecondsSinceEpoch + 14 * 24 * 60 * 60 * 1000;
    }
    if (_transcribing && _pendingAudioPath != null) {
      _voiceTargetEntryTs = current.ts;
      store.beginPendingTranscription(current, _pendingAudioPath!);
    } else {
      store.saveEntries();
    }
    store.clearJournalDraft();

    final seaManager = locate<SeaManager>();
    final buttonBox = context.findRenderObject() as RenderBox?;
    if (buttonBox != null) {
      final center = buttonBox.localToGlobal(Offset.zero) +
          Offset(buttonBox.size.width / 2, buttonBox.size.height / 2);
      seaManager.ripple(center);
    }

    widget.onKept(current);
  }

  void _togglePanel(String which, FocusNode input) {
    final opening = _openPanel != which;
    setState(() => _openPanel = opening ? which : null);
    if (opening) {
      Timer(Duration(milliseconds: widget.reduced ? 0 : 280),
          () => input.requestFocus());
    }
  }

  void _recStatusSet(String text, bool fade) {
    _recStatusClear?.cancel();
    setState(() => _recStatus = text);
    if (fade) {
      _recStatusClear = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _recStatus = '');
      });
    }
  }

  Future<void> _onAttachTap() async {
    if (_pending.length >= widget.store.attachmentCap) {
      _recStatusSet(
          'attachment limit reached (${widget.store.attachmentCap} per page).',
          true);
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1C2A2E),
      barrierColor: Colors.black.withValues(alpha: .55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('add an image',
                  style: MenteType.heading.copyWith(color: textPrimary)),
              const SizedBox(height: 18),
              _sourceOption(
                ctx,
                icon: SeaIcons.attach,
                label: 'photo library',
                source: ImageSource.gallery,
              ),
              const SizedBox(height: 6),
              _sourceOption(
                ctx,
                icon: SeaIcons.record,
                label: 'camera',
                source: ImageSource.camera,
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    final service = locate<AttachmentService>();
    final result = await service.pickAndCompress(source);
    if (result == null || !mounted) return;

    setState(() {
      _pending = [
        ..._pending,
        Attachment(
          name: result.name,
          type: result.mime,
          size: result.byteSize,
          data: result.dataUrl,
        )
      ];
    });
    _recStatusSet('added ${result.name}.', true);
    _saveDraft();
  }

  Widget _sourceOption(BuildContext ctx,
      {required SeaIconData icon,
      required String label,
      required ImageSource source}) {
    return InkWell(
      onTap: () => Navigator.pop(ctx, source),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: s12, vertical: s12),
        child: Row(children: [
          StrokeIcon(icon, size: 17, color: textSecondary),
          const SizedBox(width: 12),
          Text(label,
              style: MenteType.bodySerif.copyWith(color: textSecondary)),
        ]),
      ),
    );
  }

  Future<void> _onRecordTap() async {
    if (_transcribing) return;
    if (_recording) {
      _recTicker?.cancel();
      final length = _recElapsed;
      setState(() => _recording = false);
      final path = await _voice.stopRecording();
      if (path == null) {
        _recStatusSet("didn't catch anything there — try again.", true);
        return;
      }
      setState(() {
        _transcribing = true;
        _pendingAudioPath = path;
      });
      _recStatusSet(
          'transcribing in the background — carry on writing.', false);
      _voice.transcribe(path).then((transcript) async {
        _pendingAudioPath = null;
        if (mounted) {
          setState(() => _transcribing = false);
          final t = transcript.trim();
          if (t.isEmpty) {
            _recStatusSet("didn't catch anything there — try again.", true);
          } else {
            _insertTranscript(t);
            await _offerToKeepAudio(path, length);
            if (mounted) _recStatusSet('added from your voice.', true);
          }
          return;
        }
        final targetTs = _voiceTargetEntryTs;
        final t = transcript.trim();
        if (targetTs != null && t.isNotEmpty) {
          widget.store.completeTranscription(targetTs, t);
        } else if (targetTs != null) {
          widget.store.failTranscription(targetTs);
        }
        await _deleteTempFile(path);
      }).catchError((_) async {
        _pendingAudioPath = null;
        if (mounted) {
          setState(() => _transcribing = false);
          _recStatusSet("transcription didn't work this time.", true);
        } else if (_voiceTargetEntryTs != null) {
          widget.store.failTranscription(_voiceTargetEntryTs!);
        }
        await _deleteTempFile(path);
      });
      return;
    }
    try {
      await _voice.startRecording();
      _recElapsed = Duration.zero;
      setState(() => _recording = true);
      _recStatusSet('listening… 0:00', false);
      _recTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_recording) return;
        _recElapsed += const Duration(seconds: 1);
        _recStatusSet('listening… ${_fmtDuration(_recElapsed)}', false);
      });
    } on MicPermissionDenied {
      _recStatusSet('microphone access is needed to record.', true);
    } catch (_) {
      _recStatusSet('this device cannot record here.', true);
    }
  }

  Future<void> _deleteTempFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _insertTranscript(String transcript) {
    final sel = _text.selection;
    final value = _text.text;
    final insertAt = sel.isValid ? sel.start : value.length;
    final before = value.substring(0, insertAt);
    final after = value.substring(insertAt);
    final needsLeadingSpace =
        before.isNotEmpty && !before.endsWith('\n') && !before.endsWith(' ');
    final needsTrailingSpace =
        after.isNotEmpty && !after.startsWith('\n') && !after.startsWith(' ');
    final insertion = (needsLeadingSpace ? ' ' : '') +
        transcript +
        (needsTrailingSpace ? ' ' : '');
    final newValue = before + insertion + after;
    _text.value = TextEditingValue(
      text: newValue,
      selection: TextSelection.collapsed(offset: insertAt + insertion.length),
    );
    _saveDraft();
  }

  Future<void> _offerToKeepAudio(String audioPath, Duration length) async {
    final file = File(audioPath);
    final keep = mounted
        ? await showDialog<bool>(
            context: context,
            barrierColor: Colors.black.withValues(alpha: .45),
            builder: (ctx) => Dialog(
              backgroundColor: const Color(0xFF1C2A2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(s24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('keep the recording, too?',
                        style: GoogleFonts.alice(
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                            color: textPrimary)),
                    const SizedBox(height: 10),
                    Text(
                      'the words are already on the page. you can also keep '
                      'the original audio as an attachment, or let it go.',
                      style: MenteType.bodySerif
                          .copyWith(height: 1.5, color: textSecondary),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('just the words',
                              style: TextStyle(color: textSecondary)),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('keep audio too',
                              style: TextStyle(color: kRivaLight)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        : false;
    if (keep == true) {
      try {
        final bytes = await file.readAsBytes();
        final dataUrl = 'data:audio/wav;base64,${base64Encode(bytes)}';
        if (mounted) {
          setState(() {
            _pending = [
              ..._pending,
              Attachment(
                name: 'voice note · ${_fmtDuration(length)}',
                type: 'audio/wav',
                size: bytes.length,
                data: dataUrl,
              ),
            ];
          });
          _saveDraft();
        }
      } catch (_) {}
    }
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  void _emphasizeSelection() {
    final sel = _text.selection;
    if (!sel.isValid || sel.isCollapsed) return;
    final value = _text.text;
    final wrapped = '*${value.substring(sel.start, sel.end)}*';
    _text.value = TextEditingValue(
      text: value.substring(0, sel.start) + wrapped + value.substring(sel.end),
      selection: TextSelection(
          baseOffset: sel.start, extentOffset: sel.start + wrapped.length),
    );
    _textFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final text = _text.text.trim();
    final hasText = text.isNotEmpty;
    final showPivot = hasText && text.length > 360 && _v < -.2 && _a > .2;
    final showSafety = containsCrisisLanguage([text]);
    final sel = _text.selection;
    final showFormatBar = sel.isValid && !sel.isCollapsed;
    final recede = _writing ? 0.34 : 1.0;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _backlink('close', widget.onClose),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 6, 30, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _animatedRecede(
                    recede,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_dateLine,
                            style:
                                MenteType.caption.copyWith(color: textFaint)),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          opacity: _heldSaving ? .95 : .55,
                          child: Text(_heldText,
                              style: GoogleFonts.alice(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 11.5,
                                  color: textSecondary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _animatedRecede(
                    recede,
                    Text(_promptText,
                        style: GoogleFonts.alice(
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                            height: 1.48,
                            color: textSecondary)),
                  ),
                  const SizedBox(height: 18),
                  _animatedRecede(
                    recede,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('title',
                            style:
                                MenteType.caption.copyWith(color: textFaint)),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 98),
                          child: TextField(
                            controller: _title,
                            focusNode: _titleFocus,
                            maxLength: 120,
                            maxLines: null,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _textFocus.requestFocus(),
                            style: MenteType.title.copyWith(color: textPrimary),
                            cursorColor: kRiva,
                            decoration: InputDecoration(
                              counterText: '',
                              isCollapsed: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              border: InputBorder.none,
                              hintText: 'name this page — or don\'t',
                              hintStyle: MenteType.heading
                                  .copyWith(height: 1.3, color: textDisabled),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: showFormatBar
                        ? Padding(
                            padding: const EdgeInsets.only(top: s8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _FormatButton(
                                  label: 'emphasize',
                                  onTap: _emphasizeSelection),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _text,
                    focusNode: _textFocus,
                    maxLines: null,
                    minLines: 8,
                    keyboardType: TextInputType.multiline,
                    style: MenteType.heading
                        .copyWith(height: 1.62, color: textPrimary),
                    cursorColor: kRiva,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: _stepChosen
                          ? stepPrompt(_journalStep, _v, _a)
                          : 'start anywhere.',
                      hintStyle: MenteType.heading
                          .copyWith(height: 1.62, color: textDisabled),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: showPivot
                        ? Padding(
                            padding: const EdgeInsets.only(top: s12),
                            child: _FormatButton(
                              label:
                                  'you have named a lot — add what you need next',
                              onTap: () {
                                setState(() {
                                  _journalStep = 'need';
                                  _stepChosen = true;
                                });
                                _textFocus.requestFocus();
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: showSafety
                        ? Padding(
                            padding: const EdgeInsets.only(top: s12),
                            child: Text(
                              kSafetyText,
                              style: MenteType.caption
                                  .copyWith(height: 1.55, color: textSecondary),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          _buildShelf(),
        ],
      ),
    );
  }

  Widget _animatedRecede(double opacity, Widget child) => AnimatedOpacity(
        duration: const Duration(milliseconds: 700),
        opacity: opacity,
        child: child,
      );

  Widget _backlink(String label, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: StrokeIcon(SeaIcons.back, size: 20, color: textSecondary),
      label:
          Text(label, style: MenteType.caption.copyWith(color: textSecondary)),
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        foregroundColor: ivory(.6),
      ),
    );
  }

  Widget _buildShelf() {
    final holdingTide = _bottle.text.trim().isNotEmpty;
    final holdingTag = _tag.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: _openPanel == 'tide'
                ? _shelfPanel(
                    label: 'leave a line for the tide',
                    child: TextField(
                      controller: _bottle,
                      focusNode: _bottleFocus,
                      maxLength: 140,
                      style: MenteType.bodySerif.copyWith(color: textPrimary),
                      cursorColor: kRiva,
                      decoration: _panelInput(
                          'something you would like to meet again, later'),
                    ),
                  )
                : _openPanel == 'tag'
                    ? _shelfPanel(
                        label: 'a word to find this page by',
                        child: TextField(
                          controller: _tag,
                          focusNode: _tagFocus,
                          maxLength: 18,
                          style:
                              MenteType.bodySerif.copyWith(color: textPrimary),
                          cursorColor: kRiva,
                          decoration:
                              _panelInput('like work, home, or the sea'),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
          if (_pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: s8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _pending.map(_attachmentChip).toList(),
              ),
            ),
          Row(
            children: [
              _shelfTool(SeaIcons.tide, holdingTide,
                  () => _togglePanel('tide', _bottleFocus)),
              _shelfTool(SeaIcons.tag, holdingTag,
                  () => _togglePanel('tag', _tagFocus)),
              _shelfTool(SeaIcons.attach,
                  _pending.length >= widget.store.attachmentCap, _onAttachTap),
              _shelfTool(SeaIcons.record, _recording, _onRecordTap),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_recStatus,
                    maxLines: 2,
                    style: GoogleFonts.alice(
                        fontStyle: FontStyle.italic,
                        fontSize: 11.5,
                        color: textSecondary)),
              ),
              _keepButton(),
            ],
          ),
          const SizedBox(height: 7),
          Text('this page never leaves your device.',
              textAlign: TextAlign.center,
              style: MenteType.caption.copyWith(color: textDisabled)),
        ],
      ),
    );
  }

  InputDecoration _panelInput(String hint) => InputDecoration(
        counterText: '',
        isDense: true,
        border:
            UnderlineInputBorder(borderSide: BorderSide(color: textDisabled)),
        enabledBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: textDisabled)),
        focusedBorder:
            const UnderlineInputBorder(borderSide: BorderSide(color: kRiva)),
        hintText: hint,
        hintStyle: MenteType.bodySerif.copyWith(color: textDisabled),
      );

  Widget _shelfPanel({required String label, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: s8),
      constraints: const BoxConstraints(maxHeight: 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: MenteType.caption.copyWith(color: textFaint)),
          child,
        ],
      ),
    );
  }

  Widget _shelfTool(SeaIconData icon, bool holding, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: s4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: holding ? kRiva.withValues(alpha: .7) : ivory(.18)),
            color: holding ? kRiva.withValues(alpha: .12) : Colors.transparent,
          ),
          child: Center(
            child: StrokeIcon(icon,
                size: 21, color: holding ? kRivaLight : ivory(.62)),
          ),
        ),
      ),
    );
  }

  Widget _keepButton() {
    return GestureDetector(
      onTap: _keepEntry,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kept
              ? kOro.withValues(alpha: .16)
              : const Color(0xFF2D3D43).withValues(alpha: .55),
          border: Border.all(
              color: _kept ? kOro.withValues(alpha: .72) : ivory(.4)),
        ),
        child: Center(
          child: Text(_keepLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.alice(
                  fontStyle: FontStyle.italic,
                  fontSize: 13.5,
                  color: textPrimary)),
        ),
      ),
    );
  }

  Widget _attachmentChip(Attachment a) {
    final label = a.isAudio ? a.name.split(' · ').first : a.name;
    Widget leading;
    if (a.isImage && a.data.isNotEmpty) {
      leading = _dataUrlImage(a.data, 24);
    } else if (a.isAudio) {
      leading = StrokeIcon(SeaIcons.record, size: 16, color: textSecondary);
    } else {
      leading = Text('◌', style: TextStyle(color: textSecondary));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: s8, vertical: s4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: textDisabled),
        color: textDisabled,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: MenteType.caption.copyWith(color: textSecondary)),
          ),
        ],
      ),
    );
  }
}

Widget _dataUrlImage(String dataUrl, double size) {
  final comma = dataUrl.indexOf(',');
  if (comma < 0) return const SizedBox.shrink();
  try {
    final bytes = base64Decode(dataUrl.substring(comma + 1));
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.memory(bytes,
          width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
    );
  } catch (_) {
    return const SizedBox.shrink();
  }
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: s12, vertical: s8),
        child: Text(label,
            style: GoogleFonts.alice(
                fontStyle: FontStyle.italic,
                fontSize: 12.5,
                color: textSecondary,
                decoration: TextDecoration.underline,
                decorationColor: ivory(.35))),
      ),
    );
  }
}
