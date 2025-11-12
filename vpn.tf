resource "aws_customer_gateway" "cgw" {
  bgp_asn    = 65000
  ip_address = aws_instance.ubuntu_onprem.public_ip
  type       = "ipsec.1"
  tags       = { Name = "CGW-1" }
  lifecycle { create_before_destroy = true }
  depends_on = [aws_instance.ubuntu_onprem]
}

resource "aws_vpn_connection" "vpn" {
  customer_gateway_id = aws_customer_gateway.cgw.id
  transit_gateway_id  = aws_ec2_transit_gateway.tgw.id #automatically creates a TGW VPN Attachment
  type                = aws_customer_gateway.cgw.type
  static_routes_only  = false #false=BGP | true=static routes
  tags                = { Name = "site-to-site-vpn" }

  # tunnel options: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_VpnTunnelOptionsSpecification.html
  # --- Tunnel 1 Configuration ---
  tunnel1_preshared_key = random_password.vpn.result
  tunnel1_inside_cidr   = "169.254.10.0/30" # Must be a /30 from 169.254.0.0/16 and unique across tunnels

  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase1_lifetime_seconds      = 28800 # 8 hours default

  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]
  tunnel1_phase2_lifetime_seconds      = 3600 # 1 hour default

  tunnel1_ike_versions   = ["ikev2"]
  tunnel1_startup_action = "start" # Can be "start" or "add"

  # --- Tunnel 2 Configuration ---
  tunnel2_preshared_key = random_password.vpn.result
  tunnel2_inside_cidr   = "169.254.11.0/30" # Must be a /30 from 169.254.0.0/16 and unique across tunnels

  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase1_lifetime_seconds      = 28800

  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]
  tunnel2_phase2_lifetime_seconds      = 3600

  tunnel2_ike_versions   = ["ikev2"]
  tunnel2_startup_action = "start"

  # Optional: Local and Remote Network CIDRs
  # These define the CIDR blocks that are allowed to communicate over the VPN tunnels.
  # If not specified, defaults to 0.0.0.0/0
  #local_ipv4_network_cidr  = "10.0.0.0/16"    # VPC CIDR | not necessary when using TGW

  remote_ipv4_network_cidr = var.on-prem-cidr # on-premises network CIDR
}

# Output the VPN connection details
output "vpn_connection_id" {
  description = "VPN connection ID"
  value       = aws_vpn_connection.vpn.id
}

output "customer_gateway_configuration" {
  description = "Config file for customer gateway (XML)"
  value       = aws_vpn_connection.vpn.customer_gateway_configuration
  sensitive   = true # mark as sensitive = contains keys/IPs
}

/* delete this | aws_vpn_connection_route used when: The VPN is attached to a Virtual Private Gateway 
#Static route /DELETE IF USING BGP/DYNAMIC
resource "aws_vpn_connection_route" "onprem_static_route" {
  vpn_connection_id = aws_vpn_connection.vpn.id
  destination_cidr_block = "10.222.1.0/24"
}
*/