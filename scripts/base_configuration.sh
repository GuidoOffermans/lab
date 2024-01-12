#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

echo "Starting the base configuration script..."

# Update the server's package index
sudo apt-get update

# Install wget, gpg, coreutils if not already installed
sudo apt-get install wget gpg coreutils -y

# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository if it doesn't exist
if [ ! -f /etc/apt/sources.list.d/hashicorp.list ]; then
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
fi

# Update the package index again after adding new repository
sudo apt-get update || {
    echo "Failed to update package list"
    exit 1
}

# Install jq if not already installed
sudo apt-get install jq -y

# Install or update Consul
if ! dpkg -s consul &>/dev/null || [ "$(dpkg-query -W -f='${CONSUL_VERSION}' consul)" != "${CONSUL_VERSION}" ]; then
    echo "Installing or updating Consul to version ${CONSUL_VERSION}"
    sudo apt-get install -y consul=${CONSUL_VERSION} || {
        echo "Failed to install Consul"
        exit 1
    }
fi

# Install or update Nomad
if ! dpkg -s nomad &>/dev/null || [ "$(dpkg-query -W -f='${NOMAD_VERSION}' nomad)" != "${NOMAD_VERSION}" ]; then
    echo "Installing or updating Nomad to version ${NOMAD_VERSION}"
    sudo apt-get install -y nomad=${NOMAD_VERSION} || {
        echo "Failed to install Nomad"
        exit 1
    }
fi

# Check versions
nomad -v
consul -v

which consul
which nomad

sudo mkdir -p /etc/consul.d
sudo mkdir -p /etc/nomad.d

# Set permissions for Consul
sudo chown -R consul:consul /etc/consul.d
sudo chmod -R 640 /etc/consul.d/*

# Set permissions for Nomad
sudo chown -R nomad:nomad /etc/nomad.d
sudo chmod -R 640 /etc/nomad.d/*

# Configure Nomad only if the configuration file doesn't exist
NOMAD_CONFIG_FILE="/etc/nomad.d/nomad.hcl"
if [ ! -f "$NOMAD_CONFIG_FILE" ]; then
    echo "Creating Nomad configuration file."
    cat <<EOF >"$NOMAD_CONFIG_FILE"
datacenter = "dc1"
data_dir = "/opt/nomad"
EOF
fi

echo "Base configuration script completed successfully."

Configure auto updates and security patches
apt install unattended-upgrades -y

cat <<EOF >/etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

cat <<EOF >/etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
        "\$${distro_id}:\$${distro_codename}";
        "\$${distro_id}:\$${distro_codename}-security";
        // Extended Security Maintenance; doesn't necessarily exist for
        // every release and this system may not have it installed, but if
        // available, the policy for updates is such that unattended-upgrades
        // should also install from here by default.
        "\$${distro_id}ESMApps:\$${distro_codename}-apps-security";
        "\$${distro_id}ESM:\$${distro_codename}-infra-security";
        "\$${distro_id}:\$${distro_codename}-updates";
        "\$${distro_id}:\$${distro_codename}-proposed";
//      "\$${distro_id}:\$${distro_codename}-backports";
};

// Python regular expressions, matching packages to exclude from upgrading
Unattended-Upgrade::Package-Blacklist {
    // The following matches all packages starting with linux-
//  "linux-";

    // Use $ to explicitely define the end of a package name. Without
    // the $, "libc6" would match all of them.
//  "libc6$";
//  "libc6-dev$";
//  "libc6-i686$";

    // Special characters need escaping
//  "libstdc\+\+6$";

    // The following matches packages like xen-system-amd64, xen-utils-4.1,
    // xenstore-utils and libxenstore3.0
//  "(lib)?xen(store)?";

    // For more information about Python regular expressions, see
    // https://docs.python.org/3/howto/regex.html
};

// This option controls whether the development release of Ubuntu will be
// upgraded automatically. Valid values are "true", "false", and "auto".
Unattended-Upgrade::DevRelease "auto";

// Do automatic removal of unused packages after the upgrade
// (equivalent to apt-get autoremove)
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Automatically reboot *WITHOUT CONFIRMATION* if
//  the file /var/run/reboot-required is found after the upgrade
Unattended-Upgrade::Automatic-Reboot "true";

// Automatically reboot even if there are users currently logged in
// when Unattended-Upgrade::Automatic-Reboot is set to true
//Unattended-Upgrade::Automatic-Reboot-WithUsers "true";

// If automatic reboot is enabled and needed, reboot at the specific
// time instead of immediately
//  Default: "now"
//Unattended-Upgrade::Automatic-Reboot-Time "02:00";

// Use apt bandwidth limit feature, this example limits the download
// speed to 70kb/sec
//Acquire::http::Dl-Limit "70";
EOF

sudo apt-get upgrade -y
