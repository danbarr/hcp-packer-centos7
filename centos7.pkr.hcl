packer {
  required_version = ">= 1.7.0"
  required_plugins {
    amazon = {
      version = "~>1.0"
      source  = "github.com/hashicorp/amazon"
    }
    azure = {
      version = "~>1.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

locals {
  timestamp  = regex_replace(timestamp(), "[- TZ:]", "")
  image_name = "${var.prefix}-centos7-${local.timestamp}"
}

data "amazon-ami" "centos7" {
  region = var.aws_region
  filters = {
    name                = "CentOS-7-*"
    product-code        = "cvugziknvmxgqna9noibqnnsy"
    virtualization-type = "hvm"
    root-device-type    = "ebs"
  }
  most_recent = true
  owners      = ["aws-marketplace"]
}

source "amazon-ebs" "base" {
  region        = var.aws_region
  source_ami    = data.amazon-ami.centos7.id
  instance_type = "t3.small"
  ssh_username  = "centos"
  ami_name      = local.image_name

  tags = {
    owner           = var.owner
    dept            = var.department
    source_ami_id   = data.amazon-ami.centos7.id
    source_ami_name = data.amazon-ami.centos7.name
    Name            = local.image_name
  }
}

source "azure-arm" "base" {
  os_type         = "Linux"
  image_publisher = "OpenLogic"
  image_offer     = "CentOS"
  image_sku       = "7_9"

  #location                          = var.az_region
  build_resource_group_name         = var.az_resource_group
  vm_size                           = "Standard_A2_v2"
  managed_image_name                = local.image_name
  managed_image_resource_group_name = var.az_resource_group

  azure_tags = {
    owner = var.owner
    dept  = var.department
  }
  use_azure_cli_auth = true
}

build {
  hcp_packer_registry {
    bucket_name = "centos7"
    description = <<EOT
    CentOS 7 base images.
    EOT
    bucket_labels = {
      "owner"          = var.owner
      "dept"           = var.department
      "os"             = "CentOS",
      "centos-version" = "7",
    }
    build_labels = {
      "build-time" = local.timestamp
    }
  }

  sources = [
    "source.amazon-ebs.base",
    "source.azure-arm.base"
  ]

  provisioner "shell" {
    script          = "./update.sh"
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
  }
}