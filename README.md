# Robot setup: robot, mouse, keyboard and internet connection are needed
1) Create ubuntu installation memory stick and plug it into the computer on the robot
2) Power on the computer and press F10 on the keyoard
3) In the appeared menu select the boot device your USB
4) Install ubuntu:
   * Connect to WiFi
   * Setup your username as **peko**
   * Create a password and don't forget it
   * Follow installation steps
5) Download installation repository on the robot: 
```
sudo apt install git
```
```
git clone https://github.com/robotont/robotont-setup
```
6) Run the following command to install ansible:
<!-- ```
sudo apt install python3-pip
```
```
python3 -m pip install --user ansible
``` -->
```
sudo apt install ansible
```
7) Adjust the file **hosts** in ansible folder of the repository. Edit second line and enter the password of the access point you would like to have **wifi_pass=** ***your_password***
8) Open terminal with right click when you are in the ansible folder of the ropository
9) Run ansible and enter user password in the become field:
```
ansible-playbook robots-local.yaml -K
```
10) After it is completed your robot installation is done!
### Truobleshooting:
  * If there's an error on the Apply connection step run:
  ```
  nmcli connection up netplan-wlp58s0-robotont-1
  ```
# Laptop setup: 2 laptops and two memory sticks are needed
#### Boot linux in trial mode from the installation memory stick
#### Then copy scripts from main laptop to the one which installs ubuntu
```
scp -r ~/robotont-setup/partitioning/* ubuntu@<ip addr>:.
```
#### Then first run partitioning
It prompts for disk name. If something fails unplug target memory stick and plug back again.
```
sudo ./pa
```
#### After that install ubuntu and select not to reboot
#### And then run copying script after which it can be rebooted
```
sudo ./copying
```
### After that run ansible for laptops(with the correct laptop ip in hosts file)
```
ansible-playbook laptops.yaml -K
```

## SSH part outdated
### Installing ssh on robot
```
sudo apt install -y openssh-server
```
### Generating keys
```
ssh-keygen -t ed25519 -f ~/.ssh/robotont_ed25519
```
### Copying ssh keys
```
ssh-copy-id -i ~/.ssh/robotont_ed25519 peko@[ip_address]
```
### First configure ip in hosts file and then run
```
ansible-playbook robots.yaml -K
```


# Old robotont-setup
Scripts and other stuff that does not belong to the catkin workspace

# How to update robotont

## Connecting to internet
Before updating we need to connect a LAN cable to the robot.
Open a terminal and ssh into robot. Use the command in form of
```bash
ssh <USERNAME>@<ROBOT_IP_ADDRESS>
```
For example:
```bash
ssh clearbot@192.168.200.1
```

Obtain an IP address for the LAN interface:
```bash
sudo dhclient -v
```

Check for connection:
```bash
ping google.com
```

## Updating the system 
To update all ubuntu packages run:
```bash
sudo apt update
sudo apt upgrade -y
```
## Getting the latest catkin workspace for the robot
Make a backup of the existing workspace:
```bash
mv ~/catkin_ws ~/backup_ws
```

Create a new workspace
```bash
mkdir -p catkin_ws/src
cd catkin_ws
catkin build
```
Download and build all the latest robotont ROS packages for the robot.

```bash
cd ~/catkin_ws
wstool init src https://raw.githubusercontent.com/robotont/robotont-setup/melodic-devel/ansible/resources/.rosinstall
catkin build
```



