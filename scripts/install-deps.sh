#!/usr/bin/env bash
set -euo pipefail

echo "Installing ARM64 host tools and amd64 runtime/cross-build dependencies..."

sudo dpkg --add-architecture amd64
sudo apt-get update

gtk_pkg="libgtk-3-0:amd64"
if apt-cache show libgtk-3-0t64:amd64 >/dev/null 2>&1; then
  gtk_pkg="libgtk-3-0t64:amd64"
fi

sudo apt-get install -y --no-install-recommends \
  ca-certificates \
  file \
  binutils \
  gcc \
  g++ \
  make \
  tar \
  unzip \
  xz-utils \
  gcc-x86-64-linux-gnu \
  g++-x86-64-linux-gnu \
  libc6:amd64 \
  libc6-dev:amd64 \
  libstdc++6:amd64 \
  zlib1g:amd64 \
  libncurses6:amd64 \
  libtinfo6:amd64 \
  libxrender1:amd64 \
  libxtst6:amd64 \
  libxi6:amd64 \
  libxinerama1:amd64 \
  libxss1:amd64 \
  libxft2:amd64 \
  "$gtk_pkg"

echo "Dependencies installed."
