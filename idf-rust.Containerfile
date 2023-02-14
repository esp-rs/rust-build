ARG VARIANT=bullseye-slim
FROM debian:${VARIANT}
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Arguments
ARG CONTAINER_USER=esp
ARG CONTAINER_GROUP=esp
ARG ESP_BOARD=esp32,esp32s2,esp32s3,esp32c3
ARG GITHUB_TOKEN

# Install dependencies
RUN apt-get update \
    && apt-get install -y git curl gcc clang ninja-build unzip libudev-dev tar xz-utils \
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
    chmod u+x "${HOME}/.cargo/bin/espup" && \
    curl -L "https://github.com/bjoernQ/esp-web-flash-server/releases/latest/download/web-flash-${ARCH}.zip" -o "${HOME}/.cargo/bin/web-flash.zip" && \
    unzip "${HOME}/.cargo/bin/web-flash.zip" -d "${HOME}/.cargo/bin/" && \
    rm "${HOME}/.cargo/bin/web-flash.zip" && \
    chmod u+x "${HOME}/.cargo/bin/web-flash"

# Install Xtensa Rust
RUN if [ -n "${GITHUB_TOKEN}" ]; then export GITHUB_TOKEN=${GITHUB_TOKEN}; fi  \
    && ${HOME}/.cargo/bin/espup install\
    --targets "${ESP_BOARD}" \
    --log-level debug \
    --profile-minimal \
    --export-file /home/${CONTAINER_USER}/export-esp.sh

# Activate ESP environment
RUN echo "source /home/${CONTAINER_USER}/export-esp.sh" >> ~/.bashrc

# Set default toolchain
RUN if [ "${ESP_BOARD}" = "all" ] || echo "$ESP_BOARD" | grep -q "esp32c3"; then \
    rustup default nightly; \
    rustup component add rust-src; \
    else \
    rustup default esp; \
    fi

CMD [ "/bin/bash" ]