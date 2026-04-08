# AWS Free Tier Deployment Guide

This project is highly compatible with the **AWS Free Tier**, which allows you to host the entire system with zero or minimal costs for the first 12 months.

## 1. Project Readiness Overview
The project is architected in a modular way (Golang Backend, PostgreSQL Database, Flutter Frontend) which translates perfectly to AWS infrastructure.

| Component | AWS Service | Free Tier Eligibility |
| :--- | :--- | :--- |
| **Backend API** | Amazon EC2 (t2.micro/t3.micro) | 750 hours/month (Free) |
| **Database** | Amazon RDS (PostgreSQL t2/t3.micro) | 750 hours/month + 20GB Storage (Free) |
| **Notifications** | Amazon SNS | 1 Million Mobile Push Notifications (Free) |
| **File Storage** | Amazon S3 | 5GB Storage (Free) |
| **Frontend (Web)**| Amazon S3 + CloudFront | 50GB Data Transfer (Free) |

---

## 2. Infrastructure Setup (Step-by-Step)

### A. Database (RDS)
1. Go to the **RDS Console** and create a new database.
2. Select **PostgreSQL**.
3. Choose the **"Free Tier"** template.
4. Set the master username and password (matches your `.env` or update accordingly).
5. **Important**: Under "Connectivity", ensure "Public access" is set to "Yes" if you want to connect from your local machine (though for production, only EC2 should have access).

### B. Backend (EC2)
1. Launch an instance using **Amazon Linux 2023** (t2.micro).
2. **Security Group**: Open port `8080` (API) and `22` (SSH).
3. SSH into the instance and install Go: `sudo yum install golang -y`.
4. Build and run: `go build -o server backend/cmd/server/main.go`.

### C. Notifications (SNS)
The project includes a real AWS SNS implementation in `backend/internal/notification/aws_sns.go`. 1. Create an SNS Topic. 2. Request a limit increase if needed.

---

## 3. Configuration & Wiring
To move from "Development" to "AWS Production", update these values:

### Backend `.env` Changes
```env
DB_HOST=your-rds-endpoint.aws.com
DB_PORT=5432
DB_NAME=civic_db
DB_USER=your_user
DB_PASSWORD=your_password
AWS_REGION=ap-south-1
```

### Frontend (Flutter) Change
The frontend currently has a hardcoded local IP. You **must** update this to your EC2 Elastic IP:
- **File**: `frontend/lib/core/utils/api_constants.dart`
- **Change**: `static const String baseUrl = "http://YOUR-AWS-IP:8080";`

---

## 4. Current "Readiness" Gaps (Action Items)

1. **SNS Activation**: In `backend/cmd/server/main.go` (Line 83), change `auth.MockSNSSender{}` to `notification.NewAWSSNS(cfg.AWSRegion)`.
2. **Dockerization**: The files in `infra/docker/` are placeholders. Populate them to use AWS ECS or App Runner.
3. **Migrations**: Run `go run backend/cmd/migrate/main.go` before starting the server.

## 5. Security Best Practices
- **IAM Roles**: Use IAM Roles for EC2 instead of putting Secret Keys in `.env`.
- **VPC**: Place RDS in a private subnet for better security.
