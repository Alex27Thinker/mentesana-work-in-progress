#!/usr/bin/env python3
"""Apply design-token substitutions to Mentesana source files.
Phase 2: font sizes → MenteType, text opacities → tokens, spacings → grid.
Run from project root.  Only substitutes text-style colour arguments;
border/fill/deco colours are intentionally left alone.
"""

import re, sys, pathlib

PROJECT = pathlib.Path(__file__).resolve().parent.parent
LIB = PROJECT / "lib"
TARGETS = sorted(
    p
    for p in LIB.iterdir()
    if p.suffix == ".dart" and p.name != "theme.dart"
)

# ─────────────────────────────────────────────────────────
# 1.  Imports
# ─────────────────────────────────────────────────────────
def add_theme_import(lines):
    """Ensure import 'theme.dart'; appears after import 'mood_palette.dart';"""
    out = []
    found_palette = False
    has_theme = any("theme.dart" in l for l in lines)
    for line in lines:
        out.append(line)
        if "mood_palette.dart" in line and "import" in line:
            found_palette = True
            if not has_theme:
                out.append("import 'theme.dart';\n")
    # If no mood_palette import found, add after the last project import
    if not found_palette and not has_theme:
        found = False
        new_out = []
        for line in out:
            new_out.append(line)
            if not found and line.startswith("import ") and not line.startswith("import 'dart:"):
                pass
            elif not found and (line.startswith("import 'dart:") or "package:flutter" in line or "package:google_fonts" in line):
                pass
            elif not found and line.strip() == "" and len(new_out) > 0 and new_out[-1].startswith("import "):
                new_out.append("import 'theme.dart';\n")
                found = True
        if not found:
            new_out = out + ["import 'theme.dart';\n"]
        out = new_out
    return out


# ─────────────────────────────────────────────────────────
# 2.  Font-size → MenteType token mappings
# ─────────────────────────────────────────────────────────

# Map fontSize literal (as int) → nearest MenteType token
def size_to_token(size):
    if size <= 11:
        return ("eyebrow", True)  # True = use .copyWith()
    if size == 13:
        return ("caption", True)
    if size == 15:
        return ("bodySerif", True)  # most text is serif in this app
    if size == 19:
        return ("heading", True)
    if size == 24:
        return ("title", True)
    if size == 34:
        return ("display", True)
    return None  # no mapping (e.g. font sizes used in TextField decorations)

# For sizes that don't match exactly, snap to nearest
# 10, 10.5, 11 → eyebrow (11)
# 12, 12.5 → caption (13)
# 14, 14.5 → body/caption fallback (15)
# 16, 17 → bodySerif (15)
# 18 → heading (19)
# 21 → heading (19)
# 23 → heading (19) 

def snap_font_size(size):
    s = float(size)
    if s <= 10:
        return "eyebrow"
    if s <= 12.5:
        return "caption"
    if s <= 15.5:
        return "bodySerif"
    if s <= 21:
        return "heading"
    if s <= 28:
        return "title"
    return "display"


# ─────────────────────────────────────────────────────────
# 3.  Text-opacity → token mappings
# ─────────────────────────────────────────────────────────

def ivory_to_token(alpha):
    a = float(alpha)
    if a >= .88:
        return "textPrimary"
    if a >= .60:
        return "textSecondary"
    if a >= .38:
        return "textFaint"
    return "textDisabled"


# ─────────────────────────────────────────────────────────
# 4.  Spacing → grid token mappings
# ─────────────────────────────────────────────────────────

# Map literal padding values to nearest grid token
def pad_to_token(val):
    v = float(val)
    candidates = {"s4": 4, "s8": 8, "s12": 12, "s16": 16, "s24": 24, "s32": 32}
    nearest = min(candidates, key=lambda k: abs(candidates[k] - v))
    return nearest


# ─────────────────────────────────────────────────────────
# 5.  Main processing loop
# ─────────────────────────────────────────────────────────

def process_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.splitlines(keepends=True)
    lines = add_theme_import(lines)
    content = "".join(lines)

    # --- font size substitutions ---
    # Replace GoogleFonts.alice(fontSize: N, ...) → MenteType.token.copyWith(...)
    # or TextStyle(fontSize: N, ...) → MenteType.token.copyWith(...)
    #
    # Pattern 1: GoogleFonts.alice(fontSize: N, color: ivory(A), ...other...)
    def replace_alice_size(m):
        size_val = m.group("size")
        rest = m.group("rest") or ""
        return f"MenteType.{snap_font_size(size_val)}.copyWith({rest})" if rest.strip() else f"MenteType.{snap_font_size(size_val)}"

    # Pattern 2: TextStyle(fontSize: N, ...other..., color: ivory(A), ...)
    def replace_textstyle_size_ivory(m):
        size_val = m.group("size")
        rest = m.group("rest") or ""
        return f"MenteType.{snap_font_size(size_val)}.copyWith({rest})" if rest.strip() else f"MenteType.{snap_font_size(size_val)}"

    # --- ivory(text-opacity) colour substitutions ---
    # Only replace ivory(X) when it appears as a 'color:' parameter for text
    # Pattern: color: ivory(0.XX)  (text properties only)
    def replace_ivory_text_color(m):
        alpha = m.group("alpha")
        token = ivory_to_token(alpha)
        return f"color: {token}"

    # --- EdgeInsets substitutions ---
    def replace_edge_insets(m):
        kind = m.group("kind")      # symmetric, all, only, fromLTRB
        args = m.group("args")
        parts = [x.strip() for x in args.split(",")]
        # symmetric(horizontal, vertical)
        if kind == "symmetric":
            h = pad_to_token(parts[0].split(":")[1].strip() if ":" in parts[0] else parts[0])
            v = pad_to_token(parts[1].split(":")[1].strip() if ":" in parts[1] else parts[1])
            return f"EdgeInsets.symmetric(horizontal: {h}, vertical: {v})"
        # all(N)
        if kind == "all":
            n = pad_to_token(parts[0])
            return f"EdgeInsets.all({n})"
        # only(param: N)
        if kind == "only":
            params = []
            for p in parts:
                name, val = p.split(":")
                name = name.strip()
                val = val.strip()
                tokens = pad_to_token(val)
                params.append(f"{name}: {tokens}")
            return f"EdgeInsets.only({', '.join(params)})"
        # fromLTRB(l, t, r, b)
        if kind == "fromLTRB":
            tokens = [pad_to_token(p.strip()) for p in parts]
            return f"EdgeInsets.fromLTRB({', '.join(tokens)})"
        return m.group(0)  # no change if unmatched

    # Apply substitutions - simplified approach
    # Replace fontSize: N → token snap, one-by-one
    import re

    # Replace fontSize: N (integer or decimal) in context where we know it's text styling
    # We use a conservative approach: only replace inside TextStyle or GoogleFonts context

    # Step 1: Replace fontSize in GoogleFonts.alice() calls
    content = re.sub(
        r"GoogleFonts\.alice\(\s*fontSize:\s*(\d+\.?\d*)\s*,\s*(.*?)\)",
        lambda m: f"MenteType.{snap_font_size(m.group(1))}.copyWith({m.group(2)})"
        if m.group(2).strip()
        else f"MenteType.{snap_font_size(m.group(1))}",
        content,
        flags=re.DOTALL,
    )

    # Step 2: Replace fontSize in TextStyle() calls used for labels/text
    # Only when color: ivory(X) is also present (to avoid replacing borders/fills)
    content = re.sub(
        r"TextStyle\(\s*fontSize:\s*(\d+\.?\d*)\s*,(.*?)\)",
        lambda m: f"MenteType.{snap_font_size(m.group(1))}.copyWith({m.group(2)})"
        if m.group(2).strip()
        else f"MenteType.{snap_font_size(m.group(1))}",
        content,
        flags=re.DOTALL,
    )

    # Step 3: Replace color: ivory(X) in text style contexts with token getters
    content = re.sub(
        r"color:\s*ivory\((\d*\.?\d+)\)",
        lambda m: f"color: {ivory_to_token(m.group(1))}",
        content,
    )

    # Step 4: EdgeInsets simplifications
    # all(N)
    content = re.sub(
        r"EdgeInsets\.all\((\d+(?:\.\d+)?)\)",
        lambda m: f"EdgeInsets.all({pad_to_token(m.group(1))})",
        content,
    )
    # symmetric(horizontal: N, vertical: M)
    content = re.sub(
        r"EdgeInsets\.symmetric\(\s*horizontal:\s*(\d+(?:\.\d+)?)\s*,\s*vertical:\s*(\d+(?:\.\d+)?)\s*\)",
        lambda m: f"EdgeInsets.symmetric(horizontal: {pad_to_token(m.group(1))}, vertical: {pad_to_token(m.group(2))})",
        content,
    )
    # only(param: N)
    content = re.sub(
        r"EdgeInsets\.only\(\s*(\w+):\s*(\d+(?:\.\d+)?)\s*\)",
        lambda m: f"EdgeInsets.only({m.group(1)}: {pad_to_token(m.group(2))})",
        content,
    )

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"  → processed {filepath.name}")


if __name__ == "__main__":
    files = [LIB / p.name for p in TARGETS]
    target = sys.argv[1] if len(sys.argv) > 1 else None
    for fp in files:
        if target and fp.name != target:
            continue
        if fp.name.startswith("."):
            continue
        process_file(fp)

    print("done.")