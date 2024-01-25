terraform {
  cloud {
    organization = "monsteralab"
    workspaces {
      name = "MonsteraLab"
    }
  }
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">=1.45.0"
    }
  }
  required_version = ">= 1.5.7"
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "nomad" {
  address = "http://${hcloud_server.server[0].ipv4_address}:4646"
  region  = "global"
}

# resource "nomad_job" "fabio" {
#   depends_on = [null_resource.nomad_servers_post_script, null_resource.nomad_clients_post_script]
#   jobspec    = file("${path.module}/jobs/fabio.hcl")
# }

# resource "nomad_job" "test" {
#   depends_on = [null_resource.nomad_servers_post_script, null_resource.nomad_clients_post_script]
#   jobspec    = file("${path.module}/jobs/test.hcl")
# }

