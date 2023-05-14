# Prerequisites

Note these instructions are all based on MacOS.

- Ansible 6 (Note: MUST be 6): `brew install ansible@6`

Unfortunately the Ansible installation is slow and somewhat unreliable, but the usual cause for failure is a Cloud Alchemy role for Prometheus and Grafana, which can be rereun. 


```bash
ansible-galaxy install cloudalchemy.node_exporter
ansible-galaxy install cloudalchemy.prometheus
ansible-galaxy install cloudalchemy.grafana
ansible-galaxy install mrlesmithjr.mdadm
```

- Once Ansible@6 is installed, add `export PATH=“/usr/local/opt/ansible@6/bin:$PATH”` to your ~/.bashrc or ~/.zshrc file. It just makes things easier.
- Install gnu-tar `brew install gnu-tar`
- Terraform `brew install terraform`
- An AWS account

1. Create an SSH key

```bash
ssh-keygen -f ~/.ssh/omb
```
2.  Run this before running Ansible

I have to run the following to stop Python from exiting midway through. This is required on each shell that I run this Ansible script from. I have been too lazy to figure out why.

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

3. Compile from the root directory using:
```
mvn clean install -Dlicense.skip=true
```

