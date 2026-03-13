# Robotont Setup

Automated setup toolkit for the [Robotont](https://robotont.ut.ee) mobile robot platform. Configures Ubuntu + ROS 2 Jazzy on Raspberry Pi 5, including networking, hardware drivers, IMX500 AI camera support, and the ROS workspace.

## Repository Structure

| Folder | Description |
|---|---|
| [`ansible/`](ansible/readme.md) | Ansible playbooks and roles for robot and laptop configuration |
| [`robotont_kernel/`](robotont_kernel/readme.md) | Scripts for cross-compiling and deploying a custom RPi 5 kernel |
| [`partitioning/`](partitioning/readme.md) | Disk partitioning and imaging scripts for laptop setup |
| [`utils/`](utils/) | Miscellaneous utilities (e.g. voltage/temperature monitor) |

---

## Robot Setup with Raspberry Pi 5 on board computer

**What you need:** Raspberry Pi 5, keyboard, mouse, monitor (micro-HDMI to HDMI cable), internet connection (via ethernet or WiFi).

### 1. Install Ubuntu

Install **Ubuntu 24.04** on the robot. During installation set the username to **`peko`**. This user needs to have administrative (sudo) privileges to run the Ansible playbook. 


### 2. Install Prerequisites

```bash
sudo apt install ansible git
```

### 3. Clone this repository

Open a terminal (`Ctrl+Alt+T`) and run:

```bash
git clone https://github.com/robotont/robotont-setup
cd robotont-setup/ansible
```

### 4. Configure the robot id, WiFi passwords, and other settings

Prepare `hosts` file to configure the robot. Adjust the robot id, username, passwords, WiFi credentials, and other settings as needed. See [readme.md](ansible/readme.md) for details on each setting. Example configuration with available options is provided in `hosts.example`. In the `ansible` folder, run:

```bash
# Copy the example hosts file and open it for editing
cp hosts.example hosts
nano hosts
# Once done, save (Ctrl+O) and exit (Ctrl+X) the editor
```

### 5. Run the Ansible playbook

Now we're ready to run the playbook. Make sure you are in the `robotont-setup/ansible` directory and that the `ansible/hosts` file is configured.

```bash
ansible-playbook robots-local.yaml -K -b
```

Enter your current user password when prompted at the `BECOME` field to allow system-wide changes. The playbook will configure the full software stack and reboot the robot automatically at the end.

After reboot the robot is ready — it will try to connect first to the WiFi network provided, if one is not found the robot will turn into an Access Point with the credentials you set.

## What the Ansible Playbook Configures

- System packages and services optimized for robot use
- Hostname set to `robotont-{id}`
- WiFi in access point mode (static IP `192.168.200.1`)
- User groups for serial, input, and camera devices
- Udev rules for Robotont MCU
- ROS 2 Jazzy installation and workspace setup
- IMX500 AI camera (custom libcamera build + rpicam-apps)
- Systemd service for automatic robot startup on boot

See [ansible/readme.md](ansible/readme.md) for full details on roles and playbooks.

---

## Custom Kernel (IMX500 Camera Support)

To enable IMX500 AI camera for robotont, we need a custom kernel with proper modules enabled. Since this is rather slow on the Pi, we recommend cross compiling it on a more powerful system. Simply make sure your host machine is connected to the same network as the robot and the following scripts will guide you to get the kernel built and uploaded to the robot.

**Build** (cross-compile on x86 host):

```bash
cd robotont_kernel
./build_robotont_kernel.sh
```

**Deploy** to a running robot remotely over SSH or directly to an SD card inserted to the host system:

```bash
cd robotont_kernel
./copy_kernel_to_robotont.sh
```

See [robotont_kernel/readme.md](robotont_kernel/readme.md) for full details.

---

## Remote Setup via SSH

If the robot already has a network connection, you can configure it remotely from another host system (e.g. a laptop). For that to succeed, you need to have SSH server running on the robot and an SSH key pair set up.

### Set up SSH server on the robot for remote access

Make sure you have SSH server installed on the robot:
```bash
sudo apt install openssh-server
```

### Setting up SSH key on the host machine (e.g. laptop)
To allow Ansible on the host system to access the robot without a password prompt, we need to generate an SSH key pair and copy the public key to the robot.
On **your host system** run:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/robotont_ed25519
ssh-copy-id -i ~/.ssh/robotont_ed25519 peko@<robot-ip>
```

Configure `hosts` file (see above) and then run:

```bash
cd ansible
ansible-playbook robots.yaml -K -b
```

If you have many robots, you list them all in the `[robots]` section of the `hosts` file and the playbook configures your entire robotont swarm simultaneously.


## Replicating the Setup on Multiple Robots

Running the full playbook from scratch on every robot is slow — Ubuntu installation and package downloads take a significant amount of time. A much faster approach is to prepare one fully configured **master robot**, image its SD card, and clone that image onto the remaining robots. Ansible then handles only the fast per-robot personalisation (hostname, WiFi credentials, ROS domain ID, etc.), skipping all the heavy downloading.

The following guide is written for Linux hosts, but the same principles apply on other platforms too.  

**Overview:**

1. Prepare and fully configure one master robot using the steps above
2. Image the master SD card with Clonezilla
3. Clone the image onto each additional robot's SD card
4. Configure your router's DHCP server to assign fixed IPs to each robot
5. Run `robots.yaml` over SSH to personalise all robots simultaneously

---

### Step 1 — Prepare the master robot

Follow the [Robot Setup](#robot-setup-with-raspberry-pi-5-on-board-computer) steps to fully configure one robot. Shut it down cleanly before imaging:

```bash
sudo shutdown now
```

Remove the SD card from the robot and insert it into your host machine.

---

### Step 2 — Image the master SD card with Clonezilla

Install Clonezilla on your host machine:

```bash
sudo apt install clonezilla
```

Identify the SD card device name by running `lsblk` before and after inserting the card and comparing the output:

```bash
lsblk
```

> The SD card will typically appear as `/dev/mmcblk0` or similar. **Always verify the device name** before proceeding — writing to the wrong device will overwrite data.

Ubuntu may automatically mount the SD card partitions on insert. Unmount them first (replace `<source_device>` with your SD card device name, without `/dev/`):

```bash
sudo umount /dev/<source_device>?*
```

Save the image:

```bash
sudo ocs-sr -q2 -j2 -i 4096 -sc -b savedisk robotont-master <source_device>
```

The image will be saved to `/home/partimag/robotont-master/` by default. Alternatively, launch the interactive Clonezilla interface with `sudo clonezilla`.

---

### Step 3 — Clone the image to each robot's SD card

Swap in a blank SD card for the next robot. Unmount any auto-mounted partitions (replace `<target_device>` with the new SD card's device name):

```bash
sudo umount /dev/<target_device>?*
```

Write the image to the new SD card:

> [!WARNING]
> **Double-check the target device name** before running the command. A typo here can wipe your host system's drive with no questions asked.

```bash
sudo ocs-sr -q2 -j2 -k1 -scr restoredisk robotont-master <target_device>
```

Repeat for each robot.

---

### Step 4 — Assign fixed IPs via DHCP

For Ansible to reach each robot reliably, configure your router's DHCP server to assign a fixed IP address leases to each robot based on its MAC address. Use the `192.168.200.x` range (e.g. `192.168.200.2`, `192.168.200.3`, ...) and add each entry to the `[robots]` section of the `hosts` file. See your router's documentation for instructions on how to set up static DHCP reservations.

---

### Step 5 — Personalise all robots with Ansible

Boot all robots and ensure they are reachable over the network. Then run the remote playbook from your host machine:

```bash
cd robotont-setup/ansible
ansible-playbook robots.yaml -K -b
```

Ansible will configure each robot's hostname, WiFi credentials, ROS domain ID, and any other identity-specific settings — simultaneously across the entire swarm. Since all packages are already installed from the master image, this completes in a fraction of the time of a full setup.

Several playbook tasks are tagged, so if you need to re-run only specific parts (e.g. just the camera configuration), you can do so with:

```bash
ansible-playbook robots.yaml -K -b --tags camera
```