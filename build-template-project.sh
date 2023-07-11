set -ef

curl -L "https://github.com/cargo-generate/cargo-generate/releases/latest/download/cargo-generate-$(git ls-remote --refs --sort="version:refname" --tags "https://github.com/cargo-generate/cargo-generate" | cut -d/ -f3- | tail -n1)-$($HOME/.cargo/bin/rustup show | grep "Default host" | sed -e 's/.* //').tar.gz" -o "${HOME}/.cargo/bin/cargo-generate.tar.gz"
tar -xf "${HOME}/.cargo/bin/cargo-generate.tar.gz" -C ${HOME}/.cargo/bin
chmod u+x ${HOME}/.cargo/bin/cargo-generate

export USER=esp
source /home/esp/export-esp.sh

# Build esp-idf-template
cargo generate esp-rs/esp-idf-template cargo --name test-std-$1 --vcs none --silent -d mcu=$1 -d advanced=false
cd test-std-$1
cargo build
# Build esp-tempalte
cargo generate esp-rs/esp-template --name test-nostd-$1 --vcs none --silent -d mcu=$1 -d advanced=false
cd test-nostd-$1
cargo build
