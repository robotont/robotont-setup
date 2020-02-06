# Robotont ansible playbook

This is an ansible playbook for installing [ROS](http://www.ros.org/) Melodic and robotont workspace
on Ubuntu 18.04.

`ros.yaml` - playbook for installing ROS
`catkin_ws.yaml` playbook for installing catkin workspace with realsense support
`xbox-one.yaml` playbook for installing a driver for XBox One controller
`clearbot-network.yaml` playbook for configuring network for robotont. DO NOT run this on your laptop!


Feel free to modify the host groups in the `hosts` file.

Usage:
  * ```ansible-playbook ros.yaml clearbots``` to run ros.yaml playbook for the entire clearbots group
  * `ansible-playbook ros.yaml clearbot-5` to run ros.yaml playbook on clearbot-5
