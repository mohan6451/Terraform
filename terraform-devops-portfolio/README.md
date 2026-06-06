# Terraform DevOps Portfolio — AWS + K3s + GitOps

A production-pattern AWS infrastructure project built with Terraform, provisioning a
K3s Kubernetes cluster on free-tier EC2 instances with a full GitOps CI/CD pipeline
via GitHub Actions.

## Architecture

```
GitHub PR  ──►  terraform plan  ──►  PR comment with plan diff
GitHub merge ──►  terraform apply  ──►  AWS infrastructure
```

**Infrastructure layers:**

| Layer | Resources |
|---|---|
| Networking | VPC, 2 public + 2 private subnets (2 AZs), IGW, route tables |
| Compute | 1 K3s master + 2 K3s workers on `t2.micro` (free tier) |
| Security | Least-privilege security groups, IAM instance profiles |
| State | S3 (versioned, encrypted) + DynamoDB state lock |
| CI/CD | GitHub Actions with OIDC auth (no static AWS keys) |

## Cost

**$0/month** on AWS free tier (750 hours/month of t2.micro included).

> Always run `terraform destroy` after demos — EC2 instances run whether or not you are
> using them.

## Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/install) >= 1.5
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured
- SSH key pair: `ssh-keygen -t ed25519 -f ~/.ssh/k3s-key`
- AWS free-tier account

## Quick start

### Step 1 — Bootstrap remote state (once only)

```bash
cd bootstrap
cp terraform.tfvars terraform.tfvars.local
# Edit terraform.tfvars.local — set a unique state_bucket_name
terraform init
terraform apply -var-file=terraform.tfvars.local
```

### Step 2 — Update backend config

Edit `environments/dev/main.tf` and replace the `bucket` value in the `backend "s3"` block
with the bucket name from Step 1 output.

### Step 3 — Configure variables

```bash
cd environments/dev
cp terraform.tfvars terraform.tfvars.local
# Edit: set github_org, your IP in allowed_ssh_cidrs
```

### Step 4 — Deploy

```bash
terraform init
terraform plan -var-file=terraform.tfvars.local
terraform apply -var-file=terraform.tfvars.local
```

### Step 5 — Configure kubectl

Run the command from the `kubeconfig_command` output, then:

```bash
kubectl get nodes        # should show 1 master + 2 workers
kubectl apply -f ../../k3s-manifests/sample-app/
kubectl get pods
```

Access the app at `http://<master_public_ip>:30080`

### Destroy when done

```bash
terraform destroy -var-file=terraform.tfvars.local
```

Or trigger the `Terraform Destroy` workflow from GitHub Actions → Actions tab.

## CI/CD setup

1. Fork/clone this repo to your GitHub account
2. Run Step 1–3 above to get the `github_actions_role_arn` output
3. Add GitHub secret: `AWS_ROLE_ARN` = the role ARN from output
4. Push a branch and open a PR — the plan workflow runs automatically
5. Merge to `main` — the apply workflow runs automatically

## Project structure

```
├── bootstrap/               # Run once to create S3 + DynamoDB for state
├── modules/
│   ├── vpc/                 # VPC, subnets, IGW, route tables
│   ├── ec2/                 # K3s master + worker EC2 instances
│   ├── security-groups/     # Ingress/egress rules
│   └── iam/                 # EC2 instance profile + GitHub OIDC role
├── environments/
│   ├── dev/                 # Dev environment (wires all modules)
│   └── prod/                # Prod environment (larger instances)
├── .github/workflows/
│   ├── terraform-plan.yml   # Runs on PR
│   ├── terraform-apply.yml  # Runs on merge to main
│   └── terraform-destroy.yml # Manual trigger only
├── k3s-manifests/
│   └── sample-app/          # Nginx deployment to verify cluster
├── DECISIONS.md             # Why each architectural choice was made
└── README.md
```

## Why K3s instead of EKS?

See [DECISIONS.md](./DECISIONS.md) for the full reasoning. Short answer: EKS costs
$72/month just for the control plane. K3s provides identical Kubernetes primitives on
free-tier EC2.
