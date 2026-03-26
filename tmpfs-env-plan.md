# Plan: Migrate .env Secrets to tmpfs via AWS Secrets Manager Cron Job

## Context

Currently, the demo instance at Hetzner receives its `.env` file via SCP during the GitHub Actions
deployment pipeline (`webservice-deployment-pipeline.yml`). The file is fetched from AWS Secrets Manager
(`fiscalismia-backend/.env`) and placed at `/usr/local/etc/fiscalismia-demo/.env`, where it persists
on disk indefinitely. This is a security concern: secrets at rest on the host filesystem can be
exfiltrated if the instance is compromised.

**Goal:** Replace the static `.env` file with a dynamically-refreshed tmpfs-backed secrets mount at
`/run/secrets/.env`, populated by a cron job that queries AWS Secrets Manager. Later, replace the
static AWS access keys with x.509 certificates via step-ca + IAM Roles Anywhere.

---

## Critical Design Consideration: Two Types of .env Usage in Docker Compose

The current `docker-compose.demo.instance.yml` uses the `.env` file in **two distinct ways**:

1. **Compose-level YAML interpolation** (lines 11, 12, 22, 25): `${POSTGRES_HOST}`, `${POSTGRES_PORT}`,
   `${POSTGRES_USER}`, `${POSTGRES_DB}` are resolved by `docker compose` when parsing the YAML file.
   These come from the `.env` file in the project directory OR the `--env-file` CLI flag.

2. **Container-level env injection** (`env_file: - .env` on lines 16-17, 60-61, 110-112): Injects
   all key-value pairs as environment variables into the container process. This is how the Node.js
   backend reads `process.env.*` and the Python webscraper reads `os.environ[*]`.

**These are independent mechanisms.** Moving the .env file requires addressing both.

---

## Recommended Approach: Two-Phase Implementation

### Phase 1 (This PR): Host-level tmpfs + env_file path change

The simplest approach that eliminates secrets-at-rest without requiring any container image changes.

**How apps receive env vars:** Same as today - `env_file:` directive injects them as process
environment variables. The only change is the file's location and lifecycle.

**Trade-off:** Env vars remain visible via `docker inspect` and `/proc/<pid>/environ` inside the
container. This is acceptable for Phase 1 because the primary threat model is secrets persisting
on the host filesystem (survives reboots, appears in backups, accessible to other host processes).

### Phase 2 (Future): Volume-mounted secrets file + entrypoint wrappers

For defense-in-depth, mount the `.env` as a read-only file inside containers and source it at
startup via entrypoint wrappers. This removes secrets from Docker metadata and `/proc`. Requires
knowing each image's original ENTRYPOINT/CMD (inspect GHCR images). Documented as future work below.

---

## Phase 1 Implementation

### 1. Cron Script: `/run/secrets` Provisioning

**New file:** `scripts/refresh-secrets-tmpfs.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

SECRETS_DIR="/run/secrets"
ENV_FILE="${SECRETS_DIR}/.env"
SECRET_ID="fiscalismia-backend/.env"
AWS_REGION="eu-central-1"
LOG_TAG="secrets-refresh"

log() { logger -t "${LOG_TAG}" "$1"; }

# Ensure tmpfs mount exists (idempotent)
if ! mountpoint -q "${SECRETS_DIR}"; then
    log "Creating tmpfs at ${SECRETS_DIR}"
    mkdir -p "${SECRETS_DIR}"
    # noswap requires kernel 6.3+ (available on Fedora); prevents secrets from being paged to disk
    # noexec,nosuid,nodev for defense-in-depth
    mount -t tmpfs -o size=1m,mode=0700,noswap,noexec,nosuid,nodev tmpfs "${SECRETS_DIR}"
fi

# Query AWS Secrets Manager
log "Querying AWS Secrets Manager for ${SECRET_ID}"
secret_value=$(aws secretsmanager get-secret-value \
    --secret-id "${SECRET_ID}" \
    --region "${AWS_REGION}" \
    --output text \
    --query SecretString 2>&1) || {
    log "ERROR: Failed to query secrets: ${secret_value}"
    exit 1
}

# Atomic write: write to temp file then rename (prevents partial reads)
tmp_file=$(mktemp "${SECRETS_DIR}/.env.XXXXXX")
printf '%s\n' "${secret_value}" > "${tmp_file}"
chmod 0400 "${tmp_file}"
mv -f "${tmp_file}" "${ENV_FILE}"

log "Secrets refreshed successfully at ${ENV_FILE}"
```

**Key design decisions:**
- `noswap` mount option (Linux 6.3+, Fedora has this) prevents secrets from hitting swap
- Atomic write via `mktemp` + `mv` prevents containers from reading a partial file
- `mode=0700` on the tmpfs limits access to root only on the host
- `chmod 0400` on the .env file makes it read-only
- `logger` for syslog integration (auditable)

### 2. Cron Job Setup

**New file:** `scripts/install-secrets-cron.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="/usr/local/bin/refresh-secrets-tmpfs.sh"
CRON_SCHEDULE="*/30 * * * *"  # Every 30 minutes

# Install the refresh script
cp scripts/refresh-secrets-tmpfs.sh "${SCRIPT_PATH}"
chmod 0700 "${SCRIPT_PATH}"

# Install cron job (idempotent)
CRON_LINE="${CRON_SCHEDULE} ${SCRIPT_PATH}"
(crontab -l 2>/dev/null | grep -v "refresh-secrets-tmpfs" ; echo "${CRON_LINE}") | crontab -

# Run once immediately to populate secrets
"${SCRIPT_PATH}"

echo "Cron job installed: ${CRON_LINE}"
```

### 3. AWS Credentials on Hetzner Host (Interim)

**New file:** `scripts/configure-aws-credentials.sh`

```bash
#!/usr/bin/env bash
# Interim: Configure static AWS credentials on the Hetzner host
# Future: Replace with x.509 certs via step-ca + IAM Roles Anywhere
set -euo pipefail

mkdir -p ~/.aws
chmod 0700 ~/.aws

cat > ~/.aws/credentials << 'CREDS'
[default]
aws_access_key_id = <TO_BE_PROVIDED>
aws_secret_access_key = <TO_BE_PROVIDED>
region = eu-central-1
CREDS

chmod 0600 ~/.aws/credentials
```

**IAM Policy required for the credentials** (minimal permissions):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "secretsmanager:GetSecretValue",
    "Resource": "arn:aws:secretsmanager:eu-central-1:010928217051:secret:fiscalismia-backend/.env-*"
  }]
}
```

### 4. Docker Compose Changes

**File:** `docker-compose.demo.instance.yml`

Changes for each service that currently uses `env_file: - .env`:

```yaml
# BEFORE (all three services):
env_file:
  - .env

# AFTER:
env_file:
  - /run/secrets/.env
```

Services affected:
- `fiscalismia-postgres` (line 16-17)
- `fiscalismia-backend` (line 60-61)
- `fiscalismia-webscraper` (line 110-112)

No changes needed for `fiscalismia-frontend` (has no env_file).

**Compose-level interpolation** (`${POSTGRES_HOST}`, etc.): Handled by changing the deployment
command to explicitly pass the env file:

```bash
docker compose --env-file /run/secrets/.env up --build --detach
```

The `--env-file` flag tells compose where to find variables for YAML interpolation.
The `env_file:` directive in each service tells compose where to find variables for container injection.
Both now point to `/run/secrets/.env`.

### 5. Deployment Pipeline Changes

**File:** `.github/workflows/webservice-deployment-pipeline.yml`

#### 5a. Modify "Secure Copy Dependencies to DEMO Instance" step (line 181+)

Remove the .env fetch-and-SCP logic. Instead, SCP the cron script and ensure it's installed:

```yaml
- name: Secure Copy Dependencies to DEMO Instance
  if: inputs.deploy_demo == true
  run: |
    ### INFRA SETUP
    scp ${INFRA_DIR}/docker-compose.demo.instance.yml demo:${REMOTE_DEMO_DIR}/docker-compose.yml
    scp ${INFRA_DIR}/scripts/refresh-secrets-tmpfs.sh demo:/usr/local/bin/refresh-secrets-tmpfs.sh
    ssh demo "chmod 0700 /usr/local/bin/refresh-secrets-tmpfs.sh"

    # Ensure secrets are fresh before compose up
    ssh demo "/usr/local/bin/refresh-secrets-tmpfs.sh"

    ### FRONTEND SETUP
    scp ${FRONTEND_DIR}/Dockerfile demo:${REMOTE_DEMO_DIR}/frontend/Dockerfile
    # ... rest unchanged ...
```

**Lines removed:** 188-195 (the aws secretsmanager get-secret-value + scp .env + rm .env block)

#### 5b. Modify "Deploy on DEMO Instance via OpenSSH" step (line 218+)

```yaml
- name: Deploy on DEMO Instance via OpenSSH
  if: inputs.deploy_demo == true
  run: |
    ssh demo "ls -Rhla ${REMOTE_DEMO_DIR}/"
    ssh demo << EOF
      cd ${REMOTE_DEMO_DIR}
      docker compose down --volumes || true
      docker compose --env-file /run/secrets/.env up --build --detach
    EOF
```

### 6. Systemd tmpfs Mount (Boot Persistence)

The cron job handles creating the tmpfs, but after a reboot the mount won't exist until
the first cron run. To ensure the tmpfs exists immediately at boot (even before cron fires),
add a systemd mount unit:

**New file:** `scripts/run-secrets.mount` (systemd mount unit)

```ini
[Unit]
Description=tmpfs for application secrets
DefaultDependencies=no
Before=docker.service

[Mount]
What=tmpfs
Where=/run/secrets
Type=tmpfs
Options=noswap,noexec,nosuid,nodev,mode=0700,size=1m

[Install]
WantedBy=multi-user.target
```

Install with: `cp run-secrets.mount /etc/systemd/system/ && systemctl enable run-secrets.mount`

The cron script's `mountpoint -q` check makes it idempotent with this.

---

## How Each Application Receives Its Environment Variables

### Answer to the Core Question

With **Phase 1 (env_file approach)**, applications receive env vars exactly as they do today:

| Service | Runtime | How it reads config | Change needed? |
|---------|---------|-------------------|----------------|
| fiscalismia-backend | Node.js | `process.env.VARIABLE` | None - env_file injects into process env |
| fiscalismia-webscraper | Python/FastAPI | `os.environ['VARIABLE']` | None - env_file injects into process env |
| fiscalismia-postgres | PostgreSQL | Standard POSTGRES_* env vars | None - env_file injects into process env |
| fiscalismia-frontend | Nginx (static) | No env vars needed | None - no env_file today |

The `env_file:` directive reads the file on the **host** at `docker compose up` time and sets
each key-value pair as an environment variable in the container's process. The applications
never read the file directly - they read `process.env` / `os.environ` as normal. Changing the
host path from `.env` to `/run/secrets/.env` is transparent to the applications.

### Phase 2 (Future): Volume Mount + Entrypoint Wrapper

If you later want to remove env vars from `docker inspect` / `/proc/<pid>/environ`, the approach is:

1. Remove `env_file:` from services
2. Bind-mount the secrets file into each container:
   ```yaml
   volumes:
     - /run/secrets/.env:/run/secrets/.env:ro
   ```
3. Override the entrypoint to source the file before exec'ing the original command:
   ```yaml
   entrypoint: ["/bin/sh", "-c", "set -a && . /run/secrets/.env && set +a && exec <original-cmd>"]
   ```
4. This requires inspecting each GHCR image to determine the original ENTRYPOINT/CMD:
   ```bash
   docker inspect ghcr.io/fiscalismia/fiscalismia-backend-demo:latest --format='{{json .Config.Entrypoint}} {{json .Config.Cmd}}'
   ```
5. For postgres: the `/run` tmpfs mount (line 42) would conflict with a bind mount at `/run/secrets/.env`.
   Either mount at `/secrets/.env` instead, or change the postgres tmpfs to `/run/postgresql`.

---

## Future: x.509 / step-ca / IAM Roles Anywhere Migration Path

The cron script is designed with a clean separation: AWS credential management is external to the
secrets refresh logic. To migrate from static keys to IAM Roles Anywhere:

1. **Deploy step-ca** on the Hetzner infrastructure (or use a hosted ACME CA)
2. **Issue x.509 client certificates** to the demo instance via step-ca
3. **Configure IAM Roles Anywhere** trust anchor pointing to the step-ca root CA
4. **Create an IAM Roles Anywhere profile** with the same SecretsManager policy
5. **Replace `~/.aws/credentials`** with the Roles Anywhere credential helper:
   ```bash
   # ~/.aws/config
   [default]
   credential_process = aws_signing_helper credential-process \
     --certificate /path/to/cert.pem \
     --private-key /path/to/key.pem \
     --trust-anchor-arn arn:aws:rolesanywhere:eu-central-1:010928217051:trust-anchor/XXXXX \
     --profile-arn arn:aws:rolesanywhere:eu-central-1:010928217051:profile/XXXXX \
     --role-arn arn:aws:iam::010928217051:role/HetznerSecretsAccess
   ```
6. **The cron script remains unchanged** - it just calls `aws secretsmanager get-secret-value`,
   and the credential_process handles STS token exchange transparently.
7. **Certificate rotation** can be automated via step-ca's ACME protocol + a certbot-like renewal cron.

---

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `scripts/refresh-secrets-tmpfs.sh` | **Create** | Cron script to populate /run/secrets from AWS SM |
| `scripts/install-secrets-cron.sh` | **Create** | One-time installer for cron job + systemd mount |
| `scripts/run-secrets.mount` | **Create** | Systemd mount unit for boot-time tmpfs |
| `scripts/configure-aws-credentials.sh` | **Create** | Interim static AWS key setup (to be replaced by step-ca) |
| `docker-compose.demo.instance.yml` | **Modify** | Change `env_file: - .env` to `env_file: - /run/secrets/.env` (3 services) |
| `.github/workflows/webservice-deployment-pipeline.yml` | **Modify** | Remove .env SCP, add cron script SCP, add `--env-file` flag to compose command |

## Verification

1. **Unit test the cron script locally:**
   ```bash
   # On any machine with AWS CLI configured
   bash scripts/refresh-secrets-tmpfs.sh
   cat /run/secrets/.env  # verify content matches AWS SM secret
   mountpoint /run/secrets  # verify tmpfs
   mount | grep /run/secrets  # verify noswap,noexec,nosuid flags
   ```

2. **Test docker compose with new env_file path:**
   ```bash
   cd /usr/local/etc/fiscalismia-demo
   docker compose --env-file /run/secrets/.env config  # dry-run: shows resolved config
   docker compose --env-file /run/secrets/.env up --build --detach
   docker exec fiscalismia-backend env | grep -c .  # verify env vars are injected
   docker exec fiscalismia-webscraper env | grep -c .
   ```

3. **Verify secrets are NOT on persistent disk:**
   ```bash
   # After deployment, the old .env should not exist
   test ! -f /usr/local/etc/fiscalismia-demo/.env && echo "PASS: no .env on disk"
   # Verify /run/secrets is tmpfs
   df -T /run/secrets | grep tmpfs && echo "PASS: tmpfs confirmed"
   ```

4. **Verify reboot resilience:**
   ```bash
   systemctl reboot
   # After reboot:
   mountpoint /run/secrets  # systemd mount should recreate tmpfs
   # Wait for cron or run manually:
   /usr/local/bin/refresh-secrets-tmpfs.sh
   cat /run/secrets/.env  # should be populated
   ```

5. **Test deployment pipeline** via workflow_dispatch with `deploy_demo: true`
