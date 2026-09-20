[README (1).md](https://github.com/user-attachments/files/32426863/README.1.md)
# AWS Cloud Engineer Journey

Work log for the IDX Exchange AWS Cloud Engineer intern track. Over 12 weeks I take one small Flask app, **PropertyLite**, from a local script to a containerized, monitored, Terraform-managed production deployment on AWS.

**Goal:** AWS Certified Solutions Architect Associate (SAA-C03) readiness, plus a working capstone I can destroy and rebuild from scratch with `terraform apply`.

---

## Progress

| Week | Topic | What PropertyLite gets | Status |
|---|---|---|---|
| 00 | Environment setup | Runs locally | ☐ |
| 01 | Cloud fundamentals, account security | | ☐ |
| 02 | IAM and least privilege | | ☐ |
| 03 | EC2 | First deploy on a real server | ☐ |
| 04 | S3, RDS, DynamoDB | Real (sanitized) listing data | ☐ |
| 05 | VPC networking | Public and private subnets | ☐ |
| 06 | ALB and Auto Scaling | Load balanced, self-healing | ☐ |
| 07 | Lambda, API Gateway, SQS | Serverless read path | ☐ |
| 08 | Terraform | Infrastructure as code | ☐ |
| 09 | Docker, ECR, ECS Fargate | Containerized | ☐ |
| 10 | GitHub Actions CI/CD with OIDC | Automated releases | ☐ |
| 11 | CloudWatch, Well-Architected, cost | Dashboards and alarms | ☐ |
| 12 | Capstone | Production-ready | ☐ |

---

## Repo structure

```
aws-cloud-engineer-journey/
├── README.md
├── .gitignore
├── propertylite/            # The app operated all program
│   ├── app.py
│   ├── requirements.txt
│   ├── rets_property_sample.csv
│   └── Dockerfile           # Added in Week 9
├── .github/workflows/       # Added in Week 10
│   └── deploy.yml
├── week-01/
├── week-02/
│   └── policies/
├── ...
└── week-12/
```

Each `week-XX/` folder holds that week's deliverable, notes, and `billing-screenshot.png`.

---

## Environment

| Component | Choice |
|---|---|
| Machine | Windows laptop |
| Linux layer | WSL2 with Ubuntu |
| Editor | VS Code with the WSL, AWS Toolkit, and Terraform extensions |
| Containers | Docker Desktop with the WSL2 backend |
| AWS region | us-east-1 |

All work happens inside the Ubuntu terminal. The repo lives in the Linux filesystem at `~/aws-cloud-engineer-journey`, not under `/mnt/c/`.

---

## Setup (Week 0)

### 1. Install WSL2 and Ubuntu

In PowerShell as administrator:

```powershell
wsl --install -d Ubuntu
```

Restart Windows, open Ubuntu, and create a Linux username and password. Every command below runs in the Ubuntu terminal.

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y unzip curl wget git python3-pip python3-venv
```

### 2. AWS CLI v2

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
aws --version
```

Expected: `aws-cli/2.x.x Python/3.x.x Linux/...`

### 3. Terraform

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
terraform -version
```

Share one copy of the AWS provider across all week folders instead of downloading about 700 MB per folder:

```bash
mkdir -p ~/.terraform.d/plugin-cache
echo 'plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"' >> ~/.terraformrc
```

### 4. Docker Desktop

1. Install Docker Desktop for Windows.
2. Settings → General → enable "Use the WSL 2 based engine".
3. Settings → Resources → WSL Integration → enable Ubuntu.
4. Check from Ubuntu:

```bash
docker run --rm hello-world
```

### 5. VS Code

Install VS Code on Windows, then add these extensions: **WSL**, **AWS Toolkit**, **HashiCorp Terraform**. Open the repo from Ubuntu with:

```bash
cd ~/aws-cloud-engineer-journey && code .
```

The bottom-left corner of VS Code should say `WSL: Ubuntu`.

### 6. Git

```bash
git config --global user.name "<your-name>"
git config --global user.email "<your-email>"
git config --global core.autocrlf input
git config --global init.defaultBranch main
```

`core.autocrlf input` keeps Windows line endings out of bash scripts, which would otherwise break the Week 3 EC2 user data script.

### 7. Clone or create the repo

```bash
cd ~
mkdir aws-cloud-engineer-journey && cd aws-cloud-engineer-journey
git init
git remote add origin https://github.com/<your-username>/aws-cloud-engineer-journey.git
```

### 8. Run PropertyLite locally

```bash
cd propertylite
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python3 app.py
```

In a second Ubuntu terminal:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/properties
curl http://localhost:8080/properties/R100234
```

All three should return JSON.

---

## PropertyLite field glossary

The data uses IDX Exchange's legacy RETS column names.

| Column | Meaning |
|---|---|
| `L_ListingID` | Listing ID |
| `L_City` | City |
| `L_Keyword2` | Bedrooms |
| `LM_Dec_3` | Bathrooms |
| `LM_Int2_3` | Approx. finished square footage |
| `L_SystemPrice` | List price |
| `L_Status` | Listing status (Active, Pending, etc.) |

---

## Rules I follow in this repo

**Security**
- No root access keys, ever. Daily work uses an IAM admin user with MFA.
- No credentials in Git. That includes access keys, DB passwords, `.pem` files, and Terraform state.
- SSH keys live in `~/.ssh/` inside WSL with `chmod 400`. They never go on `/mnt/c/`.
- The raw `rets_property.sql` export contains real agent PII. It is never committed. It gets deleted from my laptop and any EC2 instance after the Lab 4.2 cleanup.

**Cost**
- Zero spend budget alert is on.
- Every lab gets torn down the same week.
- The expensive-by-the-hour resources are NAT Gateways, ALBs, and RDS. Check for those first.
- Each week's folder includes a billing screenshot showing $0.00 to $1.00.

**Workflow**
- Commit at the end of every session, not just the end of the week.
- Read `terraform plan` output before every `apply`.
- Once a resource is managed by Terraform, it only changes through Terraform.

---

## Teardown checklist (every Friday)

- [ ] EC2 instances terminated, no orphaned EBS volumes
- [ ] NAT Gateways deleted and Elastic IPs released
- [ ] Load balancers and target groups deleted
- [ ] RDS instances deleted
- [ ] ECS services and clusters deleted
- [ ] Old ECR images removed
- [ ] `terraform destroy` run for any active Terraform config
- [ ] Billing dashboard shows $0.00 to $1.00
- [ ] Billing screenshot saved to this week's folder

---

## Capstone

_Filled in during Week 12._

- Architecture diagram: `week-12/architecture.png`
- Depth items chosen: _TBD_
- Walkthrough recording: _link_
- Setup: `cd week-12 && terraform init && terraform apply`
- Teardown: `cd week-12 && terraform destroy`

---

## SAA-C03 prep

| Date | Practice exam | Score | Weak domains |
|---|---|---|---|
| | | | |

Exam date: the Monday after Week 12.
