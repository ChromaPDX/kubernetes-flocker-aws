#!/bin/bash
kube-aws init --cluster-name=REPLACE_ME_WITH_CLUSTERNAME \
--external-dns-name=REPLACE_ME_WITH_ENDPOINT_DNS \
--region=us-east-1 \
--availability-zone=us-east-1c \
--key-name=REPLACE_ME_WITH_EC2_KEYPAIR_NAME \
--kms-key-arn="REPLACE_ME_WITH_ARN"
