[deploy]
%{ for i, ip in runner_public_ips ~}
${ ip } ansible_user=${ ssh_user } ansible_become=True private_ip=${runner_private_ips[i]} id=${i}
%{ endfor ~}

[client]
%{ for i, ip in clients_public_ips ~}
${ ip } ansible_user=${ ssh_user } ansible_become=True private_ip=${clients_private_ips[i]} id=${i}
%{ endfor ~}

[prometheus]
%{ for i, ip in prometheus_host_public_ips ~}
${ ip } ansible_user=${ ssh_user } ansible_become=True private_ip=${prometheus_host_private_ips[i]} id=${i}
%{ endfor ~}