## Upload configuration files to Azure Storage
#Input Variables
tunnels_string="${tunnels_string}"
wg_server_name="${wg_server_name}"
wg_storage_account_name="${wg_storage_account_name}"
wg_conf_storage_container_name="${wg_conf_storage_container_name}"
wg_rgrp_name="${wg_rgrp_name}"
CONF_DIRECTORY=${wg_conf_directory}

# Upload conf files
key=$(az storage account keys list -g $wg_rgrp_name -n $wg_storage_account_name --query [0].value -o tsv)
tunnels=${tunnels}
for t in "${tunnel_loop}"
do
    conf_file=$wg_server_name-$t.conf
    az storage blob upload --account-key $key --account-name $wg_storage_account_name -c $wg_conf_storage_container_name -n conf_file -f $CONF_DIRECTORY/$conf_file
done

