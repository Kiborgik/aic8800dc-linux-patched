#!/bin/bash

# Bail on any error AND on any unset variable. The latter guards against a
# future edit that accidentally blanks PACKAGE_VERSION/SRC_DIR/etc., which
# would otherwise let `rm -rf "${SRC_DIR}"` expand to a wrong path.
set -eu

PACKAGE_NAME="aic8800dc"
PACKAGE_VERSION="6.4.3.0-patched.8"
SRC_DIR="/usr/src/${PACKAGE_NAME}-${PACKAGE_VERSION}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "##################################################"
echo "AIC8800DC Wi-Fi driver installer"
echo "Version: ${PACKAGE_VERSION}"
echo "##################################################"

# Check for root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this script must be run as root (use sudo)" >&2
    exit 1
fi

# Check dependencies. `eject` is needed by tools/aic.rules to flip dongles
# out of USB mass-storage mode on first plug; without it the device stays
# at VID:PID a69c:5721 and the Wi-Fi PID never appears.
for cmd in dkms make depmod eject; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: '$cmd' is not installed." >&2
        echo ""
        echo "Install dependencies first:"
        echo "  Ubuntu/Debian: sudo apt install dkms build-essential linux-headers-\$(uname -r) eject"
        echo "  (if not found): sudo apt install dkms build-essential linux-headers-generic eject"
        echo "  Arch:          sudo pacman -S dkms linux-headers base-devel eject"
        echo "  Fedora:        sudo dnf install dkms kernel-devel kernel-headers eject"
        exit 1
    fi
done

# Check kernel headers are present for the running kernel
if [ ! -d "/lib/modules/$(uname -r)/build" ]; then
    echo "Error: kernel headers not found for $(uname -r)" >&2
    echo "  Ubuntu/Debian: sudo apt install linux-headers-\$(uname -r)" >&2
    echo "  (if not found): sudo apt install linux-headers-generic" >&2
    echo "  Fedora:        sudo dnf install kernel-devel-\$(uname -r)" >&2
    echo "  Arch:          sudo pacman -S linux-headers" >&2
    exit 1
fi

# --- Firmware and udev rules ---
echo "[1/5] Installing firmware and udev rules..."
# create if missing (containers/CI) so cp nests aic8800DC/ instead of its files
mkdir -p /lib/firmware
cp -rf "${SCRIPT_DIR}/fw/aic8800DC" /lib/firmware/
cp "${SCRIPT_DIR}/tools/aic.rules" /etc/udev/rules.d/
# Reload first so the daemon picks up the new aic.rules, then trigger so
# already-attached devices re-evaluate against the new rules. Doing it the
# other way round fires the trigger with stale rules.
udevadm control --reload
udevadm trigger
if [ -L /dev/aicudisk ]; then
    eject /dev/aicudisk || true
fi

# --- Prepare DKMS source tree ---
# Remove every previously registered version (not just the same version)
# before installing the new one. Otherwise upgrading patched.1 -> patched.2
# leaves the old DKMS entry, source tree, and .ko lingering on disk.
# Parsing covers both dkms 3.x ('aic8800dc/<ver>, ...') and dkms 2.x
# ('aic8800dc, <ver>, ...') output formats; same regex pair as uninstall.sh.
echo "[2/5] Preparing DKMS source tree..."
old_versions="$(dkms status -m "${PACKAGE_NAME}" 2>/dev/null \
                | sed -n \
                    -e "s@^${PACKAGE_NAME}/\([^,:]*\)[,:].*@\1@p" \
                    -e "s@^${PACKAGE_NAME}, \([^,:]*\)[,:].*@\1@p" \
                | sort -u)"
if [ -n "${old_versions}" ]; then
    for v in ${old_versions}; do
        echo "  Removing existing DKMS registration ${PACKAGE_NAME}/${v}..."
        dkms remove -m "${PACKAGE_NAME}" -v "${v}" --all || true
    done
fi
# Glob-clean any orphan source trees too, including the about-to-be-recreated
# one. nullglob makes the array empty (rather than the literal pattern) when
# nothing matches.
shopt -s nullglob
old_src_dirs=(/usr/src/${PACKAGE_NAME}-*)
shopt -u nullglob
if [ ${#old_src_dirs[@]} -gt 0 ]; then
    rm -rf "${old_src_dirs[@]}"
fi
mkdir -p "${SRC_DIR}"
cp -rp "${SCRIPT_DIR}/." "${SRC_DIR}/"

# --- DKMS add / build / install ---
echo "[3/5] Registering with DKMS..."
dkms add -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"

echo "[4/5] Building kernel modules (this may take a minute)..."
dkms build -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"

echo "[5/5] Installing kernel modules..."
dkms install -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"

# --- Auto-load on boot ---
tee /etc/modules-load.d/aic8800.conf > /dev/null <<EOF
aic_load_fw
aic8800_fdrv
EOF

# --- Load now ---
echo ""
echo "Loading modules..."
modprobe aic_load_fw || echo "  Note: aic_load_fw not loaded (plug in the device and run: sudo modprobe aic_load_fw)"
modprobe aic8800_fdrv || echo "  Note: aic8800_fdrv not loaded (plug in the device and run: sudo modprobe aic8800_fdrv)"

echo ""
echo "##################################################"
echo "Installation complete!"
echo ""
echo "To verify:  sudo ./test.sh"
echo "To remove:  sudo ./uninstall.sh"
echo "##################################################"
