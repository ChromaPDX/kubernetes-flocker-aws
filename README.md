# kubernetes-flocker-aws

kubernetes + flocker on AWS notes

## 1 CLONE

### 1.1

```
https://github.com/ChromaPDX/kubernetes-flocker-aws.git
cd kubernetes-flocker-aws
```

### 1.2 GET COMMAND LINE TOOLS

requirement homebrew

```
brew install wget gpg2 kubectl awscli
```

### 1.3 GET + VERIFY KUBE-AWS

```
export PLATFORM=darwin-amd64
wget https://github.com/coreos/coreos-kubernetes/releases/download/v0.7.1/kube-aws-darwin-amd64.tar.gz
wget https://github.com/coreos/coreos-kubernetes/releases/download/v0.7.1/kube-aws-darwin-amd64.tar.gz.sig
tar zxvf kube-aws-${PLATFORM}.tar.gz
gpg2 --keyserver pgp.mit.edu --recv-key FC8A365E
gpg2 --fingerprint FC8A365E
gpg2 --verify kube-aws-${PLATFORM}.tar.gz.sig kube-aws-${PLATFORM}.tar.gz
```

should equal 18AD 5014 C99E F7E3 BA5F 6CE9 50BD D3E0 FC8A 365E

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

```
kube-aws init --cluster-name=CLUSTERNAME \
--external-dns-name=ENDPOINT_DNS \
--region=us-east-1 \
--availability-zone=us-east-1c \
--key-name=EC2_KEYPAIR_NAME \
--kms-key-arn="ARN"
```

### 3.1 CREATE STACK TEMPLATE

kube-aws render
kube-aws validate

### 3.2 DEPLOY STACK

kube-aws up

### 3.3 VERIFY LEAD NODE CAN SEE CORE OS BOX

kubectl --kubeconfig=kubeconfig get nodes
ssh -i ~/aws-keypair-key.pem core@kube.chroma.fund

### 3.4 INSTALL DASHBOARD

```sh
kubectl --kubeconfig=kubeconfig create -f https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml
```

### 3.5 LOGIN TO DASHBOARD

this did not create a
```sh
kubectl proxy
Starting to serve on 127.0.0.1:8001
```

https://localhost:8001/ui

## 4 PERSISTENT data

### 4.1 CREATE EBS VOLUMES

```sh
aws configure
aws ec2 create-volume --availability-zone eu-west-1a --size 10 --volume-type gp2
```

### 4.2 GET FLOCKER TOOLS FLOCKER

```sh
curl -sSL https://raw.githubusercontent.com/ClusterHQ/unofficial-flocker-tools/master/go.sh | sh
uft-flocker-ca --version
```

## GET IPS FROM AWS

```sh
aws ec2 describe-instances | grep -A1 "PublicIpAddress"
```

## SETUP CLUSTER.YML (not cluster.YAML, that file is for kube-aws -- confusing but flocker wants cluster.yml)

edit cluster.yml with IP addresses and keys (maybe copy the downloaded .pem from Amazon)
vim / atom etc. cluster.yml

## INSTALL FLOCKER

uft-flocker-install cluster.yml
uft-flocker-config cluster.yml
uft-flocker-plugin-install cluster.yml

## TEST FLOCKER

uft-flocker-volumes list-nodes

## DESTROY

kube-aws destroy
