#!/bin/bash

# extract the current directory name from pwd command (everything behind the last backslash
CURRENT_DIR=$(pwd | sed 's:.*/::')
if [ "$CURRENT_DIR" != "scripts" ]
then
  echo "please change directory to scripts folder and execute the shell script again."
  exit 1
fi

read -p "Please provide the existing project path to bootstrap with best practice ansible project structure: " PROJECT_DIR
read -p "Please provide 1-n role names delimited by space to create role directories and files  " ROLE_NAMES
declare -a ROLE_ARR=($ROLE_NAMES)

cd ..
cd $PROJECT_DIR

CURRENT_DIR=$(pwd | sed 's:.*/::')
if [ "$CURRENT_DIR" != $PROJECT_DIR ]
then
  echo "could not change directory to $PROJECT_DIR"
  exit 1
fi

# Create the top-level files and directories
touch ansible.cfg hosts site.yaml

mkdir -p group_vars host_vars roles
touch group_vars/all.yaml group_vars/ec2-instances.yaml

# Create files in host_vars
mkdir -p host_vars
touch host_vars/ec2-instance1.yaml
touch host_vars/ec2-instance2.yaml

for role_name in "${ROLE_ARR[@]}"
do
  # Create directories for each role and the required subdirectories and files
  mkdir -p roles/$role_name/{defaults,files,handlers,tasks,vars}
  touch roles/$role_name/defaults/main.yaml
  touch roles/$role_name/files/.gitignore
  touch roles/$role_name/handlers/main.yaml
  touch roles/$role_name/tasks/main.yaml
  touch roles/$role_name/vars/main.yaml
done


# set defaults
echo "[defaults]
host_key_checking = False
inventory = hosts" > ansible.cfg

echo "
[ec2_instances]

[all:vars]
ansible_python_interpreter=/usr/bin/python3" > hosts

echo "# variables for the specific host corresponding to this filename
# overwrites the 'group specific' and 'all' vars in /group_vars/" > host_vars/ec2-instance1.yaml
echo "# variables for the specific host corresponding to this filename
# overwrites the 'group specific' and 'all' vars in /group_vars/" > host_vars/ec2-instance2.yaml

echo "# variables applying to all groups" > group_vars/all.yaml
echo "# variables for the group contained in the filename" > group_vars/ec2-instances.yaml
