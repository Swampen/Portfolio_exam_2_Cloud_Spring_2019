
scp -i "$sshKeyLocation" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="$sshProxyCommand" `dirname "$0"`"/database-init-script" ubuntu@10.10.15.153:
