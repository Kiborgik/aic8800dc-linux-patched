#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "##################################################"
echo "AIC8800DC Wi-Fi driver updater"
echo "##################################################"

# Refuse root: running 'git pull' as root mixes root-owned files into
# .git and breaks later regular-user git operations. The install step
# below elevates via sudo on its own, so update.sh itself does not
# need root.
if [ "$(id -u)" -eq 0 ]; then
    echo "Error: do not run this script with sudo." >&2
    echo "  Run it as your regular user; install.sh will be sudo'd internally." >&2
    exit 1
fi

# Check dependencies
if ! command -v git &>/dev/null; then
    echo "Error: 'git' is not installed." >&2
    echo ""
    echo "Install dependencies first:"
    echo "  Ubuntu/Debian: sudo apt install git"
    echo "  Arch:          sudo pacman -S git"
    echo "  Fedora:        sudo dnf install git"
    exit 1
fi

# Verify we're inside a git checkout (handles both .git dirs and
# worktree .git files).
if ! git -C "${SCRIPT_DIR}" rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: ${SCRIPT_DIR} is not a git checkout." >&2
    echo "  This script pulls upstream changes; it requires the repo to" >&2
    echo "  have been obtained via 'git clone', not as a tarball download." >&2
    exit 1
fi

if [ ! -x "${SCRIPT_DIR}/install.sh" ]; then
    echo "Error: ${SCRIPT_DIR}/install.sh not found or not executable." >&2
    exit 1
fi

cd "${SCRIPT_DIR}"

# Refuse if the working tree has uncommitted changes. A pull could
# overwrite or conflict with local edits.
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Error: working tree has uncommitted changes." >&2
    echo "  Commit, stash, or discard local changes before running update." >&2
    echo "" >&2
    echo "Files with changes:" >&2
    git status --short >&2
    exit 1
fi

OLD_HEAD="$(git rev-parse HEAD)"

echo "[1/2] Pulling latest changes from upstream..."
if ! git pull --ff-only; then
    echo "" >&2
    echo "Error: git pull failed (likely non-fast-forward)." >&2
    echo "  Your local branch has diverged from upstream." >&2
    echo "  Inspect with 'git status' / 'git log' and resolve manually." >&2
    exit 1
fi

NEW_HEAD="$(git rev-parse HEAD)"

if [ "${OLD_HEAD}" = "${NEW_HEAD}" ]; then
    echo ""
    echo "##################################################"
    echo "Already up to date. Nothing to install."
    echo "##################################################"
    exit 0
fi

echo "[2/2] Reinstalling driver via DKMS (sudo will prompt for password)..."
echo "      ${OLD_HEAD:0:12} -> ${NEW_HEAD:0:12}"
sudo "${SCRIPT_DIR}/install.sh"

echo ""
echo "##################################################"
echo "Update complete."
echo ""
echo "To verify:  sudo ./test.sh"
echo "##################################################"
