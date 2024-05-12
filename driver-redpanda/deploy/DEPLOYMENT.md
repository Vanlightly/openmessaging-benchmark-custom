# How to deploy

Due to the age of this automation, some is no longer supported, and some parts do not work on Aple Silicon. The deployment is split up into:
1. Terraform, to provision all the servers, including a server for running Ansible.
2. Running Ansible from an Ubuntu 22.04 instance inside the VPC.

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
- `ebs-io-drive`
- `local-nvme-drive`

Choose which type of drive you want. Configure the `terraform.tfvars` according to your needs. There is an example tfvars file in each of the above directories.

Example `terraform.tfvars`:

```
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az		        = "us-west-2a"
runner_ami      = "ami-0d31d7c9fc9503726" # Ubuntu 22.04, AMD64
redpanda_ami    = "ami-0fcf52bcf5db7b003"
other_ami       = "ami-0d31d7c9fc9503726"

instance_types = {
  "deploy"        = "t3.small"
  "redpanda"      = "i3en.6xlarge"
  "client"        = "c5n.9xlarge"
  "prometheus"    = "i3en.xlarge"
}

num_instances = {
  "deploy"     = 1
  "client"     = 2
  "redpanda"   = 3
  "prometheus" = 1
}
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
cd driver-redpanda/deploy/ansible
ansible-galaxy install -r requirements.yaml
```

## 3) Run Ansible

You will run Ansible from the cloned `openmessaging-benchmark-custom` directory.

Check which yaml file you want to use in the `ansible-config` directory.

For example, `my-config.yaml`:

```
redpanda_package: redpanda=23.1.7-1
clientMinJvmHeap: 16g
clientMaxJvmHeap: 40g
partition_percent: 100
tls_enabled: false
sasl_enabled: false
```
To run with TLS, set `tls_enabled` and `sasl_enabled` to true. To run the latest Redpanda, comment out `redpanda_package`. To add overprovisioning to cope with Redpanda random IO, set how much of the drive it writable using `partition_percent`. 

If you are running Ansible from your local machine, or any server outside the VPC, then change the `inventory` config in `ansible.cfg`. See the inline comments.

Now run Ansible. You can deploy with or without TLS.

Without TLS.

```bash
ansible-playbook deploy.yaml --extra-vars "@ansible-config/my-non-tls-config.yaml"
```

With TLS. (Note: If you run this from your local machine, it will prompt you for your password as it needs sudo locally for the TLS cert work, so add `--ask-become-pass`)

```bash
ansible-playbook deploy.yaml --extra-vars "@ansible-config/my-tls-config.yaml" 
```

You will need to make sure that things like heap sizes and drive counts adequately match the hardware you have chosen.

### Handling Ansible failures

If Ansible fails, just run it again. The usual culprit is a Cloud Alchemy role so can just rerun the job with the additional argument `--tags "monitori
ng,profiling"` plus `tls` is you are configuring that.

> Ansible can take a while to complete (15-20 min) depending on your deployment.

Once Ansible has finished, you can choose and deploy a workload.

### 4) OPTIONAL: Configure Redpanda in some way

If you run long-running tests you'll need to set a retention limit. You can find the IP of one of the Redpanda instances in the `hosts.ini`. Then ssh onto the machine and run `rpk` commands. If you SSH from the deploy server, use the private IP address. If you SSH from your local machine, use the public IP address.

Example of setting retention limits to 5GB per partition and 30 minutes:

```bash
ssh -i ~/.ssh/omb ubuntu@<any-redpanda-ip-address>
sudo -i
rpk cluster config set retention_bytes 5000000000
rpk cluster config set delete_retention_ms 1800000
```

For write caching, the following configs are relevant:

- `raft_replica_max_pending_flush_bytes` defaults to 262144.
- `raft_replica_max_flush_delay_ms` defaults to 100ms.

## 5) Tear down your environments!
If you use temporary credentials, remember you may need to refresh them first.

From the same Terraform directory that you ran the `apply` command, run: `terraform destroy --auto-approve` and use the same owner tag value when prompted.

```bash
terraform destroy --auto-approve
```