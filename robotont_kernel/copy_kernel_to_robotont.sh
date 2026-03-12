#!/bin/bash
set -e

# Find all built kernels
KERNELS=()
for dir in linux-rpi-*/; do
    if [ -f "$dir/arch/arm64/boot/Image" ]; then
        KERNELS+=("${dir%/}")
    fi
done

if [ ${#KERNELS[@]} -eq 0 ]; then
    echo "No built kernels found"
    exit 1
fi

echo "Select kernel to copy:"
for i in "${!KERNELS[@]}"; do
    echo "$((i+1))) ${KERNELS[$i]}"
done

read -p "Choice [1-${#KERNELS[@]}]: " choice

if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#KERNELS[@]} ]; then
    echo "Invalid choice"
    exit 1
fi

SRC_DIR="${KERNELS[$((choice-1))]}"

echo ""
echo "Select copy method:"
echo "1) SSH (network)"
echo "2) SD card (local)"
read -p "Choice [1-2]: " method

case $method in
    1)
        # SSH method
        read -p "Enter Robotont SSH address [robotont@robotont]: " PI_HOST
        PI_HOST="${PI_HOST:-robotont@robotont}"

        STAGING=$(mktemp -d)
        mkdir -p "$STAGING/boot/firmware/overlays"
        mkdir -p "$STAGING/lib/modules"

        cp "$SRC_DIR/arch/arm64/boot/Image" "$STAGING/boot/firmware/Image-imx500"
        cp $SRC_DIR/arch/arm64/boot/dts/broadcom/*.dtb "$STAGING/boot/firmware/"
        cp $SRC_DIR/arch/arm64/boot/dts/overlays/*.dtb* "$STAGING/boot/firmware/overlays/"
        cp -r modules_out/lib/modules/* "$STAGING/lib/modules/"

        SSH_SOCKET="/tmp/ssh-kernel-$$"
        cleanup() {
            ssh -S "$SSH_SOCKET" -o IdentitiesOnly=yes -O exit "$PI_HOST" 2>/dev/null || true
            rm -rf "$STAGING"
        }
        trap cleanup EXIT

        echo "Connecting..."
        ssh -M -S "$SSH_SOCKET" -o ControlPersist=60 -o IdentitiesOnly=yes -fN "$PI_HOST"

        echo "Copying kernel files..."
        tar -C "$STAGING" -cf - . | ssh -S "$SSH_SOCKET" "$PI_HOST" "mkdir -p /tmp/kernel_staging && tar -xf - -C /tmp/kernel_staging"

        echo "Installing kernel (sudo password required)..."
        ssh -t -S "$SSH_SOCKET" "$PI_HOST" '
            sudo cp /tmp/kernel_staging/boot/firmware/Image-imx500 /boot/firmware/ &&
            sudo cp /tmp/kernel_staging/boot/firmware/*.dtb /boot/firmware/ &&
            sudo cp /tmp/kernel_staging/boot/firmware/overlays/* /boot/firmware/overlays/ &&
            sudo cp -r /tmp/kernel_staging/lib/modules/* /lib/modules/ &&
            sudo depmod -a &&
            rm -rf /tmp/kernel_staging &&
            echo "Kernel installed successfully!"
        '
        ;;

    2)
        # SD card method
        echo ""
        echo "Available block devices:"
        lsblk -d -o NAME,SIZE,MODEL | grep -E "^(sd|mmcblk|nvme)"
        echo ""
        read -p "Enter device name (e.g., mmcblk0 or sdb): " DEVICE

        DEVICE="/dev/$DEVICE"

        if [ ! -b "$DEVICE" ]; then
            echo "Error: $DEVICE is not a valid block device"
            exit 1
        fi

        # Determine partition naming (mmcblk0p1 vs sdb1)
        if [[ "$DEVICE" == *"mmcblk"* ]] || [[ "$DEVICE" == *"nvme"* ]]; then
            BOOT_PART="${DEVICE}p1"
            ROOT_PART="${DEVICE}p2"
        else
            BOOT_PART="${DEVICE}1"
            ROOT_PART="${DEVICE}2"
        fi

        echo "Boot partition: $BOOT_PART"
        echo "Root partition: $ROOT_PART"
        read -p "Continue? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Aborted"
            exit 1
        fi

        # Create mount points
        BOOT_MNT=$(mktemp -d)
        ROOT_MNT=$(mktemp -d)

        cleanup() {
            echo "Cleaning up..."
            sync
            sudo umount "$BOOT_MNT" 2>/dev/null || true
            sudo umount "$ROOT_MNT" 2>/dev/null || true
            rmdir "$BOOT_MNT" "$ROOT_MNT" 2>/dev/null || true
        }
        trap cleanup EXIT

        echo "Mounting partitions..."
        sudo mount "$BOOT_PART" "$BOOT_MNT"
        sudo mount "$ROOT_PART" "$ROOT_MNT"

        echo "Copying kernel image..."
        sudo cp "$SRC_DIR/arch/arm64/boot/Image" "$BOOT_MNT/Image-imx500"

        echo "Copying device trees..."
        sudo cp $SRC_DIR/arch/arm64/boot/dts/broadcom/*.dtb "$BOOT_MNT/"

        echo "Copying overlays..."
        sudo mkdir -p "$BOOT_MNT/overlays"
        sudo cp $SRC_DIR/arch/arm64/boot/dts/overlays/*.dtb* "$BOOT_MNT/overlays/"

        echo "Copying modules..."
        sudo cp -r modules_out/lib/modules/* "$ROOT_MNT/lib/modules/"

        echo "Running depmod..."
        KERNEL_VERSION=$(ls modules_out/lib/modules/)
        sudo depmod -a -b "$ROOT_MNT" "$KERNEL_VERSION"

        echo "Syncing..."
        sync

        echo "Kernel installed successfully!"
        ;;

    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo "Done! Reboot the Pi to use the new kernel."
