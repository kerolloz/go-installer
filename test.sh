#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$SCRIPT_DIR/go.sh"

# Create isolated test environment to avoid modifying real shell profiles
test_home=$(mktemp -d 2>/dev/null || mktemp -d -t go-installer-test)
trap 'rm -rf "$test_home"' EXIT
export HOME="$test_home"
export SHELL_PROFILE="$test_home/test-profile.sh"

unset GOROOT GOPATH
export GOROOT="$HOME/.go-test"
export GOPATH="$HOME/go-test-workspace"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() {
  TESTS_PASSED=$((TESTS_PASSED + 1))
  printf '  \033[32mPASS\033[0m %s\n' "$1"
}

fail() {
  TESTS_FAILED=$((TESTS_FAILED + 1))
  printf '  \033[31mFAIL\033[0m %s — %s\n' "$1" "$2"
}

run_test() {
  TESTS_RUN=$((TESTS_RUN + 1))
  printf '\n--- %s ---\n' "$1"
}

ensure_clean() {
  rm -rf "$GOROOT" "$GOPATH" "${GOROOT}.bak" 2>/dev/null || true
}

# ============================================================
# Tests
# ============================================================

run_test "Install latest Go"
ensure_clean
if bash "$SCRIPT"; then
  if [ -x "$GOROOT/bin/go" ] && "$GOROOT/bin/go" version >/dev/null 2>&1; then
    INSTALLED_VERSION=$("$GOROOT/bin/go" version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    pass "Installed Go $INSTALLED_VERSION"
  else
    fail "Install latest" "go binary not found or not executable at $GOROOT/bin/go"
  fi
else
  fail "Install latest" "installer exited with a non-zero status"
fi

run_test "Install again (already installed, should be a no-op)"
REINSTALL_LOG=$(mktemp 2>/dev/null || mktemp -t go-test-reinstall)
if bash "$SCRIPT" 2>&1 | tee "$REINSTALL_LOG"; then
  if grep -q "nothing to do" "$REINSTALL_LOG"; then
    pass "Correctly detected existing installation"
  else
    fail "Re-install detection" "did not report 'nothing to do'"
  fi
else
  fail "Install again" "installer exited with a non-zero status"
fi

run_test "Update (already on latest, should be a no-op)"
UPDATE_LOG=$(mktemp 2>/dev/null || mktemp -t go-test-update)
if bash "$SCRIPT" update 2>&1 | tee "$UPDATE_LOG"; then
  if grep -q "nothing to do" "$UPDATE_LOG"; then
    pass "Update correctly detected latest is current"
  else
    fail "Update no-op" "did not report 'nothing to do'"
  fi
else
  fail "Update" "installer exited with a non-zero status"
fi

run_test "Workspace directories created"
if [ -d "$GOPATH/src" ] && [ -d "$GOPATH/pkg" ] && [ -d "$GOPATH/bin" ]; then
  pass "GOPATH subdirectories exist"
else
  fail "Workspace dirs" "expected src/pkg/bin under $GOPATH"
fi

run_test "Help message"
output=$(bash "$SCRIPT" help 2>&1)
if printf '%s' "$output" | grep -q "Usage"; then
  pass "Help prints usage info"
else
  fail "Help" "output did not contain 'Usage'"
fi

run_test "Help exits with code 0"
if bash "$SCRIPT" help >/dev/null 2>&1; then
  pass "Exit code 0"
else
  fail "Help exit code" "expected 0"
fi

run_test "Unknown argument exits with code 1"
if bash "$SCRIPT" garbage >/dev/null 2>&1; then
  fail "Unknown arg" "expected non-zero exit"
else
  pass "Exit code non-zero for unknown arg"
fi

run_test "Remove Go"
if bash "$SCRIPT" remove; then
  if [ ! -d "$GOROOT" ]; then
    pass "GOROOT removed"
  else
    fail "Remove" "$GOROOT still exists"
  fi
else
  fail "Remove" "installer exited with a non-zero status"
fi

run_test "Remove again (nothing to remove, should be a no-op)"
if bash "$SCRIPT" remove 2>&1; then
  pass "Correctly exited cleanly when nothing to remove"
else
  fail "Remove idempotency" "expected zero exit when nothing to remove"
fi

run_test "Install specific version (1.21.0)"
ensure_clean
if bash "$SCRIPT" --version 1.21.0; then
  actual=$("$GOROOT/bin/go" version 2>&1)
  if printf '%s' "$actual" | grep -q "go1.21.0"; then
    pass "Installed Go 1.21.0"
  else
    fail "Specific version" "expected 1.21.0, got: $actual"
  fi
else
  fail "Specific version" "installer exited with a non-zero status"
fi

run_test "--version without value exits with error"
if bash "$SCRIPT" --version 2>/dev/null; then
  fail "Missing version arg" "expected non-zero exit"
else
  pass "Correctly failed without version value"
fi

run_test "Checksum was verified (not empty)"
ensure_clean
if output=$(bash "$SCRIPT" --version 1.22.0 2>&1); then
  if printf '%s' "$output" | grep -q "Checksum verified"; then
    pass "Checksum verification ran"
  else
    fail "Checksum" "no checksum verification in output"
  fi
else
  fail "Checksum" "installer exited with a non-zero status"
fi

run_test "Cleanup"
ensure_clean
pass "Test environment cleaned up"

# ============================================================
# Summary
# ============================================================
printf '\n============================================================\n'
printf 'Results: %d run, \033[32m%d passed\033[0m, \033[31m%d failed\033[0m\n' \
  "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
printf '============================================================\n'

[ "$TESTS_FAILED" -eq 0 ]
