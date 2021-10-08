FROM espressif/idf-rust

# Some tools to make life with examples easier
RUN apt update \
    && apt install -y vim nano

# Requirement for Cargo-first example
RUN rustup install stable \
    && rustup default stable \
    && rustup component add rustfmt

# Dependency for Cargo-first example
RUN cargo install cargo-pio ldproxy espflash

COPY entrypoint.sh /opt/esp/entrypoint.sh
COPY motd /etc/motd

# Add repositories with examples
RUN if [ ! -e /opt/rust-esp32-example ]; then git clone https://github.com/espressif/rust-esp32-example.git /opt/rust-esp32-example; fi \
    && git clone https://github.com/ivmarkov/rust-esp32-std-hello.git /opt/rust-esp32-std-hello

# Test builds
RUN cd /opt/rust-esp32-example \
    && . $IDF_PATH/export.sh \
    && idf.py build \
    && idf.py fullclean

RUN cd /opt/rust-esp32-std-hello \
    && cargo +esp build \
    && cargo clean

WORKDIR /opt/

