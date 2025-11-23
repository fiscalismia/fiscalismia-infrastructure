#!/usr/bin/env bash

# Update system and upgrade packages
sudo yum update -y
sudo yum upgrade -y
sudo yum autoremove -y

# Install required packages
sudo yum install -y net-tools
sudo yum install -y jq
sudo yum install -y zip
sudo yum install -y unzip
sudo yum install -y openssl
sudo yum install -y htop
sudo yum install -y tree
sudo yum install -y lsof
sudo yum install -y vim

# Output the versions of installed tools
echo "####################################"
echo "Installed [lsof] version:$(lsof -v). to list open/in use files."
echo "####################################"
echo "Installed [tree] version:$(tree --version) for clean file hierarchy listing."
echo "####################################"
echo "Installed [htop] version:$(htop --v)."
echo "####################################"
echo "Installed [openssl] version:$(openssl version)."
echo "####################################"
echo "Installed [unzip] version:$(unzip -v)."
echo "####################################"
echo "Installed [zip] version:$(zip --version)."
echo "####################################"
echo "Installed [jq] version:$(jq --version) for parsing json in shell scripts."
echo "####################################"
echo "Installed net-tools version $(netstat --version) for executing e.g. 'netstat -ltnp'"
echo "####################################"
echo "Installed [gpg2] version:$(gpg --version) for signatures and encryption."
echo "####################################"
echo "Installed [tldr] version $(tldr --version) to list essential commands of installed software."
echo "####################################"
echo "Installed [vim] version:$(vim --version)."
