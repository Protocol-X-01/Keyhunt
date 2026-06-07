#!/bin/bash
set -e

echo "=== Keyhunt — Build, Test & Push ==="
echo ""

cd "$(dirname "$0")"

# ── Build ────────────────────────────────────────────────────────────────
echo "[*] Building..."
make clean 2>/dev/null || true
make
echo "[+] Build OK"
echo ""

# ── Quick test ───────────────────────────────────────────────────────────
echo "[*] Running smoke test (bit 20, sequential)..."
timeout 5 ./keyhunt -m address -f tests/1to32.txt -b 20 -l compress -q -s 2 -t 1 2>&1 | grep -c 'Hit!' | xargs -I{} echo "[+] Found {} keys — sequential OK"

echo "[*] Running smoke test (bit 20, Feistel random)..."
timeout 5 ./keyhunt -m address -f tests/1to32.txt -b 20 -l compress -q -s 2 -t 1 -R 2>&1 | grep -c 'Hit!' | xargs -I{} echo "[+] Found {} keys — Feistel OK"
echo ""

# ── Git push ─────────────────────────────────────────────────────────────
echo "[*] Pushing to GitHub..."

if [ ! -d .git ]; then
    git init
    git remote add origin https://github.com/Protocol-X-01/Keyhunt.git
fi

git add -A
git commit -m "Fix critical bugs + Feistel permutation for true exhaustive random search

CRITICAL FIXES:
- reserve() -> resize() on 5 std::vector uses (UB)
- ETH endomorphism: wrong array for beta2 points (missed 1/3 of matches)
- exit(EXIT_FAILURE) -> exit(EXIT_SUCCESS) when all BSGS targets found
- Memory leaks: added delete grp in 7 thread functions

FEISTEL PERMUTATION (deck shuffle):
- Fixed init timing: was called before ranges set, domain always 0
- Fixed domain: permutes chunk indices (range/4G), not individual keys
- Made re-entrant for BSGS mode range re-setup
- Removed dead std::set<string> tracker code

HOUSEKEEPING:
- .gitignore added, committed .o files and binary removed
- CRLF -> LF line endings" 2>/dev/null || echo "[*] Nothing new to commit"

git push origin main
echo ""
echo "[+] Pushed to https://github.com/Protocol-X-01/Keyhunt"
echo "[+] Done."
