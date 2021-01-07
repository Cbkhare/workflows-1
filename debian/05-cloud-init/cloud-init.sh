#!/bin/bash

source functions.sh && init
set -o nounset


target="/mnt/target"
BASEURL='http://192.168.1.2/misc/osie/current'

mkdir -p $target
mount -t ext4 /dev/sda3 $target

ephemeral=/workflow/data.json
OS=$(jq -r .os "$ephemeral")


echo -e "${GREEN}#### Configuring cloud-init for Packet${NC}"
if [ -f $target/etc/cloud/cloud.cfg ]; then
	case ${OS} in
	centos* | rhel* | scientific*) repo_module=yum-add-repo ;;
	debian* | ubuntu*) repo_module=apt-configure ;;
	esac

	cat <<-EOF >$target/etc/cloud/cloud.cfg
		apt:
		  preserve_sources_list: true
		disable_root: 0
		package_reboot_if_required: false
		package_update: false
		package_upgrade: false
		hostname: worker
		users:
		 - default
		 - name: debian 
		   gecos: Default user
		   groups: admin
		   sudo: true
		   shell: /bin/bash
		chpasswd:
		 list: |
		   debian:debian
		bootcmd:
		 - echo 192.168.1.1 provisioner | tee -a /etc/hosts
		 - systemctl disable network-online.target
		 - systemctl mask network-online.target
		runcmd:
		 - touch /etc/cloud/cloud-init.disabled
		ssh_genkeytypes: ['rsa', 'dsa', 'ecdsa', 'ed25519']
		ssh_pwauth: True
		ssh_authorized_keys:
		 - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqkBXEDE38n2Zwuxs+nE8r9tnA5hV1AIfCpv6t29LUgDe2VLxgKuCnQt73mqeB05kwTj0xsFKob52HyHEzerdWmnrYnL4i3i93jr1ihub5JJWoxnv8Le2tZgJchSIG5g7GYlrbfF/PVMNBYzc8zXzRgEzbwrnIJegUEwUckNLWtTlRZt0/6mN9kXrhzUWnRAP2+T4AqcBTLznqM3rOK4OO+JEUKoUM4VoS6tgL0eiIpkBDPhHGpeIJgsusY727UUOor+TFCA1MayoTO+JaAKNuRtd/+KfUa8nH+GbyLZCS17xRel6Iei0NOOOXTAqy8tGoeIT1K4M6vPaWi4Aan0O5 vagrant@provisioner
		cloud_init_modules:
		 - migrator
		 - bootcmd
		 - write-files
		 - growpart
		 - resizefs
		 - update_hostname
		 - update_etc_hosts
		 - users-groups
		 - rsyslog
		 - ssh
		cloud_config_modules:
		 - mounts
		 - locale
		 - set-passwords
		 ${repo_module:+- $repo_module}
		 - package-update-upgrade-install
		 - timezone
		 - puppet
		 - chef
		 - salt-minion
		 - mcollective
		 - runcmd
		cloud_final_modules:
		 - phone-home
		 - scripts-per-once
		 - scripts-per-boot
		 - scripts-per-instance
		 - scripts-user
		 - ssh-authkey-fingerprints
		 - keys-to-console
		 - final-message
	EOF
	echo "Disabling cloud-init based network config via cloud.cfg.d include"
	echo "network: {config: disabled}" >$target/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
	echo "WARNING: Removing /var/lib/cloud/*"
	rm -rf $target/var/lib/cloud/*
else
	echo "Cloud-init post-install -  default cloud.cfg does not exist!"
fi

if [ -f $target/etc/init/cloud-init-nonet.conf ]; then
	sed -i 's/dowait 120/dowait 1/g' $target/etc/init/cloud-init-nonet.conf
		sed -i 's/dowait 10/dowait 1/g' $target/etc/init/cloud-init-nonet.conf
else
	echo "Cloud-init post-install - cloud-init-nonet does not exist. skipping edit"
fi

cat <<EOF >$target/etc/cloud/cloud.cfg.d/90_dpkg.cfg
datasource_list: [ NoCloud ]
EOF

## Note

# Change enp1s0f0 to eno1 if working with a local on-premises machine.

cat <<EOF >$target/etc/network/interfaces
auto lo
iface lo inet loopback
#
auto enp1s0f0
iface enp1s0f0 inet dhcp
EOF

cat <<EOF >$target/etc/resolv.conf
nameserver 1.1.1.1
EOF

cat <<EOF >$target/etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0f0:
      dhcp4: yes
      nameservers:
          addresses: [1.1.1.1]
EOF
