# infrastructure/terraform/main.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate${random_string.suffix.result}"
    container_name       = "tfstate"
    key                 = "prod.terraform.tfstate"
  }
}

module "data_lake_infrastructure" {
  source = "./modules/data_lake"
  
  environment = var.environment
  location    = var.location
  tags        = local.tags

  storage_configuration = {
    replication_type     = "ZRS"
    performance_tier     = "Premium"
    access_tier         = "Hot"
    hierarchy_enabled   = true
  }

  network_configuration = {
    vnet_address_space  = ["10.0.0.0/16"]
    subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24"]
    private_endpoints   = true
  }

  compute_configuration = {
    spark_version       = "3.5"
    autoscaling        = true
    min_nodes          = 2
    max_nodes          = 10
    node_type          = "Standard_E8s_v3"
  }
}

# kenyir/terraform/main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "kenyir" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  tags = {
    Name = "KenyirDataLake"
  }
}