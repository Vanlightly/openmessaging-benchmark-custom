
# Running benchmarks

You will SSH onto the control instance (one of the client instances) to run benchmarks.

## 1) Start a Workload

When you SSH to the control instance (the first client instance), make sure you use the right IP address. Use the public IP address of the control instance if connecting from your local machine, or the private IP if connecting from the deploy server.

1. Choose a workload file

Identify a workload file you'd like to run under the `workloads` directory. Alternately, write your own.

2. Copy the workload file to the control instance

```bash
scp -i ~/.ssh/omb workloads/my-workload.sh ubuntu@<control-instance-ip-address>:/opt/benchmark
```

3. SSH onto the control instance a run the workload.

Use a screen session for longer-running workloads, so that if your terminal closes it won't stop.
```bash
ssh -i ~/.ssh/omb ubuntu@<control-instance-ip-address>
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

There are a number of driver files directly under the `driver-kafka` directory. If you change a driver file you must build OMB again and run Ansible with `--tags "client"` to deploy the client again.

I use workload files in the form of bash scripts which run multi-step benchmarks. You can find examples under `deploy/workloads`. These bash scripts have everything you need to run multiple benchmarks in one go.

I prefer to work on workload files locally and copy them myself. Most of my benchmarking is exploratory and I am constantly tweaking stuff. So will upload my latest workload files to control machine. The IP address of the control instance you will run the benchmarks from is under `[control]` in the `hosts.ini`.

Example copying the large workload scripts:

```bash
scp -i ~/.ssh/omb workloads/large/*.sh ubuntu@<control-instance-ip-address>:/opt/benchmark
```

### Running multiple workloads sequentially

If you want to leave a suite of benchmarks running, copy the `run-many.sh` file to the control instance and simply pass it a list of files to run. It will pause for ten minutes between each.

Examples:

```bash
./run-many.sh workflow-file1.sh workflow-file2.sh workflow-file3.sh  
```

## 2) Monitor progress with Grafana or Prometheus

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

You should now be able to see both client and Kafka server metrics coming through (unless running the clients-only deployment).

## 3) Collect the results

At the end the OMB benchmark program will write summarized results to a json file. If you run multiple step benchmarks, you'll get one json file per step. Copies the json files to your local directory.

1. From another shell, or after exiting the SSH session, scp the files to your machine.

```bash
scp -i ~/.ssh/omb ubuntu@<control-instance-ip-address>:'/opt/benchmark/*.json' .
```

2. Visualize the results
   See the [charts README.md](../charts/README.md) for more details.