#!/usr/bin/env bash

## Input Variables
wg_server_port="${wg_server_port}"
wg_server_cidr="${wg_server_cidr}"

## Install required packages
apt-get -y update
apt-get -y install ca-certificates curl apt-transport-https lsb-release gnupg jq

## Install WireGuard
add-apt-repository "ppa:wireguard/wireguard"
apt-get update -y
apt-get upgrade -y
apt-get install wireguard -y

## Install az
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list
apt-get -y update
apt-get -y install azure-cli

## Firewall config to allow for traffic from clients

ufw allow ssh
ufw allow $wg_server_port/udp
ufw allow from $wg_server_cidr to any port 53
ufw allow from $wg_server_cidr to any port 80
ufw allow from $wg_server_cidr to any port 443
ufw --force enable

${personal_vpn_tunnels}

${upload_configurations}

## IP Forwarding
sed -i -e 's/#net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i -e 's/#net.ipv6.conf.all.forwarding.*/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
sysctl -p

