#!/usr/bin/env bash
set -e

export PATH=$PATH:$HOME/.cargo/bin
#. $IDF_PATH/export.sh
. /home/rust/export-rust.sh
#export LIBCLANG_PATH=/opt/.espressif/tools/xtensa-esp32-elf-clang/esp-14.0.0-20220415-aarch64-unknown-linux-gnu/xtensa-esp32-elf-clang/lib/
cat /etc/motd

exec "$@"
