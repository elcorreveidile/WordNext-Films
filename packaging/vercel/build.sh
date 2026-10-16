#!/usr/bin/env bash
# WordNext fork: build the browser version on Vercel (static output in dist/site).
# Installs Rust, the wasm target and the wasm-bindgen CLI at the crate's exact version.
set -euo pipefail

export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
export PATH="$CARGO_HOME/bin:$PATH"
if ! command -v rustup >/dev/null 2>&1; then
  curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal --default-toolchain stable
fi
rustup default stable
rustup target add wasm32-unknown-unknown
cargo --version

WB="$(sed -n 's/^const WASM_BINDGEN: &str = "\(.*\)";$/\1/p' xtask/src/main.rs)"
if ! { command -v wasm-bindgen >/dev/null && wasm-bindgen --version | grep -qF "$WB"; }; then
  # Prebuilt binary (fast); fall back to compiling it.
  mkdir -p "$CARGO_HOME/bin"
  if ! curl -fsSL "https://github.com/rustwasm/wasm-bindgen/releases/download/${WB}/wasm-bindgen-${WB}-x86_64-unknown-linux-musl.tar.gz" \
      | tar -xz -C "$CARGO_HOME/bin" --strip-components=1 "wasm-bindgen-${WB}-x86_64-unknown-linux-musl/wasm-bindgen"; then
    cargo install wasm-bindgen-cli --version "$WB" --locked
  fi
fi
wasm-bindgen --version

cargo xtask web
mkdir -p dist
rm -rf dist/web
cp -R target/web/dist dist/web
ls dist/web

# Landing page at /, the app at /app/ (see packaging/vercel/assemble.sh).
bash packaging/vercel/assemble.sh
