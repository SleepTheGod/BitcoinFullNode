#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

################################################################################
#                         TCrYpT Full Node + Pool Setup
#                   Made by Taylor Christian Newsome (c) 2025
################################################################################

# === ENVIRONMENT SETUP ===
BITCOIN_VERSION="27.1"
BITCOIN_DIR="$HOME/bitcoin-core"
MINER_DIR="/media/n/Ventoy/TCrYpT"
MINER_LOGDIR="$MINER_DIR/logs"
MINER_CONF="$MINER_DIR/TCrYpT.conf"
MINER_BIN="TCrYpT"
CKPOOL_REPO="https://bitbucket.org/ckolivas/ckpool.git"

echo -e "\n\033[1;36m=== TCrYpT Full Node + Mining Pool Installer ===\033[0m"
echo "Made by Taylor Christian Newsome"

# === FUNCTIONS ===

install_bitcoin_core() {
    echo "[*] Installing Bitcoin Core..."
    curl -sSL https://bitnodes.io/install-full-node.sh | bash
}

build_tcrypt_miner() {
    echo "[*] Setting up TCrYpT mining pool software..."

    # Ensure clean workspace
    mkdir -p "$MINER_DIR"
    cd "$MINER_DIR"
    rm -rf src
    git clone "$CKPOOL_REPO" src
    cd src

    echo "[*] Generating configure script..."
    autoreconf -i
    [[ -f configure ]] || { echo "[-] Failed to generate configure script."; exit 1; }

    echo "[*] Applying TCrYpT branding..."
    find . -type f \( -name "*.c" -o -name "*.h" \) -exec sed -i \
        -e 's/"ckpool"/"TCrYpT"/g' \
        -e 's/"ckpool /"TCrYpT /g' {} +

    echo "[*] Building TCrYpT..."
    ./configure --without-ckdb --program-prefix=""
    make clean && make -j"$(nproc)"

    [[ -f ckpool ]] || { echo "[-] Build failed: binary not found."; exit 1; }
    mv ckpool "$MINER_DIR/$MINER_BIN"
    chmod +x "$MINER_DIR/$MINER_BIN"
    echo "[+] Built miner: $MINER_BIN"
}

generate_miner_conf() {
    echo "[*] Creating TCrYpT config file..."
    mkdir -p "$MINER_LOGDIR"
    cat > "$MINER_CONF" <<EOF
{
  "btcd": [
    {
      "url": "127.0.0.1:8332",
      "auth": "rpcuser",
      "pass": "rpcpassword",
      "notify": true
    }
  ],
  "btcaddress": "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
  "serverurl": ["0.0.0.0:3333"],
  "logdir": "$MINER_LOGDIR"
}
EOF
    echo "[+] Config saved to $MINER_CONF"
}

validate_bitcoin_node() {
    echo "[*] Validating Bitcoin node..."
    if ! "$BITCOIN_DIR/bin/bitcoin-cli" -conf="$BITCOIN_DIR/.bitcoin/bitcoin.conf" getblockchaininfo >/dev/null 2>&1; then
        echo "[!] Bitcoin node not responsive. Attempting restart..."
        "$BITCOIN_DIR/bin/start.sh"
        sleep 10
    fi
}

start_tcrypt() {
    echo "[*] Launching TCrYpT in background..."
    cd "$MINER_DIR"
    ./"$MINER_BIN" -c "$MINER_CONF" &
    sleep 2
    echo "[+] TCrYpT launched. Monitor logs using:"
    echo "    tail -f $MINER_LOGDIR/ckpool.log"
    echo "    To stop: pkill -f $MINER_BIN"
}

# === EXECUTION FLOW ===

install_bitcoin_core
build_tcrypt_miner
generate_miner_conf
validate_bitcoin_node
start_tcrypt

echo -e "\n\033[1;32m=== Installation Complete ===\033[0m"
echo "Bitcoin Full Node and TCrYpT mining pool are now running."
echo -e "Made by \033[1;35mTaylor Christian Newsome\033[0m"
