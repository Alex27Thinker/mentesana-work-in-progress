// Phase 2 token migration — apply to all remaining Dart files.
// Run: node _scripts/tokenise.js lib/file.dart
const fs = require('fs');
const path = require('path');

const file = process.argv[2];
if (!file || !fs.existsSync(file)) {
  console.error('Usage: node _scripts/tokenise.js lib/filename.dart');
  process.exit(1);
}

let src = fs.readFileSync(file, 'utf8');

// ──────────────────────────────────────────────
// 1. Add import after mood_palette if not present
// ──────────────────────────────────────────────
if (!src.includes("import 'theme.dart';") && src.includes("import 'mood_palette.dart';")) {
  src = src.replace(
    "import 'mood_palette.dart';",
    "import 'mood_palette.dart';\nimport 'theme.dart';"
  );
}

// ──────────────────────────────────────────────
// 2. fontSize -> MenteType token
// ──────────────────────────────────────────────
function snapSize(v) {
  if (v <= 10)   return 'eyebrow';
  if (v <= 12.5) return 'caption';
  if (v <= 15.5) return 'bodySerif';
  if (v <= 21)   return 'heading';
  if (v <= 28)   return 'title';
  return 'display';
}

// GoogleFonts.alice(fontSize: N, ...rest)
src = src.replace(/GoogleFonts\.alice\(\s*fontSize:\s*([\d.]+)\s*,\s*(.*?)\)/gs,
  (_, size, rest) => {
    const token = snapSize(parseFloat(size));
    return rest.trim() ? `MenteType.${token}.copyWith(${rest})` : `MenteType.${token}`;
  });

// TextStyle(fontSize: N, ...rest) — careful: only when color: ivory or it's clearly text
src = src.replace(/TextStyle\(\s*fontSize:\s*([\d.]+)\s*,(.*?)\)/gs,
  (_, size, rest) => {
    const token = snapSize(parseFloat(size));
    return rest.trim() ? `MenteType.${token}.copyWith(${rest})` : `MenteType.${token}`;
  });

// ──────────────────────────────────────────────
// 3. color: ivory(X) -> textPrimary/Secondary/Faint/Disabled
// ──────────────────────────────────────────────
function ivoryToken(a) {
  if (a >= 0.88) return 'textPrimary';
  if (a >= 0.60) return 'textSecondary';
  if (a >= 0.38) return 'textFaint';
  return 'textDisabled';
}

src = src.replace(/color:\s*ivory\(([\d.]+)\)/g,
  (_, alpha) => `color: ${ivoryToken(parseFloat(alpha))}`);

// ──────────────────────────────────────────────
// 4. EdgeInsets -> grid tokens
// ──────────────────────────────────────────────
function gridSnap(v) {
  const grid = [4, 8, 12, 16, 24, 32];
  const names = ['s4', 's8', 's12', 's16', 's24', 's32'];
  let best = 0, bestDist = Math.abs(grid[0] - v);
  for (let i = 1; i < grid.length; i++) {
    const d = Math.abs(grid[i] - v);
    if (d < bestDist) { best = i; bestDist = d; }
  }
  return names[best];
}

// EdgeInsets.all(N)
src = src.replace(/EdgeInsets\.all\((\d+(?:\.\d+)?)\)/g,
  (_, v) => `EdgeInsets.all(${gridSnap(parseFloat(v))})`);

// EdgeInsets.symmetric(horizontal: N, vertical: M)
src = src.replace(/EdgeInsets\.symmetric\(\s*horizontal:\s*(\d+(?:\.\d+)?)\s*,\s*vertical:\s*(\d+(?:\.\d+)?)\s*\)/g,
  (_, h, v) => `EdgeInsets.symmetric(horizontal: ${gridSnap(parseFloat(h))}, vertical: ${gridSnap(parseFloat(v))})`);

// EdgeInsets.only(param: N) — single-param only
src = src.replace(/EdgeInsets\.only\(\s*(\w+):\s*(\d+(?:\.\d+)?)\s*\)/g,
  (_, key, v) => `EdgeInsets.only(${key}: ${gridSnap(parseFloat(v))})`);

// ──────────────────────────────────────────────
// Write back
// ──────────────────────────────────────────────
fs.writeFileSync(file, src, 'utf8');
console.log(`OK: ${file}`);