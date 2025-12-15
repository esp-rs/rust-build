#!/usr/bin/env bash

set -e

git clone --recursive --depth 1 --shallow-submodules https://github.com/esp-rs/rust.git -b "esp-${RELEASE_VERSION}"
cd rust
# TODO
# this doesn't work in the docker container when the host is ARM64, it fails at the documentation stage, which can be skipped with `--disable-docs`
# however, at the time of writing this disables rustdoc tool creation, which we need in the toolchain. Until this is fixed, we can just build on an x86_64 host.
python3 src/bootstrap/configure.py --experimental-targets=Xtensa --release-channel=nightly --release-description="${RELEASE_VERSION}" --enable-extended --enable-cargo-native-static --tools=rustdoc,clippy,cargo,rustfmt,rust-analyzer-proc-macro-srv,src --dist-compression-formats='xz' --enable-lld --host x86_64-unknown-linux-gnu
python3 x.py dist --stage 2