# How to deploy

This is a cut-down version, with only the Kafka clients and without Grafana and Prometheus. Unfortunately, the Grafana and Prometheus Ansible Galaxy roles have been abandoned, so a new way of deploying these is needed. However, The OpenMessagingBenchmark statistics are high quality and so Grafana is not strictly needed.

The automation of OMB is quite old now, and may not be easy to run on modern developer machines. So I recommend running it entire from an Ubuntu VM, or the hybrid approach described in this page.

## 0. Prerequisites

You can deploy from your developer machine, or from an Ubuntu server. If you are using a modern Apple device, then you will like find that the Ansible playbook does not work, especially if you are on Apple silicon. If you encounter issues, then use an Ubuntu 22.04 server instead.

You will need to install Terraform and Ansible.

### Deployment machine

You can deploy OMB with one of the following methods:

1. From a developer machine. Your mileage may vary. OMB automation is old and won't work on modern machines, especially Apple silicon.
2. From an Ubuntu server in AWS.
3. Hybrid. Deploy the servers with Terraform from your local machine. Then run Ansible from a deployed Ubuntu VM. This might be necessary if you have restrictive security controls that only allow AWS provisioning from your laptop on a VPN with 2FA etc etc.

#### Developer laptop - MacOS

```
brew install terraform
brew install ansible
```

You will also need Python 3.

#### Ubuntu (22.04 tested)

Terraform.

```
sudo apt install snapd
sudo snap install terraform --classic
```

Ansible.

```
sudo apt update
sudo apt-get install python3-pip python3-dev -y
sudo -H pip3 install pyopenssl==24.0.0
sudo -H pip3 install ansible
```

#### Hybrid method

Deploy all the servers using Terraform from your developer machine, and then perform the rest from the `runner` Ubuntu VM. Usually, any technical problems are due to Ansible. This guide has been tested on Ubuntu 22.04 and the Ansible playbook will work when run there.

The only prerequisite in this case is Terraform.

### Build OMB

From the project root directory.

```
mvn clean install -Dlicense.skip=true
```

This will place the jar file in the `package/target` directory.

### Create an SSH key

```bash
ssh-keygen -f ~/.ssh/omb
```

## Steps

### 1. Deploy a cluster (manual)

Deploy a cluster. This is outside the scope of this work.

#### Confluent Cloud

When deploying a Confluent Cloud dedicated cluster, create a network with a CIDR block of `10.10.0.0/16`.

Make a note of:
* The bootstrap server.
* The cluster API key and secret (you may need to create this).

### 2. Deploy servers (Terraform)

From the `deploy/clients-only/terraform` directory, deploy the servers using Terraform.

If you are using the hybrid deployment, set the number of runners in the tfvars file to 1, else leave it at 0.

Before you deploy, check the `terraform.tfvars` to ensure you have the right number of client machines and VM sizes for the workload. When running a workload, monitor the CPU load on the client machines and make sure they do not reach full utilization. `htop` works fine for this.

Example `terraform.tfvars`:

```
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az		        = "us-west-2b"
runner_ami      = "ami-0d31d7c9fc9503726" # Ubuntu 22.04, AMD64
ami             = "ami-0d31d7c9fc9503726" # Ubuntu 22.04, AMD64
profile         = "my-profile"

instance_types = {
  "runner"     = "t3.small"
  "client"     = "c5n.xlarge"
  "prometheus" = "i3en.xlarge"
}

num_instances = {
  "runner"     = 1
  "client"     = 2
  "prometheus" = 1
}
```
Set `runner = 0` if you are not using the hybrid deployment approach.

Terraform init will need to be run just once:

```
terraform init
```

Then deploy with:

```
terraform apply --auto-approve
```

If you are deploying from an Ubuntu server inside the VPC of the benchmark (such as with the hybrid method) then copy the `hosts_private.ini` to the `ansible` directory, else copy the `hosts.ini` file.

```
cp hosts_private.ini ../ansible/hosts.ini
```

Or, if deploying from outside the VPC.

```
cp hosts.ini ../ansible/hosts.ini
```

The `hosts.ini` file is used by Ansible to know which hosts it must deploy to and their IP addresses.

If you are using the hybrid approach, make a note of the runner IP address in the Terraform output.

## 3. Setup VPC peering

If benchmarking Confluent Cloud, go the the network and add a VPC peering connection. Then accept the peering connection request in the VPC that you just created. Next add the peering connection as an additional route in your VPC route table.

## 4. Hybrid only - copy necessary files to runner VM

If you ran Terraform from your developer machine, but use an Ubuntu VM to run Ansible, then you need to copy the Ansible files to the server. You can either clone this repository to the server, or just scp the necessary files. Note, that you'll need to copy the key as associated with the deployed VMs so Ansible can SSH onto them.

The scp method is as follows (from the `deploy/clients-only` directory):

```
export RUNNER=<the ip of the deployment VM>
scp -r -i ~/.ssh/omb ansible ubuntu@${RUNNER}:.
scp -i ~/.ssh/omb ../../../package/target/openmessaging-benchmark-0.0.1-SNAPSHOT-bin.tar.gz ubuntu@${RUNNER}:./ansible/.
scp -i ~/.ssh/omb ~/.ssh/omb* ubuntu@${RUNNER}:./.ssh/.
```

Next SSH onto the runner VM

```
ssh -i ~/.ssh/omb ubuntu@${RUNNER}
```

If you are using the hybrid approach, you'll now need to install Ansible now (see prerequistes above).

## 5. Deploy client software (Ansible)

Run from the machine you will run Ansible from, go to the `deploy/clients-only/ansible` directory and run the Ansible playbook. If you are using the `runner` VM, it will be in the `home/ubuntu/ansible` directory.

Create a yaml file in `ansible-config` directory with the client Java memory min and max option.

For example, `small-client-mem.yaml`:

```
clientMinJvmHeap: 4G
clientMaxJvmHeap: 16G
```

Run Ansible.

```
ansible-playbook deploy.yaml \
--extra-vars "@ansible-config/small-client-mem.yaml" \
--extra-vars "api_key=my_kafka_api_key" \
--extra-vars "api_secret=my_kafka_api_secret" \
--extra-vars "bootstrapServers=my_bootstrap_servers"
```

## 6. Run workload

In order to run a workload, you'll need to copy some workload files to the 1st client server.

Get the IP address of the 1st client server (in the hosts.ini) and save it to a variable. If you are deploying from inside the VPC, use the private IP address, else use the public IP address

```
export=CHOST=<private or public IP>
```

Copy some workload files.

```
scp -i ~/.ssh/omb workloads/my-workload.sh ubuntu@$CHOST:/opt/benchmark
```

Next SSH onto the 1st client machine to run the workload.

```
ssh -i ~/.ssh/omb ubuntu@$CHOST
cd /opt/benchmark
chmod +x *.sh
screen -S benchmark
./my-workload.sh
```

Use `screen` so if the SSH connection fails, you can resume the session.

## 7. Collect results and generate charts

Once the workload has terminated, copy the json file with the statistics to where you can run the chart generation python script.

Exit the SSH session on the client host, then:

```bash
scp -i ~/.ssh/omb ubuntu@${CHOST}:'/opt/benchmark/*.json' .
```

Now you have one or more json files, copy them to the `charts/results` directory. 

To generate the charts, see the README.md in the `charts` directory.