FROM espressif/idf

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV RUSTUP_HOME=/opt/rustup
ENV CARGO_HOME=/opt/cargo
ENV PATH=/opt/cargo/bin:/opt/rustup/bin:/opt/esp/tools/xtensa-esp32-elf-clang/esp-14.0.0-20220415-x86_64-unknown-linux-gnu/bin/:$PATH

WORKDIR /opt

COPY install-rust-toolchain.sh .
RUN ./install-rust-toolchain.sh
