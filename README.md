# AWS CVA6 Setup

## Agree to License

First to use the software one has to agree to the EULA:

https://aws.amazon.com/marketplace/pp/prodview-gimv3gqbpe57k

This will take a few minutes to complete.


## Using this repo

This repository contains a set of Terraform/OpenTofu definitions which make it
simple to deploy an Amazon AWS F1 instance (or other machine type), including
spawning the host as a spot instance.  This results in a system which has a
pricing discount of up to 80%.  The discount comes from the need to explore the
cost of different availability zones (AZs) and manually placing the host in the
AZ.


To begin, common variables are defined in `variables.tf`.  These can then be
populated in a `tfvars` file.  Below is an example of a file I use called
`development.tfvars`:

```
instance_type     = "t3.2xlarge"
# Centos AMI
marketplace_id    = "/aws/service/marketplace/prod-a77hqdkwpdk3o/"
spot_price        = 0.14
use_spot_instance = true
```

Populating this file allows for calling the following command:

    tofu apply -var-file development.tfvars

This will run in an idempotent manner, attempting to reconcile the difference
between the proposed state (as defined in these files) and the running state.

## Identify the correct image

Currently this repo is focused around retreiving the AMI ID using AWS SSM
(formerly "Simple Systems Manager").  This presents the ability to use
marketplace AMI images, like ones with the Nvidia or Xilinx toolsets installed.

Users are encouraged to experiment with other marketplace IDs. As an example,
one can get the AMI IDs for the CentOS 7 with the following command:

    aws ssm get-parameters-by-path --path "/aws/service/marketplace/prod-a77hqdkwpdk3o/"

If you see the correct sets of images (and one ending in `/latest`), use the
path to populate the `marketplace_id` variable.


<!--

vim: ts=2 sw=2 et tw=80 sts
-->
