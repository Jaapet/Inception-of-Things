#!/bin/bash

# Install tools
echo "----- Installing tools -----"
sudo bash ./scripts/install_tools.sh
echo "----- Tools installed -----"

# Launch cluster (includes GitLab and Argo CD setup)
sudo bash ./scripts/launch_cluster.sh
