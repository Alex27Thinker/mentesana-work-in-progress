// Mentesana — design tokens.
//
// Single source of truth for the presentation layer: type scale, text
// opacities, spacing, shape, the motion scale, and the two supported button
// styles. Built on top of the existing palette helpers in
// lib/mood_palette.dart (ivory, riva, kBreath, kExhale, seaTint, …).
//
// CHARTER NOTES
// - Minimum text size anywhere is 12. No fontSize literal below 12.
// - letterSpacing is 0 across the whole scale. Section labels are plain
//   13px sans (caption) or 14px serif, sentence-case lowercase, normal
//   tracking. The only place letterspaced micro-labels survive is the
//   ritual mood check-in / keep moment (the design reference), which is
//   never migrated.
// - All serif runs through GoogleFonts.alice. Sans is the existing system
//   sans (no Roboto leak: every colored text on the sea goes through the
//   ivory() opacity tokens below).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mood_palette.dart';

// ───────────────────────── Text opacities ─────────────────────────
//
// The four text opacity tokens on the existing ivory() helper. Nothing
// else may invent a text colour for the sea — use these.

/// Primary text: headlines, body, the mood word, insight letter.
Color get textPrimary => ivory(.95);

/// Secondary text: captions, helper lines, metadata.
Color get textSecondary => ivory(.68);

/// Faint text: ambient / placeholder / decorative lines.
Color get textFaint => ivory(.45);

/// Disabled text: unavailable actions, the quietest hints.
Color get textDisabled => ivory(.28);

// ───────────────────────── Type scale ─────────────────────────
//
// The only allowed text styles. Sizes ≥ 12. letterSpacing is 0 on the
// scale itself; per-call overrides must not exceed 0.5 on text under 14
// in migrated files (see CHARTER NOTES above).

class MenteType {
  const MenteType._();

  /// Display: large screen headlines (34, Alice serif).
  static TextStyle get display => GoogleFonts.alice(
        fontSize: 34,
        height: 1.18,
        color: textPrimary,
      );

  /// Title: screen headers / large headlines (24, Alice serif).
  static TextStyle get title => GoogleFonts.alice(
        fontSize: 24,
        height: 1.22,
        color: textPrimary,
      );

  /// Heading: section / row headings (19, Alice serif).
  static TextStyle get heading => GoogleFonts.alice(
        fontSize: 19,
        height: 1.3,
        color: textPrimary,
      );

  /// Body: primary reading text (15, system sans).
  static TextStyle get body => TextStyle(
        fontSize: 15,
        height: 1.5,
        color: textPrimary,
      );

  /// Body serif: reflective / poetic body text (15, Alice serif).
  static TextStyle get bodySerif => GoogleFonts.alice(
        fontSize: 15,
        height: 1.55,
        color: textPrimary,
      );

  /// Caption: labels, metadata, one-line subtitles, section labels
  /// (13, system sans, normal tracking — sentence-case lowercase).
  static TextStyle get caption => TextStyle(
        fontSize: 13,
        height: 1.45,
        color: textPrimary,
      );

  /// Eyebrow: section labels and tiny metadata (13, system sans).
  /// Normal tracking by default; the ritual mood check-in is the only
  /// place that re-adds letterspacing on top, and it is never migrated.
  static TextStyle get eyebrow => TextStyle(
        fontSize: 13,
        height: 1.3,
        color: textPrimary,
      );
}

// ───────────────────────── Spacing (4pt grid) ─────────────────────────

const double s4 = 4;
const double s8 = 8;
const double s12 = 12;
const double s16 = 16;
const double s20 = 20;
const double s24 = 24;
const double s32 = 32;

/// Horizontal screen padding used by most surfaces.
const EdgeInsets padH = EdgeInsets.symmetric(horizontal: s16);

/// v2 — THE screen gutter. Screens historically mixed 22 and s16; 22 wins
/// (it is what most surfaces already use). Screen-level scroll padding must
/// use [kGutter] / [padScreen]; padH stays for component-internal spacing.
const double kGutter = 22;
const EdgeInsets padScreen = EdgeInsets.symmetric(horizontal: kGutter);

// ───────────────────────── Shape ─────────────────────────

/// The app's single corner radius — reserved for the ritual keep button
/// and sheet/dialog surfaces only. Per the charter the sea is the only
/// container; cards do not use this.
const double r = 18;

/// A hairline border tuned for the dark sea palette — used sparingly,
/// only to separate sections where whitespace alone is not enough.
BorderSide get hairline => BorderSide(color: ivory(.13));

/// Section-separator hairline: ivory(.08), the charter's only allowed
/// divider line between sections.
const BorderSide sectionRule = BorderSide(color: Color(0x14F2EEE6));

// ───────────────────────── Motion scale ─────────────────────────
//
// Reactive, not looping. Springs for gestures; single staggered fade for
// content reveal; ambient loops live only inside the sea painter. Every
// duration here honours the existing reduced-motion setting, which the
// per-screen builders snap to 0 or Duration.zero.

/// Fast: gestures, taps, small state changes.
const Duration kMotionFast = Duration(milliseconds: 180);

/// Normal: most surface transitions, toggles.
const Duration kMotionNormal = Duration(milliseconds: 320);

/// Slow: screen-level crossfades, the keep ceremony.
const Duration kMotionSlow = Duration(milliseconds: 550);

/// The long breath — ambient type breathing (greeting, daily prompt).
/// Mirrors the ritual ~5.8s breath (kBreath) for widgets that want the
/// duration without importing the palette.
const Duration kBreathe = Duration(milliseconds: 5800);

// ─────────────────────── Grain (v2) ───────────────────────
//
// A whisper of animated film grain over every gradient surface kills the
// flat digital look. Deliberately tiny — grain must be felt, not seen.

const double kGrainOpacity = .028; // at the surface
const double kGrainOpacityDeep = .05; // at full depth

/// The ritual breath — reserved for the mood check-in lens and the keep
/// button only (re-exported from mood_palette so screens import one place).
// kBreath is already defined in mood_palette.dart; do not re-declare.

// ───────────────────────── Buttons ─────────────────────────
//
// Exactly two button styles: a primary pill and a quiet text link.
// The circular keep button in journal/mood selector is the third,
// sacred exception and remains unchanged where it lives.

class MenteButtons {
  const MenteButtons._();

  /// Primary pill: the main call-to-action on any surface.
  static Widget primary({
    required String label,
    required VoidCallback? onTap,
    bool expanded = false,
    double radius = 12,
  }) {
    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 44),
        width: expanded ? double.infinity : null,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: s16, vertical: s12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: riva(.62)),
          color: riva(.14),
        ),
        child:
            Text(label, style: MenteType.bodySerif.copyWith(color: kRivaLight)),
      ),
    );
    return expanded
        ? child
        : IntrinsicWidth(
            child: child,
          );
  }

  /// Quiet text link: secondary actions that should not compete with
  /// the primary pill or the circular keep button.
  static Widget quiet({
    required String label,
    required VoidCallback? onTap,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFCF8B7B) : textFaint;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: s8, vertical: s8),
        child: Text(
          label,
          style: MenteType.caption.copyWith(color: color),
        ),
      ),
    );
  }
}
