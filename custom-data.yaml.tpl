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
  - tmux
  - policycoreutils-python-utils
  - azure-cli
  - cyclecloud8-${cyclecloud8_ver}

# runcmd:
#   - groupadd -g 20001 hpcadmin
#   - useradd -g 20001 -u 20001 -m -s /bin/bash hpcadmin
#   - passwd -d hpcadmin
#   - su - hpcadmin -c "ssh-keygen -t ed25519 -N '' -f /home/hpcadmin/.ssh/id_ed25519"
#   # - su - hpcadmin -c "cat /home/hpcadmin/.ssh/id_ed25519.pub >> /home/hpcadmin/.ssh/authorized_keys"
#   # - su - hpcadmin -c "chmod 600 /home/hpcadmin/.ssh/authorized_keys"
#   - su - hpcadmin -c "chmod 700 /home/hpcadmin/.ssh"
#   - passwd -e hpcadmin