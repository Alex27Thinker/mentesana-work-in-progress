#!/usr/bin/env bash
# Mentesana — Phase Verification Script
# Usage: ./tool/verify.sh [phase-name]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

phase="${1:-current}"

echo "=== Phase: $phase ==="
echo ""

# 1. Format
echo "--- dart format ---"
dart format --output=none --set-exit-if-changed . 2>&1 || {
    echo -e "${RED}FAILED${NC}"
    echo "Run 'dart format .' to fix."
    exit 1
}
echo -e "${GREEN}PASS${NC}"
echo ""

# 2. Analyze
echo "--- flutter analyze ---"
flutter analyze 2>&1 || {
    echo -e "${RED}FAILED${NC}"
    exit 1
}
echo -e "${GREEN}PASS${NC}"
echo ""

# 3. Tests
echo "--- flutter test ---"
flutter test 2>&1 || {
    echo -e "${RED}FAILED${NC}"
    exit 1
}
echo -e "${GREEN}PASS${NC}"
echo ""

# 4. Integration tests (if present)
if [ -d "integration_test" ]; then
    echo "--- flutter test integration_test ---"
    flutter test integration_test 2>&1 || {
        echo -e "${RED}FAILED${NC}"
        exit 1
    }
    echo -e "${GREEN}PASS${NC}"
    echo ""
fi

echo "=== Phase $phase: ALL PASSED ==="
