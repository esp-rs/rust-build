#!/usr/bin/env bash

set -e

git clone --recursive --depth 1 --shallow-submodules https://github.com/esp-rs/rust.git
cd rust
python3 src/bootstrap/configure.py --experimental-targets=Xtensa --enable-extended --tools=clippy,cargo,rustfmt --dist-compression-formats='xz'
python3 x.py dist --stage 2

