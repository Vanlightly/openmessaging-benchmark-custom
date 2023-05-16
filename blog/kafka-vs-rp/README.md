# Kafka vs Redpanda tests

All tests were performed on three i3en.6xlarge instances with c5n.9xlarge for the clients. Between 2 and 6 client instances were deployed depending on the client counts.

The readme files in the driver directories have full details on how to deploy and run the tests. This is a reference for understanding the configuration I used in these specfic tests.

## Terraform tfvars - reference

The Terraform tfvars files were as follows:

Kafka, low client tests (<= 50).

```
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az              = "us-west-2b"
ami             = "ami-0d31d7c9fc9503726" // "ami-9fa343e7" // RHEL-7.4

instance_types = {
  "kafka"      = "i3en.6xlarge"
  "zookeeper"  = "t2.medium"
  "client"     = "c5n.9xlarge"
  "prometheus" = "i3en.xlarge"
}

num_instances = {
  "client"     = 2
  "kafka"      = 3
  "zookeeper"  = 3
  "prometheus" = 1
}
```

Kafka, high client tests (> 50).

```
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az              = "us-west-2b"
ami             = "ami-0d31d7c9fc9503726" // "ami-9fa343e7" // RHEL-7.4

instance_types = {
  "kafka"      = "i3en.6xlarge"
  "zookeeper"  = "t2.medium"
  "client"     = "c5n.9xlarge"
  "prometheus" = "i3en.xlarge"
}

num_instances = {
  "client"     = 6
  "kafka"      = 3
  "zookeeper"  = 3
  "prometheus" = 1
}
```

Redpanda, low client tests (<= 50).

```
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az		        = "us-west-2a"
# AMIs in us-west
# Intel: Ubuntu 20.04 ami-0d31d7c9fc9503726 , Ubuntu 22.04 ami-0fcf52bcf5db7b003
# ARM: Ubuntu 22.04 ami-03f6bd8c9c6230968
redpanda_ami    = "ami-0fcf52bcf5db7b003"
other_ami       = "ami-0d31d7c9fc9503726"

instance_types = {
  "redpanda"      = "i3en.6xlarge"
  "client"        = "c5n.9xlarge"
  "prometheus"    = "i3en.xlarge"
}

num_instances = {
  "client"     = 2
  "redpanda"   = 3
  "prometheus" = 1
}
```

Redpanda, high client tests (> 50).

```
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az		        = "us-west-2a"
# AMIs in us-west
# Intel: Ubuntu 20.04 ami-0d31d7c9fc9503726 , Ubuntu 22.04 ami-0fcf52bcf5db7b003
# ARM: Ubuntu 22.04 ami-03f6bd8c9c6230968
redpanda_ami    = "ami-0fcf52bcf5db7b003"
other_ami       = "ami-0d31d7c9fc9503726"

instance_types = {
  "redpanda"      = "i3en.6xlarge"
  "client"        = "c5n.9xlarge"
  "prometheus"    = "i3en.xlarge"
}

num_instances = {
  "client"     = 6
  "redpanda"   = 3
  "prometheus" = 1
}
```

## Ansible variables - reference

Kafka Ansible variables. TLS is not configured with variables but has a separate yaml file.

```
kafkaServerVersion: 3.4.0
kafkaServerLogDirs: /mnt/data-1,/mnt/data-2
kafkaServerNumReplicaFetchers: 8
kafkaServerNumNetworkThreads: 8
kafkaServerMinJvmHeap: 6G
kafkaServerMaxJvmHeap: 6G
clientMinJvmHeap: 16G
clientMaxJvmHeap: 40G
```

Redpanda Ansible without TLS.

```
redpanda_package: redpanda=23.1.7-1
clientMinJvmHeap: 16g
clientMaxJvmHeap: 40g
partition_percent: 100
tls_enabled: false
sasl_enabled: false
```

Redpanda Ansible with TLS.

```
redpanda_package: redpanda=23.1.7-1
clientMinJvmHeap: 16g
clientMaxJvmHeap: 40g
partition_percent: 100
tls_enabled: true
sasl_enabled: true
```

To set some NVMe drive over-provisioning for Redpanda, use the `partition_percent` variable. 10% OP would be `partition_percent: 90`.

## Other

Java 17 was installed on Kafka servers and all client instances, including Redpanda clients. The G1 garbage collector was used in all cases.