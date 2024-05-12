[kafka]
%{ for i, ip in kafka_private_ips ~}
${ ip } ansible_user=${ ssh_user } ansible_become=True public_ip=${kafka_public_ips[i]} private_ip=${kafka_private_ips[i]} id=${i}
%{ endfor ~}

[zookeeper]
%{ for i, ip in zookeeper_private_ips ~}
${ ip } ansible_user=${ ssh_user } ansible_become=True public_ip=${zookeeper_public_ips[i]} private_ip=${zookeeper_private_ips[i]} id=${i}
%{ endfor ~}

[client]
%{ for i, ip in clients_private_ips ~}
${ ip } ansible_user=${ ssh_user } ansible_become=True private_ip=${clients_private_ips[i]} public_ip=${clients_public_ips[i]} id=${i}
%{ endfor ~}

[control]
${control_private_ips[0]} ansible_user=${ ssh_user } ansible_become=True public_ip=${control_public_ips[0]} private_ip=${control_private_ips[0]} id=0

[prometheus]
%{ for i, ip in prometheus_host_private_ips ~}
${ ip } ansible_user=${ ssh_user } ansible_become=True public_ip=${prometheus_host_public_ips[i]} private_ip=${prometheus_host_private_ips[i]} id=${i}
%{ endfor ~}