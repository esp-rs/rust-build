# Base image
ARG VARIANT=bullseye-slim
FROM debian:${VARIANT}
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
# Arguments
ARG CONTAINER_USER=esp
ARG CONTAINER_GROUP=esp
ARG NIGHTLY_TOOLCHAIN_VERSION=nightly
ARG XTENSA_TOOLCHAIN_VERSION=1.65.0.1
ARG ESP_IDF_VERSION=""
ARG ESP_BOARD=esp32,esp32s2,esp32s3
ARG HOST_TRIPLE=x86_64-unknown-linux-gnu

# Install dependencies
RUN apt-get update \
    && apt-get install -y git curl gcc clang ninja-build libudev-dev unzip xz-utils \
    python3 python3-pip python3-venv libusb-1.0-0 libssl-dev pkg-config libtinfo5  libpython2.7 \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts
# Set user
RUN adduser --disabled-password --gecos "" ${CONTAINER_USER}
USER ${CONTAINER_USER}
WORKDIR /home/${CONTAINER_USER}
# Install rust toolchain(s), extra crates and esp-idf.
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH=${PATH}:/home/${CONTAINER_USER}/.cargo/bin
# ADD --chown=${CONTAINER_USER}:${CONTAINER_GROUP} \
#     https://github.com/esp-rs/espup/releases/latest/download/espup-${HOST_TRIPLE} \
#     espup
# RUN chmod a+x espup \
#     && ./espup install \
RUN cargo install espup
RUN espup install \
    --extra-crates "ldproxy" \
    --targets "${ESP_BOARD}" \
    --nightly-version "${NIGHTLY_TOOLCHAIN_VERSION}" \
    --esp-idf-version "${ESP_IDF_VERSION}" \
    --profile-minimal \
    --toolchain-version "${XTENSA_TOOLCHAIN_VERSION}" \
    --export-file  ${HOME}/export-esp.sh

# Activate ESP-IDF and Xtensa Rust toolchain environment
RUN echo "source ${HOME}/export-esp.sh" >> ~/.bashrc
