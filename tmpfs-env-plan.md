# Plan: Migrate .env Secrets to tmpfs via PKI-based AWS Credential Flow

## Context

The CI pipeline currently fetches `.env` from AWS Secrets Manager using OIDC, SCPs it to the demo instance at `/usr/local/etc/fiscalismia-demo/.env`, where it persists on disk. The PKI infrastructure (scripts 01-05) already sets up IAM Roles Anywhere credentials on the server via step-ca + `aws_signing_helper`. Script 05 already fetches the `.env` using these PKI credentials but immediately shreds it. This change moves the secret retrieval to a new script 06 that places it on a dedicated tmpfs, eliminating secrets-at-rest.

---

## Changes

### 1. New file: `pki/06_provision_secrets_tmpfs.sh` (runs remotely after 03-05)

Creates:
- **Systemd mount unit** (`/etc/systemd/system/run-secrets.mount`): 1MB tmpfs at `/run/secrets` with `noswap,noexec,nosuid,nodev,mode=0700`, ordered `Before=docker.service`
- **Refresh script** (`/usr/local/bin/refresh-secrets-tmpfs.sh`): fetches `.env` from AWS SM using `--profile hetzner-pki`, atomic write via `mktemp`+`mv` to `/run/secrets/.env`, chmod 0400, syslog logging
- **Systemd timer** (`secrets-refresh.service` + `secrets-refresh.timer`): runs on boot (`OnBootSec=1min`) and every 30min (`OnUnitActiveSec=30min`), follows pattern from script 04's cert renewal timer
- **Cleanup**: shreds legacy `.env` at `/usr/local/etc/fiscalismia-demo/.env` if present
- Runs the refresh script once immediately to populate `/run/secrets/.env`

### 2. Modify: `pki/05_aws_sts_credential_req.sh`

**Remove lines 22-32** (the `.env` fetch and shred). Keep lines 1-20 (aws_signing_helper install + AWS profile config). Add a comment that secrets retrieval is handled by script 06.

### 3. Modify: `docker-compose.demo.instance.yml`

Change `env_file:` path in 3 services (keeps same injection mechanism, just new path):
- Line 17: `- .env` -> `- /run/secrets/.env` (fiscalismia-postgres)
- Line 61: `- .env` -> `- /run/secrets/.env` (fiscalismia-backend)
- Line 112: `- .env` -> `- /run/secrets/.env` (fiscalismia-webscraper)

### 4. Modify: `.github/workflows/webservice-deployment-pipeline.yml`

**4a. Remove .env fetch** (lines 185, 196-203): delete `ENV_FILE_SECRET_ID` env var and the `aws secretsmanager` + `scp .env` + `rm .env` block.

**4b. Add script 06 to SCP/chmod** (~lines 244-253): add `06_provision_secrets_tmpfs.sh` to the `scp` and `chmod` blocks alongside 03-05.

**4c. Call script 06** in "Setup DEMO Instance /w PKI" step (~line 279): add `./06_provision_secrets_tmpfs.sh` after `./05_aws_sts_credential_req.sh`.

**4d. Add `--env-file` flag** (line 289): `docker compose --env-file /run/secrets/.env up --build --detach` for Compose-level YAML interpolation.

---

## Critical Files

| File | Action |
|------|--------|
| `pki/06_provision_secrets_tmpfs.sh` | **Create** |
| `pki/05_aws_sts_credential_req.sh` | **Modify** - remove lines 22-32 |
| `docker-compose.demo.instance.yml` | **Modify** - 3 env_file paths |
| `.github/workflows/webservice-deployment-pipeline.yml` | **Modify** - remove .env SCP, add script 06, add --env-file |

## Verification

```bash
# On remote after deployment:
mountpoint /run/secrets && mount | grep /run/secrets
wc -l /run/secrets/.env
test ! -f /usr/local/etc/fiscalismia-demo/.env && echo "PASS: no .env on disk"
cd /usr/local/etc/fiscalismia-demo && docker compose --env-file /run/secrets/.env config | grep POSTGRES
docker exec fiscalismia-backend env | grep -c .
systemctl status run-secrets.mount
systemctl list-timers | grep secrets-refresh
```
