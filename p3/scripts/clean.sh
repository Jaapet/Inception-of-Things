#!/bin/bash

# Clean cluster
sudo bash ./scripts/clean_cluster.sh

echo "----- Cluster cleaned -----"

# Clean tools
sudo bash ./scripts/clean_tools.sh

echo "----- Tools cleaned -----"
