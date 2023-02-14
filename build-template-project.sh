set -ef

curl -L "https://github.com/cargo-generate/cargo-generate/releases/latest/download/cargo-generate-$(git ls-remote --refs --sort="version:refname" --tags "https://github.com/cargo-generate/cargo-generate" | cut -d/ -f3- | tail -n1)-aarch64-unknown-linux-gnu.tar.gz" -o "${HOME}/.cargo/bin/cargo-generate.tar.gz"
tar -xzvf "${HOME}/.cargo/bin/cargo-generate.tar.gz" -C ${HOME}/.cargo/bin
chmod u+x ${HOME}/.cargo/bin/cargo-generate
rm LICENSE-APACHE LICENSE-MIT README.md

export USER=esp
source /home/esp/export-esp.sh
if [[ "$1" == 'esp-idf-template' ]]; then
    cargo generate --git https://github.com/esp-rs/esp-idf-template cargo --name test-$2 --vcs none --silent -d mcu=$2 -d std=true -d espidfver=$3 -d devcontainer=false
elif [[ "$1" == 'esp-template' ]]; then
    cargo generate --git https://github.com/esp-rs/esp-template --name test-$2 --vcs none --silent -d mcu=$2 -d devcontainer=false -d alloc=false
fi
cd test-$2
cargo build
