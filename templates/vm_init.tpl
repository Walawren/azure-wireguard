#!/usr/bin/env bash

## Install required packages
apt-get -y update
apt-get -y install ca-certificates curl apt-transport-https lsb-release gnupg unbound jq

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
ufw allow ${wg_server_port}/udp
ufw allow from ${wg_server_cidr} to ${wg_server_address} port 53
ufw --force enable

