terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
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
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token
  pm_tls_insecure     = var.proxmox_tls_insecure

  # Logging (optional)
  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}
