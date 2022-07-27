#!/usr/bin/env bash

pacman -Sy pacman-mirrors

pacman -S git \
            make \
            diffutils \
            tar \
            mingw-w64-x86_64-python \
            mingw-w64-x86_64-cmake \
            mingw-w64-x86_64-gcc \
            mingw-w64-x86_64-ninja
