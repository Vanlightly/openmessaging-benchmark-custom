# How to deploy

Due to the age of this automation, some is no longer supported, and some parts do not work on Aple Silicon. The deployment is split up into:
1. Terraform, to provision all the servers, including a server for running Ansible.
2. Running Ansible from an Ubuntu 20.04 instance inside the VPC.

Run Terraform to deploy all the servers, optionally including one for Ansible. The Ansible automation does not work on Apple silicon.

## 0. Prerequisites

Install Terraform on your local machine.

```
brew install terraform
```

Create an SSH key.

```bash
ssh-keygen -f ~/.ssh/omb
```

## Steps

### 1) Deploy servers (Terraform)

There are a number of deployments in the `deploy/terraform` directory:
- `ebs-gp3-drive`
- `local-nvme-drive`

Choose which type of drive you want. Configure the `terraform.tfvars` according to your needs. There is an example tfvars file in each of the above directories.

Example `terraform.tfvars`:

```
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az		        = "us-west-2b"
deploy_ami      = "ami-0d31d7c9fc9503726" # Ubuntu 20.04, AMD64
ami             = "ami-09c3a3c2cf6003f6c" # Ubuntu 22.04, AMD64

instance_types = {
  "deploy"     = "t3.small"
  "kafka"      = "m6in.4xlarge"
  "zookeeper"  = "t2.medium"
  "client"     = "c5n.4xlarge"
  "prometheus" = "i3en.xlarge"
}

num_instances = {
  "deploy"     = 1
  "client"     = 2
  "kafka"      = 3
  "zookeeper"  = 3
  "prometheus" = 1
}

gp3_size_gb       = 3000
gp3_iops          = 6000
gp3_throughput_mb = 500
gp3_count         = 1
```

Set `deploy = 0` if you want to run Ansible locally. This will only work on older MacOS versions, and on Intel architectures. When `deploy = 1`, an Ubuntu 20.04 instance is deployed which you will use to run Ansible.

Terraform init will need to be run just once:

```
terraform init
```

Then deploy with:

```
terraform apply --auto-approve
```

## 2) Configure the Ansible deploy server

The Terraform output includes the IP address of the deploy server. SSH to it.

First copy your `omb` private key to the server. This is a throwaway key that you can destroy after running the benchmark. Ansible will need it to SSH onto the servers.

```
scp -i ~/.ssh/omb ~/.ssh/omb* ubuntu@<public-ip-of-deploy-server>:./.ssh/.
```

Now SSH onto the server.

```
ssh -i ~/.ssh/omb ubuntu@<public-ip-of-deploy-server>
```

Install Java, Python and Ansible.

```
sudo apt update
sudo apt install openjdk-17-jdk maven python3-pip python3-dev -y
```

Install `pyopenssl`, I've had pip get in a bad state without it.

```
sudo -H pip3 install pyopenssl==24.0.0
```

Cloudalchemy roles need jmespath.

```
sudo -H pip3 install jmespath
```

Finally, install Ansible.

```
sudo -H pip3 install ansible
```

Clone this repo.

```
git clone https://github.com/Vanlightly/openmessaging-benchmark-custom.git
```

Build a jar file.

```
cd openmessaging-benchmark-custom
mvn clean install -Dlicense.skip=true
```

Next install the Ansible Galaxy roles.

```
cd driver-kafka/deploy/apache-kafka/ansible
ansible-galaxy install -r requirements.yaml
```

If you run Ansible from MacOS, then you may need to run the following to avoid errors.

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

## 3) Run Ansible

If you will run Ansible from the deploy server, first copy the `hosts_private.ini` to the Ansible deploy server. This file was created in the `driver-kafka/deploy/apache-kafka/ansible` directory on your local machine.

```
scp -i ~/.ssh/omb ansible/hosts_private.ini ubuntu@<public-ip-of-deploy-server>:./openmessaging-benchmark-custom/driver-kafka/deploy/apache-kafka/ansible/.
```

You will run Ansible from the cloned `openmessaging-benchmark-custom` repo, in the `openmessaging-benchmark-custom/driver-kafka/deploy/apache-kafka/ansible` directory.

Check which yaml file you want to use in the `ansible-config` directory.

For example, `my-config.yaml`:

```
kafkaServerVersion: 3.7.0
kafkaServerLogDirs: /mnt/data-1
kafkaServerNumReplicaFetchers: 2
kafkaServerNumNetworkThreads: 2
kafkaServerMinJvmHeap: 2g
kafkaServerMaxJvmHeap: 2g
clientMinJvmHeap: 8g
clientMaxJvmHeap: 8g
```

If you are running Ansible from your local machine, or any server outside the VPC, then change the `inventory` config in `ansible.cfg`. See the inline comments.

Now run Ansible. You can deploy with or without TLS.

Without TLS
```bash
ansible-playbook deploy-no-tls.yaml --extra-vars "@ansible-config/my-config.yaml"
```

With TLS. (Note: If you run this from your local machine, it will prompt you for your password as it needs sudo locally for the TLS cert work, so add `--ask-become-pass`)

```bash
ansible-playbook deploy-tls.yaml --extra-vars "@ansible-config/my-config.yaml"
```

You will need to make sure that things like heap sizes and drive counts adequately match the hardware you have chosen.

### Handling Ansible failures

If Ansible fails, just run it again. The usual culprit is a Cloud Alchemy role so can just rerun the job with the additional argument `--tags "monitori
ng,profiling"` plus `tls` is you are configuring that.

> Ansible can take a while to complete (15-20 min) depending on your deployment.

Once Ansible has finished, you can choose and deploy a workload.

### 4) OPTIONAL: Configure Kafka in some way

If you run long-running tests you'll need to set a retention limit. You can find the IP of one of the Kafka instances in the `hosts.ini`. Then ssh onto the machine and run `kafka-admin.sh` commands.

Example of setting segment file size and retention limits on broker 0:

```bash
ssh -i ~/.ssh/omb ubuntu@<kafka-ip-address>
sudo -i
cd /opt/kafka/bin
./kafka-configs.sh --bootstrap-server localhost:9092 --alter --entity-type brokers --entity-name 0 --add-config segment.bytes=134217728,log.segment.bytes=134217728,log.retention.ms=1200000,log.retention.bytes=40000000000,retention.ms=1200000,retention.bytes=40000000000
```

## 5) Tear down your environments!
If you use temporary credentials, remember you may need to refresh them first.

From the same Terraform directory that you ran the `apply` command, run: `terraform destroy --auto-approve` and use the same owner tag value when prompted.

```bash
terraform destroy --auto-approve
```