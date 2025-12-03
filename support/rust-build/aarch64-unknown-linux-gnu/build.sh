#!/usr/bin/env bash

set -e

git clone --recursive --depth 1 --shallow-submodules https://github.com/esp-rs/rust.git -b "esp-${RELEASE_VERSION}"
cd rust
python3 src/bootstrap/configure.py --experimental-targets=Xtensa --release-channel=nightly --release-description="${RELEASE_VERSION}" --enable-extended --enable-cargo-native-static --tools=rustdoc,clippy,cargo,rustfmt,rust-analyzer-proc-macro-srv,src --dist-compression-formats='xz' --enable-lld

python3 x.py dist --stage 2
