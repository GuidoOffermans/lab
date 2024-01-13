resource "local_file" "private_key" {
  count           = var.generate_ssh_key_file ? 1 : 0
  content         = tls_private_key.machines.private_key_openssh
  filename        = "${path.root}/machines.pem"
  file_permission = "0600"
}

resource "tls_private_key" "machines" {
  algorithm = "Ed25519"
}

resource "hcloud_ssh_key" "temp_ssh_key" {
  name       = "temp_ssh_key"
  public_key = tls_private_key.machines.public_key_openssh
}

data "hcloud_ssh_key" "Hetzner-cloud" {
  name = "Hetzner-cloud"
}

