import re, sys

# Apply Phase 2 token substitutions to a Dart file.
# Usage: python _scripts/tokenise.dart lib/some_file.dart
# Operates in-place. Only substitutes text-style properties.

def process(path):
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()

    # 1. Add import after mood_palette if not present
    if "import 'theme.dart';" not in src and "import 'mood_palette.dart';" in src:
        src = src.replace(
            "import 'mood_palette.dart';",
            "import 'mood_palette.dart';\nimport 'theme.dart';"
        )

    # 2. Snap fontSize values (only inside TextStyle or GoogleFonts.alice)
    def font_snap(m):
        val = float(m.group(1))
        if val <= 10: return "MenteType.eyebrow"
        if val <= 12.5: return "MenteType.caption"
        if val <= 15.5: return "MenteType.bodySerif"
        if val <= 21: return "MenteType.heading"
        if val <= 28: return "MenteType.title"
        return "MenteType.display"

    # Replace GoogleFonts.alice(fontSize: N, ...rest...)  
    src = re.sub(
        r"GoogleFonts\.alice\(\s*fontSize:\s*(\d+\.?\d*)\s*,(.*?)\)",
        lambda m: f"{font_snap(m)}.copyWith({m.group(2)})",
        src, flags=re.DOTALL
    )

    # Replace TextStyle(fontSize: N, ...rest...)  
    src = re.sub(
        r"TextStyle\(\s*fontSize:\s*(\d+\.?\d*)\s*(,.*?)?\)",
        lambda m: f"{font_snap(m)}.copyWith({m.group(2)})" if m.group(2) else font_snap(m),
        src, flags=re.DOTALL
    )

    # 3. Replace ivory(X) text colors with opacity tokens
    def ivory_snap(m):
        a = float(m.group(1))
        if a >= .88: return "textPrimary"
        if a >= .60: return "textSecondary"
        if a >= .38: return "textFaint"
        return "textDisabled"

    # Only replace in text-style contexts (color: ivory(X))
    src = re.sub(r"color:\s*ivory\((\d*\.?\d+)\)", lambda m: f"color: {ivory_snap(m)}", src)

    # 4. EdgeInsets → grid tokens
    def grid_snap(val):
        v = float(val)
        best, best_dist = "s4", abs(v-4)
        for name, g in [("s8",8),("s12",12),("s16",16),("s24",24),("s32",32)]:
            if abs(v-g) < best_dist:
                best, best_dist = name, abs(v-g)
        return best

    src = re.sub(r"EdgeInsets\.all\((\d+(?:\.\d+)?)\)", lambda m: f"EdgeInsets.all({grid_snap(m.group(1))})", src)
    src = re.sub(
        r"EdgeInsets\.symmetric\(\s*horizontal:\s*(\d+(?:\.\d+)?)\s*,\s*vertical:\s*(\d+(?:\.\d+)?)\s*\)",
        lambda m: f"EdgeInsets.symmetric(horizontal: {grid_snap(m.group(1))}, vertical: {grid_snap(m.group(2))})",
        src
    )
    src = re.sub(
        r"EdgeInsets\.only\(\s*(\w+):\s*(\d+(?:\.\d+)?)\s*\)",
        lambda m: f"EdgeInsets.only({m.group(1)}: {grid_snap(m.group(2))})",
        src
    )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(src)
    print(f"tokenised {path}")

if __name__ == "__main__":
    process(sys.argv[1])