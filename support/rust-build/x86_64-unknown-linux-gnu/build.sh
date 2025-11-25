#!/usr/bin/env bash

set -e

git clone --recursive --depth 1 --shallow-submodules https://github.com/esp-rs/rust.git -b "esp-${RELEASE_VERSION}"
cd rust
python3 src/bootstrap/configure.py configure --experimental-targets=Xtensa --release-channel=nightly --enable-extended --tools=rustdoc,clippy,cargo,rustfmt,rust-analyzer-proc-macro-srv,src --enable-lld --prefix $(pwd)/build/esp --sysconfdir $(pwd)/build/esp-etc --disable-docs

python3 x.py build
python3 x.py dist
