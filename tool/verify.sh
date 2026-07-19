#!/usr/bin/env bash
# Mentesana — Phase Verification Script
# Usage: ./tool/verify.sh [phase-name]
#
# Runs dart format, flutter analyze, and flutter test. Fails on any
# non-zero exit code. The phase-name argument is recorded in the
# banner but is not required.
#
# LF line endings only. Run from the repository root.

set -euo pipefail

phase="${1:-current}"

echo "=== Phase: $phase ==="
echo ""

echo "--- dart format ---"
dart format --output=none --set-exit-if-changed lib test 2>&1 || {
    echo "FAILED"
    echo "Run 'dart format .' to fix."
    exit 1
}
echo "PASS"
echo ""

echo "--- flutter analyze ---"
flutter analyze 2>&1 || {
    echo "FAILED"
    exit 1
}
echo "PASS"
echo ""

echo "--- flutter test ---"
flutter test 2>&1 || {
    echo "FAILED"
    exit 1
}
echo "PASS"
echo ""

if [ -d "integration_test" ]; then
    echo "--- flutter test integration_test ---"
    flutter test integration_test 2>&1 || {
        echo "FAILED"
        exit 1
    }
    echo "PASS"
    echo ""
fi

echo "=== Phase $phase: ALL PASSED ==="
