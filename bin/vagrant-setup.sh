#!/bin/sh
################################################################################
# CONFIG
################################################################################

# Packages which are pre-installed (minimal to reduce box size)
INSTALLED_PACKAGES="sudo ca_root_nss"

# Configuration files
RAW_GITHUB="https://raw.githubusercontent.com/oddnoc"
MAKE_CONF="$RAW_GITHUB/vagrant-freebsd/qi-ss/etc/make.conf"
RC_CONF="$RAW_GITHUB/vagrant-freebsd/qi-ss/etc/rc.conf"
RESOLV_CONF="$RAW_GITHUB/vagrant-freebsd/qi-ss/etc/resolv.conf"
LOADER_CONF="$RAW_GITHUB/vagrant-freebsd/qi-ss/boot/loader.conf"

# Message of the day
MOTD="$RAW_GITHUB/vagrant-freebsd/qi-ss/etc/motd"

# Private key of Vagrant (you probably don't want to change this)
VAGRANT_PRIVATE_KEY="https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub"

################################################################################
# PACKAGE INSTALLATION
################################################################################

# Install required packages
for p in $INSTALLED_PACKAGES; do
    pkg install -y "$p"
done

################################################################################
# Configuration
################################################################################

# Create the vagrant user with password "vagrant"; defer setting up bash to provisioning
pw useradd -n vagrant -d /usr/home/vagrant -s /bin/sh -m -G wheel -h 0 <<EOP
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
