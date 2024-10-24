#!/usr/bin/env bash

cd c:
git clone --recursive --depth 1 --shallow-submodules https://github.com/esp-rs/rust.git r
cd r

python3 src/bootstrap/configure.py --experimental-targets=Xtensa --enable-extended --tools=clippy,cargo,rustfmt,rust-analyzer-proc-macro-srv,src --dist-compression-formats='xz' --host 'x86_64-pc-windows-gnu' --enable-lld

python3 x.py dist --stage 2
