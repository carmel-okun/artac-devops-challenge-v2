# ArtAc DevOps Challenge

## Scenario

A contractor built this ML prediction API and set up the initial deployment infrastructure before leaving the company. The application works, but the deployment setup was never fully validated or hardened for production. Some things are broken, some are intentional trade-offs, and some might need improvement.

**Your job is to take ownership of this codebase**: get it running, assess the current state of everything the contractor left behind, fix what needs fixing, and make it production-ready.

The contractor left a [`DECISIONS.md`](DECISIONS.md) file documenting some of their choices. Read it carefully — but don't assume everything in it is correct.

---

## The Application

A FastAPI service that serves a pre-trained scikit-learn sentiment classifier.

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/predict` | POST | Accepts `{"text": "..."}`, returns `{"sentiment": "positive/negative", "confidence": 0.92}` |
| `/health` | GET | Liveness probe — returns 200 if the server process is running |
| `/ready` | GET | Readiness probe — returns 200 only after the model is loaded and ready to serve |

**Run locally (without Docker):**

```bash
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

**Run tests:**

```bash
pytest tests/ -v
```

---

## What the Contractor Left

| File | Status |
|------|--------|
| `app/` | Application source code (working) |
| `models/` | Pre-trained ML model |
| `tests/` | Unit tests for the API and model |
| `requirements.txt` | Python dependencies |
| `Dockerfile` | Container image definition |
| `.github/workflows/ci.yml` | CI/CD pipeline |
| `terraform/` | AWS infrastructure code |
| `DECISIONS.md` | Contractor's notes on design choices |

---

## Your Assignment

### Rules

- **You may NOT modify files in `app/` or `models/`.** Treat the application as a black box you are deploying — this is a DevOps role, not a developer role.
- You MAY modify everything else: `requirements.txt`, `Dockerfile`, CI/CD configs, Terraform, and any supporting files.
- **Commit early and often.** We want to see your thought process, not a single final commit.

### Part 1: Get It Running (25%)

Build the Docker image and get all three endpoints (`/health`, `/ready`, `/predict`) working correctly in the container.

If something is broken, fix it. Document what you found and what you did in your assessment.

### Part 2: Assess the Codebase (40%)

This is the most important part.

Create an **`ASSESSMENT.md`** file. For each issue or decision you find across the Dockerfile, CI/CD pipeline, and Terraform configuration:

1. **What you found** — describe the issue clearly
2. **Classification** — is this a **Bug**, an **Intentional Trade-off**, or something that **Needs Improvement**?
3. **Contractor's reasoning** — does the `DECISIONS.md` mention it? Do you agree or disagree with their rationale?
4. **What you did** — did you fix it, keep it, or modify it? **Why?**

We're not looking for a specific number of findings. We're looking for accuracy, judgment, and justification. Flagging something that isn't actually a problem is just as bad as missing something that is.

### Part 3: Production-Ready Deployment (15%)

Improve the Dockerfile and deployment setup:
- The Docker image should be production-ready in every way you can think of
- Ensure the CI/CD pipeline works correctly end-to-end
- The Terraform configuration should pass `terraform plan`

### Part 4: AI Workflow Documentation (10%)

Create an **`AI_WORKFLOW.md`** that documents:
- Which AI tools you used and for what tasks
- 2-3 specific examples of prompts that worked well
- At least 1 example where AI gave you something wrong or suboptimal, and how you caught it
- Your honest estimate of time saved vs. doing it manually
- Total time spent on the assignment

### Initiative (10%)

Anything extra you think demonstrates your skills or understanding. Examples: Docker Compose for local dev, observability setup, cost analysis, deployment strategy improvements, security hardening beyond the basics.

---

## Setup / Deployment Instructions

This section covers how to build and run the app locally, how the CI/CD pipeline is wired up, and how to provision the AWS infrastructure with Terraform. See [`ASSESSMENT.md`](ASSESSMENT.md) for the reasoning behind each change, and [`DECISIONS.md`](DECISIONS.md) for the original contractor's notes.

### Prerequisites

- Docker Desktop (or Docker Engine) installed and running
- An AWS account (Free Tier is sufficient — see the [Cost / Free Tier](#cost--free-tier) note below)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured (`aws configure`) with an IAM user/role that has EC2, security group, and IAM permissions
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- A GitHub account with permission to fork this repo and manage its Actions secrets

---

### 1. Run it locally with Docker

```bash
docker build -t sentiment-api .
docker run -d --name sentiment-api -p 8080:8080 sentiment-api
```

Test the three endpoints:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/ready
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I love this product, it works great!"}'
```

On Windows PowerShell, use `curl.exe` with escaped quotes, or `Invoke-RestMethod`:

```powershell
curl.exe -X POST http://localhost:8080/predict -H "Content-Type: application/json" -d '{\"text\": \"I love this product, it works great!\"}'
```

---

### 2. CI/CD pipeline (`.github/workflows/ci.yml`)

The pipeline runs on every push/PR to `main` and has four jobs: `build` (builds and pushes the image to GHCR), `test` (runs `pytest`), `security-scan` (runs Trivy against the built image), and `deploy` (SSHes into the EC2 instance and redeploys the container). `deploy` only runs on a push to `main`, and only after `test` and `security-scan` both pass.

**To use this pipeline in your own fork:**

1. **Add repository secrets** — Settings → Secrets and variables → Actions → Repository secrets:
   | Secret | Value |
   |---|---|
   | `EC2_SSH_PRIVATE_KEY` | Full contents of the `.pem` private key for the EC2 key pair (see [Terraform setup](#3-provision-infrastructure-with-terraform) below) |

   `GITHUB_TOKEN` is provided automatically by GitHub for every run and is used to authenticate to GHCR — no setup needed.

2. **Set the EC2 target IP** — the `deploy` job currently reads the target host from a hardcoded `EC2_IP` value in the workflow's `env:` block. After running `terraform apply` (below), copy the `instance_public_ip` output into that value:
   ```yaml
   env:
     EC2_IP: "<paste terraform output instance_public_ip here>"
   ```
   This is manual by design for now — see [Known limitations](#known-limitations-and-things-id-improve-next) for how this should be automated instead.

3. **Trigger a run** — push to `main`, open a PR against `main`.

---

### 3. Provision infrastructure with Terraform

All infrastructure code lives in [`terraform/`](terraform/).

**Step 1 — Create an EC2 key pair** (needed for `ssh_key_name` and for SSH-based deploys):
```bash
aws ec2 create-key-pair --key-name sentiment-api-key --query 'KeyMaterial' --output text > sentiment-api-key.pem
chmod 400 sentiment-api-key.pem   # macOS/Linux
```
Keep the `.pem` file safe — this is also the value you paste into the `EC2_SSH_PRIVATE_KEY` GitHub secret above.

**Step 2 — Configure your variables:**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars`:
```hcl
aws_region    = "us-east-1"
instance_type = "t3.micro"                 # must be Free Tier eligible — see note below
app_port      = 8080
docker_image  = "ghcr.io/<your-username>/artac-devops-challenge-v2:<tag>"
ssh_key_name  = "sentiment-api-key"         # the key pair created above
```
`terraform.tfvars` is gitignored — it's not committed, since it can contain environment-specific values.

**Step 3 — Init, plan, apply:**
```bash
terraform init
terraform plan -out=plan-output.txt
terraform apply
```
`terraform plan` only needs valid AWS credentials (no charges incurred); `terraform apply` actually provisions the EC2 instance and security group.

**Step 4 — Get connection info:**
```bash
terraform output
```
This prints `instance_public_ip`, `instance_id`, `app_url`, and a ready-to-use `ssh_command`. Use `instance_public_ip` for the `EC2_IP` value in the CI/CD setup above.

**Step 5 — Confirm the app is up:**
```bash
curl http://<instance_public_ip>:8080/health
```
It can take a minute or two after `apply` finishes for `user-data.sh` to finish installing Docker and starting the container — if `/health` doesn't respond right away, SSH in and check progress:
```bash
ssh -i sentiment-api-key.pem ubuntu@<instance_public_ip>
sudo tail -f /var/log/user-data.log
```

**Tearing down:**
```bash
terraform destroy
```

#### A note on instance type / Free Tier

Not every `t2.*`/`t3.*` type is Free Tier eligible in every account. If `terraform apply` fails with `InvalidParameterCombination: not eligible for Free Tier`, check what's currently eligible in your account/region:
```bash
aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true" --query "InstanceTypes[].InstanceType" --output table
```

#### A note on the AMI

`ami_id` is pinned (not dynamically looked up) — this is intentional, not an oversight. See [`DECISIONS.md`](DECISIONS.md) and [`ASSESSMENT.md`](ASSESSMENT.md) for why: a prior incident showed that "latest Ubuntu AMI" lookups can silently ship an incompatible `containerd` version and break `user-data.sh`. It's exposed as a variable (default in `variables.tf`) so bumping it is a deliberate, reviewable change rather than automatic drift.

#### A note on Terraform state

Remote state (S3) is wired up but **commented out** in `terraform/main.tf`, so this repo defaults to local state and won't incur any S3 costs on its own:
```hcl
# backend "s3" {
#   bucket = "artac-terraform-state"
#   key    = "${var.project_name}/terraform.tfstate"
#   region = "us-east-1"
# }
```
To use it: create an S3 bucket yourself first (Terraform can't create the backend it's about to use — see [`ASSESSMENT.md`](ASSESSMENT.md)), uncomment the block with your bucket name, then run `terraform init -migrate-state`. DynamoDB-based state locking was deliberately left out — see `ASSESSMENT.md` for the reasoning (single-operator use case; add it back if this ever becomes a multi-operator setup).

---

### Cost / Free Tier

Everything here is designed to fit inside AWS Free Tier: a single `t3.micro` EC2 instance, a 20GB `gp3` EBS volume, and (if enabled) a few KB of S3 storage for state. No resource in this repo requires anything beyond Free Tier limits. Remember to run `terraform destroy` when you're done experimenting so nothing keeps running/accruing cost after your session.

---

### Known limitations and things I'd improve next

These are documented trade-offs, not oversights — full reasoning for each is in [`ASSESSMENT.md`](ASSESSMENT.md):

- **SSH open to `0.0.0.0/0`** — needed because GitHub-hosted Actions runners don't have a small, stable IP range to allowlist. A production fix would replace SSH-based deploys with **AWS Systems Manager (SSM) Session Manager** (no inbound port needed at all, IAM-governed, CloudTrail-audited), or move to a **self-hosted runner** inside the VPC so SSH can be restricted to a private CIDR.
- **`EC2_IP` is a manually-updated value in `ci.yml`**, rather than wired automatically from Terraform's output. The intended fix is to have the `deploy` job resolve the IP at runtime — either via `aws ec2 describe-instances --filters "Name=tag:Name,Values=..."` (no Terraform dependency in CI) or `terraform output` directly (requires the S3 backend above to be enabled so state is centrally accessible). Also worth pairing with an `aws_eip` (Elastic IP) so the address is stable across instance stop/start, not just reboots.
- **No DynamoDB state locking** — acceptable for a single-operator deployment; would be added alongside the S3 backend if multiple people/pipelines ever run `terraform apply` concurrently.
- **No explicit VPC** — resources currently rely on the AWS account's default VPC/subnet. A production setup would define an explicit VPC with proper public/private subnet separation.
- **No blue/green or zero-downtime deploy** — the deploy script does `stop` → `rm` → `run`, which has a brief window with no container serving traffic. A zero-downtime version would start the new container alongside the old one, health-check it via `/ready`, then cut over.

---

**You are not expected to spend any money.** Everything is achievable within AWS Free Tier and free CI/CD tooling. Use `terraform plan` to validate your infrastructure code — actual deployment to AWS is optional.

We explicitly encourage the use of AI tools throughout this assignment. What matters is not whether you used AI, but whether you understood and validated what it produced.

Good luck.
