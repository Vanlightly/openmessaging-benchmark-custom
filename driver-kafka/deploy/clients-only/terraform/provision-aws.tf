provider "aws" {
  region  = "${var.region}"
  version = "3.74"
}

provider "random" {
  version = "~> 3.0"
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
  default     = "benchmark-key"
  description = "Desired name prefix for the AWS key pair"
}

variable "region" {}
variable "az" {}
variable "runner_ami" {}
variable "ami" {}
variable "profile" {}

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
    Name = "Benchmark-VPC-${random_id.hash.hex}"
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
  name   = "benchmark-${random_id.hash.hex}"
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

resource "aws_instance" "deploy" {
  ami                    = "${var.runner_ami}"
  instance_type          = "${var.instance_types["deploy"]}"
  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.benchmark_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.benchmark_security_group.id}"]
  count                  = "${var.num_instances["deploy"]}"
  monitoring             = true

  tags = {
    Name = "benchmark-deploy-${count.index}"
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
    Name = "benchmark-client-${count.index}"
    owner = "${var.owner}"
  }
}

resource "local_file" "hosts_ini" {
  content = templatefile("${path.module}/hosts_ini.tpl",
    {
      runner_public_ips   = aws_instance.deploy.*.public_ip
      runner_private_ips  = aws_instance.deploy.*.private_ip
      clients_public_ips   = aws_instance.client.*.public_ip
      clients_private_ips  = aws_instance.client.*.private_ip
      ssh_user              = "ubuntu"
    }
  )
  filename = "${path.module}/../ansible/hosts.ini"
}

resource "local_file" "hosts_private_ini" {
  content = templatefile("${path.module}/hosts_private_ini.tpl",
    {
      runner_public_ips   = aws_instance.deploy.*.public_ip
      runner_private_ips  = aws_instance.deploy.*.private_ip
      clients_public_ips   = aws_instance.client.*.public_ip
      clients_private_ips  = aws_instance.client.*.private_ip
      ssh_user              = "ubuntu"
    }
  )
  filename = "${path.module}/../ansible/hosts_private.ini"
}

output "clients" {
  value = {
    for instance in aws_instance.client :
    instance.public_ip => instance.private_ip
  }
}

output "runner_host" {
  value = {
    for instance in aws_instance.deploy :
    instance.public_ip => instance.private_ip
  }
}
