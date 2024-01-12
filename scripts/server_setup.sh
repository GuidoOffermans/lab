#!/usr/bin/env bash

# Arguments
instanceNumber=$1
serverIpAdresses=$2
serverCount=$3
ipRange=$4
aclEnabled=$5

echo "Arguments passed: $@"

formattedServerIps=$(echo $serverIpAdresses | sed 's/\[/["/g; s/\]/"]/g; s/,/","/g')

#################################
# CONSUL CONFIGURATION
#################################

cat <<EOF >/etc/consul.d/consul.hcl
datacenter = "dc1"
data_dir = "/opt/consul"

connect {
  enabled = true
}

client_addr = "0.0.0.0"

ui_config {
  enabled = true
}

retry_join = ${formattedServerIps}
bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"$ipRange\" | attr \"address\" }}"

acl = {
  enabled = true
  default_policy = "allow"
  down_policy    = "extend-cache"
}

performance {
  raft_multiplier = 1
}
EOF

consul validate /etc/consul.d/consul.hcl

cat <<EOF >/etc/consul.d/server.hcl
server = true
bootstrap_expect = $serverCount
EOF

#################################
# NOMAD CONFIGURATION
#################################

cat <<EOF >/etc/nomad.d/server.hcl
server {
  enabled = true
  bootstrap_expect = $serverCount
}

client {
  enabled = false
}

acl {
 enabled = $([ "$aclEnabled" == "true" ] && echo "true" || echo "false")
}
EOF

cat >/etc/nomad.d/nomad.hcl <<EOF
datacenter = "dc1"
data_dir = "/opt/nomad/data"

bind_addr = "0.0.0.0"

name = "nomad-server-$instanceNumber"

server {
    enabled = true
    bootstrap_expect = $serverCount
}

client {
  enabled = false
}

EOF

# Enable both services on all servers
systemctl enable consul
systemctl enable nomad

# and start the services
systemctl start consul
systemctl start nomad

#reboot
