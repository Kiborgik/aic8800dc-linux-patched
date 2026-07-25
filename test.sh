#!/bin/bash

PACKAGE_NAME="aic8800dc"
PACKAGE_VERSION="6.4.3.0-patched.7"
KVER="$(uname -r)"
PASS=0
FAIL=0

ok()   { echo "  [OK]   $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
info() { echo "  [INFO] $1"; }

echo "##################################################"
echo "AIC8800DC DKMS installation test"
echo "Kernel: ${KVER}"
echo "##################################################"
echo ""

# --- 1. DKMS registration ---
echo "-- DKMS status --"
if command -v dkms &>/dev/null; then
    STATUS="$(dkms status -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" 2>/dev/null)"
    if echo "${STATUS}" | grep -q "installed"; then
        ok "DKMS shows '${PACKAGE_NAME}/${PACKAGE_VERSION}' as installed"
    elif echo "${STATUS}" | grep -q "built"; then
        fail "DKMS built but not installed. Run: sudo dkms install -m ${PACKAGE_NAME} -v ${PACKAGE_VERSION}"
    elif echo "${STATUS}" | grep -q "added"; then
        fail "DKMS added but not built. Run: sudo dkms build -m ${PACKAGE_NAME} -v ${PACKAGE_VERSION}"
    else
        fail "DKMS has no record of ${PACKAGE_NAME}/${PACKAGE_VERSION}. Run: sudo ./install.sh"
    fi
else
    fail "dkms command not found. Install dkms package first"
fi
echo ""

# --- 2. Module files on disk ---
echo "-- Installed .ko files --"
for mod in aic_load_fw aic8800_fdrv; do
    KO_PATH="$(find /lib/modules/${KVER} \
                -name "${mod}.ko"     -o \
                -name "${mod}.ko.xz"  -o \
                -name "${mod}.ko.zst" -o \
                -name "${mod}.ko.gz"  2>/dev/null | head -1)"
    if [ -n "${KO_PATH}" ]; then
        ok "${KO_PATH}"
    else
        fail "${mod}.ko not found under /lib/modules/${KVER}"
    fi
done
echo ""

# --- 3. modinfo ---
echo "-- Module metadata --"
for mod in aic_load_fw aic8800_fdrv; do
    if modinfo "${mod}" &>/dev/null; then
        VER="$(modinfo -F version "${mod}" 2>/dev/null || echo "n/a")"
        ok "${mod} (version: ${VER})"
    else
        fail "modinfo ${mod} failed. Module may not be installed"
    fi
done
echo ""

# --- 4. Loaded in kernel ---
echo "-- Loaded modules --"
for mod in aic_load_fw aic8800_fdrv; do
    if lsmod | grep -q "^${mod}"; then
        ok "${mod} is loaded"
    else
        info "${mod} is not currently loaded (normal if no device plugged in)"
    fi
done
echo ""

# --- 5. Firmware files ---
echo "-- Firmware --"
if [ -d /lib/firmware/aic8800DC ]; then
    COUNT="$(ls /lib/firmware/aic8800DC/*.bin 2>/dev/null | wc -l)"
    ok "/lib/firmware/aic8800DC/ exists (${COUNT} .bin files)"
else
    fail "/lib/firmware/aic8800DC/ not found. Firmware not installed"
fi
echo ""

# --- 6. udev rule ---
echo "-- udev rule --"
if [ -f /etc/udev/rules.d/aic.rules ]; then
    ok "/etc/udev/rules.d/aic.rules present"
else
    fail "/etc/udev/rules.d/aic.rules missing"
fi
echo ""

# --- 7. Auto-load on boot ---
echo "-- Boot auto-load --"
if [ -f /etc/modules-load.d/aic8800.conf ]; then
    ok "/etc/modules-load.d/aic8800.conf present"
else
    fail "/etc/modules-load.d/aic8800.conf missing. Modules won't load on boot"
fi
echo ""

# --- 8. AUTOINSTALL hook ---
echo "-- DKMS AUTOINSTALL hook --"
if [ -f /etc/kernel/postinst.d/dkms ]; then
    # Debian/Ubuntu: dpkg kernel post-install hook
    ok "/etc/kernel/postinst.d/dkms present (auto-rebuild on kernel update)"
elif [ -f /etc/kernel/postinst.d/dkms-autoinstall ]; then
    ok "/etc/kernel/postinst.d/dkms-autoinstall present"
elif [ -f /usr/lib/kernel/install.d/40-dkms.install ]; then
    # Fedora/RHEL: kernel-install hook
    ok "/usr/lib/kernel/install.d/40-dkms.install present (Fedora/RHEL auto-rebuild)"
elif find /etc/pacman.d/hooks/ -name '*dkms*' 2>/dev/null | grep -q .; then
    # Arch: pacman hook
    ok "pacman dkms hook present (Arch auto-rebuild)"
else
    info "No DKMS kernel hook found. AUTOINSTALL may not trigger automatically"
    info "Debian/Ubuntu: /etc/kernel/postinst.d/dkms (installed with dkms package)"
    info "Fedora:        /usr/lib/kernel/install.d/40-dkms.install"
    info "Arch:          /etc/pacman.d/hooks/"
fi
echo ""

# --- Summary ---
echo "##################################################"
echo "Result: ${PASS} passed, ${FAIL} failed"
if [ "${FAIL}" -eq 0 ]; then
    echo "Everything looks good!"
else
    echo "Fix the failures above, then re-run: sudo ./test.sh"
fi
echo ""
echo "To simulate a kernel upgrade rebuild:"
echo "  1. Install headers for another kernel version (use your distro's package manager)"
echo "  2. sudo dkms build -m ${PACKAGE_NAME} -v ${PACKAGE_VERSION} -k <new-version>"
echo "  3. dkms status"
echo "##################################################"
