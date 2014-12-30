#!/bin/bash

echo "Cleaning up..."

CPATH=`pwd`
EXPORT_PORTS="-p 111:111 -p 24007:24007 -p 2049:2049 -p 38465:38465 -p 38466:38466 -p 38467:38467 -p 1110:1110 -p 4045:4045"

docker rm -vf glusterfs-node01 glusterfs-node02 glusterfs-master 2>/dev/null

sudo umount "$PWD/mnt/data01"
sudo umount "$PWD/mnt/data02"
sudo umount "$PWD/mnt/master"

rm -f ./node01.btrfs ./node02.btrfs ./master.btrfs 2>/dev/null
rm -rf ./mnt 2>/dev/null

mkdir -p ./mnt/data01 ./mnt/data02 ./mnt/master

echo "Creating fake storages..."
dd if=/dev/zero of=./node01.btrfs bs=1M count=2048
dd if=/dev/zero of=./node02.btrfs bs=1M count=2048
dd if=/dev/zero of=./master.btrfs bs=1M count=2048

echo "Formatting storages to BTRFS..."
mkfs.btrfs -f ./node01.btrfs 2>/dev/null
mkfs.btrfs -f ./node02.btrfs 2>/dev/null
mkfs.btrfs -f ./master.btrfs 2>/dev/null

echo "Mounting..."
sudo mount -oloop,noatime ./node01.btrfs ./mnt/data01
sudo mount -oloop,noatime ./node02.btrfs ./mnt/data02
sudo mount -oloop,noatime ./master.btrfs ./mnt/master

NODE01_CONTAINER_ID=`docker run -d --name glusterfs-node01 --privileged -v $CPATH/mnt/data01:/data -e GLUSTERFS_TYPE=node -e GLUSTERFS_NODE01=glusterfs-node01.pods.neoway.com.br -e GLUSTERFS_NODE02=glusterfs-node02.pods.neoway.com.br neowaylabs/glusterfs`

NODE01_IPADDRESS=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $NODE01_CONTAINER_ID`

curl -XPUT http://127.0.0.1:4001/v2/keys/skydns/br/com/neoway/pods/glusterfs-node01 \
    -d value="{\"host\":\"$NODE01_IPADDRESS\",\"priority\":20}" 1>/dev/null


NODE02_CONTAINER_ID=`docker run -d --name glusterfs-node02 --privileged -v $CPATH/mnt/data02:/data -e GLUSTERFS_TYPE=node -e GLUSTERFS_NODE01=glusterfs-node01.pods.neoway.com.br -e GLUSTERFS_NODE02=glusterfs-node02.pods.neoway.com.br neowaylabs/glusterfs`

NODE02_IPADDRESS=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $NODE02_CONTAINER_ID`
curl -XPUT http://127.0.0.1:4001/v2/keys/skydns/br/com/neoway/pods/glusterfs-node02 \
     -d value="{\"host\":\"$NODE02_IPADDRESS\",\"priority\":20}" 1>/dev/null

docker run --rm -it $EXPORT_PORTS --privileged -v $CPATH/mnt/master:/data -e GLUSTERFS_TYPE=master -e GLUSTERFS_NODE01=glusterfs-node01.pods.neoway.com.br -e GLUSTERFS_NODE02=glusterfs-node02.pods.neoway.com.br neowaylabs/glusterfs
