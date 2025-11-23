#!/bin/bash

set -e

# =========================================
# Stable Terraform Version for AWS Ubuntu
# =========================================
TF_VERSION="1.6.6"
OS="linux"

# Detect architecture (AWS EC2 Intel/AMD → amd64, Graviton → arm64)
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Detected architecture: $ARCH"
echo "Installing Terraform version $TF_VERSION ..."

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y wget unzip

# Download Terraform binary
wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_${OS}_${ARCH}.zip

# Unzip & install
unzip terraform_${TF_VERSION}_${OS}_${ARCH}.zip
sudo mv terraform /usr/local/bin/

# Clean up
rm terraform_${TF_VERSION}_${OS}_${ARCH}.zip

# Verify installation
echo "Terraform installed successfully!"
terraform -version
