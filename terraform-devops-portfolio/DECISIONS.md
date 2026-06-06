# Architecture decisions

A record of key decisions made in this project and the reasoning behind them.
This file is specifically for interviewers and reviewers who want to understand *why*,
not just *what*.

---

## K3s instead of EKS

**Decision:** Run Kubernetes on EC2 t2.micro instances using K3s rather than AWS EKS.

**Reasoning:** EKS charges $0.10/hour for the managed control plane regardless of usage —
that is $72/month just to have a cluster sitting idle. For a portfolio project with no
real traffic, this cost is unjustifiable. K3s is a CNCF-certified, production-grade
Kubernetes distribution that runs comfortably on 512MB RAM. It provides the same
Kubernetes primitives (Deployments, Services, ConfigMaps, RBAC) with zero control-plane
cost on free-tier EC2.

**Trade-off:** In a real production environment I would use EKS for the managed control
plane, automatic etcd backups, seamless node group upgrades, and native AWS integrations
(Load Balancer Controller, IRSA). The decision to use K3s here is explicitly a cost
decision, not a capability preference.

---

## OIDC over static IAM keys for GitHub Actions

**Decision:** Use GitHub's OIDC provider with `sts:AssumeRoleWithWebIdentity` instead of
storing `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as GitHub secrets.

**Reasoning:** Static long-lived keys are a security liability. If a key leaks (accidental
commit, secret scanning bypass, supply-chain attack on a GitHub Action), an attacker has
persistent AWS access until someone manually rotates it. OIDC issues short-lived tokens
scoped to a specific repository and workflow run — the token expires when the job ends and
can never be used outside that context.

**Trade-off:** OIDC requires an initial IAM setup that static keys don't. This is a
one-time cost that pays back immediately in security posture.

---

## S3 + DynamoDB for remote state

**Decision:** Store Terraform state in S3 with DynamoDB locking rather than local state files.

**Reasoning:** Local state files cannot be shared across team members or CI/CD pipelines.
Two concurrent `terraform apply` runs on local state will corrupt the state file.
S3 provides durable, versioned storage (state can be rolled back). DynamoDB provides
a distributed lock so only one apply runs at a time.

**Trade-off:** Requires bootstrapping (the S3 bucket and DynamoDB table must exist before
any other Terraform can run). This is handled by the `bootstrap/` directory which is
applied manually once.

---

## Modular structure (modules/ + environments/)

**Decision:** Separate reusable modules from environment-specific configuration.

**Reasoning:** Flat Terraform configs (one giant `main.tf`) cannot be reused across
environments. The module pattern allows `dev` and `prod` to share identical infrastructure
code while differing only in variable values (instance size, replica count, CIDR ranges).
This is the standard pattern used in production Terraform codebases.

**Trade-off:** More files and indirection than a flat structure. Worth it once you have
more than one environment.

---

## ap-south-1 (Mumbai) region

**Decision:** Default region is `ap-south-1`.

**Reasoning:** Closest AWS region to Chennai, India. Lower latency for development and
lower data transfer costs. Free-tier is region-agnostic so there is no cost reason to
prefer `us-east-1`.
