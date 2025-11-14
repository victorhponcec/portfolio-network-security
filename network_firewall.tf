/* #ToDo
# Network Firewall Policy 
resource "aws_networkfirewall_firewall_policy" "main_policy" {
  name = "vpca-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.allowed_traffic.arn
    }

  }
}

# Network Firewall Rule Group 
resource "aws_networkfirewall_rule_group" "allowed_traffic" {
  capacity = 100
  name     = "allowed-egress-rules"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<EOF
pass tcp any any -> any 80 (msg:"Allow HTTP";)
pass tcp any any -> any 443 (msg:"Allow HTTPS";)
pass tcp any any -> any 22 (msg:"Allow SSH";)
pass tcp any any -> any 3306 (msg:"Allow MySQL App->DB";)
pass udp any any -> any 53 (msg:"Allow DNS";)
pass udp any any -> any 123 (msg:"Allow NTP";)
pass icmp any any -> any (msg:"Allow ICMP Ping";)
drop ip any any -> any any (msg:"Drop all other traffic";)
EOF
    }
  }
}

# Firewall Endpoints
resource "aws_networkfirewall_firewall" "vpca_firewall" {
  name                = "vpca-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main_policy.arn
  vpc_id              = aws_vpc.vpca.id

  subnet_mapping {
    subnet_id = aws_subnet.private_subnet_fw1_vpca.id
  }
  subnet_mapping {
    subnet_id = aws_subnet.private_subnet_fw2_vpca.id
  }

  tags = {
    Name = "vpca-network-firewall"
  }
}

# Logging
resource "aws_networkfirewall_logging_configuration" "firewall_logs" {
  firewall_arn = aws_networkfirewall_firewall.vpca_firewall.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_alerts.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_flows.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}

resource "aws_cloudwatch_log_group" "firewall_alerts" {
  name              = "/aws/network-firewall/alerts"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "firewall_flows" {
  name              = "/aws/network-firewall/flows"
  retention_in_days = 1
}
*/