#!/bin/bash

set -e

TF_VERSION="1.6.6"
OS="linux"

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Detected architecture: $ARCH"
echo "Installing Terraform version $TF_VERSION ..."

sudo apt-get update -y
sudo apt-get install -y wget unzip

wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_${OS}_${ARCH}.zip

unzip terraform_${TF_VERSION}_${OS}_${ARCH}.zip
sudo mv terraform /usr/local/bin/

rm terraform_${TF_VERSION}_${OS}_${ARCH}.zip

echo "Terraform installed successfully!"
terraform -version
