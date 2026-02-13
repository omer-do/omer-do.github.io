#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

cd "$(git rev-parse --show-toplevel)"

echo "=== Hugo sanity check ==="
echo ""

echo "[1/6] Hugo installed"
if command -v hugo &>/dev/null; then
    pass "hugo found ($(hugo version 2>/dev/null | head -c 60))"
else
    fail "hugo not found on PATH"
    echo "Aborting — cannot continue without hugo."
    exit 1
fi

echo "[2/6] Theme present"
if [ -d "themes/PaperMod/layouts" ]; then
    pass "themes/PaperMod is initialized"
else
    fail "themes/PaperMod missing or empty — run: git submodule update --init --recursive"
fi

echo "[3/6] Clean build"
rm -rf public
BUILD_OUTPUT=$(hugo 2>&1) || true
if echo "$BUILD_OUTPUT" | grep -q "Total in" && ! echo "$BUILD_OUTPUT" | grep -qi "^ERROR"; then
    PAGE_COUNT=$(echo "$BUILD_OUTPUT" | grep "Pages" | head -1 | awk '{print $3}')
    pass "build succeeded (${PAGE_COUNT} pages)"
else
    fail "build failed"
    echo "$BUILD_OUTPUT"
    echo "Aborting — cannot validate output without a successful build."
    exit 1
fi

echo "[4/6] Expected pages rendered"
EXPECTED_PATHS=(
    "public/index.html"
    "public/posts/index.html"
    "public/tags/index.html"
    "public/categories/index.html"
    "public/series/index.html"
    "public/archives/index.html"
    "public/about/index.html"
)
for p in "${EXPECTED_PATHS[@]}"; do
    if [ -f "$p" ]; then
        pass "$p"
    else
        fail "$p missing"
    fi
done

echo "[5/6] Image references"
BROKEN_IMAGES=0
for post in content/posts/*.md; do
    while IFS= read -r img_ref; do
        img_path=$(echo "$img_ref" | tr -d '\r' | sed -n 's|.*\(/img/[^)"]*\).*|\1|p' | tr -d '"' | tr -d ' ')
        if [ -n "$img_path" ] && [ ! -f "static${img_path}" ]; then
            fail "$(basename "$post") references ${img_path} — not found"
            BROKEN_IMAGES=$((BROKEN_IMAGES + 1))
        fi
    done < <(grep '/img/' "$post" 2>/dev/null || true)
done
if [ "$BROKEN_IMAGES" -eq 0 ]; then
    pass "all image references resolve"
fi

echo "[6/6] Front matter lint"
REQUIRED_FIELDS=("title" "date" "categories" "tags" "summary")
LINT_CLEAN=true
for post in content/posts/*.md; do
    frontmatter=$(tr -d '\r' < "$post" | awk '/^---$/{if(++n==2)exit}n==1')
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! echo "$frontmatter" | grep -q "^${field}:"; then
            fail "$(basename "$post") missing field: ${field}"
            LINT_CLEAN=false
        fi
    done
done
if [ "$LINT_CLEAN" = true ]; then
    pass "all posts have required front matter"
fi

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
