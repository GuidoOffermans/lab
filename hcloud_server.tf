locals {
  ip_range   = var.virtual_network_cidr
  server_ips = jsonencode([for server in hcloud_server.server : (server.network[*].ip)[0]])
}

resource "hcloud_server" "server" {
  depends_on = [
    hcloud_network_subnet.network
  ]
  count       = var.nomad_server_count
  name        = "nomad-server-${count.index}"
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id, data.hcloud_ssh_key.Hetzner-cloud.id]

  labels = {
    "nomad-server" = "any"
  }

  network {
    network_id = hcloud_network.network.id
  }

  public_net {
    ipv6_enabled = false
  }

  user_data = templatefile("${path.module}/scripts/base_configuration.sh", {
    CONSUL_VERSION = var.apt_consul_version
    NOMAD_VERSION  = var.apt_nomad_version
  })

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'"
    ]

    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = tls_private_key.machines.private_key_openssh
    }
  }
}

resource "null_resource" "nomad_servers_post_script" {
  count      = var.nomad_server_count
  depends_on = [hcloud_server.server]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = tls_private_key.machines.private_key_openssh
    host        = hcloud_server.server[count.index].ipv4_address
  }

  provisioner "file" {
    source      = "${path.module}/scripts/server_setup.sh"
    destination = "setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x setup.sh",
      "./setup.sh ${count.index + 1} ${local.server_ips} ${var.nomad_server_count} ${local.ip_range} ${var.enable_nomad_acls}"
    ]
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
  ssh_keys    = [hcloud_ssh_key.default.id, data.hcloud_ssh_key.Hetzner-cloud.id]
  labels = {
    "nomad-client" = "any"
  }

  network {
    network_id = hcloud_network.network.id
  }

  public_net {
    ipv6_enabled = false
  }

  user_data = templatefile("${path.module}/scripts/base_configuration.sh", {
    CONSUL_VERSION = var.apt_consul_version
    NOMAD_VERSION  = var.apt_nomad_version
  })

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'"
    ]

    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = tls_private_key.machines.private_key_openssh
    }
  }
}

resource "null_resource" "nomad_clients_post_script" {
  count      = var.nomad_client_count
  depends_on = [hcloud_server.client, null_resource.nomad_servers_post_script]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = tls_private_key.machines.private_key_openssh
    host        = hcloud_server.client[count.index].ipv4_address
  }

  provisioner "file" {
    source      = "${path.module}/scripts/client_setup.sh"
    destination = "setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x setup.sh",
      "./setup.sh ${count.index + 1} ${local.server_ips} ${local.ip_range} ${var.enable_nomad_acls}"
    ]
  }
}
