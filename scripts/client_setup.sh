#!/usr/bin/env bash

# Arguments
instanceNumber=$1
serverIpAdresses=$2
ipRange=$3
aclEnabled=$4

formattedServerIps=$(echo $serverIpAdresses | sed 's/\[/["/g; s/\]/"]/g; s/,/","/g')

# Consul configuration

# Open the configuration file /etc/consul.d/consul.hcl and add the content
cat <<EOF >/etc/consul.d/consul.hcl
datacenter = "dc1"
data_dir = "/opt/consul"

connect {
  enabled = true
}

retry_join = ${formattedServerIps}
bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"$ipRange\" | attr \"address\" }}"

check_update_interval = "0s"

acl = {
  enabled = true
  default_policy = "allow"
  down_policy    = "extend-cache"
}

performance {
  raft_multiplier = 1
}
EOF

# Nomad configuration

# Nomad has to be configured as well. For that, add the configuration file /etc/nomad.d/client.hcl with the content
cat <<EOF >/etc/nomad.d/client.hcl
name = "nomad-client-$instanceNumber"

client {
  enabled = true

  options {
    "driver.raw_exec.enable" = "1"
    "docker.privileged.enabled" = "true"
  }

  server_join {
    retry_join     = $formattedServerIps
    retry_max      = 3
    retry_interval = "15s"
  }

  network_interface = "{{ GetPrivateInterfaces | include \"network\" \"$ipRange\" | attr \"name\" }}"
}

acl {
  enabled = $([ "$aclEnabled" == "true" ] && echo "true" || echo "false")
}
EOF

cat >/etc/nomad.d/nomad.hcl <<EOF
datacenter = "dc1"
data_dir = "/opt/nomad/data"

bind_addr = "0.0.0.0"

name = "nomad-client-$instanceNumber"

server {
    enabled = false
}

client {
  enabled = false
  servers = $formattedServerIps
}

EOF

# Install CNI plugins
CNI_VERSION="v1.2.0"
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/$CNI_VERSION/cni-plugins-linux-$([ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-$CNI_VERSION.tgz
mkdir -p /opt/cni/bin
tar -C /opt/cni/bin -xzf cni-plugins.tgz
cat <<EOF >/etc/sysctl.d/10-consul.conf
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Install Docker Engine
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

sudo apt-get update -y
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update -y 

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# To make the snapshot as small as possible, we will only enable the services, but won't start them yet.
systemctl enable consul
systemctl enable nomad

systemctl start consul
systemctl start nomad
