#!/bin/bash

_dir=repos
if [ ! -d $_dir ]; then
  mkdir $_dir
fi
cd $_dir

git clone https://salsa.debian.org/chromium-team/chromium.git \
  debian-chromium \
  --branch debian/$RULES_deb_chromium_ver

git clone https://gitlab.archlinux.org/archlinux/packaging/packages/electron$RULES_electron_ver_major.git \
  archlinux-electron$RULES_electron_ver_major

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

git clone https://github.com/riscv-forks/electron.git \
  --branch v$RULES_electron_ver-riscv

git clone https://github.com/chromium/chromium chromium \
  --branch $RULES_chromium_ver --depth=2
