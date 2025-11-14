# Project: Multi-VPC Secure Network Architecture with Transit Gateway & On-Prem VPN

**Author:** Victor Ponce | **Contact:** [Linkedin](https://www.linkedin.com/in/victorhugoponce) | **Website:** [victorponce.com](https://victorponce.com)

**Spanish Version:** [README.es.md](https://github.com/victorhponcec/portfolio-aws-security-1/blob/main/README.es.md)

## 1. Overview  

This project showcases a **secure, production-grade network architecture in AWS**, fully deployed and automated using **Terraform**.  
The infrastructure consists of **three isolated VPCs** (VPCA, VPCB, VPCC) connected through an **AWS Transit Gateway**, plus an **IPSec Site-to-Site VPN** simulating an on-premises environment.

The goal of this project is to demonstrate **cloud security engineering skills**, with a focus on:

- Network segmentation & east-west isolation  
- Least-privilege security groups & controlled traffic flows  
- Encrypted communication across all layers  
- Secure access to RDS & internal applications  
- Threat detection & continuous monitoring  
- Modern cloud-native perimeter controls (WAF, CloudFront, ALB)  
- Defense-in-depth aligned with AWS Well-Architected Security Pillar  

---

## 2. Architecture

<div align="center">

![Overview Diagram](README/Diagram.png)
<p><em>(img. 1 – Architecture Diagram)</em></p>
</div>

## VPC and Subnet Configuration
<div align="center">

| VPC Name | VPC CIDR Block | Subnet Name               | Subnet CIDR Block |
|----------|----------------|---------------------------|--------------------|
| VPCA     | 10.111.0.0/16  | vpcA-public-a             | 10.111.1.0/24      |
| VPCA     | 10.111.0.0/16  | vpcA-public-b             | 10.111.2.0/24      |
| VPCA     | 10.111.0.0/16  | vpcA-private-web-1        | 10.111.10.0/24     |
| VPCA     | 10.111.0.0/16  | vpcA-private-web-2        | 10.111.11.0/24     |
| VPCB     | 10.112.0.0/16  | vpcB-private-a            | 10.112.1.0/24      |
| VPCB     | 10.112.0.0/16  | vpcB-private-b            | 10.112.2.0/24      |
| VPCC     | 10.113.0.0/16  | vpcC-private-1            | 10.113.1.0/24      |
<p><em>(Table 1 – VPCs and Subnets)</em></p>
</div>

## Route Table Configuration (VPC Route Tables)
<div align="center">

| VPC Name | Route Table           | Destination CIDR | Target (Next Hop)         | Notes                              |
|----------|------------------------|------------------|----------------------------|-------------------------------------|
| VPCA     | public_rtb_vpca       | 0.0.0.0/0        | Internet Gateway (igw)     | Internet access                     |
| VPCA     | public_rtb_vpca       | 10.112.0.0/16    | Transit Gateway (tgw)       | Route to VPCB                       |
| VPCA     | public_rtb_vpca       | 10.113.0.0/16    | Transit Gateway (tgw)       | Route to VPCC                       |
| VPCA     | private_rtb_vpca_web  | 0.0.0.0/0        | NAT Gateway (nat)          | Outbound updates for EC2/ASG        |
| VPCA     | private_rtb_vpca_web  | 10.112.0.0/16    | Transit Gateway (tgw)       | Route to VPCB                       |
| VPCA     | private_rtb_vpca_web  | 10.113.0.0/16    | Transit Gateway (tgw)       | Route to VPCC                       |
| VPCB     | private_rtb_vpcb      | 10.111.0.0/16    | Transit Gateway (tgw)       | Route to VPCA                       |
| VPCB     | private_rtb_vpcb      | 10.113.0.0/16    | Transit Gateway (tgw)       | Route to VPCC                       |
| VPCC     | private_rtb_vpcc      | 10.111.0.0/16    | Transit Gateway (tgw)       | Route to VPCA                       |
| VPCC     | private_rtb_vpcc      | 10.112.0.0/16    | Transit Gateway (tgw)       | Route to VPCB                       |
<p><em>(Table 2 – Route tables)</em></p>
</div>

## Transit Gateway Route Table
<div align="center">

| Destination CIDR | TGW Attachment (Source)   | Traffic Origin      | Notes |
|------------------|---------------------------|----------------------|-------|
| 10.111.0.0/16    | VPCA Attachment           | VPCA subnets         | Static TGW route |
| 10.112.0.0/16    | VPCB Attachment           | VPCB subnets         | Static TGW route |
| 10.113.0.0/16    | VPCC Attachment           | VPCC subnets         | Static TGW route |
| (dynamic via BGP) | VPN Attachment           | On-prem network      | Propagated if BGP enabled |
<p><em>(Table 3 – Transit Gateway Route tables)</em></p>
</div>

## Transit Gateway Attachments
<div align="center">

| VPC / VPN | Attached Subnets                                                                 | Notes |
|-----------|-----------------------------------------------------------------------------------|-------|
| VPCA      | public-a, public-b, private-web-1, private-web-2                                 | Full ingress/egress hybrid routing |
| VPCB      | private-a, private-b                                                             | Database / internal workload VPC |
| VPCC      | private-1                                                                        | Reporting instance VPC |
| VPN       | Virtual VPN attachment (AWS side)                                                | BGP or static routing supported |
<p><em>(Table 4 – Transit Gateway attachments)</em></p>
</div>

---

## 3. Infrastructure Summary  

The architecture is divided into **three VPCs**, each with a specific purpose:

---

### VPCA – Web Tier / Public Entry Point

VPCA hosts the public-facing and application logic components:

- **ALB (HTTPS)** with ACM certificate  
- **Auto Scaling Group**  
- **Private subnets** for ASG instances  
- **Public subnets** each with a **NAT Gateway**  
- **VPC Endpoint for Secrets Manager**  
- Strict **security groups**:  
  - ALB only accepts CloudFront origin traffic  
  - App servers only accept traffic from ALB  
  - Outbound minimized  

---

### VPCB – Database & Internal Applications

VPCB contains backend and sensitive components:

- **RDS MySQL**, multi-AZ  
- **One internal EC2 instance** simulating a backend service  
- **No public internet exposure**  
- DB SG only allows traffic from:  
  - VPCA private subnets  
  - VPCC reporting instance  

---

### VPCC – Reporting Tier

VPCC contains:

- **One EC2 instance** used for analytics/reporting  
- Private-only access via Transit Gateway  
- Communicates with RDS in VPCB  

---

### On-Premises Simulation

A fourth VPC simulates an on-premises data center:

- **Ubuntu instance** acting as customer gateway  
- **IPSec VPN connection** to AWS  
- Full route propagation to the Transit Gateway  

Note that the simulated on-prem environment can be easily replaced and integrated with a firewall appliance such as FortiGate (as shown in the architecture diagram) by downloading the VPN config. 

---

## 4. Key Security Services Implemented  

### Identity & Access  
- EC2 IAM roles with limited Secrets Manager & SSM access  
- Minimal IAM policies  
- Terraform-managed SSH key via `tls_private_key`

### Network Security  
- Multi-VPC segmentation  
- Transit Gateway routing isolation  
- NAT Gateways for controlled egress  
- VPC Flow Logs stored in S3  
- VPC Endpoint for Secrets Manager  

### Threat Detection & Monitoring  
- **GuardDuty** with SNS alerts  
- **CloudTrail** (encrypted, delivered to S3)  
- **AWS Config** with rules  
- **CloudWatch** alarms & EventBridge rules  

### Application & Edge Security  
- A **CloudFront** distribution with ACM certificate 
- **AWS WAFv2 Web ACL**  
- **ALB HTTPS** listener  

### Data Security  
- RDS encrypted  
- Credentials stored in **Secrets Manager**  
- App servers fetch DB secrets via IAM role  

---

## 5. Networking Logic  

### Routing Overview  
- All VPC-to-VPC traffic flows **through Transit Gateway**  
- VPCA private subnets use NAT Gateways for outbound updates  
- VPCB/VPCC have **no direct internet access**  
- VPN routes for on-prem are propagated to the TGW  
- East-west traffic is strictly controlled  

---

## 6. Deployed Terraform Resources  

| Category | Key Resources |
|---------|--------------|
| **Networking** | VPCs, Subnets, IGWs, NAT GWs, TGW, TGW routes, VPN, Customer Gateway |
| **Compute** | EC2 (3 total), Auto Scaling Group, Launch Template |
| **Security** | SGs (web/app/db/reporting), WAFv2, GuardDuty, AWS Config, CloudTrail, Flow Logs |
| **Identity** | IAM roles, instance profiles, Secrets Manager |
| **Storage** | S3 buckets, RDS MySQL |
| **Edge** | CloudFront, ALB, ACM certificates |

---

## 7. Purpose of the Project  

With this project I simulate the foundational layout of a secure, multi-environment enterprise network and demonstrate expertise in:

- Secure hybrid architectures  
- Zero-trust segmentation  
- Production-level Terraform automation  
- Layered security controls  
- Centralized monitoring & detection  
- Real-world enterprise network topologies  

---

## 8. Deployment  

```bash
terraform init
terraform plan
terraform apply
```

---

## 9. Future Improvements

- Add Network Firewall for centralized egress filtering
- Add Transit Gateway Network Manager for global monitoring
- SCPs for multi-account setups