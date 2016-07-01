# kubernetes-flocker-aws

kubernetes + flocker on AWS notes

## 1 CLONE

### 1.1

```
https://github.com/ChromaPDX/kubernetes-flocker-aws.git
cd kubernetes-flocker-aws
```

### 1.2 GET COMMAND LINE TOOLS

recommend homebrew to install some things like awscli + kubectl however it's not strictly necessary

if you don't have it then:
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

some other things

```
brew install wget gpg2 kubectl awscli
```

### 1.3 GET + VERIFY KUBE-AWS

```
export PLATFORM=darwin-amd64
wget https://github.com/coreos/coreos-kubernetes/releases/download/v0.7.1/kube-aws-darwin-amd64.tar.gz
tar zxvf kube-aws-${PLATFORM}.tar.gz
```

OPTIONAL: GPG verify

```
wget https://github.com/coreos/coreos-kubernetes/releases/download/v0.7.1/kube-aws-darwin-amd64.tar.gz.sig
gpg2 --keyserver pgp.mit.edu --recv-key FC8A365E
gpg2 --fingerprint FC8A365E
gpg2 --verify kube-aws-${PLATFORM}.tar.gz.sig kube-aws-${PLATFORM}.tar.gz
```

Primary key fingerprint: 18AD 5014 C99E F7E3 BA5F  6CE9 50BD D3E0 FC8A 365E
     Subkey fingerprint: 55DB DA91 BBE1 849E A27F  E733 A6F7 1EE5 BEDD BA18

### 1.4 INSTALL AWS_KUBE + CLEAN UP

```
mv ${PLATFORM}/kube-aws /usr/local/bin
sudo rm -R ${PLATFORM}
rm kube-aws-${PLATFORM}.tar.gz
rm kube-aws-${PLATFORM}.tar.gz.sig
```

## 2 SETUP AWS CREDENTIALS

### SETUP CRED AND ENV

mkdir ~/.aws
touch ~/.aws/credentials

```
[default]
aws_access_key_id = AKIA
aws_secret_access_key = sOK0
```

### 2.1 CREATE EC KEYS

http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html

### 2.2 CREATE KMS

```
aws kms --region=us-east-1 create-key --description="kube-aws assets" > kms.json
```

### 3 USE KUBE-AWS to create CLUSTER DEFINITION

edit aws_init.sh replace fields, and set region

replace EC2_KEYPAIR_NAME with name from 2.1
replace ARN with field from 2.2
replace CLUSTERNAME
replace ENDPOINT_DNS with route53 or . . .

### 3.1 CREATE STACK TEMPLATE

```
./aws_init.sh
```

edit cluster.yaml

```yml
# Version of hyperkube image to use. This is the tag for the hyperkube image repository.
kubernetesVersion: v1.2.4_coreos.cni.1
# Hyperkube image repository to use.
hyperkubeImageRepo: quay.io/coreos/hyperkube
# Use Calico for network policy. When set to "true" the kubernetesVersion (above)
# must also be updated to include a version tagged with CNI e.g. v1.2.4_coreos.cni.1
useCalico: true
```

```
kube-aws render
kube-aws validate
```
UserData is valid.

### 3.2 DEPLOY STACK

```
kube-aws up
```

Creating AWS resources. This should take around 5 minutes.

### 3.3 VERIFY SSH + KUBECTL

Success! Your AWS resources have been created:
Cluster Name: cluster_name
Controller IP:	CLUSTER_IP

you can verify that by ssh, the following snippet needs CLUSTER_DNS and aws-keypair-key.pem replaced
```sh
echo "CLUSTER_IP CLUSTER_DNS" | sudo tee -a /etc/hosts
```

OR just edit your hosts file with vim or . . . then

```sh
kubectl --kubeconfig=kubeconfig get nodes
```

if you get The connection to the server kube.chroma.fund was refused - did you specify the right host or port?

wait a few minutes

optionally can ssh in to see coreos box

```
ssh -i ~/your-aws-ec2-key.pem core@CLUSTER_DNS
```

### 3.4 SETUP kubectl and INSTALL DASHBOARD

```sh
kubectl --kubeconfig=kubeconfig create -f https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml
```

can confirm dashboard pos if u want

```
kubectl --kubeconfig=kubeconfig get pods --all-namespaces
```

### 3.5 LOGIN TO DASHBOARD

it did not create a user, so one has to proxy locally using kubectl

if your hosts or remote DNS is working then
```sh
kubectl --kubeconfig=kubeconfig proxy
```

Starting to serve on 127.0.0.1:8001
navigate to http://localhost:8001/ui

localhost doesn't serve https

## 4 PERSISTENT data

### 4.1 CREATE EBS VOLUMES

```sh
aws configure
aws ec2 create-volume --availability-zone eu-east-1c --size 80 --volume-type gp2
```

### 4.2 GET FLOCKER TOOLS FLOCKER

```sh
curl -sSL https://raw.githubusercontent.com/ClusterHQ/unofficial-flocker-tools/master/go.sh | sh
uft-flocker-ca --version
```

### GET IPS FROM AWS

```sh
aws ec2 describe-instances | grep -A1 "PublicIpAddress"
aws ec2 describe-instances | grep -A1 "PublicDnsName"
```

### SETUP CLUSTER.YML (not cluster.YAML, that file is for kube-aws -- confusing but flocker wants cluster.yml)

edit cluster.yml with IP addresses and keys (maybe copy the downloaded .pem from Amazon)
vim / atom etc. cluster.yml

### Authorize Flocker ports using ec2

```
aws ec2 describe-security-groups | grep GroupName
aws ec2 describe-security-groups | grep GroupId
```
Open up flocker ports, and app ports for each group ID
```
aws ec2 authorize-security-group-ingress --group-id GROUP_ID --protocol tcp --port 4523-4524 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id GROUP_ID --protocol tcp --port 4523-4524 --cidr 0.0.0.0/0
```

### INSTALL FLOCKER

```
uft-flocker-install cluster.yml
uft-flocker-config cluster.yml
uft-flocker-plugin-install cluster.yml
```

### TEST FLOCKER

uft-flocker-volumes list-nodes

## DESTROY

kube-aws destroy
