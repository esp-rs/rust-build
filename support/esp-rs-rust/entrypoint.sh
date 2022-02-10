#!/usr/bin/env bash
set -e

. $IDF_PATH/export.sh
. /opt/rust-export.sh
export LIBCLANG_PATH=/opt/.espressif/tools/xtensa-esp32-elf-clang/esp-13.0.0-20211203-aarch64-unknown-linux-gnu/xtensa-esp32-elf-clang/lib/
cat /etc/motd

exec "$@"
