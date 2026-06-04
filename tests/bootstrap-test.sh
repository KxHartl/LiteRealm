#!/usr/bin/env bash
# Bootstrap smoke test: run bootstrap.sh in an isolated copy and assert the result.
# Deterministic (uses --brain none, no network). If an AgentBrain is available it
# additionally checks version stamping + the version contract.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
assert() { if eval "$2"; then echo "  OK:   $1"; else echo "  FAIL: $1"; fail=1; fi; }

make_skeleton() {
    local dst="$1"
    cp -r "$REPO/.ai" "$dst/.ai"
    rm -f "$dst/.ai/.bootstrapped"
    cp "$REPO/STATE.md" "$dst/" 2>/dev/null || true
    cp "$REPO/VERSION" "$dst/" 2>/dev/null || true
    cp "$REPO/.env.example" "$dst/" 2>/dev/null || true
    git -C "$dst" init -q
    git -C "$dst" config user.email t@example.com
    git -C "$dst" config user.name tester
}

# ---------------------------------------------------------------------------
echo "--- bootstrap --brain none ---"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp" "${tmp2:-}"' EXIT
make_skeleton "$tmp"
( cd "$tmp" && bash .ai/scripts/bootstrap.sh --name "Boot_Test" --brain none >/dev/null )

assert "marker created"             "[[ -f '$tmp/.ai/.bootstrapped' ]]"
assert "docs/ created"              "[[ -d '$tmp/docs' ]]"
assert "data/sources/ created"      "[[ -d '$tmp/data/sources' ]]"
assert "SOURCES_LOG.md created"     "[[ -f '$tmp/data/SOURCES_LOG.md' ]]"
assert "pre-commit hook installed"  "[[ -f '$tmp/.git/hooks/pre-commit' ]]"
assert "name written to yaml"       "grep -q 'Boot_Test' '$tmp/.ai/config/project.yaml'"
assert "marker has brain=unknown"   "grep -q 'brain=unknown' '$tmp/.ai/.bootstrapped'"

# pre-commit hook must block a data/raw/ change
echo data > "$tmp/data/raw/x.txt"
( cd "$tmp" && git add -f data/raw/x.txt >/dev/null 2>&1 && git commit -q -m x >/dev/null 2>&1 )
rc=$?
assert "hook blocks data/raw commit" "[[ $rc -ne 0 ]]"

# ---------------------------------------------------------------------------
brain_path="${AGENTBRAIN_PATH:-$HOME/.agentbrain}"
if [[ -f "$brain_path/manifest.yaml" ]]; then
    echo "--- bootstrap --brain global (version stamping) ---"
    tmp2="$(mktemp -d)"
    make_skeleton "$tmp2"
    ( cd "$tmp2" && AGENTBRAIN_PATH="$brain_path" bash .ai/scripts/bootstrap.sh --name "Boot_Test2" --brain global >/dev/null )
    assert "agentbrain_version stamped" "grep -q 'agentbrain_version' '$tmp2/.ai/config/project.yaml'"
    assert "marker brain != unknown"    "[[ -f '$tmp2/.ai/.bootstrapped' ]] && ! grep -q 'brain=unknown' '$tmp2/.ai/.bootstrapped'"
else
    echo "--- skipping --brain global check (no AgentBrain at $brain_path) ---"
fi

if [[ $fail -ne 0 ]]; then
    echo "BOOTSTRAP TEST: FAILED"
else
    echo "BOOTSTRAP TEST: PASSED"
fi
exit $fail
