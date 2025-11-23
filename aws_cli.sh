#!/bin/bash

set -e

echo "Updating package index..."
sudo apt update -y

echo "Installing unzip..."
sudo apt install unzip -y

# Detect architecture (x86_64 for Intel/AMD, aarch64 for ARM/Graviton)
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    AWSCLI_ZIP="awscli-exe-linux-x86_64.zip"
elif [ "$ARCH" = "aarch64" ]; then
    AWSCLI_ZIP="awscli-exe-linux-aarch64.zip"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Detected architecture: $ARCH"
echo "Downloading AWS CLI v2 for $ARCH ..."

curl "https://awscli.amazonaws.com/${AWSCLI_ZIP}" -o "awscliv2.zip"

echo "Unzipping the installer..."
unzip -o awscliv2.zip

echo "Installing AWS CLI..."
sudo ./aws/install

echo "Cleaning up..."
rm -rf awscliv2.zip aws/

echo "Installation complete!"
aws --version
