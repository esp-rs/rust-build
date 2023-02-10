ARG VARIANT=bullseye-slim
FROM debian:${VARIANT}
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Arguments
ARG CONTAINER_USER=esp
ARG CONTAINER_GROUP=esp
ARG ESP_BOARD=esp32
ARG GITHUB_TOKEN

# Install dependencies
# TODO: Update dependencies
RUN apt-get update \
    && apt-get install -y git curl gcc clang ninja-build libudev-dev tar xz-utils \
    python3 python3-pip python3-venv libusb-1.0-0 libssl-dev pkg-config libtinfo5  libpython2.7 \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

# Set users
RUN adduser --disabled-password --gecos "" ${CONTAINER_USER}
USER ${CONTAINER_USER}
WORKDIR /home/${CONTAINER_USER}

# Install rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    --default-toolchain none -y --profile minimal

# Update envs
ENV PATH=${PATH}:/home/${CONTAINER_USER}/.cargo/bin

# Install extra crates
RUN ARCH=$($HOME/.cargo/bin/rustup show | grep "Default host" | sed -e 's/.* //') && \
    curl -L "https://github.com/esp-rs/espup/releases/latest/download/espup-${ARCH}" -o "${HOME}/.cargo/bin/espup" && \
    chmod u+x "${HOME}/.cargo/bin/espup"

RUN ${HOME}/.cargo/bin/cargo +esp install web-flash --git https://github.com/bjoernQ/esp-web-flash-server

# Install Xtensa Rust
RUN if [ -n "${GITHUB_TOKEN}" ]; then export GITHUB_TOKEN=${GITHUB_TOKEN}; fi  \
    && ${HOME}/.cargo/bin/espup install\
    --targets "${ESP_BOARD}" \
    --log-level debug \
    --profile-minimal \
    --export-file /home/${CONTAINER_USER}/export-esp.sh

# Activate ESP environment
RUN echo "source /home/${CONTAINER_USER}/export-esp.sh" >> ~/.bashrc

# Install and add to PATH linker for esp32s2
RUN curl -L "https://github.com/espressif/crosstool-NG/releases/latest/download/xtensa-esp32s2-elf-gcc11_2_0-esp-2022r1-linux-arm64.tar.xz" -o "${HOME}/linker_s2.tar.xz" && \
    tar -xf "${HOME}/linker_s2.tar.xz" -C "${HOME}/.cargo/bin" && \
    rm "${HOME}/linker_s2.tar.xz"

ENV PATH=${PATH}:${HOME}/.cargo/bin/xtensa-esp32s2-elf/bin/

CMD [ "/bin/bash" ]