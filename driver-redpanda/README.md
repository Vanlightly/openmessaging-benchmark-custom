# Redpanda deployment

This README provides you with step-by-step instructions for running three main Redpanda examples, on different hardware configurations.
Each of these options has their own similar-yet-different setup steps, as the ansible and terraform configurations need to match.
- Example deployment with i3en.6xlarge instances (which is for storage optimized instances such as the i3 class)
- Example deployment with m6in.8xlarge instances with io1 EBS drives (which provisions Redpanda instances with io1 or io2 volumes)
- Example deployment with m6in.8xlarge instances with gp3 EBS drives (which provisions Redpanda instances with gp3 volumes)

Running the workloads, observing progress, and collecting results all share a common workflow.

## 0) Prerequisites

> :warning: Make sure you have [followed the common prerequisites instructions](../COMMON_PREREQS.md)

## 1) Create a deployment setup with Terraform and Ansible

You will need to ensure Terraform can access your AWS account - doing this is not included in this readme. I will assume this is already solved.

There are three Terraform files (you only run one of them):

### a) Example deployment with i3en.6xlarge instances

1. Go to the `driver-redpanda/deploy` directory.

```bash
cd driver-redpanda/deploy
```

2. Create a tfvars file (you may need to specify an AWS profile) with Redpanda brokers using i3en.6xlarge instances.

```bash
cd tf-local-ssd
cat > terraform.tfvars << EOF 
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az            = "us-west-2a"
# AMIs in us-west
# Intel: Ubuntu 20.04 ami-0d31d7c9fc9503726 , Ubuntu 22.04 ami-0fcf52bcf5db7b003
# ARM: Ubuntu 22.04 ami-03f6bd8c9c6230968
redpanda_ami    = "ami-0d31d7c9fc9503726"
other_ami       = "ami-0d31d7c9fc9503726"
profile         = "my-aws-profile"

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
EOF
```

3. Run Terraform

If you haven't previously done so, run the following:

```bash
terraform init
```

Now run Terraform apply to provision the ec2 instances.

```bash
terraform apply --auto-approve
```
You will need to enter an owner name.


4. Copy the hosts.ini file to the `deploy` directory.

```bash
cp hosts.ini ../.
```


### b) Example deployment with m6in.8xlarge instances with io1 EBS drives
2x io1 drives with maxed out iops and throughput

1. Go to the `driver-redpanda/deploy` directory.

```bash
cd driver-redpanda/deploy
```

2. Create a tfvars file (you may need to specify an AWS profile) with Redpanda brokers using i3en.6xlarge instances.

```bash
cd tf-ebs-io-drive
cat > terraform.tfvars << EOF 
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az            = "us-west-2a"
# AMIs in us-west
# Intel: Ubuntu 20.04 ami-0d31d7c9fc9503726 , Ubuntu 22.04 ami-0fcf52bcf5db7b003
# ARM: Ubuntu 22.04 ami-03f6bd8c9c6230968
redpanda_ami    = "ami-0d31d7c9fc9503726"
other_ami       = "ami-0d31d7c9fc9503726"
profile         = "my-aws-profile"

instance_types = {
  "redpanda"      = "m6in.8xlarge"
  "client"        = "c5n.9xlarge"
  "prometheus"    = "i3en.xlarge"
}

num_instances = {
  "client"     = 2
  "redpanda"   = 3
  "prometheus" = 1
}

io_drive_type          = "io1"
io_drive_size_gb       = 7500
io_drive_throughput_mb = 1000
io_drive_iops          = 64000
io_drive_count         = 2
EOF
```

3. Run Terraform

If you haven't previously done so, run the following:

```bash
terraform init
```

Now run Terraform apply to provision the ec2 instances.

```bash
terraform apply --auto-approve
```
You will need to enter an owner name.

4. Copy the hosts.ini file to the `deploy` directory.

```bash
cp hosts.ini ../.
```

### c) Example deployment with m6in.8xlarge instances with gp3 EBS drives

1. Go to the `driver-redpanda/deploy` directory.

```bash
cd driver-redpanda/deploy
```

2. Create a tfvars file (you may need to specify an AWS profile) with Redpanda brokers using i3en.6xlarge instances.

```bash
cd tf-ebs-gp3
cat > terraform.tfvars << EOF 
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az            = "us-west-2a"
# AMIs in us-west
# Intel: Ubuntu 20.04 ami-0d31d7c9fc9503726 , Ubuntu 22.04 ami-0fcf52bcf5db7b003
# ARM: Ubuntu 22.04 ami-03f6bd8c9c6230968
redpanda_ami    = "ami-0d31d7c9fc9503726"
other_ami       = "ami-0d31d7c9fc9503726"
profile         = "my-aws-profile"

instance_types = {
  "redpanda"      = "m6in.8xlarge"
  "client"        = "c5n.9xlarge"
  "prometheus"    = "i3en.xlarge"
}

num_instances = {
  "client"     = 2
  "redpanda"   = 3
  "prometheus" = 1
}

gp3_size_gb       = 7500
gp3_iops          = 16000
gp3_throughput_mb = 1000
gp3_count         = 2
EOF
```

3. Run Terraform

If you haven't previously done so, run the following:

```bash
terraform init
```

Now run Terraform apply to provision the ec2 instances.

```bash
terraform apply --auto-approve
```
You will need to enter an owner name.

4. Copy the hosts.ini file to the `deploy` directory.

```bash
cp hosts.ini ../.
```


## 2) Run Ansible

Making sure you copied the `hosts.ini` from your Terraform directory, you can run either the non-TLS or the TLS Ansible script.

1. Create an Ansible config file with variable values

Example with TLS and SASL.

```bash
cd ..
cat > ansible-config/my-tls-config.yaml << EOF
clientMinJvmHeap: 16g
clientMaxJvmHeap: 40g
partition_percent: 100
tls_enabled: true
sasl_enabled: true
EOF
```

Example without TLS and SASL.

```bash
cd ..
cat > ansible-config/my-non-tls-config.yaml << EOF
clientMinJvmHeap: 16g
clientMaxJvmHeap: 40g
partition_percent: 100
tls_enabled: false
sasl_enabled: false
EOF
```

2. From the `deploy` directory run Ansible.

Without TLS
```bash
ansible-playbook deploy.yaml --extra-vars "@ansible-config/my-non-tls-config.yaml"
```

With TLS. It will prompt you for your password as it needs sudo locally for the TLS cert work.
```bash
ansible-playbook deploy.yaml --extra-vars "@ansible-config/my-tls-config.yaml" --ask-become-pass
```

You will need to make sure that things like heap sizes and drive counts adequately match the hardware you have chosen.

### Handling Ansible failures

If Ansible fails, just run it again. The usual culprit is a Cloud Alchemy role so can just rerun the job with the additional argument `--tags "monitori
ng,profiling"` plus `tls` is you are configuring that.

> Ansible can take a while to complete (15-20 min) depending on your deployment. 

Once Ansible has finished, you can choose and deploy a workload.

### 3) OPTIONAL: Configure Redpanda in some way

If you run long-running tests you'll need to set a retention limit. You can find the IP of one of the Redpanda instances in the `hosts.ini`. Then ssh onto the machine and run `rpk` commands.

Example of setting retention limits to 10GB per partition and 1 hour:

```bash
ssh -i ~/.ssh/omb ubuntu@<redpanda-ip-address>
sudo -i
rpk cluster config set retention_bytes 10000000000
rpk cluster config set delete_retention_ms 3600000
```

## 4) Start a Workload

1. Choose a workload file

Identify a workload file you'd like to run under the `workloads` directory. Alternately, write your own.

2. Copy the workload file to the control instance

Replace 1.2.3.4 with the IP address of the control instance, found in the `hosts.ini` file.

```bash
scp -i ~/.ssh/omb workloads/my-workload.sh ubuntu@1.2.3.4:/opt/benchmark
```

3. SSH onto the control instance a run the workload.

Use a screen session for longer-running workloads, so that if your terminal closes it won't stop.
```bash
ssh -i ~/.ssh/omb ubuntu@1.2.3.4
screen -S benchmark
chmod +x *.sh
```
4. Run the workload.

```bash
./my-workload.sh
```

If you get disconnected you can ssh back onto the machine a run `screen -r` to resume the screen session.

Next, let's monitor its progress.

### If you want to tweak and run your own drivers and workloads

OMB requires two types of file to run a benchmark:
- Driver files, which configure the specific system and clients. It is technology specific. For example, Redpanda driver files include things like boo
tstrapServers and replicationFactor.
- Workload files, which configure the workload: number of topics, producers, producer rate etc.

You run a single workload by running a command like: 
```bash
sudo bin/benchmark -d \
driver-redpanda/<driver-file-here>.yaml \
<workload-file-here>.yaml
```

There are a number of driver files directly under the `driver-redpanda` directory.

I use workload files in the form of bash scripts which run multi-step benchmarks. You can find examples under `deploy/workloads`. These bash scripts have everything you need to run multiple benchmarks in one go. 

I prefer to work on workload files locally and copy them myself. Most of my benchmarking is exploratory and I am constantly tweaking stuff. So will upload my latest workload files to control machine. The IP address of the control instance you will run the benchmarks from is under `[control]` in the `hosts.ini`. 

Example copying the large workload scripts:

```bash
scp -i ~/.ssh/omb workloads/large/*.sh ubuntu@<the-ip-address>:/opt/benchmark
```

### Running multiple workloads sequentially

If you want to leave a suite of benchmarks running, copy the `run-many.sh` file to the control instance and simply pass it a list of files to run. It will pause for ten minutes between each.

Examples:

```bash
./run-many.sh workflow-file1.sh workflow-file2.sh workflow-file3.sh  
```


## 5) Monitor progress with Grafana or Prometheus

You can follow the progress from the command line and also looking at the Grafana dashboards. You can get the IP of the Grafana and Prometheus server from the `hosts.ini` file. The EC2 security group only allows access from your IP so setting a strong password is unnecessary unless you want to expose it to the world (not recommended).

The ports are as follows:
- Grafana: 3000
- Prometheus: 9090

The Grafana password is set to `set_me_if_you_want` which you can change in the Ansible file, look for `grafana_security`. Go to the EC2 security group to modify the ingress rules if you want others to be able to access the dashboard.

### Eg: Connecting to Grafana:

1. Obtain the Grafana IP address from your `hosts.ini` file. 

2. Open a browser and go to `<your-grafana-ip-address>:3000`

3. Username: `admin`, password: `set_me_if_you_want`

4. Import the dashboard json files under `monitoring/dashboards`

You should now be able to see both client and redpanda server metrics coming through.

## 6) Collect the results

At the end the OMB benchmark program will write summarized results to a json file. If you run multiple step benchmarks, you'll get one json file per step. Copies the json files to your local directory.

1. From another shell, or after exiting the SSH session, scp the files to your machine.

```bash
scp -i ~/.ssh/omb ubuntu@<ip-address>:'/opt/benchmark/*.json' .
```

2. Visualize the results
See the [charts README.md](../charts/README.md) for more details.

## 7) Tear down your environments!
If you use temporary credentials, remember you may need to refresh them first.

From the same Terraform directory that you ran the `apply` command, run: `terraform destroy --auto-approve` and use the same owner tag value when prompted. If you ran the i3en.6xlarge instances configuration:
```bash
cd tf-local-ssd
terraform destroy --auto-approve
```

If you ran the gp3 volumes instances configuration:
```bash
cd tf-ebs-gp3
terraform destroy --auto-approve
```

If you ran the io1 volumes instances configuration:
```bash
cd tf-ebs-io-drive
terraform destroy --auto-approve
```