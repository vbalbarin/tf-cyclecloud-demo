#cloud-config
disk_setup:
  /dev/nvme0n2:
    table_type: gpt
    layout: true
    overwrite: true

fs_setup:
  - device: /dev/nvme0n2
    partition: auto
    filesystem: xfs

mounts:
  - ["/dev/nvme0n2p1", "/opt/cycle_server", "xfs", "defaults", "0", "2"]

yum_repos:
  cyclecloud:
    name: cyclecloud
    baseurl: https://packages.microsoft.com/yumrepos/cyclecloud
    gpgcheck: true
    gpgkey: https://packages.microsoft.com/keys/microsoft.asc
  azure-cli:
    name: Azure CLI
    baseurl: https://packages.microsoft.com/yumrepos/azure-cli
    gpgcheck: true
    gpgkey: https://packages.microsoft.com/keys/microsoft.asc

package_update: true
package_upgrade: true
packages:
  - vim
  - git
  - python38
  - unzip
  - tmux
  - policycoreutils-python-utils
  - azure-cli
  - cyclecloud8-${cyclecloud8_ver}

write_files:
  - path: /home/srvadmin/cyclecloud_account.json # cp . /opt/cycle_server/config/data/cyclecloud_account.json
    content: |
      [
        {
          "AdType": "Application.Setting",
          "Name": "cycleserver.installation.initial_user",
          "Value": "hpcadmin"
        },
        {
          "AdType": "AuthenticatedUser",
          "Name": "hpcadmin",
          "RawPassword": "",
          "Superuser": true
        },
        {
          "AdType": "Credential",
          "CredentialType": "PublicKey",
          "Name": "hpcadmin/public",
          "PublicKey": ""
        },
        {
          "AdType": "Application.Setting",
          "Name": "cycleserver.installation.complete",
          "Value": true
        }
      ]
  - path: /home/srvadmin/cyclecloud_provider.json
    content: |
      {
        "AcceptMarketplaceTerms": true,
        "AuthType": "ManagedIdentity",
        "AzureRMClientId": null,
        "AzureRMSubscriptionId": "${cyclecloud8_subscription_id}",
        "AzureResourceGroup": "${cyclecloud8_compute_rg_name}",
        "DefaultAccount": true,
        "Location": "${cyclecloud8_compute_rg_locaton}",
        "LockerAuthMode": "ManagedIdentity",
        "LockerIdentity": "${cyclecloud8_umi_locker_resource_id}",
        "RMStorageAccount": "${cyclecloud8_storage_account_locker_name}",
        "RMStorageContainer": "cyclecloud",
        "Name": "${cyclecloud8_subscription_name}",
        "PredefinedCreds": true,
        "Provider": "azure",
        "ProviderId": "${cyclecloud8_subscription_id}"
      }

runcmd:
  - update-alternatives --set python3 /usr/bin/python3.8
  - unzip /opt/cycle_server/tools/cyclecloud-cli.zip -d /tmp
  - python3 /tmp/cyclecloud-cli-installer/install.py -y --installdir /home/hpcadmin/.cycle --system
  - /opt/cycle_server/cycle_server stop
  - semanage fcontext -a -t bin_t "/opt/cycle_server(/.*)?"
  - restorecon -v /opt/cycle_server
  - sed -i 's_\(webServerSslPort\s*=\s*\)8443_\1443_' /opt/cycle_server/config/cycle_server.properties
  - sed -i 's_\(webServerEnableHttps\s*=\s*\)false_\1true_' /opt/cycle_server/config/cycle_server.properties
  - sed -i 's_\(webServerRedirectHttp\s*=\s*\)false_\1true_' /opt/cycle_server/config/cycle_server.properties
  - groupadd -g 20001 hpcadmin
  - useradd -g 20001 -u 20001 -m -s /bin/bash hpcadmin
  - passwd -d hpcadmin
  - su - hpcadmin -c "ssh-keygen -t ed25519 -N '' -f /home/hpcadmin/.ssh/id_ed25519"
  # - su - hpcadmin -c "cat /home/hpcadmin/.ssh/id_ed25519.pub >> /home/hpcadmin/.ssh/authorized_keys"
  # - su - hpcadmin -c "chmod 600 /home/hpcadmin/.ssh/authorized_keys"
  - su - hpcadmin -c "chmod 700 /home/hpcadmin/.ssh"
  - az login --identity
  - hpcadmin_cc_passwd=$(az keyvault secret show --name "hpcadmin-password" --vault-name "${key_vault_name}" --query "value" -otsv)
  # NB, | is used instead of _ because randomized password may contain _s and that confuses sed.
  - printf -v sed_set_passwd 's|\("RawPassword"\s*:\s*\)""|\\1"%s"|' "$hpcadmin_cc_passwd"
  - sed -i "$sed_set_passwd" "/home/srvadmin/cyclecloud_account.json"
  - hpcadmin_cc_pubkey=$(cat /home/hpcadmin/.ssh/id_ed25519.pub)
  - printf -v sed_set_pubkey 's|\("PublicKey"\s*:\s*\)""|\\1"%s"|' "$hpcadmin_cc_pubkey"
  - sed -i "$sed_set_pubkey" "/home/srvadmin/cyclecloud_account.json"
  - cp "/home/srvadmin/cyclecloud_account.json" "/opt/cycle_server/config/data/cyclecloud_account.json"
  - /opt/cycle_server/cycle_server start
  - cp "/home/srvadmin/cyclecloud_provider.json" "/home/hpcadmin/cyclecloud_provider.json"
  - chown hpcadmin:hpcadmin "/home/hpcadmin/cyclecloud_provider.json"
  - printf -v cyclecloud8_init '/usr/local/bin/cyclecloud initialize --loglevel=debug --batch --url=https://localhost --verify-ssl=false --username=hpcadmin --password=%s' "$hpcadmin_cc_passwd"
  - su - hpcadmin --login -c "$cyclecloud8_init"
  - su - hpcadmin --login -c '/usr/local/bin/cyclecloud account create -f /home/hpcadmin/cyclecloud_provider.json'
  - passwd -e hpcadmin