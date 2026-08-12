# AIC8800DC Linux Driver (Patched)

[![6.12 LTS](https://github.com/Kiborgik/aic8800dc-linux-patched/actions/workflows/kernel-6.12-lts.yml/badge.svg)](https://github.com/Kiborgik/aic8800dc-linux-patched/actions/workflows/kernel-6.12-lts.yml)
[![6.18](https://github.com/Kiborgik/aic8800dc-linux-patched/actions/workflows/kernel-6.18.yml/badge.svg)](https://github.com/Kiborgik/aic8800dc-linux-patched/actions/workflows/kernel-6.18.yml)
[![7.1 stable](https://github.com/Kiborgik/aic8800dc-linux-patched/actions/workflows/kernel-7.1.yml/badge.svg)](https://github.com/Kiborgik/aic8800dc-linux-patched/actions/workflows/kernel-7.1.yml)
[![latest](https://github.com/Kiborgik/aic8800dc-linux-patched/actions/workflows/kernel-latest.yml/badge.svg)](https://github.com/Kiborgik/aic8800dc-linux-patched/actions/workflows/kernel-latest.yml)
[![mainline rc](https://github.com/Kiborgik/aic8800dc-linux-patched/actions/workflows/kernel-mainline-rc.yml/badge.svg)](https://github.com/Kiborgik/aic8800dc-linux-patched/actions/workflows/kernel-mainline-rc.yml)
[![scripts](https://github.com/Kiborgik/aic8800dc-linux-patched/actions/workflows/scripts.yml/badge.svg)](https://github.com/Kiborgik/aic8800dc-linux-patched/actions/workflows/scripts.yml)

Out-of-tree Linux driver for the AIC8800DC USB Wi-Fi chipset, based on
upstream 6.4.3.0 with compatibility fixes. DKMS-aware: rebuilds itself
on every kernel update.

## Install

```bash
# Debian / Ubuntu
sudo apt install dkms build-essential linux-headers-$(uname -r) eject

# Arch
sudo pacman -S dkms linux-headers base-devel eject

# Fedora
sudo dnf install dkms kernel-devel kernel-headers eject
```

Then:

```bash
git clone https://github.com/Kiborgik/aic8800dc-linux-patched.git
cd aic8800dc-linux-patched
sudo ./install.sh
sudo ./test.sh   # optional sanity check
```

## Update

`git pull` + reinstall in one step (run as your normal user, not sudo):

```bash
./update.sh
```

## Uninstall

```bash
sudo ./uninstall.sh
```

## Troubleshooting

**Driver loads but no `wlan0` appears.** The dongle is probably stuck in
USB mass-storage mode (VID:PID `a69c:5721`). The udev rule in
`tools/aic.rules` runs `eject` to flip it into Wi-Fi mode; if `eject`
isn't installed or the dongle enumerates as a CD-ROM (`sr0` instead of
`sd*`), nothing happens. Manual fix:

```bash
sudo apt install usb-modeswitch
sudo usb_modeswitch -v a69c -p 5721 -KQ
# wait a few seconds, then:
ip link show
dmesg | tail -30
```

**Secure Boot.** The .ko must be signed for Secure Boot to load it. See
your distro's MOK (Machine Owner Key) docs.

**Kernel hang or no boot after install.** This driver is tested on
x86_64 and arm64. Untested platforms (ARMv7 32-bit, single-core, exotic
embedded boards) may hang during firmware download or USB enumeration.
Capture logs over a serial console or `journalctl -k -b -1` and open an
issue.

## Manual / cross-compile build

```bash
cd drivers/aic8800
make
sudo make install
sudo depmod -a
sudo modprobe aic_load_fw aic8800_fdrv
```

For Rockchip / Allwinner / Amlogic, set the platform variables in
`drivers/aic8800/Makefile` before building.

## Build for another kernel without rebooting

```bash
sudo dkms build -m aic8800dc -v 6.4.3.0-patched.9 -k <other-version>
dkms status
```
