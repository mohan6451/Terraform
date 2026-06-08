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
| Compute | 1 K3s master + 2 K3s workers on `c7i-flex.large` (free tier) |
| Security | Least-privilege security groups, IAM instance profiles |
| State | S3 (versioned, encrypted) + DynamoDB state lock |
| CI/CD | GitHub Actions with OIDC auth (no static AWS keys) |

## Cost

**$0/month** on AWS free tier (750 hours/month of c7i-flex.large included).

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


tfstate file purge:

1. Empty the S3 bucket 
        aws s3 rm s3://tfstate-portfolio-mohan --recursive

    # Delete all versioned objects
        aws s3api delete-objects \
          --bucket tfstate-portfolio-mohan \
          --delete "$(aws s3api list-object-versions \
            --bucket tfstate-portfolio-mohan \
            --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
            --output json)"
    #Delete delete markers too
        aws s3api delete-objects \
          --bucket tfstate-portfolio-mohan \
          --delete "$(aws s3api list-object-versions \
            --bucket tfstate-portfolio-mohan \
            --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
            --output json)"
    #Delete the S3 bucket

        aws s3 rb s3://tfstate-portfolio-mohan --force

2. Delete the DynamoDB table
        aws dynamodb delete-table --table-name terraform-state-lock --region us-east-1

3. Verify 
        aws s3 ls | grep tfstate-portfolio-mohan
        aws dynamodb list-tables --region us-east-1 | grep terraform-state-lock

```



## Project structure

```
terraform-k3s-aws-infra/
├── bootstrap/                  # run once — creates S3 + DynamoDB
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── modules/
│   ├── vpc/                    # custom VPC, subnets, IGW
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security-group/         # inbound/outbound SG rules
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/                    # EC2 instance role + policies
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2-k3s/                # EC2 with K3s bootstrap script
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── scripts        # K3s init script
│            └── master.sh
│            └── worker.sh
├── main.tf                     # root — calls all modules
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── backend.tf                  # points to S3 remote state


```

IMDSv2 token-based request used;

Step 1: Request a Session TokenYour application or script must first issue an HTTP PUT request to a local, non-routable IP address (169.254.169.254). This request must include a header specifying how long you want the token to last (up to 6 hours).

# Example: Requesting a token valid for 21600 seconds (6 hours)
TOKEN=$(curl -X PUT "http://169.254.169" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

Step 2: Use the Token to Fetch MetadataOnce you have the token string, you must include it inside a custom HTTP header (X-aws-ec2-metadata-token) in every subsequent metadata request.

# Example: Using the token to safely fetch the instance's IAM security credentials
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169


During the initial instance startup, the cloud-init package fetches network parameters from AWS and logs them. You can search these text files:Path: /var/log/cloud-init-output.log or /var/log/cloud-init.log



aws: [ERROR]: An error occurred (AccessDeniedException) when calling the PutParameter operation: User: arn:aws:sts::070815351274:assumed-role/dev-k3s-ec2-role/i-07bf3551a46fb0a8e is not authorized to perform: ssm:PutParameter on resource: arn:aws:ssm:us-east-1:070815351274:parameter/dev/k3s/node-token because no identity-based policy allows the ssm:PutParameter action
2026-06-08 07:41:28,782 - cc_scripts_user.py[WARNING]: Failed to run module scripts_user (scripts in /var/lib/cloud/instance/scripts)
2026-06-08 07:41:28,782 - log_util.py[WARNING]: Running module scripts_user (<module 'cloudinit.config.cc_scripts_user' from '/usr/lib/python3/dist-packages/cloudinit/config/cc_scripts_user.py'>) failed
Cloud-init v. 26.1-0ubuntu1~24.04.1 finished at Mon, 08 Jun 2026 07:41:28 +0000. Datasource DataSourceEc2Local.  Up 43.38 seconds


sol: Added ssm putParameter permission in iam.tf 

--------------------------------------------------------------------------
separated the shell script from the main.tf for handle free and fixed the syntax errors from shell script 
--------------------------------------------------------------------------
to check the worker node got token: aws ssm get-parameter --name "/dev/k3s/node-token" --with-decryption --region us-east-1

----------------------------------
# Check if K3s service exists and its status
sudo systemctl status k3s

# Check if the install script ran at all
ls /etc/rancher/k3s/

# Check the cloud-init user_data logs — this shows if bootstrap script ran
sudo cat /var/log/cloud-init-output.log | tail -50

# Watch K3s install in real time
sudo journalctl -u k3s -f


