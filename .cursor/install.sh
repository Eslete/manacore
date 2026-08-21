#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for the Mana Core Godot 4.7 project.
# Installs the system libraries Godot needs, the pinned Godot editor binary,
# then imports the project so it is ready to run.
set -euo pipefail

GODOT_VERSION="4.7.2-stable"
GODOT_BIN_NAME="Godot_v${GODOT_VERSION}_linux.x86_64"
GODOT_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}/${GODOT_BIN_NAME}.zip"
INSTALL_DIR="/opt/godot"
GODOT_BIN="${INSTALL_DIR}/${GODOT_BIN_NAME}"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. System libraries required to run the prebuilt Godot binary (idempotent).
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq --no-install-recommends \
  libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libxext6 \
  libgl1 libglu1-mesa libglx-mesa0 libgl1-mesa-dri mesa-vulkan-drivers \
  libfontconfig1 libfreetype6 libasound2t64 libpulse0 libudev1 \
  libxkbcommon0 libwayland-client0 libwayland-cursor0 libwayland-egl1 \
  libegl1 libdbus-1-3 unzip curl ca-certificates xvfb x11-utils fonts-noto-cjk

# 2. Pinned Godot editor/runtime (skip the download when already present).
if [ ! -x "${GODOT_BIN}" ]; then
  tmp="$(mktemp -d)"
  curl -fsSL -o "${tmp}/godot.zip" "${GODOT_URL}"
  sudo mkdir -p "${INSTALL_DIR}"
  sudo unzip -o "${tmp}/godot.zip" -d "${INSTALL_DIR}"
  sudo chmod +x "${GODOT_BIN}"
  rm -rf "${tmp}"
fi
sudo ln -sf "${GODOT_BIN}" /usr/local/bin/godot

# 3. Import project resources so scripts compile and the game is ready to run.
godot --headless --path "${PROJECT_DIR}" --import

echo "Mana Core environment ready. Run the game with: godot --path ${PROJECT_DIR}"
