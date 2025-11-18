# Proyecto: Arquitectura de Red Segura Multi-VPC con Transit Gateway y VPN On-Prem

**Autor:** Victor Ponce | **Contacto:** [Linkedin](https://www.linkedin.com/in/victorhugoponce) | **Website:** [victorponce.com](https://victorponce.com)

**English Version:** [README.md](https://github.com/victorhponcec/portfolio-network-security/blob/main/README.md)

## 1. Descripción General

Este proyecto presenta una **arquitectura de red segura y de nivel productivo en AWS**, desplegada y automatizada completamente con **Terraform**.  
La infraestructura consiste en **tres VPC aisladas** (VPCA, VPCB, VPCC) conectadas mediante un **AWS Transit Gateway**, más una **VPN IPSec Site-to-Site** que simula un entorno on-premises.

El objetivo de este proyecto es demostrar **habilidades de ingeniería de seguridad en la nube**, con enfoque en:

- Segmentación de red y aislamiento este-oeste  
- Grupos de seguridad de mínimo privilegio y flujos de tráfico controlados  
- Comunicación cifrada en todas las capas  
- Acceso seguro a RDS y aplicaciones internas  
- Detección de amenazas y monitoreo continuo  
- Controles modernos de perímetro cloud-native (WAF, CloudFront, ALB)  
- Defensa en profundidad alineada con el **Pilar de Seguridad del AWS Well-Architected Framework**  

---

## 2. Arquitectura

<div align="center">

![Overview Diagram](README/Diagram.png)
<p><em>(img. 1 – Diagrama de Arquitectura)</em></p>
</div>

## Configuración de VPCs y Subnets
<div align="center">

| Nombre VPC | CIDR VPC       | Nombre Subnet            | CIDR Subnet     |
|------------|----------------|---------------------------|------------------|
| VPCA       | 10.111.0.0/16  | vpcA-public-a             | 10.111.1.0/24    |
| VPCA       | 10.111.0.0/16  | vpcA-public-b             | 10.111.2.0/24    |
| VPCA       | 10.111.0.0/16  | vpcA-private-web-1        | 10.111.3.0/24   |
| VPCA       | 10.111.0.0/16  | vpcA-private-web-2        | 10.111.4.0/24   |
| VPCB       | 10.112.0.0/16  | vpcB-private-a            | 10.112.1.0/24    |
| VPCB       | 10.112.0.0/16  | vpcB-private-b            | 10.112.2.0/24    |
| VPCC       | 10.113.0.0/16  | vpcC-private-1            | 10.113.1.0/24    |
<p><em>(Tabla 1 – VPCs y Subnets)</em></p>
</div>

## Configuración de Tablas de Rutas (VPC Route Tables)
<div align="center">

| VPC Name | Route Table           | CIDR Destino | Siguiente Salto       | Notas |
|----------|------------------------|--------------|------------------------|-------|
| VPCA     | public_rtb_vpca       | 0.0.0.0/0    | Internet Gateway (igw) | Acceso a Internet |
| VPCA     | public_rtb_vpca       | 10.112.0.0/16 | Transit Gateway (tgw) | Ruta a VPCB |
| VPCA     | public_rtb_vpca       | 10.113.0.0/16 | Transit Gateway (tgw) | Ruta a VPCC |
| VPCA     | private_rtb_vpca_web  | 0.0.0.0/0    | NAT Gateway (nat)      | Egresos controlados |
| VPCA     | private_rtb_vpca_web  | 10.112.0.0/16 | Transit Gateway (tgw) | Ruta a VPCB |
| VPCA     | private_rtb_vpca_web  | 10.113.0.0/16 | Transit Gateway (tgw) | Ruta a VPCC |
| VPCB     | private_rtb_vpcb      | 10.111.0.0/16 | Transit Gateway (tgw) | Ruta a VPCA |
| VPCB     | private_rtb_vpcb      | 10.113.0.0/16 | Transit Gateway (tgw) | Ruta a VPCC |
| VPCC     | private_rtb_vpcc      | 10.111.0.0/16 | Transit Gateway (tgw) | Ruta a VPCA |
| VPCC     | private_rtb_vpcc      | 10.112.0.0/16 | Transit Gateway (tgw) | Ruta a VPCB |
<p><em>(Tabla 2 – Tablas de Rutas)</em></p>
</div>

## Tabla de Rutas del Transit Gateway  
<div align="center">

| CIDR Destino | Attachment TGW       | Origen del Tráfico | Notas |
|--------------|----------------------|----------------------|-------|
| 10.111.0.0/16 | VPCA Attachment     | Subnets VPCA         | Ruta estática |
| 10.112.0.0/16 | VPCB Attachment     | Subnets VPCB         | Ruta estática |
| 10.113.0.0/16 | VPCC Attachment     | Subnets VPCC         | Ruta estática |
| (dinámico BGP) | VPN Attachment     | Red on-prem           | Ruta propagada |
<p><em>(Tabla 3 – Rutas del Transit Gateway)</em></p>
</div>

## Attachments del Transit Gateway
<div align="center">

| VPC / VPN | Subnets Asociadas                                                     | Notas |
|-----------|------------------------------------------------------------------------|-------|
| VPCA      | public-a, public-b, private-web-1, private-web-2                       | Ingreso/egreso híbrido |
| VPCB      | private-a, private-b                                                   | VPC de base de datos |
| VPCC      | private-1                                                              | VPC de reporting |
| VPN       | AWS VPN Attachment                                                     | Soporta BGP o rutas estáticas |
<p><em>(Tabla 4 – Attachments del TGW)</em></p>
</div>

---

## 3. Resumen de la Infraestructura

La arquitectura está dividida en **tres VPCs**, cada una con un propósito específico.

---

### VPCA – Capa Web / Punto de Entrada Público

VPCA aloja los componentes públicos y de aplicación:

- **ALB (HTTPS)** con certificado ACM  
- **Auto Scaling Group** aloja el aplicativo web 
- **Subnets privadas** para las instancias del Auto Scaling Group (ASG)  
- **Subnets públicas** con **NAT Gateways**  
- **VPC Endpoint para el servicio Secrets Manager**  
- Grupos de seguridad estrictos:  
  - ALB solo acepta tráfico de CloudFront  
  - Servidores app solo aceptan tráfico del ALB  
  - Egresos minimizados  

---

### VPCB – Base de Datos y Aplicaciones Internas

VPCB aloja los componentes sensibles:

- **RDS MySQL** multi-AZ  
- **Una instancia EC2 interna** simulando un backend  
- **Sin exposición pública**  
- SG del RDS solo permite tráfico desde:  
  - Subnets privadas de VPCA  
  - Instancia de reporting de VPCC  

---

### VPCC – Capa de Reporting

VPCC contiene:

- **Una instancia EC2** para analítica/reportes  
- Acceso privado mediante Transit Gateway  
- Comunicación con RDS en VPCB  

---

### Simulación On-Prem

Una cuarta VPC simula un entorno on-prem:

- **Instancia Ubuntu** como customer gateway  
- **VPN IPSec** hacia AWS  
- Rutas propagadas al Transit Gateway  

Puede reemplazarse fácilmente por un firewall real (ej. FortiGate) usando la configuración VPN generada por AWS.

---

## 4. Servicios de Seguridad Implementados

### Identidad y Acceso  
- Roles IAM para EC2 con acceso mínimo  
- Políticas IAM reducidas  
- Llave SSH generada por `tls_private_key`

### Seguridad de Red  
- Segmentación multi-VPC  
- Aislamiento mediante Transit Gateway  
- NAT Gateways para egreso controlado  
- VPC Flow Logs en S3  
- VPC Endpoint para Secrets Manager  

### Detección de Amenazas y Monitoreo  
- **GuardDuty**: Configurado para entregar alertas via SNS para hallazgos CRÍTICOS
- **CloudTrail:** Registra las llamadas a las APIs realizadas en la cuenta y las cifra y almacena en S3  
- **AWS Config:** Registra toda la configuración y los cambios de configuración de nuestros recursos y también guarda la información en su propio bucket de S3.  
- **CloudWatch Metrics:** Se crean cuatro métricas de CloudWatch junto al despliegue del recurso WAF, y nos permitirán seguir las reglas Managed y Rate-based del WAF (como se describe en la sección de Network Security).
- **Security Hub:** Provee una vista centralizada de hallazgos de seguridad y cumplimiento que nos permitirá generar dashboards de cumplimiento para marcos de seguridad tales como CIS, PCI DSS, NIST o integrar sistemas SIEM como Splunk.
- **Alarmas CloudWatch + EventBridge**  

### Seguridad de Aplicación y Perímetro  
- **CloudFront:** Con ACM para entregar conexión cifrada con STL entre usuarios y aplicativo. 
- **AWS WAFv2:** Protege la distribución de CloudFront con la implementación de cuatro reglas (tabla 5)
- **ALB HTTPS:** Un Application Load balancer entrega cifrado hasta la capa de aplicación. 

<div align="center">

| Prioridad | Nombre de la regla                   | Tipo               | Acción                        | Descripción                                                                           |
| --------- | ------------------------------------ | ------------------ | ----------------------------- | ------------------------------------------------------------------------------------- |
| 1         | AWSManagedRulesCommonRuleSet          | Managed Rule Group | Predeterminado                | Protecciones básicas contra amenazas comunes                                          |
| 2         | RateLimitPerIP                        | Rate-Based Rule    | Bloquear                      | Bloquea IPs que excedan 800 solicitudes durante 5 minutos (protección contra DDoS/fuerza bruta) |
| 3         | AWSManagedRulesSQLiRuleSet            | Managed Rule Group | Predeterminado                | Detecta intentos de inyección SQL                                                     |
| 4         | AWSManagedRulesAmazonIpReputationList | Managed Rule Group | Predeterminado                | Detecta/bloquea solicitudes desde IPs maliciosas conocidas (aws threat intelligence) |

<p><em>(Tabla 5 – Reglas WAF)</em></p>
</div>

### Seguridad de Datos  
- RDS cifrado  
- Credenciales en **Secrets Manager**  
- Servidores app obtienen secretos vía IAM  

---

## 5. Lógica de Red  

### Resumen del Enrutamiento  
- Todo el tráfico VPC-a-VPC fluye por el **Transit Gateway**  
- Subnets privadas de VPCA usan NAT Gateways  
- VPCB y VPCC **no tienen acceso directo a Internet**  
- Rutas VPN on-prem se propagan al TGW  
- Tráfico este-oeste estrictamente controlado  

---

## 6. Recursos Terraform Desplegados  
<div align="center">

| Categoría | Recursos Principales |
|----------|-----------------------|
| **Networking** | VPCs, Subnets, IGW, NAT, TGW, rutas TGW, VPN, Customer Gateway |
| **Compute** | EC2 (3), ASG, Launch Template |
| **Security** | SGs, WAFv2, GuardDuty, Config, CloudTrail, Flow Logs |
| **Identity** | Roles IAM, perfiles, Secrets Manager |
| **Storage** | S3, RDS MySQL |
| **Edge** | CloudFront, ALB, ACM |

<p><em>(Tabla 6 – Recursos del Proveedor AWS en Terraform)</em></p>
</div>

---

## 7. Propósito del Proyecto  

Con este proyecto simulo la base de una red empresarial segura multi-entorno, demostrando experiencia en:

- Arquitecturas híbridas seguras  
- Segmentación zero-trust  
- Automatización productiva con Terraform  
- Controles de seguridad por capas  
- Monitoreo y detección centralizados  
- Topologías reales de red empresarial  

---

## 8. Despliegue  

```bash
terraform init
terraform plan
terraform apply
```
Se deben reemplazar variables relevantes tales cómo el nombre de dominio desde variables.tf

---

## 9. Mejoras Futuras y Comentarios

- Añadir AWS Network Firewall para filtrado de egreso  
- Añadir Transit Gateway Network Manager  
- Implementar SCPs para escenarios multi-cuenta  

### Comentarios:
- Integraciones con servicios externos a AWS tales cómo Splunk, Datadog o FortiWeb serán abordados en otros proyectos. 
- Recursos cómo AWS Shield Advanced no fueron considerado por su alto costo para testing (3000 USD/mes)
- El proyecto se enfoca principalmente en seguridad de red en AWS, por tanto hay varios servicios de seguridad que dejé de lado, pueden revisar mis otros proyectos de seguridad para tener una visión más holística sobre la seguridad en AWS. Comparto algunos de ellos:

  - [Asegurando una Arquitectura de 3 Capas](https://github.com/victorhponcec/portfolio-aws-security-1/blob/main/README.es.md)