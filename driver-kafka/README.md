# Kafka deployment

This README provides you with step-by-step instructions for running three main Kafka examples, on different hardware configurations.
Each of these options has their own similar-yet-different setup steps, as the ansible and terraform configurations need to match.
- Deployment with i3en.6xlarge instances (This is what I used for my testing)
- Small sized deployment with one gp3 volume per broker (if you want to test gp3 volumes)
- Large sized deployment with two gp3 volumes per broker (an expanded gp3 volume example)

Running the workloads, observing progress, and collecting results all share a common workflow.

## 0) Prerequisites

> :warning: Make sure you have [followed the common prerequisites instructions](../COMMON_PREREQS.md)

## 1) Create a deployment setup with Terraform and Ansible

There are three examples: a), b) and c). Just run one of them.

### a) Setup deployment with i3en.6xlarge instances

1. Start from the `driver-kafka/deploy` directory.

```bash
cd driver-kafka/deploy
```

2. Create a tfvars file (you may need to specify an AWS profile) with Kafka brokers using i3en.6xlarge instances.

```bash
cd tf-local-ssd
cat > terraform.tfvars << EOF 
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az              = "us-west-2b"
ami             = "ami-0d31d7c9fc9503726"
profile         = "my-aws-profile"

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

4. Copy the hosts.ini file to the `deploy` directory.

```bash
cp hosts.ini ../.
```

5. Create an Ansible config file with variable values

```bash
cd ..
cat > ansible-config/my-config.yaml << EOF
kafkaServerVersion: 3.4.0
kafkaServerLogDirs: /mnt/data-1,/mnt/data-2
kafkaServerNumReplicaFetchers: 8
kafkaServerNumNetworkThreads: 8
kafkaServerMinJvmHeap: 6G
kafkaServerMaxJvmHeap: 6G
clientMinJvmHeap: 16G
clientMaxJvmHeap: 40G
EOF
```

You're now ready to run Ansible. Go to Step 2 - Run Ansible.


### b) Setup a small sized deployment with one gp3 volume per broker

1. Start from the `driver-kafka/deploy` directory.

```bash
cd driver-kafka/deploy
```

2. Create a tfvars file (you may need to specify an AWS profile) with Kafka brokers using m5.4xlarge instances with two gp3 drives attached.

```bash
cd tf-ebs-gp3
cat > terraform.tfvars << EOF 
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az              = "us-west-2b"
ami             = "ami-0d31d7c9fc9503726"
profile         = "my-aws-profile"

instance_types = {
  "kafka"      = "m6in.2xlarge"
  "zookeeper"  = "t2.medium"
  "client"     = "c5n.4xlarge"
  "prometheus" = "i3en.xlarge"
}

num_instances = {
  "client"     = 2
  "kafka"      = 3
  "zookeeper"  = 3
  "prometheus" = 1
}

gp3_size_gb       = 500
gp3_iops          = 3000
gp3_throughput_mb = 125
gp3_count         = 1
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
You will need to enter a value when prompted for the `owner` tag.

4. Copy the hosts.ini file to the `deploy` directory.

```bash
cp hosts.ini ../.
```

5. Create an Ansible config file with variable values

```bash
cd ..
cat > ansible-config/my-config.yaml << EOF
kafkaServerVersion: 3.4.0
kafkaServerLogDirs: /mnt/data-1
kafkaServerNumReplicaFetchers: 2
kafkaServerNumNetworkThreads: 2
kafkaServerMinJvmHeap: 2G
kafkaServerMaxJvmHeap: 2G
clientMinJvmHeap: 16G
clientMaxJvmHeap: 16G
EOF
```
You're now ready to run Ansible. Go to Step 2 - Run Ansible.

### c) Setup a large sized deployment with two gp3 volumes per broker

1. Start from the `driver-kafka/deploy` directory.

```bash
cd driver-kafka/deploy
```

2. Create a tfvars file (you may need to specify an AWS profile) with Kafka brokers using m5.4xlarge instances with two gp3 drives attached.

```bash
cd tf-ebs-gp3
cat > terraform.tfvars << EOF 
public_key_path = "~/.ssh/omb.pub"
region          = "us-west-2"
az              = "us-west-2b"
ami             = "ami-0d31d7c9fc9503726"
profile         = "my-aws-profile"

instance_types = {
  "kafka"      = "m6in.8xlarge"
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

4. Copy the hosts.ini file to the `deploy` directory.

```bash
cp hosts.ini ../.
```

5. Create an Ansible config file with variable values

```bash
cd ..
cat > ansible-config/my-config.yaml << EOF
kafkaServerVersion: 3.4.0
kafkaServerLogDirs: /mnt/data-1,/mnt/data-2
kafkaServerNumReplicaFetchers: 8
kafkaServerNumNetworkThreads: 8
kafkaServerMinJvmHeap: 6G
kafkaServerMaxJvmHeap: 6G
clientMinJvmHeap: 16G
clientMaxJvmHeap: 40G
EOF
```

You're now ready to run Ansible. Go to Step 2 - Run Ansible.

## 2) Run Ansible

Making sure you copied the `hosts.ini` from your Terraform directory, you can run either the non-TLS or the TLS Ansible script.

From the `deploy` directory run Ansible.

Without TLS
```bash
ansible-playbook deploy-no-tls.yaml --extra-vars "@ansible-config/my-config.yaml"
```

With TLS. It will prompt you for your password as it needs sudo locally for the TLS cert work.
```bash
ansible-playbook deploy-tls.yaml --extra-vars "@ansible-config/my-config.yaml" --ask-become-pass
```

The scripts have certain required variables which must be supplied. There are a couple of example files under `ansible-config`. If your example you have provisioned two gp3 drives, or used an instance with two local SSDs, then you'll need to make sure that `kafkaServerLogDirs` has a value that can take advantage of both. By default, Ansible mounts drives with the pattern: `/mnt/data-<drive number>`, for example: `kafkaServerLogDirs: /mnt/data-1,/mnt/data-2`.

You will need to make sure that things like heap sizes and drive counts adequately match the hardware you have chosen.

### Handling Ansible failures

If Ansible fails, and if Kafka was installed successfully then running the whole script again, including the Kafka steps, will cause Kafka to enter a bad state with ZooKeeper. You can run ansible again but target the necessary remaining tasks using tags or simply redeploy from scratch.

The following tags are used:
- server (all OS level stuff like package installation)
- kafka ( all Kafka and ZooKeeper installation)
- client (all installation steps for the benchmark clients)
- monitoring (all Cloud Alchemy roles like Prometheus, Grafana and NodeExporter)
- profiling (some profiling tools)

The usual culprit is a Cloud Alchemy role so just rerun the job with the additional argument `--tags "monitoring,profiling"`.

> Ansible can take a while to complete (15-20 min) depending on your deployment. 

Once Ansible has finished, you can choose and deploy a workload.


## 3)OPTIONAL: Configure Kafka in some way

If you run long-running tests you'll need to set a retention limit. You can find the IP of one of the Kafka instances in the `hosts.ini`. Then ssh onto the machine and run `kafka-admin.sh` commands.

Example of setting segment file size and retention limits on broker 0:

```bash
ssh -i ~/.ssh/omb ubuntu@<kafka-ip-address>
sudo -i
cd /opt/kafka/bin
./kafka-configs.sh --bootstrap-server localhost:9092 --alter --entity-type brokers --entity-name 0 --add-config segment.bytes=134217728,log.segment.bytes=134217728,log.retention.ms=1200000,log.retention.bytes=40000000000,retention.ms=1200000,retention.bytes=40000000000
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
- Driver files, which configure the specific system and clients. It is technology specific. For example, Kafka driver files include things like bootstrapServers and replicationFactor.
- Workload files, which configure the workload: number of topics, producers, producer rate etc.

You run a single workload by running a command like: 

```bash
sudo bin/benchmark -d \
driver-kafka/<driver-file-here>.yaml \
<workload-file-here>.yaml
```

There are a number of driver files directly under the `driver-kafka` directory.

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

You should now be able to see both client and Kafka server metrics coming through.

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