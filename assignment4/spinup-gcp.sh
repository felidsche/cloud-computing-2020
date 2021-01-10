#!/bin/bash

# set ssh key
gcloud compute project-info add-metadata --metadata-from-file ssh-keys=/Users/fschnei4/.ssh/gcp.pub

# network
gcloud compute networks create kubernetes-the-kubespray-way --subnet-mode custom

# subnet
gcloud compute networks subnets create kubernetes \
  --network kubernetes-the-kubespray-way \
  --range 10.240.0.0/24 \
  --region europe-west1

# internal firewall
gcloud compute firewall-rules create kubernetes-the-kubespray-way-allow-internal \
  --allow tcp,udp,icmp,ipip \
  --network kubernetes-the-kubespray-way \
  --source-ranges 10.240.0.0/24

# external firewall
gcloud compute firewall-rules create kubernetes-the-kubespray-way-allow-external \
  --allow tcp:80,tcp:6443,tcp:443,tcp:22,icmp \
  --network kubernetes-the-kubespray-way \
  --source-ranges 0.0.0.0/0

# instances
for i in 0 1 2; do
  gcloud compute instances create node-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-standard-2 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-kubespray-way \
    --zone europe-west1-b
done

# test ssh
ssh -i /Users/fschnei4/.ssh/gcp felix@public-ip

# deploy
ansible-playbook -i inventory/mycluster/hosts.yaml -u felix -b -v --private-key=~/.ssh/gcp cluster.yml

# access the cluster

➜ ssh -i /Users/fschnei4/.ssh/gcp felix@public-ip
USERNAME=felix
sudo chown -R $USERNAME:$USERNAME /etc/kubernetes/admin.conf
exit

# copy over the kubeconfig to the local machine
scp -i /Users/fschnei4/.ssh/gcp $USER@$IP_NODE_0:/etc/kubernetes/admin.conf kubespray-do.conf

# load the config for kubectl
export KUBECONFIG=$PWD/kubespray-do.conf

# communicate with the cluster
kubectl get nodes
