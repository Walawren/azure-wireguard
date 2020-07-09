#!/bin/bash

## Input Variables
vm_identity_id=${vm_identity_id}
vault_name=${vault_name}
wg_server_address=${wg_server_address}
tunnels_string=${tunnels_string}
tunnels=${tunnels}
dns_server=${dns_server}
wg_server_endpoint=${wg_server_endpoint}
wg_server_port=${wg_server_port}
persistent_keep_alive=${persistent_keep_alive}
wg_server_address_with_cidr=${wg_server_address_with_cidr}
wg_server_name=${wg_server_name}

# Login in Azure
az login --identity -u $vm_identity_id

## Generate server security keys
CONF_DIRECTORY=/etc/wireguard
KEYS_DIRECTORY=./WireGuardSecurityKeys
newline=$'\n'
mkdir -p $CONF_DIRECTORY
mkdir -p $KEYS_DIRECTORY
umask 077

# Pull keys from Azure instead of local file
server_private_secret_path="${KEYS_DIRECTORY}/server_private_key"
server_public_secret_path="${KEYS_DIRECTORY}/server_public_key"
rm -f $server_private_secret_path
rm -f $server_public_secret_path
set -o pipefail
az keyvault secret show --vault-name "$vault_name" --name "ServerPrivateKey" | jq -r '.value' > "$server_private_secret_path" || wg genkey > "$server_private_secret_path"
az keyvault secret show --vault-name "$vault_name" --name "ServerPublicKey" | jq -r '.value' > "$server_public_secret_path" || cat "$server_private_secret_path" | wg pubkey > "$server_public_secret_path"
set +o pipefail

server_private_key=$(<$server_private_secret_path)
server_public_key=$(<$server_public_secret_path)

# Add Keys to vault
az keyvault secret set --vault-name "$vault_name" --name "ServerPrivateKey" --value "$server_private_key"
az keyvault secret set --vault-name "$vault_name" --name "ServerPublicKey" --value "$server_public_key"

## Configure peers
peers=""
wg_server_substr_length=$((${wg_server_address_length} - 1))
count=${wg_server_last_ip}
addr_prefix=${addr_prefix}

for t in "${tunnel_loop}"
do
    private_secret_name="${t}PrivateKey"
    public_secret_name="${t}PublicKey"
    preshared_secret_name="${t}PresharedKey"

    private_secret_path="${KEYS_DIRECTORY}/${t}_private_key"
    public_secret_path="${KEYS_DIRECTORY}/${t}_public_key"
    preshared_secret_path="${KEYS_DIRECTORY}/${t}_preshared_key"
    rm -f $private_secret_path
    rm -f $public_secret_path
    rm -f $preshared_secret_path

    # Generate Keys - Pull keys from Azure instead of local file
    set -o pipefail
    az keyvault secret show --vault-name "$vault_name" --name "$private_secret_name" | jq -r '.value' > "$private_secret_path" || wg genkey > "$private_secret_path"
    az keyvault secret show --vault-name "$vault_name" --name "$public_secret_name" | jq -r '.value' > "$public_secret_path" || cat "$private_secret_path" | wg pubkey > "$public_secret_path"
    az keyvault secret show --vault-name "$vault_name" --name "$preshared_secret_name" | jq -r '.value' > "$preshared_secret_path" || wg genpsk > "$preshared_secret_path"
    set +o pipefail

    peer_private_key=$(<$private_secret_path)
    peer_public_key=$(<$public_secret_path)
    peer_preshared_key=$(<$preshared_secret_path)
    ((count++))
    peer_addr="${addr_prefix}${count}/32"

    # Add Keys to Vault
    az keyvault secret set --vault-name "$vault_name" --name "$private_secret_name" --value "$peer_private_key"
    az keyvault secret set --vault-name "$vault_name" --name "$public_secret_name" --value "$peer_public_key"
    az keyvault secret set --vault-name "$vault_name" --name "$preshared_secret_name" --value "$peer_preshared_key"

    # Generate Peer profile
    peer_profile=$(cat <<EOF
$newline
[Peer]
#$p
PublicKey = $peer_public_key
PresharedKey = $peer_preshared_key
PersistentKeepAlive = $persistent_keep_alive
AllowedIPs = $peer_addr$newline
EOF
)
    peers="$peers$peer_profile"

    # Generate Peer config
    conf_file=$wg_server_name-$t.conf
    cat > $CONF_DIRECTORY/$conf_file << EOF
[Interface]
#$p
PrivateKey = $peer_private_key
Address = $peer_addr
DNS=$dns_server$newline
[Peer]
#$wg_server_endpoint
PublicKey = $server_public_key
PresharedKey = $peer_preshared_key
Endpoint = $wg_server_endpoint:$wg_server_port
AllowedIps = 0.0.0.0/0, ::/0
PersistentKeepAlive = $persistent_keep_alive$newline
EOF
done

## Wireguard config
EXT_NIC=$(route | grep '^default' | grep -o '[^ ]*$')

conf_file=$wg_server_name.conf
cat > $CONF_DIRECTORY/$conf_file << EOF
[Interface]
Address = $wg_server_address_with_cidr
SaveConfig = true
PrivateKey = $server_private_key
ListenPort = $wg_server_port
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $EXT_NIC -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $EXT_NIC -j MASQUERADE
$peers
EOF

## IP Forwarding
chown -R root:root $CONF_DIRECTORY/
chmod -R og-rwx $CONF_DIRECTORY/*
sed -i -e 's/#net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i -e 's/#net.ipv6.conf.all.forwarding.*/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
sysctl -p

## WireGuard Service
wg-quick up $wg_server_name
systemctl enable wg-quick@$wg_server_name

## Clean keys
rm -rf $KEYS_DIRECTORY
