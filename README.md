# Setup
## Laptop setup: 2 laptops and two memory sticks are needed
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
### First configure ip in hosts file
#### and then run
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



