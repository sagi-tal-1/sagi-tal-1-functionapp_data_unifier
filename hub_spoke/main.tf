# ========================================
# 1. NETWORKING WITH HUB-SPOKE ARCHITECTURE
# ========================================

# Hub Virtual Network (for shared services)
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    NetworkTier = "Hub"
  }
}

# Spoke Virtual Network (for SQL workloads)
resource "azurerm_virtual_network" "spoke_sql" {
  name                = "vnet-spoke-sql-${var.environment}"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    NetworkTier = "Spoke-SQL"
  }
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spoke-sql"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_sql.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

# VNet Peering Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-sql-to-hub"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.spoke_sql.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false
}
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet" # Must be exactly this name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/26"]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet" # Must be exactly this name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/27"]
}
resource "azurerm_subnet" "management" {
  name                 = "subnet-management"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.4.0/24"]
}

# Spoke SQL Subnets
resource "azurerm_subnet" "sql_vms" {
  name                 = "subnet-sql-vms"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke_sql.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "sql_managed_instance" {
  name                 = "subnet-sql-mi"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke_sql.name
  address_prefixes     = ["10.1.2.0/24"]

  delegation {
    name = "managedinstancedelegation"
    service_delegation {
      name    = "Microsoft.Sql/managedInstances"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action",
                "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
                "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "subnet-private-endpoints"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke_sql.name
  address_prefixes     = ["10.1.3.0/24"]
  
  private_endpoint_network_policies = Disabled
}

resource "azurerm_subnet" "application_gateway" {
  name                 = "subnet-appgw"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke_sql.name
  address_prefixes     = ["10.1.4.0/24"]
}

# ========================================
# 2. AZURE FIREWALL
# ========================================

# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  name                = "pip-firewall-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                = "Standard"
  zones              = ["1", "2", "3"]

  tags = {
    Environment = var.environment
  }
}

# Azure Firewall
resource "azurerm_firewall" "main" {
  name                = "fw-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name           = "AZFW_VNet"
  sku_tier           = "Premium" # Premium for advanced threat protection
  zones              = ["1", "2", "3"]

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  threat_intel_mode = "Alert"

  tags = {
    Environment = var.environment
  }
}

# Firewall Policy
resource "azurerm_firewall_policy" "main" {
  name                = "fwpol-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                = "Premium"

  threat_intelligence_mode = "Alert"
  
  intrusion_detection {
    mode = "Alert"
  }

  tags = {
    Environment = var.environment
  }
}

# Firewall Policy Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "sql" {
  name               = "sql-rules"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 500

  # Network Rules for SQL
  network_rule_collection {
    name     = "sql-network-rules"
    priority = 400
    action   = "Allow"

    rule {
      name                  = "AllowSQLIntraVNet"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["10.1.0.0/16"]
      destination_ports     = ["1433", "1434"]
    }

    rule {
      name                  = "AllowManagementToSQL"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.4.0/24"] # Management subnet
      destination_addresses = ["10.1.0.0/16"]
      destination_ports     = ["1433", "3389", "22"]
    }

    rule {
      name                  = "AllowAzureServices"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443", "1433"]
    }
  }

  # Application Rules for SQL and Azure Services
  application_rule_collection {
    name     = "sql-app-rules"
    priority = 500
    action   = "Allow"

    rule {
      name             = "AllowAzureSQL"
      source_addresses = ["10.1.0.0/16"]
      
      destination_fqdns = [
        "*.database.windows.net",
        "*.database.secure.windows.net",
        "*.sql.azuresynapse.net"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name             = "AllowAzureAD"
      source_addresses = ["10.1.0.0/16"]
      
      destination_fqdns = [
        "login.microsoftonline.com",
        "login.windows.net",
        "*.login.microsoftonline.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name             = "AllowWindowsUpdate"
      source_addresses = ["10.1.1.0/24"] # SQL VMs subnet
      
      destination_fqdns = [
        "*.windowsupdate.com",
        "*.update.microsoft.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }
  }
}

# Associate Firewall Policy with Firewall
resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "DefaultRules"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 100

  network_rule_collection {
    name     = "DenyAll"
    priority = 1000
    action   = "Deny"

    rule {
      name                  = "DenyAllTraffic"
      protocols             = ["Any"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
  }
}

# Route Table for SQL subnets (force traffic through firewall)
resource "azurerm_route_table" "sql_subnets" {
  name                = "rt-sql-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  route {
    name           = "RouteToFirewall"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.main.ip_configuration[0].private_ip_address
  }

  tags = {
    Environment = var.environment
  }
}

# Associate Route Table with SQL VM subnet
resource "azurerm_subnet_route_table_association" "sql_vms" {
  subnet_id      = azurerm_subnet.sql_vms.id
  route_table_id = azurerm_route_table.sql_subnets.id
}

# ========================================
# 4. NETWORK SECURITY GROUPS
# ========================================

# NSG for SQL VMs
resource "azurerm_network_security_group" "sql_vms" {
  name                = "nsg-sql-vms-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow SQL from within VNet
  security_rule {
    name                       = "AllowSQLInbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }


  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
  }
}

# NSG for Private Endpoints
resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-private-endpoints-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow HTTPS from VNet
  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow SQL from VNet
  security_rule {
    name                       = "AllowSQLInbound"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
  }
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "sql_vms" {
  subnet_id                 = azurerm_subnet.sql_vms.id
  network_security_group_id = azurerm_network_security_group.sql_vms.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}