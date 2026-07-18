// Mentesana — design tokens.
//
// Single source of truth for the presentation layer: type scale, text
// opacities, spacing, shape, and the two supported button styles.
// Built on top of the existing palette helpers in lib/mood_palette.dart.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mood_palette.dart';

// ───────────────────────── Text opacities ─────────────────────────

/// Primary text: body, titles, mood word, insight letter.
Color get textPrimary => ivory(.95);

/// Secondary text: captions, helper lines, metadata.
Color get textSecondary => ivory(.65);

/// Faint text: decorative/ambient text, placeholders.
Color get textFaint => ivory(.42);

/// Disabled text: unavailable actions.
Color get textDisabled => ivory(.28);

// ───────────────────────── Type scale ─────────────────────────
//
// Allowed font sizes in the app. No other fontSize literals may be used
// after migration. Minimum size is 11.

class MenteType {
  const MenteType._();

  /// Display: large screen headlines (34, Alice serif).
  static TextStyle get display => GoogleFonts.alice(
        fontSize: 34,
        height: 1.18,
        color: textPrimary,
      );

  /// Title: screen headers / large card headlines (24, Alice serif).
  static TextStyle get title => GoogleFonts.alice(
        fontSize: 24,
        height: 1.22,
        color: textPrimary,
      );

  /// Heading: section / card headings (19, Alice serif).
  static TextStyle get heading => GoogleFonts.alice(
        fontSize: 19,
        height: 1.3,
        color: textPrimary,
      );

  /// Body: primary reading text (15, system sans).
  static TextStyle get body => const TextStyle(
        fontSize: 15,
        height: 1.5,
        color: Colors.white,
      );

  /// Body serif: reflective / poetic body text (15, Alice serif).
  static TextStyle get bodySerif => GoogleFonts.alice(
        fontSize: 15,
        height: 1.55,
        color: textPrimary,
      );

  /// Caption: labels, metadata, helper text (13, system sans).
  static TextStyle get caption => const TextStyle(
        fontSize: 13,
        height: 1.45,
        color: Colors.white,
      );

  /// Eyebrow: uppercase labels, nav badges, tiny metadata (11, system sans).
  static TextStyle get eyebrow => const TextStyle(
        fontSize: 11,
        letterSpacing: 1.4,
        height: 1.3,
        color: Colors.white,
      );
}

// ───────────────────────── Spacing (4pt grid) ─────────────────────────

const double s4 = 4;
const double s8 = 8;
const double s12 = 12;
const double s16 = 16;
const double s24 = 24;
const double s32 = 32;

/// Horizontal screen padding used by most surfaces.
const EdgeInsets padH = EdgeInsets.symmetric(horizontal: s16);

// ───────────────────────── Shape ─────────────────────────

/// The app's single corner radius for cards, panels, and sheets.
const double r = 18;

/// A hairline border tuned for the dark sea palette.
BorderSide get hairline => BorderSide(color: ivory(.13));

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
        child: Text(label, style: MenteType.bodySerif.copyWith(color: kRivaLight)),
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
          style: MenteType.caption.copyWith(
            color: color,
            letterSpacing: .05 * 11,
          ),
        ),
      ),
    );
  }
}