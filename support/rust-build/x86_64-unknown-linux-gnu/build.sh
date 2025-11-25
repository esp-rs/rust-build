#!/usr/bin/env bash

set -e

git clone --recursive --depth 1 --shallow-submodules https://github.com/esp-rs/rust.git -b "esp-${RELEASE_VERSION}"
cd rust
python3 src/bootstrap/configure.py --experimental-targets=Xtensa --release-channel=nightly --enable-extended --tools=rustdoc,clippy,cargo,rustfmt,rust-analyzer-proc-macro-srv,src --enable-lld --prefix $(pwd)/build/esp --sysconfdir $(pwd)/build/esp-etc --host x86_64-unknown-linux-gnu --target x86_64-unknown-linux-gnu --build aarch64-unknown-linux-gnu --disable-docs

python3 x.py dist
