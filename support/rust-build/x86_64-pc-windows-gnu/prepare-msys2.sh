#!/usr/bin/env bash

pacman -Sy pacman-mirrors

# Warning! Do not install git from MinGW-w64, it will break the build in rustbuild step.
# Affected version Rust 1.66.0, previous versions are not affected.

pacman -S \
            make \
            diffutils \
            tar \
            mingw-w64-x86_64-python \
            mingw-w64-x86_64-cmake \
            mingw-w64-x86_64-gcc \
            mingw-w64-x86_64-ninja
