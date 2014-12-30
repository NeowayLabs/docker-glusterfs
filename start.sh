#!/bin/bash

[[ $DEBUG ]] && set -x

echo "Running glusterd..."
glusterd

echo "GLUSTERFS_TYPE=$GLUSTERFS_TYPE"

echo "GLUSTERFS_NODE01=$GLUSTERFS_NODE01"
echo "GLUSTERFS_NODE02=$GLUSTERFS_NODE02"

if [[ "x$GLUSTERFS_TYPE" == "xmaster" ]];
then
    gluster peer probe $GLUSTERFS_NODE01
    gluster peer probe $GLUSTERFS_NODE02

    echo "==> Sleep 30 seconds for peer to settle down"
    sleep 30

    gluster volume create data rep 2 transport tcp $GLUSTERFS_NODE01:/data/brick $GLUSTERFS_NODE02:/data/brick
    gluster volume start data
    gluster volume info
fi

while [[ true ]]; do sleep 2; done
