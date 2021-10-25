#!/bin/bash

./install-rust-toolchain.sh --export-file export-rust.sh
. ./export-rust.sh

RUST_DEMO="rust-esp32-std-demo"

if [ ! -d "" ]; then
    git clone https://github.com/ivmarkov/${RUST_DEMO}.git
fi

cd "${RUST_DEMO}"
cargo +esp build --target xtensa-esp32-espidf
