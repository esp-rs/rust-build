set -ef

cargo install cargo-generate

export USER=esp
source /home/esp/export-esp.sh
if [[ "$1" == 'esp-idf-template' ]]; then
    cargo generate --git https://github.com/esp-rs/esp-idf-template cargo --name test-$2 --vcs none --silent -d mcu=$2 -d std=true -d espidfver=$3 -d devcontainer=false
elif [[ "$1" == 'esp-template' ]]; then
    cargo generate --git https://github.com/esp-rs/esp-template --name test-$2 --vcs none --silent -d mcu=$2 -d devcontainer=false -d alloc=false
fi
cd test-$2
cargo build
