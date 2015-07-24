#!/bin/sh
################################################################################
# CONFIG
################################################################################

# Packages which are pre-installed
INSTALLED_PACKAGES="ca_root_nss virtualbox-ose-additions bash sudo"

# Configuration files
RAW_GITHUB="https://raw.githubusercontent.com/oddnoc"
MAKE_CONF="$RAW_GITHUB/vagrant-freebsd/master/etc/make.conf"
RC_CONF="$RAW_GITHUB/vagrant-freebsd/master/etc/rc.conf"
RESOLV_CONF="$RAW_GITHUB/vagrant-freebsd/master/etc/resolv.conf"
LOADER_CONF="$RAW_GITHUB/vagrant-freebsd/master/boot/loader.conf"
EZJAIL_CONF="$RAW_GITHUB/vagrant-freebsd/master/usr/local/etc/ezjail.conf"
PF_CONF="$RAW_GITHUB/vagrant-freebsd/master/etc/pf.conf"

# Message of the day
MOTD="$RAW_GITHUB/vagrant-freebsd/master/etc/motd"

# Private key of Vagrant (you probable don't want to change this)
VAGRANT_PRIVATE_KEY="https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub"

################################################################################
# PACKAGE INSTALLATION
################################################################################

# Install required packages
for p in $INSTALLED_PACKAGES; do
    pkg install -y -r wunki "$p"
done

# Switch to QI repository
mkdir -p /usr/local/etc/pkg/repos
touch /usr/local/etc/pkg/repos/local.conf
cat <<EOT > /usr/local/etc/pkg/repos/local.conf
FreeBSD: { enabled: no }
local {
        url: https://pkg.dev.quinn.com/packages/${ABI}-default,
        signature_type: "pubkey",
        mirror_type: "http",
        pubkey: "/usr/local/etc/ssl/certs/poudriere.cert",
        enabled: yes
}
EOT

pkg update
pkg upgrade -y

################################################################################
# Configuration
################################################################################

# Create the vagrant user with password "vagrant"
pw useradd -n vagrant -d /usr/home/vagrant -s /usr/local/bin/bash -m -G wheel -h 0 <<EOP
vagrant
EOP

# Enable sudo for this user
echo "%vagrant ALL=(ALL) NOPASSWD: ALL" >> /usr/local/etc/sudoers

# Authorize vagrant to login without a key
mkdir /usr/home/vagrant/.ssh
touch /usr/home/vagrant/.ssh/authorized_keys
chown vagrant:vagrant /usr/home/vagrant/.ssh

# Get the public key and save it in the `authorized_keys`
fetch -o /usr/home/vagrant/.ssh/authorized_keys $VAGRANT_PRIVATE_KEY
chown vagrant:vagrant /usr/home/vagrant/.ssh/authorized_keys

# make.conf
fetch -o /etc/make.conf $MAKE_CONF

# rc.conf
fetch -o /etc/rc.conf $RC_CONF

# resolv.conf
fetch -o /etc/resolv.conf $RESOLV_CONF

# loader.conf
fetch -o /boot/loader.conf $LOADER_CONF

# motd
fetch -o /etc/motd $MOTD

# ezjail
fetch -o /usr/local/etc/ezjail.conf $EZJAIL_CONF

# pf
fetch -o /usr/local/etc/pf.conf $PF_CONF


################################################################################
# CLEANUP
################################################################################

# Clean up installed packages
pkg clean -a -y

# Remove the history
cat /dev/null > /root/.history

# Try to make it even smaller
while true; do
    read -p "Would you like me to zero out all data to reduce box size? [y/N] " yn
    case $yn in
        [Yy]* ) dd if=/dev/zero of=/tmp/ZEROES bs=1M; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Empty out tmp directory
rm -rf /tmp/*

# DONE!
echo "We are all done. Poweroff the box and package it up with Vagrant."
