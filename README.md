# Setup
## Copying ssh keys
```
ssh-copy-id -i ~/.ssh/robotont_ed25519.pubssh_ed25519 peko@[ip_address]
```
## Installing on the robot
### First configure ip in hosts file
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



