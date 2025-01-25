# modules/security/network_firewall.tf

# Network Firewall Policy
resource "aws_networkfirewall_firewall_policy" "datalake" {
  name = "datalake-${var.environment}-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.domain_filtering.arn
    }
    
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.protocol_enforcement.arn
    }
    
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.threat_prevention.arn
    }
  }
}

# Domain Filtering Rules
resource "aws_networkfirewall_rule_group" "domain_filtering" {
  capacity = 100
  name     = "datalake-${var.environment}-domain-filtering"
  type     = "STATEFUL"
  
  rule_group {
    rule_variables {
      ip_sets {
        key = "TRUSTED_HOSTS"
        ip_set {
          definition = var.trusted_ip_ranges
        }
      }
    }

    rules_source {
      rules_string = <<EOF
# Allow access to AWS services
pass tls $HOME_NET any -> $AWS_SERVICES any (tls.sni; content:".amazonaws.com"; endswith; msg:"Allow AWS Services"; sid:1000; rev:1;)

# Allow specific domains
pass tls $HOME_NET any -> $EXTERNAL_NET any (tls.sni; content:".datalake.internal"; endswith; msg:"Allow Internal Services"; sid:1001; rev:1;)

# Block known malicious domains
drop tls $HOME_NET any -> $EXTERNAL_NET any (tls.sni; content:".malicious-domain.com"; endswith; msg:"Block Malicious Domain"; sid:1002; rev:1;)
EOF
    }
  }
}

# Protocol Enforcement Rules
resource "aws_networkfirewall_rule_group" "protocol_enforcement" {
  capacity = 100
  name     = "datalake-${var.environment}-protocol"
  type     = "STATEFUL"
  
  rule_group {
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "443"
          protocol        = "TCP"
          direction       = "FORWARD"
          source_port     = "ANY"
          source         = var.vpc_cidr
        }
        rule_option {
          keyword = "sid:2000"
        }
      }
      
      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "6379"  # Redis
          protocol        = "TCP"
          direction       = "FORWARD"
          source_port     = "ANY"
          source         = var.vpc_cidr
        }
        rule_option {
          keyword = "sid:2001"
        }
      }
      
      stateful_rule {
        action = "DROP"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          protocol        = "TCP"
          direction       = "FORWARD"
          source_port     = "ANY"
          source         = "ANY"
        }
        rule_option {
          keyword = "sid:2999"
        }
      }
    }
  }
}

# Threat Prevention Rules
resource "aws_networkfirewall_rule_group" "threat_prevention" {
  capacity = 100
  name     = "datalake-${var.environment}-threats"
  type     = "STATEFUL"
  
  rule_group {
    rules_source {
      rules_string = <<EOF
# Block SQL injection attempts
drop tcp $EXTERNAL_NET any -> $HOME_NET any (msg:"SQL Injection Attempt"; flow:established,to_server; content:"UNION SELECT"; nocase; sid:3000; rev:1;)

# Block XSS attempts
drop tcp $EXTERNAL_NET any -> $HOME_NET any (msg:"XSS Attempt"; flow:established,to_server; content:"<script>"; nocase; sid:3001; rev:1;)

# Rate limiting for API endpoints
rate_limit tcp $EXTERNAL_NET any -> $HOME_NET 443 (msg:"API Rate Limit"; threshold:type limit,track by_src,count 100,seconds 60; sid:3002; rev:1;)
EOF
    }
  }
}

# Network Firewall
resource "aws_networkfirewall_firewall" "main" {
  name                = "datalake-${var.environment}-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.datalake.arn
  vpc_id             = var.vpc_id
  
  dynamic "subnet_mapping" {
    for_each = var.firewall_subnet_ids
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = {
    Environment = var.environment
    Name        = "datalake-${var.environment}-firewall"
  }
}