#cloud-config

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
  - python39
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
  - parted -a opt "/dev/nvme0n2" --script mklabel gpt mkpart primary xfs 0% 100%
  - timeout 30s sh -c 'while [ $(blkid /dev/nvme0n2p1 | grep -c xfs) -ne 1 ]; do sleep 1; done'
  - mkfs.xfs "/dev/nvme0n2p1"
  - partprobe "/dev/nvme0n2p1"
  - echo "/dev/nvme0n2p1 $cycle_server_root xfs defaults,nofail 1 2" | tee -a /etc/fstab 2>&1
  - mkdir -p "/opt/cycle_server"
  - systemctl daemon-reload
  - mount -a
  - update-alternatives --set python3 /usr/bin/python3.9
  - python3 -m pip install --upgrade pip
  - /opt/cycle_server/cycle_server stop
  - semanage fcontext -a -t bin_t "/opt/cycle_server(/.*)?"
  - restorecon -v /opt/cycle_server
  - sed -i 's_\(webServerMaxHeapSize\s*\)=\s*\(.*\)_\1=4096M_' /opt/cycle_server/config/cycle_server.properties
  - sed -i 's_\(webServerPort\s*\)=\s*\(.*\)*_\1=80_' /opt/cycle_server/config/cycle_server.properties
  - sed -i 's_\(webServerSslPort\s*\)=\s*\(.*\)*_\1=443_' /opt/cycle_server/config/cycle_server.properties
  - sed -i 's_\(webServerEnableHttps\s*\)=\s*\(.*\)_\1=true_' /opt/cycle_server/config/cycle_server.properties
  - sed -i 's_\(webServerRedirectHttp\s*\)=\s*\(.*\)_\1=true_' /opt/cycle_server/config/cycle_server.properties
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
  - restorecon -v /opt/cycle_server
  # - sleep 30s
  - /opt/cycle_server/cycle_server start
  - sleep 30s
  - unzip /opt/cycle_server/tools/cyclecloud-cli.zip -d /tmp/cyclecloud_cli_installer
  - python3 /tmp/cyclecloud_cli_installer/cyclecloud-cli-installer/install.py -y --installdir /home/hpcadmin/.cycle --system
  - cp "/home/srvadmin/cyclecloud_provider.json" "/home/hpcadmin/cyclecloud_provider.json"
  - chown hpcadmin:hpcadmin "/home/hpcadmin/cyclecloud_provider.json"
  - printf -v cyclecloud8_init '/usr/local/bin/cyclecloud initialize --loglevel=debug --batch --url=https://localhost --verify-ssl=false --username=hpcadmin --password="%s"' "$hpcadmin_cc_passwd"
  - su - hpcadmin --login -c "$cyclecloud8_init"
  - su - hpcadmin --login -c '/usr/local/bin/cyclecloud account create -f /home/hpcadmin/cyclecloud_provider.json'
  - passwd -e hpcadmin
  - ts=$(date +"%Y-%m-%d_%H-%M-%S")
  - touch /home/srvadmin/done-$ts.txt
  - chown srvadmin:srvadmin /home/srvadmin/done-$ts.txt