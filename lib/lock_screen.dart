// Mentesana — the PIN lock veil.
// 1:1 port of #lockScreen + tryUnlock from the Vite prototype.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_store.dart';
import 'mood_palette.dart';
import 'theme.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.store,
    required this.reduced,
    required this.onUnlocked,
  });

  final AppStore store;
  final bool reduced;
  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final _pin = TextEditingController();
  final _focus = FocusNode();
  String _note = '';
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  // JS tryUnlock: a 4-digit match unlocks; anything else shakes and clears.
  void _tryUnlock() {
    final value = _pin.text.trim();
    if (value.length == 4 && value == widget.store.pinCode) {
      widget.onUnlocked();
      return;
    }
    setState(() => _note = "that's not it \u2014 try again.");
    if (!widget.reduced) _shake.forward(from: 0);
    _pin.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D3D43), Color(0xFF232E36)],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final t = _shake.value;
            // a quick left-right settle, like the web keyframe shake
            final dx = t == 0 || t == 1
                ? 0.0
                : (t < .25
                    ? -7.0
                    : t < .5
                        ? 6.0
                        : t < .75
                            ? -4.0
                            : 2.0);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('the sea keeps this, quietly',
                  style: MenteType.heading.copyWith(
                      fontStyle: FontStyle.italic, color: textPrimary)),
              const SizedBox(height: s8),
              Text('enter your pin to continue',
                  style: MenteType.eyebrow.copyWith(
                      letterSpacing: .12 * 11,
                      color: textSecondary)),
              const SizedBox(height: 26),
              GestureDetector(
                onTap: () => _focus.requestFocus(),
                child: SizedBox(
                  width: 120,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // the calm, dot-based reading of how many digits are in —
                      // quieter than the system obscured field it replaces.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (i) {
                          final filled = i < _pin.text.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? kOro : Colors.transparent,
                              border: Border.all(
                                color: filled ? kOro : ivory(.32),
                              ),
                            ),
                          );
                        }),
                      ),
                      // invisible input surface — captures taps/typing only.
                      Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _pin,
                          focusNode: _focus,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            setState(() {});
                            if (value.length == 4) _tryUnlock();
                          },
                          onSubmitted: (_) => _tryUnlock(),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 18,
                child: Text(_note,
                    style: MenteType.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        color: textSecondary)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _tryUnlock,
                child: Text('unlock',
                    style: MenteType.bodySerif.copyWith(
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.underline,
                        decorationColor: kOro.withValues(alpha: .6),
                        color: kOro)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

