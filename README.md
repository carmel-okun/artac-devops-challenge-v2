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

## Set/Deployment Instructions

"to update the AMI, verify compatibility with user-data.sh in a test environment first, then bump var.ami_id explicitly."

---

**You are not expected to spend any money.** Everything is achievable within AWS Free Tier and free CI/CD tooling. Use `terraform plan` to validate your infrastructure code — actual deployment to AWS is optional.

We explicitly encourage the use of AI tools throughout this assignment. What matters is not whether you used AI, but whether you understood and validated what it produced.

Good luck.
