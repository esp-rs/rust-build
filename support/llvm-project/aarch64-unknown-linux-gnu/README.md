Build of llvm-project for Linux aarch64

- requires 8 GB of memory

Steps

```
podman build -t xtensa-builder .
podman run -it xtensa-builder /bin/bash
build-toolchain-linux.sh

