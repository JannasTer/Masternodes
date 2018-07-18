#!/bin/bash
newuser=rise
adduser --disabled-password --gecos "Admin" $newuser
echo $newuser:testnet123 | chpassw
echo "$newuser    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
systemctl reload sshd
echo 'LC_ALL="en_US.UTF-8"' >> /etc/environment
apt-get install ufw
apt-get -y update ; apt-get -y upgrade
apt-get -y install python-software-properties software-properties-common
apt-get -y install mc htop
cd /var
touch swap.img
chmod 600 swap.img
dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
mkswap /var/swap.img
swapon /var/swap.img
echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
ufw disable
ufw default deny incoming
ufw allow 22/tcp
ufw allow 5566/tcp
yes | ufw enable
ufw app list
df -h
apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade
