terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.90"
    }
  }

  # Optional: Remote State Backend (auskommentiert für lokale Entwicklung)
  # backend "s3" {
  #   bucket = "terraform-state"
  #   key    = "home-server/terraform.tfstate"
  #   region = "eu-central-1"
  # }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token}"
  insecure  = var.proxmox_tls_insecure
}
