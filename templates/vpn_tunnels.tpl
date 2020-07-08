#!/bin/bash

## Input Variables
vm_identity_id=${vm_identity_id}
vault_name=${vault_name}
wg_server_address=${wg_server_address}
personal_peers=${personal_peers}
dns_server=${dns_server}
wg_server_endpoint=${wg_server_endpoint}
wg_server_port=${wg_server_port}
persistent_keep_alive=${persistent_keep_alive}
wg_server_address_with_cidr=${wg_server_address_with_cidr}

# Login in Azure
az login --identity -u $vm_identity_id

# Delee existing configuration files
CONF_DIRECTORY=/etc/wireguard
find . -type f -name '$CONF_DIRECTORY/*.conf' -delete

## IP Forwarding
mkdir -p $CONF_DIRECTORY
chown -R root:root $CONF_DIRECTORY/
chmod -R og-rwx $CONF_DIRECTORY/*
sed -i -e 's/#net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i -e 's/#net.ipv6.conf.all.forwarding.*/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
sysctl -p

## Generate server security keys
KEYS_DIRECTORY=/home/$2/WireGuardSecurityKeys
mkdir -p $KEYS_DIRECTORY
umask 077

# Pull keys from Azure instead of local file
az keyvault secret show --vault-name $vault_name --name ServerPrivateKey | jq -r '.value' | tee $KEYS_DIRECTORY/server_private_key || wg genkey | tee $KEYS_DIRECTORY/server_private_key | wg pubkey > $KEYS_DIRECTORY/server_public_key

server_private_key=$(<$KEYS_DIRECTORY/server_private_key)
server_public_key=$(<$KEYS_DIRECTORY/server_public_key)

# Add Keys to vault
az keyvault secret set --vault-name $vault_name --name ServerPrivateKey --value $server_private_key
az keyvault secret set --vault-name $vault_name --name ServerPublicKey --value $server_public_key

## Configure peers
function join_by { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

peers=""
newline=$'\n'
wg_server_substr_length=$((${#wg_server_address} - 1))
wg_server_last_ip=$(wg_server_address | cut -d'.' -f 4)
count=$((wg_server_last_ip + 1))
addr_prefix=${$wg_server_address:0:$wg_server_substr_length}
for p in "${personal_peers[@]}"
do
    private_secret_name=$pPrivateKey
    public_secret_name=$pPublicKey
    preshared_secret_name=$pPresharedKey
    # Generate Keys - TODO - Pull keys from Azure instead of local file
    az keyvault secret show --vault-name $vault_name --name $private_secret_name | jq -r '.value' | tee $KEYS_DIRECTORY/$p_private_key || wg genkey | tee $KEYS_DIRECTORY/$p_private_key
    az keyvault secret show --vault-name $vault_name --name $public_secret_name | jq -r '.value' | tee $KEYS_DIRECTORY/$p_private_key || cat $KEYS_DIRECTORY/$p_private_key | wg pubkey > $KEYS_DIRECTORY/$p_public_key
    az keyvault secret show --vault-name $vault_name --name $preshared_secret_name | jq -r '.value' | tee $KEYS_DIRECTORY/$p_preshared_key || wg genpsk > $KEYS_DIRECTORY/$p_preshared_key

    peer_private_key=$(<$KEYS_DIRECTORY/$p_private_key)
    peer_public_key=$(<$KEYS_DIRECTORY/$p_public_key)
    peer_preshared_key=$(<$KEYS_DIRECTORY/$p_preshared_key)
    peer_addr=$addr_prefix$count/32

    # Add Keys to Vault
    az keyvault secret set --vault-name $vault_name --name $private_secret_name --value $peer_private_key
    az keyvault secret set --vault-name $vault_name --name $public_secret_name --value $peer_public_key
    az keyvault secret set --vault-name $vault_name --name $preshared_secret_name --value $peer_preshared_key

    # Generate Peer profile
    peer_properties=('[Peer]', '#$p', 'PublicKey=$peer_public_key', 'PresharedKey=$peer_preshared_key', 'AllowedIPs=$peer_addr')
    ((count++))

    newpeer=$(join_by $newline "${peer_properties[@]}")
    peers=$peers$newline$newline$(join_by $newline $peer_properties)

    # Generate Peer config
    conf_file=wg0-$p.conf
    cat > $CONF_DIRECTORY/$conf_file << EOF
[Interface]
#$p
PrivateKey=$peer_private_key
Address=$peer_addr
DNS=$dns_server

[Peer]
#$wg_server_endpoint
PublicKey = $server_public_key
PresharedKey = $peer_preshared_key
EndPoint = $wg_server_endpoint:$wg_server_port
AllowedIps = 0.0.0.0/0, ::/0
PersistentKeepAlive = $persistent_keep_alive

EOF
chmod go+r $CONF_DIRECTORY/$conf_file
done

## Wireguard config
EXT_NIC=$(route | grep '^default' | grep -o '[^ ]*$')

cat > $CONF_DIRECTORY/wg0.conf << EOF
[Interface]
Address = $wg_server_address_with_cidr
SaveConfig = true
PrivateKey = $server_private_key
ListenPort = $wg_server_port
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $EXT_NIC -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $EXT_NIC -j MASQUERADE

$peers

EOF

## WireGuard Service
wg-quick up wg0
systemctl enable wg-quick@wg0

## Clean keys
rm -rf $KEYS_DIRECTORY
