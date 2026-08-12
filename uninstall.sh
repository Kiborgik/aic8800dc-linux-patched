#!/bin/bash

# No `set -e`: this is a best-effort cleanup. If `dkms remove` fails for
# one version we still want to remove the source trees, udev rule, and
# firmware. `set -u` is safe here though; it only catches typos in
# variable references, which would always be a bug.
set -u

PACKAGE_NAME="aic8800dc"

echo "##################################################"
echo "AIC8800DC Wi-Fi driver uninstaller"
echo "##################################################"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this script must be run as root (use sudo)" >&2
    exit 1
fi

# --- Unload modules ---
echo "[1/4] Unloading modules..."
modprobe -r aic8800_fdrv 2>/dev/null || true
modprobe -r aic_load_fw 2>/dev/null || true

# --- Remove DKMS registration(s) ---
# Remove every installed version of this package, not just one. Users
# who upgraded across patched.N revisions otherwise leave stale DKMS
# entries lingering in 'dkms status'.
echo "[2/4] Removing DKMS registrations..."
if command -v dkms &>/dev/null; then
    # Parse 'dkms status -m <pkg>' output. Two formats exist in the wild:
    #   dkms 3.x (Arch, Debian 12+, Ubuntu 24.04+, Fedora):
    #     aic8800dc/6.4.3.0-patched.2, 6.19.13-arch1-1, x86_64: installed
    #   dkms 2.x (Ubuntu 22.04 LTS, Debian 11, RHEL 8):
    #     aic8800dc, 6.4.3.0-patched.2, 6.5.0-21-generic, x86_64: installed
    #     aic8800dc, 6.4.3.0-patched.2: added
    # The two sed expressions cover both; the first matches the slash form
    # (3.x), the second the comma form (2.x).
    versions="$(dkms status -m "${PACKAGE_NAME}" 2>/dev/null \
                | sed -n \
                    -e "s@^${PACKAGE_NAME}/\([^,:]*\)[,:].*@\1@p" \
                    -e "s@^${PACKAGE_NAME}, \([^,:]*\)[,:].*@\1@p" \
                | sort -u)"
    if [ -n "${versions}" ]; then
        for v in ${versions}; do
            echo "  Removing ${PACKAGE_NAME}/${v}..."
            dkms remove -m "${PACKAGE_NAME}" -v "${v}" --all || true
        done
    else
        echo "  No DKMS registration found, skipping."
    fi
else
    echo "  dkms not installed, skipping."
fi

# --- Remove DKMS source trees ---
# Glob covers /usr/src/aic8800dc-* for every patched.N tree that an
# install.sh from any prior version has ever copied in. The prefix is
# a hardcoded constant unique to this package, so the glob cannot
# accidentally match anything else on the system. nullglob makes an
# unmatched glob expand to an empty array (instead of the literal
# pattern), so the rm only runs when there is actually something to
# remove. Each path is printed before deletion for an audit trail.
echo "[3/4] Removing DKMS source tree(s)..."
shopt -s nullglob
src_dirs=(/usr/src/${PACKAGE_NAME}-*)
shopt -u nullglob
if [ ${#src_dirs[@]} -gt 0 ]; then
    for d in "${src_dirs[@]}"; do
        echo "  removing ${d}"
    done
    rm -rf "${src_dirs[@]}"
else
    echo "  No source trees found, skipping."
fi

# --- Remove firmware, udev rule, auto-load config ---
echo "[4/4] Removing firmware and udev rules..."
rm -rf /lib/firmware/aic8800DC/
rm -f /etc/udev/rules.d/aic.rules
rm -f /etc/modules-load.d/aic8800.conf
udevadm control --reload

echo ""
echo "##################################################"
echo "Uninstallation complete."
echo "##################################################"
