# This allows vscode remote ssh development to work on the ec2 machine
# Amazon Linux (from GOSP) doesn't allow tcp forwarding by default, change and restart daemon
sudo sed -i 's/AllowTcpForwarding no/AllowTcpForwarding yes/g' /etc/ssh/sshd_config
sudo systemctl restart sshd