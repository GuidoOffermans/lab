resource "hcloud_server" "server" {
  depends_on = [
    hcloud_network_subnet.network
  ]
  count       = var.nomad_server_count
  name        = "nomad-server-${count.index}"
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.temp_ssh_key.id, data.hcloud_ssh_key.Hetzner-cloud.id]

  labels = {
    "nomad_servers" = ""
    "nomads"        = ""
  }

  network {
    network_id = hcloud_network.network.id
  }

  public_net {
    ipv6_enabled = false
  }
}

resource "hcloud_server" "client" {
  depends_on = [
    hcloud_network_subnet.network
  ]
  count       = var.nomad_client_count
  name        = "nomad-client-${count.index}"
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.temp_ssh_key.id, data.hcloud_ssh_key.Hetzner-cloud.id]
  labels = {
    "nomad_clients" = ""
    "nomads"        = ""
  }

  network {
    network_id = hcloud_network.network.id
  }

  public_net {
    ipv6_enabled = false
  }
}
