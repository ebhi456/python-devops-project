# Python DevOps Project – End-to-End AWS, Jenkins, Docker & EKS Documentation

## 1. Project Overview

This project demonstrates an end-to-end DevOps workflow for a Python FastAPI Employee API backed by PostgreSQL.

### Technology Stack

* Python / FastAPI
* Uvicorn
* PostgreSQL 18
* SQLAlchemy
* psycopg2-binary
* Pytest
* Docker
* Docker Compose
* Jenkins CI/CD
* AWS ECR
* Terraform
* Amazon VPC
* Amazon EKS
* Kubernetes
* AWS EBS CSI Driver
* IAM / OIDC / IRSA
* Cluster Autoscaler
* AWS Load Balancer Controller

### Target Architecture

```text
Developer
   |
   v
Git Repository
   |
   v
Jenkins CI/CD
   |
   +--> Checkout
   +--> Dependencies
   +--> Pytest
   +--> Docker build
   +--> Push image to Amazon ECR
   |
   v
Amazon ECR
   |
   v
Amazon EKS
   |
   +--> employee-api Deployment
   |      +--> API Pod 1
   |      +--> API Pod 2
   |
   +--> employee-api ClusterIP Service
   |
   +--> employee-db Service
   |      |
   |      v
   |   PostgreSQL Pod
   |
   +--> AWS Load Balancer Controller
          |
          v
        AWS ALB
```

## 2. Repository Structure

```text
python-devops-project/
├── app/
├── tests/
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── Jenkinsfile
├── .env.example
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── vpc.tf
│   ├── eks.tf
│   ├── eks_nodes.tf
│   ├── iam.tf
│   ├── oidc.tf
│   ├── cluster_autoscaler.tf
│   ├── aws_load_balancer_controller.tf
│   └── ...
└── kubernete_files/
    ├── namespace.yml
    ├── employee-api-configmap.yml
    ├── employee-api-secret.yml
    ├── employee-api-deployment.yml
    ├── employee-api-service.yml
    ├── employee-db.yml
    └── employee-db-service.yml
```

## 3. Application Setup

Create a Python environment:

```bash
sudo apt update
sudo apt install -y python3-pip python3-venv

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt
```

Important dependencies:

```text
psycopg2-binary==2.9.12
SQLAlchemy==2.0.51
```

Run locally:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Health endpoint:

```text
GET /health
```

## 4. Testing

Run the test suite:

```bash
pytest
```

An early issue occurred in `tests/test_health.py` due to imports. Testing must remain before deployment in CI.

## 5. Dockerization

Build the application image:

```bash
docker build -t employee-api:1.0 .
docker images
```

## 6. Docker Compose

Docker Compose was used to validate FastAPI and PostgreSQL before deploying to EKS.

```yaml
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: ${DB_NAME}
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:18
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 5s
      timeout: 5s
      retries: 10
      start_period: 10s
    volumes:
      - postgres_data:/var/lib/postgresql

volumes:
  postgres_data:
```

Start and validate:

```bash
docker compose up --build
docker compose ps
docker compose logs
curl http://localhost:8000/health
```

> **PostgreSQL 18 note:** PostgreSQL 18 requires attention to the persistent mount path. The documented configuration uses `/var/lib/postgresql`.

## 7. Jenkins CI/CD

Jenkins performs the following stages:

1. Git checkout
2. Python dependency installation
3. Pytest
4. Docker/Compose validation
5. Docker image build
6. ECR authentication
7. ECR image push
8. Health validation

### CI/CD Architecture

```text
Jenkins/CI EC2
      |
      v
Docker Build
      |
      v
Amazon ECR
      |
      v
Amazon EKS
```

The Jenkins EC2 instance is the CI/build host and is **not** the production application runtime.

### ECR Repository

```text
python-devops-project-app
```

### ECR URL

```text
965224989055.dkr.ecr.us-east-1.amazonaws.com/python-devops-project-app
```

Example ECR authentication:

```bash
aws ecr get-login-password --region us-east-1 \
  | docker login \
  --username AWS \
  --password-stdin \
  965224989055.dkr.ecr.us-east-1.amazonaws.com
```

Kubernetes deployment image:

```text
965224989055.dkr.ecr.us-east-1.amazonaws.com/python-devops-project-app:35
```

## 8. Terraform Infrastructure

Terraform manages the AWS infrastructure.

### VPC

VPC:

```text
vpc-0127a27ab1eb15075
```

### Public Subnets

| Availability Zone | CIDR        | Subnet                   |
| ----------------- | ----------- | ------------------------ |
| us-east-1a        | 10.0.1.0/24 | subnet-0060c13649642903b |
| us-east-1b        | 10.0.2.0/24 | subnet-0bdd38e4a47cddbb4 |

### Private Subnets

| Availability Zone | CIDR         | Subnet                   |
| ----------------- | ------------ | ------------------------ |
| us-east-1a        | 10.0.11.0/24 | subnet-014d9fd89776bdf14 |
| us-east-1b        | 10.0.12.0/24 | subnet-0e58dac800b9aa284 |

EKS worker nodes use the private subnets.

### NAT and Routing

Terraform resources include:

```text
aws_eip.nat
aws_nat_gateway.employee_api_nat
aws_route_table.private
aws_route_table.public
aws_route_table_association.private[0]
aws_route_table_association.private[1]
aws_route_table_association.public[0]
aws_route_table_association.public[1]
```

Traffic flow:

```text
Private Subnet
      |
      v
Private Route Table
      |
      v
NAT Gateway
      |
      v
Internet Gateway
      |
      v
Internet
```

## 9. Amazon EKS

Cluster details:

```text
Name:    python-devops-project-eks
Region:  us-east-1
Version: 1.33
Status:  ACTIVE
```

Configure `kubectl`:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name python-devops-project-eks
```

Verify:

```bash
kubectl get nodes
kubectl get pods -A
```

## 10. EKS Managed Node Group

Node group:

```text
python-devops-project-nodes
```

Scaling configuration:

```text
Desired: 2
Minimum: 1
Maximum: 3
Status: ACTIVE
```

Nodes are deployed in:

```text
subnet-014d9fd89776bdf14
subnet-0e58dac800b9aa284
```

## 11. EBS CSI Driver

The AWS EBS CSI Driver is configured as an EKS add-on.

Verify:

```bash
aws eks describe-addon \
  --cluster-name python-devops-project-eks \
  --addon-name aws-ebs-csi-driver \
  --region us-east-1 \
  --query 'addon.{Status:status,Version:addonVersion}' \
  --output table
```

### Terraform Taint Issue

An issue occurred when the EBS CSI add-on became tainted:

```text
aws_eks_addon.ebs_csi is tainted, so must be replaced
```

Recovery:

```bash
terraform untaint aws_eks_addon.ebs_csi
terraform plan
```

Expected result after recovery:

```text
No changes. Your infrastructure matches the configuration.
```

## 12. EKS OIDC / IRSA

OIDC-related Terraform resources:

```text
data.tls_certificate.eks_oidc
aws_iam_openid_connect_provider.eks
data.aws_iam_openid_connect_provider.eks
```

Authentication flow:

```text
Kubernetes ServiceAccount
        |
        v
OIDC Provider
        |
        v
IAM Role
        |
        v
AWS API
```

OIDC/IRSA is required for AWS-integrated Kubernetes components such as:

* Cluster Autoscaler
* AWS Load Balancer Controller

## 13. Cluster Autoscaler

IAM resources:

```text
aws_iam_policy.cluster_autoscaler
aws_iam_role.cluster_autoscaler
aws_iam_role_policy_attachment.cluster_autoscaler
```

Node group configuration:

```text
min     = 1
desired = 2
max     = 3
```

The Cluster Autoscaler can adjust the number of nodes within this configured range when Kubernetes workloads require additional capacity.

## 14. Kubernetes Namespace

Create the namespace:

```bash
kubectl create namespace employee-api
```

Verify:

```bash
kubectl get namespace employee-api
```

## 15. ConfigMap and Secret

Example ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: employee-api-config
  namespace: employee-api
data:
  DB_HOST: "employee-db"
  DB_PORT: "5432"
```

Example Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: employee-db-secret
  namespace: employee-api
type: Opaque
stringData:
  DB_NAME: employee_db
  DB_USER: ebinejar_user
  DB_PASSWORD: CHANGE_ME
```

> **Security:** Never commit real credentials to GitHub. Use Kubernetes Secrets, an external secrets solution, or another appropriate secrets-management system for production.

## 16. PostgreSQL

Database flow:

```text
Employee API Pod
      |
      | employee-db:5432
      v
employee-db Service
      |
      v
PostgreSQL Pod
```

Database Service:

```text
Name:      employee-db
Type:      ClusterIP
Port:      5432
```

### Current Persistence Status

The documented command:

```bash
kubectl get pvc -n employee-api
```

returned:

```text
No resources found in employee-api namespace.
```

Therefore, PostgreSQL is **not currently backed by a Kubernetes PersistentVolumeClaim**.

It should **not** be considered production-grade persistent storage in its current form.

Before production use, add a PVC backed by AWS EBS or use a managed database such as Amazon RDS.

## 17. Employee API Deployment

The API Deployment runs two replicas:

```yaml
replicas: 2
```

Image:

```text
965224989055.dkr.ecr.us-east-1.amazonaws.com/python-devops-project-app:35
```

Container port:

```text
8000
```

Health endpoint:

```text
/health
```

Successful state observed:

```text
employee-api-678974fbf-cb9wg   1/1 Running
employee-api-678974fbf-jzjwt   1/1 Running
employee-api Deployment         2/2
```

## 18. Employee API Service

Initially, the API Deployment existed without an API Service. This caused:

```text
services "employee-api" not found
```

The correct Service configuration is:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: employee-api
  namespace: employee-api
  labels:
    app: employee-api
spec:
  type: ClusterIP
  selector:
    app: employee-api
  ports:
    - name: http
      port: 8000
      targetPort: 8000
      protocol: TCP
```

Verify:

```bash
kubectl get svc -n employee-api
kubectl get endpointslice -n employee-api
```

The API Service successfully resolved to both API Pods:

```text
10.0.11.79:8000
10.0.12.110:8000
```

## 19. Internal API Test

Run a temporary curl Pod:

```bash
kubectl run curl-test \
  -n employee-api \
  --image=curlimages/curl \
  --restart=Never \
  --command -- \
  curl -s http://employee-api:8000/health
```

Check the result:

```bash
kubectl logs curl-test -n employee-api
```

Clean up:

```bash
kubectl delete pod curl-test -n employee-api
```

This verifies Kubernetes service discovery and internal connectivity from within the cluster.

## 20. Troubleshooting Lessons

### 20.1 `kubectl apply` Syntax

Incorrect:

```bash
kubectl apply -f -n employee-api employee-api-deployment.yml
```

Correct:

```bash
kubectl apply -n employee-api -f employee-api-deployment.yml
```

### 20.2 `kubectl describe` Syntax

Correct:

```bash
kubectl describe pod <pod-name> -n employee-api
```

### 20.3 `kubectl logs` Syntax

Correct:

```bash
kubectl logs <pod-name> -n employee-api
```

### 20.4 Missing Database Credentials

Error:

```text
RuntimeError:
DB_USER and DB_PASSWORD environment variables are required
```

Cause:

```bash
kubectl get secrets -n employee-api
```

returned no Secret.

Fix:

1. Create the database Secret.
2. Reference the Secret from the API Deployment.
3. Restart/redeploy the affected workload if required.
4. Check the Pod logs again.

### 20.5 Missing API Service

The API Pods were running, but there was no `employee-api` Service.

Creating the ClusterIP Service fixed:

* Internal service discovery
* Kubernetes service routing
* Access to both API Pods

## 21. AWS Load Balancer Controller – Next Stage

The planned external networking architecture is:

```text
Internet
   |
   v
AWS Application Load Balancer
   |
   v
Kubernetes Ingress
   |
   v
employee-api Service
   |
   +--> API Pod 1
   +--> API Pod 2
```

The AWS Load Balancer Controller requires:

* IAM policy
* IAM role
* OIDC trust relationship
* Kubernetes ServiceAccount
* Helm release

Planned Terraform file:

```text
terraform/aws_load_balancer_controller.tf
```

Before applying infrastructure changes:

```bash
terraform validate
terraform plan
```

> **Important:** Never apply a Terraform plan containing unexpected resource destruction or replacement. Review the plan carefully before running `terraform apply`.

## 22. Demonstration Flow

For an interview or technical demonstration, present the project in this order:

1. Explain the FastAPI application and PostgreSQL database.
2. Show the Dockerfile and Docker Compose configuration.
3. Run `docker compose ps`.
4. Demonstrate the `/health` endpoint.
5. Explain the Jenkins CI/CD pipeline.
6. Show the ECR repository and container image.
7. Explain the Terraform VPC, public/private subnets, NAT Gateway, EKS cluster, and node group.
8. Show the EKS nodes.
9. Show the Kubernetes namespace, ConfigMap, Secret, Deployments, and Pods.
10. Show Services and EndpointSlices.
11. Test `/health` from inside the Kubernetes cluster.
12. Explain OIDC, IAM, EBS CSI, and Cluster Autoscaler.
13. Complete the AWS Load Balancer Controller and Ingress configuration.
14. Demonstrate external API access through the AWS ALB.

## 23. Important Verification Commands

### Terraform

```bash
terraform fmt
terraform validate
terraform plan
terraform state list
terraform output
```

### AWS

```bash
aws eks describe-cluster \
  --name python-devops-project-eks \
  --region us-east-1

aws eks describe-nodegroup \
  --cluster-name python-devops-project-eks \
  --nodegroup-name python-devops-project-nodes \
  --region us-east-1

aws ecr describe-repositories \
  --repository-names python-devops-project-app \
  --region us-east-1
```

### Kubernetes

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get all -n employee-api
kubectl get svc -n employee-api
kubectl get endpointslice -n employee-api
kubectl get secrets -n employee-api
kubectl get configmaps -n employee-api
kubectl get pvc -n employee-api
```

### Troubleshooting

```bash
kubectl logs <pod-name> -n employee-api
kubectl describe pod <pod-name> -n employee-api
```

## 24. GitHub Hygiene

Recommended `.gitignore`:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
.venv/
venv/
jenkins-venv/
.env
__pycache__/
```

Never commit:

```text
AWS access keys
Database passwords
Private keys
Real Kubernetes production secrets
terraform.tfstate
```

## 25. Current Project Status

| Component                    | Status             |
| ---------------------------- | ------------------ |
| Python FastAPI application   | ✅                  |
| PostgreSQL                   | ✅                  |
| Docker                       | ✅                  |
| Docker Compose               | ✅                  |
| Jenkins CI                   | ✅                  |
| ECR repository               | ✅                  |
| Terraform VPC                | ✅                  |
| Public + private subnets     | ✅                  |
| NAT Gateway                  | ✅                  |
| EKS cluster                  | ✅                  |
| EKS managed node group       | ✅                  |
| 2 Ready EKS nodes            | ✅                  |
| EBS CSI add-on               | ✅                  |
| EKS OIDC provider            | ✅                  |
| Cluster Autoscaler IAM       | ✅                  |
| Kubernetes namespace         | ✅                  |
| ConfigMap                    | ✅                  |
| Secret                       | ✅                  |
| Employee API Deployment      | ✅                  |
| 2 API replicas               | ✅                  |
| PostgreSQL Deployment        | ✅                  |
| Employee DB Service          | ✅                  |
| Employee API Service         | ✅                  |
| API Service endpoints        | ✅                  |
| Internal API connectivity    | ✅                  |
| AWS Load Balancer Controller | ⏳ Next stage       |
| ALB Ingress                  | ⏳ After controller |
| HTTPS / ACM                  | ⏳ Future           |
| Persistent PostgreSQL PVC    | ⏳ Future           |

## 26. One-Line Project Explanation

> Built and deployed a containerized Python FastAPI Employee Management API with PostgreSQL using Jenkins CI/CD, Docker, Amazon ECR, Terraform, Amazon EKS, Kubernetes, IAM/OIDC, EBS CSI, and autoscaling, with AWS Load Balancer integration as the next production networking layer.

## 27. Quick Start Reference

Clone the repository:

```bash
git clone <YOUR_REPOSITORY>
cd python-devops-project
```

Initialize and validate Terraform:

```bash
cd terraform

terraform init
terraform validate
terraform plan
terraform apply
```

Configure `kubectl`:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name python-devops-project-eks
```

Verify the cluster:

```bash
kubectl get nodes
kubectl get pods -A
```

Apply Kubernetes resources:

```bash
cd ../kubernete_files

kubectl apply -f namespace.yml
kubectl apply -f employee-api-configmap.yml
kubectl apply -f employee-api-secret.yml
kubectl apply -f employee-db.yml
kubectl apply -f employee-db-service.yml
kubectl apply -f employee-api-deployment.yml
kubectl apply -f employee-api-service.yml
```

Verify the application:

```bash
kubectl get all -n employee-api
kubectl get endpointslice -n employee-api
```

Test internal API connectivity:

```bash
kubectl run curl-test \
  -n employee-api \
  --image=curlimages/curl \
  --restart=Never \
  --command -- \
  curl -s http://employee-api:8000/health
```

Remove the temporary test Pod:

```bash
kubectl delete pod curl-test -n employee-api
```

> **Maintenance note:** Keep the quick-start commands synchronized with the final filenames and Terraform configuration committed to GitHub.
