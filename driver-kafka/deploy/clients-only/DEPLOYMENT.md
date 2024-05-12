# How to deploy

This automation only deploy the clients and assumes you will create a Kafka cluster yourself.

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

Configure the `terraform.tfvars` according to your needs. You will need to ensure there is enough hardware for the clients to match the desired load.

Example `terraform.tfvars`:

```
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az		        = "us-west-2b"
runner_ami      = "ami-0d31d7c9fc9503726" # Ubuntu 20.04, AMD64
ami             = "ami-09c3a3c2cf6003f6c" # Ubuntu 22.04, AMD64

instance_types = {
  "deploy"     = "t3.small"
  "client"     = "c5n.9xlarge"
  "prometheus" = "i3en.xlarge"
}

num_instances = {
  "deploy"     = 1
  "client"     = 2
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
cd driver-kafka/deploy/clients-only/ansible
ansible-galaxy install -r requirements.yaml
```

If you run Ansible from MacOS, then you may need to run the following to avoid errors.

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

## 3) Run Ansible

You will run Ansible from the cloned `openmessaging-benchmark-custom` directory.

Check which yaml file you want to use in the `ansible-config` directory.

For example, `my-config.yaml`:

```
clientMinJvmHeap: 4g
clientMaxJvmHeap: 16g
```

If you are running Ansible from your local machine, or any server outside the VPC, then change the `inventory` config in `ansible.cfg`. See the inline comments.

Run Ansible. This automation assumes TLS is used, and the SASL username and password are passed as the variables `api_key` and `api_secret`.

```
ansible-playbook deploy.yaml \
--extra-vars "@ansible-config/small-client-mem.yaml" \
--extra-vars "api_key=my_kafka_api_key" \
--extra-vars "api_secret=my_kafka_api_secret" \
--extra-vars "bootstrapServers=my_bootstrap_servers"
```

### Handling Ansible failures

If Ansible fails, just run it again. The usual culprit is a Cloud Alchemy role so can just rerun the job with the additional argument `--tags "monitori
ng"`.

> Ansible can take a while to complete (15-20 min) depending on your deployment.

Once Ansible has finished, you can choose and deploy a workload.

## 4) Tear down your environments!
If you use temporary credentials, remember you may need to refresh them first.

From the same Terraform directory that you ran the `apply` command, run: `terraform destroy --auto-approve` and use the same owner tag value when prompted.

```bash
terraform destroy --auto-approve
```