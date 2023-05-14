provider "aws" {
  region  = var.region
  version = "~> 3.0"
  profile = var.profile
}

provider "random" {
  version = "~> 2.1"
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
  default     = "redpanda-benchmark-key"
  description = "Desired name prefix for the AWS key pair"
}

variable "region" {}
variable "az" {}
variable "profile" {}

variable "redpanda_ami" {}
variable "other_ami" {}

variable "io_drive_type" {}
variable "io_drive_size_gb" {}
variable "io_drive_throughput_mb" {}
variable "io_drive_iops" {}
variable "io_drive_count" {}

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
    Name  = "RedPanda-Benchmark-VPC-${random_id.hash.hex}"
    owner = "${var.owner}"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "redpanda" {
  vpc_id = aws_vpc.benchmark_vpc.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.benchmark_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.redpanda.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "benchmark_subnet" {
  vpc_id                  = aws_vpc.benchmark_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.az}"
}

# Get public IP of this machine
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "benchmark_security_group" {
  name   = "terraform-redpanda-${random_id.hash.hex}"
  vpc_id = aws_vpc.benchmark_vpc.id

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
    Name  = "Benchmark-Security-Group-${random_id.hash.hex}"
    owner = "${var.owner}"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}-${random_id.hash.hex}"
  public_key = "${file(var.public_key_path)}"
}

locals {
  device_names = {"0" = "/dev/sdf", "1" = "/dev/sdg", "2" = "/dev/sdh"}
  instances = toset(formatlist("%d", range(var.num_instances["redpanda"])))
  volumes = toset(flatten([ for instance in local.instances :
    [ for volume in range(var.io_drive_count) : "i${instance}-v${volume}" ]
  ]))
  attachments = toset(flatten([ for instance in local.instances :
    [ for volume in formatlist("%d", range(var.io_drive_count)) : {
      instance = instance
      volume = "i${instance}-v${volume}"
      vol_index = volume
    }]
  ]))
}

resource "aws_instance" "redpanda" {
  for_each               = local.instances
  ami                    = "${var.redpanda_ami}"
  instance_type          = "${var.instance_types["redpanda"]}"
  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.benchmark_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.benchmark_security_group.id}"]
  monitoring             = true

  tags = {
    Name  = "redpanda-${each.key}"
    owner = "${var.owner}"
  }
}

# limited by io2 region limit od DevX
resource "aws_ebs_volume" "redpanda-vol" {
  for_each = local.volumes
  availability_zone = "${var.az}"
  size              = "${var.io_drive_size_gb}"
  iops              = "${var.io_drive_iops}"
  type              = "${var.io_drive_type}"
  throughput        = "${var.io_drive_throughput_mb}"

  tags = {
    Name = "redpanda-ebs-${each.key}"
  }
}

resource "aws_volume_attachment" "attachment" {
  for_each = {for att in local.attachments:  att.volume => att}
  instance_id = aws_instance.redpanda[each.value.instance].id
  volume_id = aws_ebs_volume.redpanda-vol[each.key].id
  device_name = local.device_names[each.value.vol_index]
}

resource "aws_instance" "client" {
  ami                    = "${var.other_ami}"
  instance_type          = "${var.instance_types["client"]}"
  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.benchmark_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.benchmark_security_group.id}"]
  count                  = "${var.num_instances["client"]}"
  monitoring             = true

  tags = {
    Name  = "redpanda-client-${count.index}"
    owner = "${var.owner}"
  }
}

resource "aws_instance" "prometheus" {
  ami                    = "${var.other_ami}"
  instance_type          = "${var.instance_types["prometheus"]}"
  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.benchmark_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.benchmark_security_group.id}"]
  count                  = "${var.num_instances["prometheus"]}"

  tags = {
    Name  = "prometheus-${count.index}"
    owner = "${var.owner}"
  }
}

output "client_ssh_host" {
  value = "${aws_instance.client.0.public_ip}"
}

resource "local_file" "hosts_ini" {
  content = templatefile("${path.module}/hosts_ini.tpl",
    {
      redpanda_public_ips   = [for rp in aws_instance.redpanda: rp.public_ip]
      redpanda_private_ips  = [for rp in aws_instance.redpanda: rp.private_ip]
      clients_public_ips   = aws_instance.client.*.public_ip
      clients_private_ips  = aws_instance.client.*.private_ip
      prometheus_host_public_ips   = aws_instance.prometheus.*.public_ip
      prometheus_host_private_ips  = aws_instance.prometheus.*.private_ip
      control_public_ips   = aws_instance.client.*.public_ip
      control_private_ips  = aws_instance.client.*.private_ip
      ssh_user              = "ubuntu"
    }
  )
  filename = "${path.module}/hosts.ini"
}
