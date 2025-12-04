## fiscalismia-infrastructure
Terraform configurations for provisioning AWS & Hetzner Cloud Infrastructure. Ansible Roles for Bastion-Host ProxyJump Instance Deployment & Updating. HA-Proxy Loadbalancer Instance for HTTPS Ingress and Hostname Routing. Private Networks without Public IP for Application Servers with mTLS. NAT Gateway Instance for HTTPS and DNS Egress.

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
ssh-keygen -t ed25519 -f $HOME/.ssh/fiscalismia-infrastructure-master-key-hcloud -C "Fiscalismia Infrastructure OpenSSH Public Key for User hangrybear666 to Hetzner Cloud"
ssh-keygen -t ed25519 -f $HOME/.ssh/fiscalismia-loadbalancer-instance-key-hcloud -C "Fiscalismia Load Balancer OpenSSH Public Key for User hangrybear666 to Hetzner Cloud"
ssh-keygen -t ed25519 -f $HOME/.ssh/fiscalismia-nat-gateway-instance-key-hcloud -C "Fiscalismia NAT Gateway OpenSSH Public Key for User hangrybear666 to Hetzner Cloud"
ssh-keygen -t ed25519 -f $HOME/.ssh/fiscalismia-demo-instance-key-hcloud -C "Fiscalismia Demo Instance OpenSSH Public Key for User hangrybear666 to Hetzner Cloud"
ssh-keygen -t ed25519 -f $HOME/.ssh/fiscalismia-monitoring-instance-key-hcloud -C "Fiscalismia Monitoring OpenSSH Public Key for User hangrybear666 to Hetzner Cloud"
ssh-keygen -t ed25519 -f $HOME/.ssh/fiscalismia-production-instances-key-hcloud -C "Fiscalismia Production OpenSSH Public Key for User hangrybear666 to Hetzner Cloud"
```

1. Terraform for Hetzner Cloud

Provision Hetzner Cloud first, since aws route53 depends on hcloud server ipv4 addresses for Type A Records using `terraform_remote_state`

**INFO:** This can be run in github actions pipeline via `secrets.HCLOUD_TOKEN`

```bash
cd ~/git/fiscalismia-infrastructure/terraform/hetzner-cloud/
source ../.env
terraform init
terraform apply
```

2. Terraform for persistent AWS resources

**INFO:** This has to be provisioned once initially with AWS admin credentials locally.
This is because of the chicken and egg problem, since the automated github actions pipeline running terraform apply requires an IAM role for authenticating to AWS via OIDC tokens and these permissions have to be setup first.

**Dependency Chain:** Also the S3 buckets containing the AWS lambdas and application data should exist before running the AWS Lambda pipeline and then never be destroyed again.

```bash
cd ~/git/fiscalismia-infrastructure/terraform/aws/
source ../.env
terraform init
terraform apply \
  -target=module.oidc_sts_pipeline_access \
  -target=module.s3_image_storage \
  -target=module.s3_raw_data_etl_storage \
  -target=module.s3_infrastructure_storage \
  -target=module.hcloud_iam_access \
  -auto-approve
```

3. Provide custom variables

Create `terraform/aws/terraform.tfvars` file and change any desired variables by overwriting the default values within `variables.tf`
```bash
secret_api_key                        = "klmasfdjlkfaedf7z77DAw___020"
test_sheet_url                        = "https://docs.google.com/spreadsheets/d/{YOUR_ID}/edit"
forecasted_budget_notification_email  = "example@domain.com"
```

4. Terraform for dynamic AWS resources provisioned and destroyed via pipeline

**INFO:** This can be run in github actions pipeline via `arn:aws:iam::010928217051:role/OpenID_Connect_GithubActions_TerraformPipeline`

```bash
cd ~/git/fiscalismia-infrastructure/terraform/aws/
source ../.env
terraform init
terraform apply \
  -target=module.route_53_dns \
  -target=module.api_gateway \
  -target=module.lambda_image_processing \
  -target=module.lambda_raw_data_etl \
  -target=module.infrastructure_lambdas \
  -target=module.cost_budget_alarms \
  -target=module.sns_topics \
  -target=module.cloudwatch_metric_alarms \
  -auto-approve
```

### Terraform Module Destroyer Github Actions Pipeline

**INFO:** This can be run in github actions pipeline via `arn:aws:iam::010928217051:role/OpenID_Connect_GithubActions_TerraformPipeline`

```bash
cd ~/git/fiscalismia-infrastructure/terraform/aws/
source ../.env
terraform init
terraform destroy \
  -target=module.route_53_dns \
  -target=module.api_gateway \
  -target=module.lambda_image_processing \
  -target=module.lambda_raw_data_etl \
  -target=module.infrastructure_lambdas \
  -target=module.cost_budget_alarms \
  -target=module.sns_topics \
  -target=module.cloudwatch_metric_alarms \
  -auto-approve

cd ~/git/fiscalismia-infrastructure/terraform/hetzner-cloud/
source ../.env
terraform init
terraform destroy --auto-approve
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

### Ansible Updates

```bash
# TODO
```

### Network Firewall with nftables

To secure our private instances which cannot have a hetzner cloud firewall attached, since those only work on public network interfaces, we construct an `nftables.conf` file ourselves.

It limits the private instances in both the demo and production network to:
- Ingress on Port 22 TCP from the Private IPv4 of the Bastion-Host
- Ingress on Port 443 TCP from the Private IPv4 of the LoadBalancer
- Ingress on ICMP Protocol for Pings from the Private IPv4 of the LoadBalancer
- Egress on Port {80,443} TCP to the public internet (via the Virtual Network Gateway routing to the NAT-Gateway)
- Egress on Port 53 UDP for DNS Queries to the public internet (via the Virtual Network Gateway routing to the NAT-Gateway)
- Egress for ICMP for pings to the public internet (via the Virtual Network Gateway routing to the NAT-Gateway)

#### Basic Concepts

See [wiki.nftables.org/](https://wiki.nftables.org/wiki-nftables/index.php/Configuring_chains#Base_chain_types)
See [Hetzner Cloud Community](https://community.hetzner.com/tutorials/firewall-using-nftables)
See [NFTables Setup Guide](https://www.centron.de/en/tutorial/install-and-configure-nftables-firewall-on-linux/)

- **Families**
  - _inet_: Unified for both IPv4 and IPv6.
  - _ip_: IPv4-only filtering.
  - _ip6_: IPv6-only filtering.
  - _arp_: Address resolution protocol to query for MAC-Addresses on Layer 2 before initiating TCP traffic. Required for private subnet traffic to work.
  - _bridge_: Ethernet bridge packet filtering.
  - _netdev_: Filtering at the network device level.

- **Tables** are top level containers for rules, directed at certain families
- **Chain** Chains always point to Hooks and can also define a default policy to apply to e.g. all traffic not specifically matched.
  - _filter_: is used to filter packets, most commonly used for most nftables configs.
  - _route_: is used to reroute packets if any relevant IP header field or the packet mark is modified. It is equivalent to the iptables mangle semtantics, but only for the output hook (for other hooks use type filter instead).
  - _nat_: is used to perform Networking Address Translation (NAT). Only the first packet of a given flow hits this chain; subsequent packets bypass it. Therefore, never use this chain for filtering.
- **Hooks** Within chains, they define when the rules should be evaluated
  - _prerouting_: sees all incoming packets, before any routing decision has been made.
  - _input_: sees incoming packets that are addressed to the local system.
  - _forward_: sees incoming packets that are not addressed to the local system.
  - _output_: sees packets that originated from processes in the local machine.
  - _postrouting_: sees all packets after routing, just before they leave the local system.
- **Policies** Define the default rules to apply when no rule matches
  - _accept_: Allows all unmatched traffic (useful for testing).
  - _drop_: Discards unmatched packets (secure, common in production).
  - _reject_: Sends a rejection notice (reveals server presence).
- **Connection Tracking** The ct system continuously analyzes each connection to determine its current state. It does that by analyzing OSI layers 3 and 4.
  - _new_: The connection is starting. (e.g. in a TCP connection, a SYN packet is received)
  - _established_: The connection has been established. So the firewall has seen two-way communication.
  - _related_: This is an expected connection.
  - _invalid_: This is a special state used for packets that do not follow the expected behavior of a connection.

-----

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
![img_upload lambda architecture](docs/img_upload_architecture_darkmode.png)
![raw_data_etl lambda architecture](docs/raw_data_etl_architecture_darkmode.png)

<u>Included Resources:</u>

- Public API HTTP Gateway with POST Routes that can invoke Lambda functions
- 2 Lambda Functions for Img Upload and Google Sheets Raw Data ETL protected via `secret_api_key`
- 2 Lambda Layers containing the runtime dependencies not included in aws by default
- 2 S3 Buckets accessed by Lambda for storing processed images and sheet output
- Respective IAM Roles and Permissions to allow access between API GW - Lambda - S3

</details>

-----
