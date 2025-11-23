#!/usr/bin/env bash

# Check for Python 3 Installation
python_location=$(which python3 2>&1)
if [[ $python_location != *"no python3"* ]]
  then
    echo "------------------------------"
    echo "Python located in $python_location"
    echo "Python version: $(python3 --version)"
  else
    echo "No Python3 installation found. Installing."
    sudo yum install -y python3
fi

# Check for Pip Installation
pip_version=$(python3 -m pip -V)
pip_version_substr=${pip_version:0:3}
if [ $pip_version_substr == "pip" ]
  then
    echo "pip installation in: $pip_version"
  else
    echo "Pip is not installed. Installing."
    sudo yum install -y python3-pip
fi

# Check for pipx Installation
pipx_location=$(which pipx  2>&1)
if [[ $pipx_location != *"no pipx"* ]]
  then
    echo "pipx located in $pipx_location"
    echo "pipx version: $(pipx --version)"
  else
    echo "pipx is not installed. Installing."
    python3 -m pip install --user pipx \
      --trusted-host pypi.org \
      --trusted-host pypi.python.org \
      --trusted-host files.pythonhosted.org
fi

# Configure pipx
python3 -m pipx ensurepath

### INSTALL ANSIBLE AND DEPENDENCIES ###
python3 -m pip install --user ansible
echo "" && echo "##################################"
echo "Ansible installed under $(which ansible)"
echo "Ansible version:"
ansible --version