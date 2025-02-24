#!/bin/sh

set -e

if [ -n "$DOCKER_DEBUG" ]; then
   set -x
fi

ipfs-cluster-service --version

if [ -e "${IPFS_CLUSTER_PATH}/service.json" ]; then
    echo "Found IPFS cluster configuration at ${IPFS_CLUSTER_PATH}"
else
    echo "This container only runs ipfs-cluster-service. ipfs needs to be run separately!"
    echo "Initializing default configuration..."
    ipfs-cluster-service init --consensus "${IPFS_CLUSTER_CONSENSUS}" --datastore "${IPFS_CLUSTER_DATASTORE}"
fi

exec ipfs-cluster-service daemon
