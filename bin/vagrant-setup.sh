#!/bin/sh
################################################################################
# CONFIG
################################################################################

# Packages which are pre-installed
INSTALLED_PACKAGES="virtualbox-ose-additions bash sudo"

# Configuration files
RAW_GITHUB="https://raw.githubusercontent.com/oddnoc"
MAKE_CONF="$RAW_GITHUB/vagrant-freebsd/qi-ss/etc/make.conf"
RC_CONF="$RAW_GITHUB/vagrant-freebsd/qi-ss/etc/rc.conf"
RESOLV_CONF="$RAW_GITHUB/vagrant-freebsd/qi-ss/etc/resolv.conf"
LOADER_CONF="$RAW_GITHUB/vagrant-freebsd/qi-ss/boot/loader.conf"

# Message of the day
MOTD="$RAW_GITHUB/vagrant-freebsd/qi-ss/etc/motd"

# Private key of Vagrant (you probable don't want to change this)
VAGRANT_PRIVATE_KEY="https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub"

################################################################################
# PACKAGE INSTALLATION
################################################################################

# Install required packages
for p in $INSTALLED_PACKAGES; do
    pkg install -y "$p"
done

# Switch to QI repository
mkdir -p -m 755 /usr/local/etc/pkg/repos
touch /usr/local/etc/pkg/repos/local.conf
cat <<EOT > /usr/local/etc/pkg/repos/local.conf
FreeBSD: { enabled: no }
local {
        url: https://pkg.dev.quinn.com/packages/\${ABI}-default,
        signature_type: "pubkey",
        mirror_type: "http",
        pubkey: "/usr/local/etc/ssl/certs/poudriere.cert",
        enabled: yes
}
EOT
mkdir -p -m 755 /usr/local/etc/ssl/certs
touch /usr/local/etc/ssl/certs/poudriere.cert
cat<<EOC > /usr/local/etc/ssl/certs/poudriere.cert
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAqU9kxnGdvUjVMiXZcGt6
pq/yylQ60rf7cJNxHx7qSkxkJCESDm7yMeAwaEgvPJiU6t2OtMg+fwAV4Xl2ZdwZ
9k2SqpE/cHBTwI9rZGjVR9KICLtczVRM4NUjjHt1flOxOmuatVc4FJA1FwmuYQ9G
U29eAS8G0PIQ//cFsVwCiSZT231CH4oRCdt7wfNo0W31LBsXw+Ta+SBXJG7OgLCo
nOGAvfBnpk5G6WWy60/98g8baZBZo20WA+7MZjFprXjULnmHYy07I6WE+NR3tcL7
m1mTWE/ZwPwU8UetIVX8UEQgwwYISyFoEzOPeRLx/Rgp1seki6/+tMvXxX2l8ss0
s6keUg96RW8miftJd72i7Oh28UYIXOFxRikvZHHU+B8kjW/VZUcx6/LSRl/jrv4u
uztuq755dDvdTkbzuD2WsEwTS681n2o1uED//HUdC4JZ7/aE8CEwuPwu/gGrK9rO
nKQHlIqut+/R3gG4eyajpce9G90QY1dKHJJVpefkGeZGQlrl2wmBsnuKzQkKqDeM
cgzOreGTzTYMW8qCzRKNfeiJTU3WhnqjD+1ZyWEdqblF9UjsaD4YCh5+GCUO+wVb
XGZGVyVynHR+ed1sXlYJtRIs5ZSLH6v96x376zBjM8DAgdu0aFYRsuDi1SYGHLpP
EosDQwKdcAwJ0wQo4SSx7zECAwEAAQ==
-----END PUBLIC KEY-----
EOC

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
