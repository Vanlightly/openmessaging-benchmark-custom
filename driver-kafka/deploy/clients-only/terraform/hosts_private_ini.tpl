[runner]
%{ for i, ip in runner_private_ips ~}
${ ip } ansible_user=${ ssh_user } ansible_become=True private_ip=${runner_private_ips[i]} public_ip=${runner_public_ips[i]} id=${i}
%{ endfor ~}

[client]
%{ for i, ip in clients_private_ips ~}
${ ip } ansible_user=${ ssh_user } ansible_become=True private_ip=${clients_private_ips[i]} public_ip=${clients_public_ips[i]} id=${i}
%{ endfor ~}