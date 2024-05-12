provider "aws" {
  region  = "${var.region}"
  version = "= 3.74"
}

provider "random" {
  version = "= 3.4.3"
}

variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/omb.pub
DESCRIPTION
}

resource "random_id" "hash" {
  byte_length = 8
}

variable "key_name" {
  default     = "kafka-benchmark-key"
  description = "Desired name prefix for the AWS key pair"
}

variable "region" {}
variable "az" {}
variable "deploy_ami" {}
variable "ami" {}
variable "profile" {}

variable "gp3_size_gb" {}
variable "gp3_throughput_mb" {}
variable "gp3_iops" {}
variable "gp3_count" {}

variable "instance_types" {
  type = map
}

variable "num_instances" {
  type = map
}

variable "owner" {}

# Create a VPC to launch our instances into
resource "aws_vpc" "benchmark_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Kafka-Benchmark-VPC-${random_id.hash.hex}"
    owner = "${var.owner}"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "kafka" {
  vpc_id = "${aws_vpc.benchmark_vpc.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.benchmark_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.kafka.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "benchmark_subnet" {
  vpc_id                  = "${aws_vpc.benchmark_vpc.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.az}"
}

# Get public IP of this machine
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "benchmark_security_group" {
  name   = "terraform-kafka-${random_id.hash.hex}"
  vpc_id = "${aws_vpc.benchmark_vpc.id}"

  # All ports open within the VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # All ports open to this machine
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  #Prometheus/Dashboard access
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Kafka-Benchmarks-${random_id.hash.hex}"
    owner = "${var.owner}"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}-${random_id.hash.hex}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "zookeeper" {
  ami                    = "${var.ami}"
  instance_type          = "${var.instance_types["zookeeper"]}"
  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.benchmark_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.benchmark_security_group.id}"]
  count                  = "${var.num_instances["zookeeper"]}"
  monitoring             = true

  tags = {
    Name = "zk-${count.index}"
    owner = "${var.owner}"
  }
}

locals {
  device_names = {"0" = "/dev/sdf", "1" = "/dev/sdg", "2" = "/dev/sdh", "3" = "/dev/sdi", "4" = "/dev/sdj", "5" = "/dev/sdk", "6" = "/dev/sdl"}
  instances = toset(formatlist("%d", range(var.num_instances["kafka"])))
  volumes = toset(flatten([ for instance in local.instances :
  [ for volume in range(var.gp3_count) : "i${instance}-v${volume}" ]
  ]))
  attachments = toset(flatten([ for instance in local.instances :
  [ for volume in formatlist("%d", range(var.gp3_count)) : {
    instance = instance
    volume = "i${instance}-v${volume}"
    vol_index = volume
  }]
  ]))
}

resource "aws_instance" "kafka" {
  for_each               = local.instances
  ami                    = "${var.ami}"
  instance_type          = "${var.instance_types["kafka"]}"
  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.benchmark_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.benchmark_security_group.id}"]
  monitoring             = true

  tags = {
    Name  = "kafka-${each.key}"
    owner = "${var.owner}"
  }
}

resource "aws_ebs_volume" "kafka-vol" {
  for_each = local.volumes
  availability_zone = "${var.az}"
  size              = "${var.gp3_size_gb}"
  iops              = "${var.gp3_iops}"
  type              = "gp3"
  throughput        = "${var.gp3_throughput_mb}"

  tags = {
    Name = "kafka-ebs-${each.key}"
  }
}

resource "aws_volume_attachment" "attachment" {
  for_each = {for att in local.attachments:  att.volume => att}
  instance_id = aws_instance.kafka[each.value.instance].id
  volume_id = aws_ebs_volume.kafka-vol[each.key].id
  device_name = local.device_names[each.value.vol_index]
}

resource "aws_instance" "deploy" {
  ami                    = "${var.deploy_ami}"
  instance_type          = "${var.instance_types["deploy"]}"
  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.benchmark_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.benchmark_security_group.id}"]
  count                  = "${var.num_instances["deploy"]}"
  monitoring             = true

  tags = {
    Name = "kafka-deploy-${count.index}"
    owner = "${var.owner}"
  }
}

resource "aws_instance" "client" {
  ami                    = "${var.ami}"
  instance_type          = "${var.instance_types["client"]}"
  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.benchmark_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.benchmark_security_group.id}"]
  count                  = "${var.num_instances["client"]}"
  monitoring             = true

  tags = {
    Name = "kafka-client-${count.index}"
    owner = "${var.owner}"
  }
}

resource "aws_instance" "prometheus" {
  ami                    = "${var.ami}"
  instance_type          = "${var.instance_types["prometheus"]}"
  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.benchmark_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.benchmark_security_group.id}"]
  count                  = "${var.num_instances["prometheus"]}"

  tags = {
    Name = "kafka-prometheus-${count.index}"
    owner = "${var.owner}"
  }
}

resource "local_file" "hosts_ini" {
  content = templatefile("${path.module}/../hosts_ini.tpl",
    {
      kafka_public_ips   = [for k in aws_instance.kafka: k.public_ip]
      kafka_private_ips  = [for k in aws_instance.kafka: k.private_ip]
      zookeeper_public_ips   = aws_instance.zookeeper.*.public_ip
      zookeeper_private_ips  = aws_instance.zookeeper.*.private_ip
      clients_public_ips   = aws_instance.client.*.public_ip
      clients_private_ips  = aws_instance.client.*.private_ip
      prometheus_host_public_ips   = aws_instance.prometheus.*.public_ip
      prometheus_host_private_ips  = aws_instance.prometheus.*.private_ip
      control_public_ips   = aws_instance.client.*.public_ip
      control_private_ips  = aws_instance.client.*.private_ip
      ssh_user              = "ubuntu"
    }
  )
  filename = "${path.module}/../../ansible/hosts.ini"
}

resource "local_file" "hosts_private_ini" {
  content = templatefile("${path.module}/../hosts_private_ini.tpl",
    {
      kafka_public_ips   = [for k in aws_instance.kafka: k.public_ip]
      kafka_private_ips  = [for k in aws_instance.kafka: k.private_ip]
      zookeeper_public_ips   = aws_instance.zookeeper.*.public_ip
      zookeeper_private_ips  = aws_instance.zookeeper.*.private_ip
      clients_public_ips   = aws_instance.client.*.public_ip
      clients_private_ips  = aws_instance.client.*.private_ip
      prometheus_host_public_ips   = aws_instance.prometheus.*.public_ip
      prometheus_host_private_ips  = aws_instance.prometheus.*.private_ip
      control_public_ips   = aws_instance.client.*.public_ip
      control_private_ips  = aws_instance.client.*.private_ip
      ssh_user              = "ubuntu"
    }
  )
  filename = "${path.module}/../../ansible/hosts_private.ini"
}

output "clients" {
 value = {
   for instance in aws_instance.client :
   instance.public_ip => instance.private_ip
 }
}

output "client_ssh_host" {
  value = "${aws_instance.client.0.public_ip}"
}

output "deploy" {
  value = {
    for instance in aws_instance.deploy :
    instance.public_ip => instance.private_ip
  }
}