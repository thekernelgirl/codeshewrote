#!/bin/bash

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
    echo "Homebrew is already installed."
fi

# Update Homebrew
brew update

# Install VirtualBox if not installed
if ! command -v VBoxManage &>/dev/null; then
    echo "VirtualBox not found. Installing VirtualBox..."
    brew install --cask virtualbox
else
    echo "VirtualBox is already installed."
fi

# Install Minikube if not installed
if ! command -v minikube &>/dev/null; then
    echo "Minikube not found. Installing Minikube..."
    brew install minikube
else
    echo "Minikube is already installed."
fi

# Start Minikube
echo "Starting Minikube..."
minikube start --vm-driver=virtualbox

echo "Minikube has been successfully started."

