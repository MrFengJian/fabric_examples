#!/bin/bash

rm -rf ./artifacts/*

export PATH=$PATH:./bin

cryptogen generate --config crypto-config.yaml

configtxgen --profile genesisProfile -outputBlock genesis.block  -channelID systemchain

configtxgen --profile channel1Profile -outputCreateChannelTx channel1.tx -channelID channel1

configtxgen -profile channel1Profile -outputAnchorPeersUpdate channel1-org1-anchors.tx -channelID channel1 -asOrg org1

mv *.block *.tx crypto-config ./artifacts

cp ./artifacts/genesis.block /home/fengjj/fabric/artifacts/crypto-config/ordererOrganizations/org0/orderers/orderer0.org0/

kubectl create -f yamls/
