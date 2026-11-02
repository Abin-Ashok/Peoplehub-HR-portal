# PeopleHub – Three-Tier AWS Cloud Deployment

## 1. Project Overview

PeopleHub is a cloud-based employee management application deployed on Amazon Web Services (AWS). The project demonstrates a three-tier architecture using AWS networking, compute, container orchestration, database services, CI/CD automation, infrastructure as code, security services, and monitoring tools.

The infrastructure is designed across two Availability Zones (AZs) to improve availability and reduce the impact of an individual AZ failure.

The application uses:
- **Frontend:** Deployed on Amazon EC2.
- **Backend:** Containerized Node.js application deployed on Amazon EKS.
- **Database:** Amazon RDS MySQL with a read replica.
- **CI/CD:** Jenkins with separate frontend and backend build pipelines.
- **Infrastructure as Code:** Terraform.
- **Container Registry:** Amazon ECR.
- **DNS and CDN:** Amazon Route 53 and Amazon CloudFront.
- **Security:** AWS WAF, ACM, IAM, Security Groups and Network ACLs.
- **Monitoring:** Amazon CloudWatch and Grafana Cloud.

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/c291c7c3-6c0d-4ad5-b86a-bd6907e0994b" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/7f4ecd83-5ec2-4a81-a086-74579f28c0c2" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/fb661d6e-b591-4b41-b4e4-8dea56870743" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/b5a2e932-d931-49ea-9fcf-5f4de66b5a00" />

## 2. Architecture Overview

<img width="3420" height="3792" alt="mermaid-diagram (1)" src="https://github.com/user-attachments/assets/5d08ebf4-cae3-4e65-b61b-a531662db712" />

The application follows a three-tier architecture.

### Tier 1 – Presentation Layer

The frontend is deployed on an Amazon EC2 instance.

Components:
- Amazon EC2 hosts the frontend application.
- Nginx serves the frontend and handles reverse proxy configuration.
- CloudFront distributes application content.
- AWS WAF protects the CloudFront distribution.
- AWS Certificate Manager provides HTTPS certificates.
- Route 53 manages DNS records for the application domain.

The domain is registered with GoDaddy. A Route 53 hosted zone is created for the domain, and its nameservers are configured in GoDaddy so that Route 53 manages DNS resolution.

### Tier 2 – Application Layer

The backend is deployed on Amazon Elastic Kubernetes Service (EKS).

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/7082a8fd-75ba-4435-89e9-2610f8f76c3a" />

Components:
- Amazon EKS manages the Kubernetes cluster.
- Backend Docker images are stored in Amazon ECR.
- AWS Application Load Balancer Controller manages Kubernetes Ingress resources.
- An internal Application Load Balancer routes traffic to the backend services.
- Backend pods run in the `peoplehub` Kubernetes namespace.
- Kubernetes Services distribute requests to backend pods.
- Horizontal Pod Autoscaler supports application scaling.
- Amazon SQS handles asynchronous messaging.
- AWS Lambda processes SQS messages.
- Amazon SES sends email notifications.

The frontend communicates with the backend through the internal ALB using the configured API proxy.

### Tier 3 – Database Layer

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/b0f2dff8-9ed6-4f55-9e0e-cc39affe1015" />

Amazon RDS MySQL provides persistent application data storage.

Components:
- RDS MySQL primary database.
- RDS read replica for read scaling and an additional database copy.
- Database resources are distributed across the planned Availability Zones.
- Database access is restricted through network security rules.

The database is not intended to be publicly accessible.

## 3. AWS Services Used

| Service | Purpose |
|---|---|
| Amazon VPC | Provides isolated cloud networking |
| Public and private subnets | Separates public-facing and internal resources |
| Internet Gateway | Provides internet connectivity for public subnets |
| NAT Gateway | Allows private subnet resources to access the internet |
| Route Tables | Control network traffic routing |
| Amazon EC2 | Hosts the frontend |
| Amazon EKS | Runs containerized backend workloads |
| Amazon ECR | Stores frontend and backend Docker images |
| Application Load Balancer | Routes incoming application traffic |
| Internal ALB | Routes private traffic to EKS backend services |
| Amazon RDS MySQL | Stores application data |
| RDS Read Replica | Supports read scaling |
| Amazon SQS | Provides asynchronous message processing |
| AWS Lambda | Processes queued messages |
| Amazon SES | Sends email notifications |
| Amazon CloudFront | Content delivery and application distribution |
| Amazon Route 53 | DNS hosting and domain routing |
| AWS Certificate Manager | Manages SSL/TLS certificates |
| AWS WAF | Protects the CloudFront distribution |
| AWS IAM | Controls permissions and service access |
| Amazon CloudWatch | Collects AWS metrics and logs |
| Grafana Cloud | Provides dashboards and monitoring |
| Jenkins | Automates CI/CD pipelines |
| Terraform | Provisions and manages infrastructure |

## 4. Domain, DNS and HTTPS Configuration

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/c15dc71d-bba1-450c-93ac-1783abeec8c1" />

The project uses a custom domain registered through GoDaddy.

The DNS and HTTPS setup follows this flow:

1. Register the domain through GoDaddy.
2. Create a public hosted zone in Amazon Route 53.
3. Copy the Route 53 nameservers.
4. Update the domain's nameserver records in GoDaddy.
5. Create the required DNS records in Route 53.
6. Request and validate an SSL/TLS certificate through AWS Certificate Manager.
7. Configure the certificate with CloudFront.
8. Configure AWS WAF to protect the CloudFront distribution.
9. Route application traffic through CloudFront to the configured origin.

**Important:** CloudFront certificates must be requested or imported in the `us-east-1` AWS region.

## 5. High Availability and Disaster Recovery

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/63bc5926-3313-46fc-9ab0-36092bff34a1" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/ee48795e-b0c0-4760-ac4c-3922cc116132" />

The infrastructure is designed around two Availability Zones.

The design includes:
- Resources distributed across two AZs where supported.
- Public and private subnet separation.
- NAT Gateway connectivity for private resources.
- EKS worker capacity across the AZs.
- RDS primary database and read replica.
- Load balancing for application traffic.

The read replica provides an additional database copy and can support read scaling. It should not be treated as an automatic disaster recovery failover unless replication, promotion, and recovery procedures are configured.

Similarly, two-AZ deployment improves availability but does not by itself guarantee complete disaster recovery. Recovery procedures, backups, restore testing, and documented recovery objectives are also important.

## 6. CI/CD Pipeline Using Jenkins

Jenkins is used to automate application builds and deployments.

The project uses **three separate Git repositories**, rather than a single monolithic repository.

| Repository | Responsibility |
|---|---|
| Frontend repository | Frontend application source code |
| Backend repository | Backend application source code |
| Infrastructure repository | Terraform configuration and infrastructure manifests |

### Frontend CI/CD Pipeline

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/7d972ea1-baf7-4653-af96-cfc2129bc868" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/b37de89e-f004-40c1-a56f-eb58138efed9" />

1. Developer pushes frontend code to the frontend Git repository.
2. Jenkins detects the code change.
3. Jenkins checks out the source code.
4. Dependencies are installed.
5. Frontend build is executed.
6. Docker image is built if using a containerized frontend deployment.
7. Image is pushed to Amazon ECR if applicable.
8. Frontend EC2 deployment is updated.

### Backend CI/CD Pipeline

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/e6ca83bb-dc31-43e6-8e5e-63555dd1aba1" />

1. Developer pushes backend code to the backend Git repository.
2. Jenkins detects the code change.
3. Jenkins checks out the backend source code.
4. Dependencies are installed.
5. Application tests and build checks are executed.
6. Docker image is built.
7. Image is pushed to Amazon ECR.
8. Kubernetes deployment is updated on Amazon EKS.
9. Deployment and pod status are verified.

### Infrastructure CI/CD Pipeline

The separate infrastructure repository contains Terraform code.

The workflow includes:
1. Developer updates Terraform configuration.
2. Jenkins checks out the infrastructure repository.
3. Terraform formatting and validation are executed.
4. Terraform plan is generated.
5. Changes are reviewed and approved.
6. Terraform apply provisions or updates AWS resources.

Infrastructure changes should be reviewed before applying them to production.

## 7. Infrastructure as Code – Terraform

Terraform is used to provision and manage AWS infrastructure.

The infrastructure repository manages the required AWS resources, such as:

- VPC and networking components.
- Public and private subnets.
- Internet Gateway and NAT Gateway.
- Route tables.
- Security Groups and Network ACLs.
- EC2 resources.
- EKS cluster and worker nodes.
- IAM roles and policies.
- RDS database resources.
- Supporting AWS services.

Terraform helps maintain repeatable infrastructure deployments and makes infrastructure changes easier to review and manage.

## 8. Containerization and Amazon ECR

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/22020c5b-5472-4e9a-9f87-9326ac68af88" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/1bdbef2a-516a-4421-b43f-98ea91c018c5" />

Docker is used to package the application components.

Amazon ECR stores the application container images.

Separate repositories are maintained for the frontend and backend images.

Example repository names:

- `peoplehub-frontend`
- `peoplehub-backend`

Jenkins builds and pushes the images to ECR as part of the respective CI/CD pipelines.

Amazon EKS pulls the backend image from ECR to run the application containers.

## 9. Asynchronous Processing – SQS, Lambda and SES

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/24b209f4-51d4-42cf-b118-eff3821e83d5" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/256d9da3-826e-488e-9410-a4fcbde5a0f3" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/c5c5f959-3013-4a9d-bf8f-8cf875ad2d88" />

The project uses an event-driven workflow for email notifications.

The process is:

1. A user performs an employee-related operation.
2. The backend sends an event to Amazon SQS.
3. AWS Lambda receives and processes the queued event.
4. Lambda invokes Amazon SES.
5. SES sends the required email notification.

This separates email processing from the main API request and supports asynchronous processing.

## 10. Security Implementation

Security is implemented at multiple layers.

### Network Security

- Public and private subnet separation.
- Security Groups to control instance, ALB, EKS and database traffic.
- Network ACLs for subnet-level traffic filtering.
- Private database connectivity.
- Internal ALB for private backend access.

Security Groups are stateful, while Network ACLs are stateless. Both can be used together, with Security Groups providing the primary resource-level access controls.

### Application and Edge Security

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/7331cf80-0f43-4783-8aee-e60e7e7c718c" />

- AWS WAF protects the CloudFront distribution.
- HTTPS is configured using AWS Certificate Manager.
- IAM roles and policies follow least-privilege access.
- EKS workloads use IAM permissions through EKS Pod Identity where configured.
- Kubernetes workloads are isolated using namespaces and service accounts.
- Sensitive application configuration is kept outside source code.

### Database Security

- RDS access is restricted to authorized application resources.
- Database credentials are not stored in public repositories.
- Database access is controlled through network rules and application configuration.

## 11. Monitoring and Observability

The project uses Amazon CloudWatch and Grafana Cloud.

### Amazon CloudWatch

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/fbf516a3-5998-4b56-ab87-86229d1df780" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/6fc9f802-6fdc-4b3a-9683-b82d157e9c85" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/7a930b85-e7a5-4285-a958-8c8057f0b194" />

CloudWatch is used to monitor AWS resources and collect metrics and logs.

Monitoring includes:
- EC2 performance.
- EKS and Kubernetes workloads.
- Container and pod metrics.
- Application Signals.
- AWS service metrics.
- Cognito authentication metrics.

### Grafana Cloud

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/82afaf52-3be3-424c-8074-8bbf880ba17a" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/4126be82-1f3d-4851-9d72-f0bfeb31d201" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/ac255094-49a8-421e-8f11-b1f20022e87a" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/ec56d3db-4e46-468a-aabc-3642e7ee91f6" />
<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/dc7c3103-aeeb-4d9e-bd96-56e240b4af40" />


Grafana Cloud connects to AWS CloudWatch as a data source.

It is used to build monitoring dashboards for:
- EC2 CPU and memory metrics.
- EKS cluster and workload metrics.
- Backend application performance.
- Request latency and errors.
- Cognito successful sign-in metrics.
- Cognito sign-up metrics.
- Other available AWS service metrics.

CloudWatch provides the metric data, while Grafana Cloud visualizes the data through dashboards.

## 12. Application Authentication

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/01deaf87-b62d-4006-930f-bf03b3957cb5" />

Amazon Cognito is used for user authentication.

The frontend uses the Amazon Cognito authentication SDK to authenticate users.

The backend verifies Cognito access tokens using `aws-jwt-verify`.

Protected employee API routes require valid authentication tokens.

Authentication metrics can be monitored through the AWS/Cognito CloudWatch namespace where the relevant metrics are available.

## 13. Project Benefits

- Three-tier cloud architecture.
- Separate application and infrastructure repositories.
- Automated frontend and backend CI/CD pipelines.
- Infrastructure provisioning through Terraform.
- Containerized backend deployment using Docker and EKS.
- Centralized container image management through ECR.
- DNS management through Route 53.
- CDN and edge protection through CloudFront and WAF.
- HTTPS using AWS Certificate Manager.
- Private backend and database connectivity.
- Asynchronous event processing using SQS and Lambda.
- Email notifications through SES.
- Monitoring using CloudWatch and Grafana Cloud.
- Multi-AZ architecture for improved availability.

## 14. Future Improvements

- Implement automated backup and restore testing.
- Document RDS read replica promotion and failover procedures.
- Add Jenkins automated testing and deployment approval stages.
- Configure centralized application log retention.
- Add CloudWatch alarms for critical application and infrastructure metrics.
- Implement automated vulnerability scanning for container images.
- Introduce infrastructure drift detection.
- Test disaster recovery procedures regularly.

## 15. Conclusion

PeopleHub demonstrates the deployment of a three-tier application on AWS using a combination of cloud infrastructure, container orchestration, database services, networking, security, automation, and monitoring.

The project combines Terraform for infrastructure provisioning, Jenkins for CI/CD, Docker and ECR for container management, Amazon EKS for backend deployment, EC2 for frontend hosting, and AWS managed services for DNS, content delivery, authentication, asynchronous processing, email notifications, and monitoring.

The architecture demonstrates practical implementation of AWS cloud engineering, DevOps automation, infrastructure as code, application deployment,multi-AZ availability and security.

