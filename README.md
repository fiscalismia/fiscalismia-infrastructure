## fiscalismia-infrastructure
Terraform files for provisioning AWS &amp; Hetzner Cloud Infrastructure &amp; k8s manifests for ArgoCD deployment


### Setup Ansible Control Node

```bash
yum install -y curl jq openssh-client zip
ssh -V
# debug python installation
which python3 2>&1
python3 --version
python3 -m pip -V
# to use password hash for newly creates service user
python3 -m pip install passlib
python3 -m pip install ansible
echo "" && echo "##################################"
echo "Ansible installed under $(which ansible)"
echo "Ansible version:"
ansible --version
Fetch Service User Password that is running the Containers
export DOCKER_RUNNER_PSWD=$(echo "GIT_ENV_SECRET")
#Enforce Color in Console output for cleaner visual tracking
export ANSIBLE_FORCE_COLOR=1
# set ssh private key for connecting to deployment targets
export PRIVATE_KEY_FILE=$(echo "secret_file_from_git.pem")
echo "downloaded private key to $PRIVATE_KEY_FILE"
chmod 400 ${PRIVATE_KEY_FILE}
echo "set ${PRIVATE_KEY_FILE} to read-only"
```

**Provision Backend**
```bash
export ANSIBLE_CONFIG="ansible/fiscalismia-backend/ansible.cfg"
ansible-playbook ansible/fiscalismia-backend/provision.yaml
    -e "ssh_key_override=${PRIVATE_KEY_FILE}"
    -e "docker_runner_pw=${DOCKER_RUNNER_PSWD}"
```

**Provision Frontend**
```bash
export ANSIBLE_CONFIG="ansible/fiscalismia-frontend/ansible.cfg"
ansible-playbook ansible/fiscalismia-frontend/provision.yaml
  -e "ssh_key_override=${PRIVATE_KEY_FILE}"
  -e "docker_runner_pw=${DOCKER_RUNNER_PSWD}"
```

**Deploy Backend**
```bash
export BACKEND_DOMAIN_NAME="backend.fiscalismia.net"
export DOCKER_BACKEND_CONTAINER_NAME="fiscalismia-backend:latest"
export ANSIBLE_CONFIG="ansible/fiscalismia-backend/ansible.cfg"
ansible-playbook ansible/fiscalismia-backend/deploy.yaml
  -e "docker_dev_container_name=${DOCKER_BACKEND_CONTAINER_NAME}"
  -e "docker_username=${ENV_DOCKER_USERNAME}"
  -e "docker_password=${ENV_DOCKER_PASSWORD}"
  -e "docker_repository=${ENV_DOCKER_REPOSITORY}"
  -e "ssh_key_override=${PRIVATE_KEY_FILE}"
  -e "remote_domain=${BACKEND_DOMAIN_NAME}"
```

**Deploy Frontend**
```bash
export FRONTEND_DOMAIN_NAME="fiscalismia.net"
DOCKER_FRONTEND_CONTAINER_NAME="fiscalismia-frontend:latest"
export ANSIBLE_CONFIG=${CI_PROJECT_DIR}/UNIFYY-operations-hub-webapp/ansible.cfg
ansible-playbook ${CI_PROJECT_DIR}/UNIFYY-operations-hub-webapp/deploy.yaml
  -e "docker_dev_container_name=${DOCKER_FRONTEND_CONTAINER_NAME}"
  -e "docker_username=${ENV_DOCKER_USERNAME}"
  -e "docker_password=${ENV_DOCKER_PASSWORD}"
  -e "docker_repository=${ENV_DOCKER_REPOSITORY}"
  -e "ssh_key_override=${PRIVATE_KEY_FILE}"
  -e "remote_domain=${FRONTEND_DOMAIN_NAME}"
```
