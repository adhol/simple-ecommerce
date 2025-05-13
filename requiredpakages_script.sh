#!/usr/bin/env bash

# This script installs required tools and configures the system for Kubernetes experiments.
# Supports Debian/Ubuntu and CentOS/RHEL-based distributions.

set -e

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "Disabling swap..."
swapoff -a
# Comment out swap entry in /etc/fstab
if grep -q "\s/swap\s" /etc/fstab; then
  sed -i.bak '/\s\/swap\s/ s/^/#/' /etc/fstab
fi

echo "Enabling IP forwarding..."
sysctl net.ipv4.ip_forward=1
# Persist the setting
if ! grep -q '^net.ipv4.ip_forward' /etc/sysctl.conf; then
  echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
fi

# Install prerequisites based on package manager
if command -v apt-get &>/dev/null; then
  echo "Detected apt-get. Installing dependencies via apt-get..."
  apt-get update
  apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release software-properties-common

  echo "Installing Docker..."
  curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
    $(lsb_release -cs) stable"
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
  systemctl enable docker
  systemctl start docker

elif command -v yum &>/dev/null; then
  echo "Detected yum. Installing dependencies via yum..."
  yum install -y yum-utils device-mapper-persistent-data lvm2 curl

  echo "Installing Docker..."
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum install -y docker-ce docker-ce-cli containerd.io
  systemctl enable docker
  systemctl start docker

else
  echo "Unsupported package manager. Please install Docker manually."
  exit 1
fi

# Install kubectl
echo "Installing kubectl..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Minikube
echo "Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
mv minikube-linux-amd64 /usr/local/bin/minikube

# Install kind
echo "Installing kind..."
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x kind
mv kind /usr/local/bin/kind

# Install Helm
echo "Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Prepare hostPath directory for experiments
echo "Creating hostPath directory /mnt/data..."
mkdir -p /mnt/data
chmod 755 /mnt/data

echo "All prerequisites installed successfully!"

