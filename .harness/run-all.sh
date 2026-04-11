#!/bin/bash
# ================================================================
# aiGroup Harness — 一键执行所有 Computational Sensors
# ================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL=0
PASSED=0
FAILED=0
WARNINGS=0

run_check() {
    local script="$1"
    local name="$2"
    TOTAL=$((TOTAL + 1))

    echo -e "${BLUE}[HARNESS]${NC} Running: $name"

    local exit_code=0
    bash "$script" 2>&1 || exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}  PASS${NC} $name"
        PASSED=$((PASSED + 1))
    elif [ $exit_code -eq 2 ]; then
        echo -e "${YELLOW}  WARN${NC} $name"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${RED}  FAIL${NC} $name"
        FAILED=$((FAILED + 1))
    fi
    echo ""
}

echo "================================================================"
echo "  aiGroup Harness — Computational Sensors"
echo "================================================================"
echo ""

echo "── Linters ─────────────────────────────────────────"
for script in "$SCRIPT_DIR"/linters/*.sh; do
    [ -f "$script" ] || continue
    name=$(basename "$script" .sh | sed 's/-/ /g')
    run_check "$script" "$name"
done

echo "── Structural Tests ────────────────────────────────"
for script in "$SCRIPT_DIR"/structural-tests/*.sh; do
    [ -f "$script" ] || continue
    name=$(basename "$script" .sh | sed 's/-/ /g')
    run_check "$script" "$name"
done

echo "================================================================"
echo "  Harness Results"
echo "================================================================"
echo ""
echo "Total:    $TOTAL"
echo -e "${GREEN}Passed:   $PASSED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Failed:   $FAILED${NC}"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}HARNESS CHECK FAILED — $FAILED sensor(s) triggered${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}HARNESS PASSED WITH WARNINGS${NC}"
    exit 0
else
    echo -e "${GREEN}ALL HARNESS CHECKS PASSED${NC}"
    exit 0
fi
