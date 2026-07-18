// Mentesana — the prompt library.
// 1:1 port of #screen-promptlibrary + PROMPT_LIBRARY / renderPromptLibrary
// from the Vite prototype.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_store.dart';
import 'journal_prompts.dart';
import 'mood_palette.dart';
import 'theme.dart';

class PromptLibraryScreen extends StatefulWidget {
  const PromptLibraryScreen({
    super.key,
    required this.store,
    required this.aiCachedPrompt,
    required this.onBack,
    required this.onWriteFromPrompt,
  });

  final AppStore store;
  final String? aiCachedPrompt;
  final VoidCallback onBack;
  final ValueChanged<String> onWriteFromPrompt;

  @override
  State<PromptLibraryScreen> createState() => _PromptLibraryScreenState();
}

class _PromptLibraryScreenState extends State<PromptLibraryScreen> {
  // Categories open one at a time by default (just 'to begin'), so the
  // library reads as a short list of doors rather than a wall of every
  // prompt at once. Opened state persists across visits (JS plOpenCategories
  // is module-level; here it is static for the same session lifetime).
  static final Set<String> _openCategories = {'to begin'};

  @override
  Widget build(BuildContext context) {
    final lookingBack = dailyPromptOptions(widget.store,
        includeGeneric: false, aiCachedPrompt: widget.aiCachedPrompt);
    final sections = [
      ...kPromptLibrary.entries.map((e) => (title: e.key, prompts: e.value)),
      (title: 'looking back', prompts: lookingBack),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          title: 'prompt library',
          onBack: widget.onBack,
          backLabel: 'journal',
        ),
        const WaveDivider(),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: kExhale,
            builder: (context, t, child) {
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - t)),
                  child: child,
                ),
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              children: [
                for (final section in sections)
                  _category(section.title, section.prompts),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _category(String title, List<String> prompts) {
    final open = _openCategories.contains(title);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      // Wears the day's weather like every other card in the app (#6/#7).
      decoration: seaCard(border: .12, radius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() {
              open ? _openCategories.remove(title) : _openCategories.add(title);
            }),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: MenteType.bodySerif.copyWith(color: textPrimary)),
                  ),
                  Text('${prompts.length}',
                      style:
                          MenteType.caption.copyWith(color: textFaint)),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: open ? .5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down,
                        size: 18, color: ivory(.5)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (prompts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                                'once you have kept a few pages, this will draw from them.',
                                style: GoogleFonts.alice(
                                    fontStyle: FontStyle.italic,
                                fontSize: 13,
                                color: textFaint)),
                          )
                        else
                          for (final p in prompts) _promptCard(title, p),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _promptCard(String title, String prompt) {
    final plain = stripTags(prompt);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => widget.onWriteFromPrompt(plain),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(16),
          // Wears the day's weather, like the journal-home cards (#6/#7).
          decoration: seaCard(border: .11, radius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: MenteType.eyebrow.copyWith(
                      letterSpacing: .2 * 10,
                      color: textFaint)),
              const SizedBox(height: s8),
              Text(plain,
                  style: MenteType.bodySerif.copyWith(
                      height: 1.45, color: textPrimary)),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ivory(.2)),
                  ),
                  child: Center(
                      child: Text('\u2192',
                          style: MenteType.bodySerif.copyWith(
                              color: textSecondary))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

