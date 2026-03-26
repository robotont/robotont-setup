# Robotont ansible playbook

This is a reposotory with various ansible playbooks to set up [ROS](http://www.ros.org/) Jazzy with colcon workspaces for robotont platforms as well as for the machines connecting the robots.

  `robots.yaml` - playbook for getting from fresh Ubuntu 24.04 install to a robotont default state (ROS Jazzy installation with predefined workspace set up, services peripheral devices hostnames, networking and much more automatically configured.

  `pair_gamepad.yaml` - playbook for clearing old gamepad devices and accept new device that is nearby and in pairing mode.

Before running the playbooks, make sure to list your robots on the `hosts` file and edit the entries with desired configuration including passwords, network names, robots identities, ... See `hosts.example` for reference.

Usage:
  * `ansible-playbook -K -b robots.yaml -K -b` to run robots.yaml on all robots listed in the `hosts` file `[robots]` section.
  
  * `ansible-playbook -K -b robots.yaml robotont-1` to run robots.yaml playbook on a host named robotont-1.
