#!/bin/bash

set -e

#根据configtx.yaml定义，channel对应组织可进行创建操作
#使用peerOrg1或者peerOrg2任意两个组织的管理员身份操作
export CORE_PEER_LOCALMSPID=peerOrg1MSP
export CORE_PEER_MSPCONFIGPATH=/data/orgs/peerOrg1/admin/msp
peer channel create --logging-level=DEBUG -c mychannel -f /data/channel.tx -o orderer:7050 --cafile /data/ordererOrg-ca-chain.pem --tls 

#设置tls通信根证书和要操作的peer节点
export CORE_PEER_ADDRESS=peer0-peerOrg1:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/data/peerOrg1-ca-chain.pem
export CORE_PEER_TLS_ENABLED=true
peer channel join -b mychannel.block

#设置节点
export CORE_PEER_ADDRESS=peer1-peerOrg1:7051
peer channel join -b mychannel.block

#更新组织锚节点
peer channel update -c mychannel -f /data/peerOrg1Anchor.tx -o orderer:7050 --tls --cafile /data/ordererOrg-ca-chain.pem

#切换到peerOrg2管理员来操作
export CORE_PEER_LOCALMSPID=peerOrg2MSP
export CORE_PEER_MSPCONFIGPATH=/data/orgs/peerOrg2/admin/msp
export CORE_PEER_ADDRESS=peer0-peerOrg2:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/data/peerOrg2-ca-chain.pem
export CORE_PEER_TLS_ENABLED=true
peer channel join -b mychannel.block

#设置节点
export CORE_PEER_ADDRESS=peer1-peerOrg2:7051
peer channel join -b mychannel.block

#更新组织锚节点
peer channel update -c mychannel -f /data/peerOrg2Anchor.tx -o orderer:7050 --tls --cafile /data/ordererOrg-ca-chain.pem

echo "============================================"
echo "============================================"
echo "PREPARE SUCCCESS!!!"
echo "============================================"
echo "============================================"