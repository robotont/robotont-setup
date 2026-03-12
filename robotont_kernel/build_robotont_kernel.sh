#!/bin/bash
set -e

# Install cross-compiler toolchain
sudo apt update
sudo apt install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu flex bison build-essential bc libssl-dev libncurses-dev

KERNEL_VERSION="rpi-6.6.y"
TARBALL="linux-${KERNEL_VERSION}.tar.gz"
SRC_DIR="linux-${KERNEL_VERSION}"

# Download kernel source
if [ ! -f "$TARBALL" ] || { read -p "$TARBALL exists. Redownload? [y/N] " a && [[ "$a" =~ ^[Yy]$ ]]; }; then
    wget "https://github.com/raspberrypi/linux/archive/refs/heads/${KERNEL_VERSION}.tar.gz" -O "$TARBALL"
fi

# Extract kernel source
tar -xzf "$TARBALL"

cd "$SRC_DIR"

# Configure for cross-compilation
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2712_defconfig

# Build (use all your CPU cores)
time make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

# Install modules to a temporary directory
mkdir -p ../modules_out
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=../modules_out modules_install

echo ""
echo "Build complete!"
echo "Kernel image: $SRC_DIR/arch/arm64/boot/Image"
echo "DTBs: $SRC_DIR/arch/arm64/boot/dts/broadcom/*.dtb"
echo "Overlays: $SRC_DIR/arch/arm64/boot/dts/overlays/*.dtb*"
echo "Modules: modules_out/lib/modules/"
