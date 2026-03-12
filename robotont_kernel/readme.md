# Robotont Kernel

Scripts for cross-compiling a custom Raspberry Pi 5 kernel on x86 and deploying it to the Robotont.

## Scripts

### `build_robotont_kernel.sh`
Cross-compiles the RPi kernel (`rpi-6.6.y`) for arm64 on an x86 host.

1. Installs the `aarch64-linux-gnu` toolchain
2. Downloads the kernel source from the Raspberry Pi Linux repo
3. Configures with `bcm2712_defconfig` (RPi 5)
4. Builds the kernel and installs modules to `modules_out/`

Run from this directory:
```bash
./build_robotont_kernel.sh
```

### `copy_kernel_to_robotont.sh`
Deploys a built kernel to the Robotont. Prompts to select a built kernel and a copy method:

- **SSH** — copies over the network to a running Robotont (`robotont@robotont` by default)
- **SD card** — mounts the SD card locally and writes directly to it

Run from this directory:
```bash
./copy_kernel_to_robotont.sh
```

> Both scripts must be run from the `robotont_kernel/` directory.
