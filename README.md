## fiscalismia-infrastructure
Terraform files for provisioning AWS &amp; Hetzner Cloud Infrastructure &amp; k8s manifests for ArgoCD deployment

### Prerequisites

**Install Terraform**

```bash
cd ~/git/fiscalismia-infrastructure/scripts/ && ./install-terraform-fedora.sh
```

**Setup Secrets in .env**

```bash
cd ~/git/fiscalismia-infrastructure/scripts/ && ./setup-env-vars.sh
```

**Setup SSH Keys**

```bash
cd ~/.ssh/
ssh-keygen -t ed25519 -f $HOME/.ssh/fiscalismia-infrastructure-master-key-hcloud -C "Fiscalismia Infrastructure OpenSSH Public Key for User cl.subs.contracts+hetzner@pm.me to Hetzner Cloud"
ssh-keygen -t ed25519 -f $HOME/.ssh/fiscalismia-demo-key-hcloud -C "Fiscalismia Demo Instance OpenSSH Public Key for User cl.subs.contracts+hetzner@pm.me to Hetzner Cloud"
ssh-keygen -t ed25519 -f $HOME/.ssh/fiscalismia-production-key-hcloud -C "Fiscalismia Production OpenSSH Public Key for User cl.subs.contracts+hetzner@pm.me to Hetzner Cloud"
```

### Terraform for Hetzner Cloud

**Apply Terraform IaC:**

```bash
cd ~/git/fiscalismia-infrastructure/terraform/hetzner-cloud/
source ../.env
terraform init
terraform apply
```

### Terraform for Hetzner Cloud

**Apply Terraform IaC:**

```bash
cd ~/git/fiscalismia-infrastructure/terraform/aws/
source ../.env
terraform init
terraform apply
```

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

### Ansible Provisioning

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

### Ansible Deployment

**Deploy Backend**
```bash
export BACKEND_DOMAIN_NAME="backend.fiscalismia.net"
export DOCKER_BACKEND_CONTAINER_NAME="fiscalismia-backend:latest"
export ANSIBLE_CONFIG="ansible/fiscalismia-backend/ansible.cfg"
ansible-playbook ansible/fiscalismia-backend/deploy.yaml
  -e "docker_container_name=${DOCKER_BACKEND_CONTAINER_NAME}"
  -e "docker_username=${ENV_DOCKER_USERNAME}"
  -e "docker_password=${ENV_DOCKER_PASSWORD}"
  -e "docker_repository=${ENV_DOCKER_REPOSITORY}"
  -e "ssh_key_override=${PRIVATE_KEY_FILE}"
  -e "remote_domain=${BACKEND_DOMAIN_NAME}"
```

**Deploy Frontend**
```bash
export FRONTEND_DOMAIN_NAME="fiscalismia.net"
export DOCKER_FRONTEND_CONTAINER_NAME="fiscalismia-frontend:latest"
export ANSIBLE_CONFIG="ansible/fiscalismia-frontend/ansible.cfg"
ansible-playbook ansible/fiscalismia-frontend/deploy.yaml
  -e "docker_container_name=${DOCKER_FRONTEND_CONTAINER_NAME}"
  -e "docker_username=${ENV_DOCKER_USERNAME}"
  -e "docker_password=${ENV_DOCKER_PASSWORD}"
  -e "docker_repository=${ENV_DOCKER_REPOSITORY}"
  -e "ssh_key_override=${PRIVATE_KEY_FILE}"
  -e "remote_domain=${FRONTEND_DOMAIN_NAME}"
```

<details closed>
<summary><b>AWS Serverless (Lambda, API Gateway) and S3 storage</b></summary>

### Theory

#### Anti-Patterns

- Chaining 2-n Lambda functions synchronously (where the first function waits for the last function to return) creates exponentially overlapping costs
- Breaking the single responsibility principle of a lambda function makes it difficult to monitor, optimize and debug a function and might create additional costs due to autoscaling to the level of the most demanding task

#### Best Practices

- Use step functions instead of synchronous lambda functions to construct an event flow, branching paths, error handling, retries and fallbacks
- When integrating with SQS use batch processing with x seconds wait window after queueing a message to collect multiple messages at once to avoid spamming lambda invocations (Optionally enable lambda to report failed message IDs in the batch to avoid reprocessing the entire batch)

#### Architectural Overview
![img_upload lambda architecture](terraform/aws/docs/img_upload_architecture_darkmode.png)
![raw_data_etl lambda architecture](terraform/aws/docs/raw_data_etl_architecture_darkmode.png)

<u>Included Resources:</u>

- API HTTP Gateway that can invoke Lambda functions
- 2 Lambda Functions for Img Upload and Google Sheets Raw Data ETL
- 2 Lambda Layers containing the runtime dependencies not included in aws by default
- 2 S3 Buckets accessed by Lambda for storing processed images and sheet output
- Respective IAM Roles and Permissions to allow access between API GW - Lambda - S3

#### 1. Provide custom variables

Create `terraform/aws/terraform.tfvars` file and change any desired variables by overwriting the default values within `variables.tf`
```bash
secret_api_key = "xxx"
test_sheet_url = "https://docs.google.com/spreadsheets/d/{YOUR_ID}/edit"
```

</details>

-----
