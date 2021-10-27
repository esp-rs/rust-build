FROM espressif/idf-rust

# Some tools to make life with examples easier
RUN apt update \
    && apt install -y vim nano

COPY entrypoint.sh /opt/esp/entrypoint.sh
COPY motd /etc/motd

# Add repositories with examples
RUN if [ ! -e /opt/rust-esp32-example ]; then git clone https://github.com/espressif/rust-esp32-example.git /opt/rust-esp32-example; fi \
    && git clone https://github.com/ivmarkov/rust-esp32-std-demo.git /opt/rust-esp32-std-demo

# Test builds
RUN cd /opt/rust-esp32-example \
    && . $IDF_PATH/export.sh \
    && idf.py build \
    && idf.py fullclean

ENV RUST_ESP32_STD_DEMO_WIFI_SSID=rust
ENV RUST_ESP32_STD_DEMO_WIFI_PASS=for-esp32

RUN cd /opt/rust-esp32-std-demo \
    && cargo +esp build \
    && cargo clean

WORKDIR /opt/

