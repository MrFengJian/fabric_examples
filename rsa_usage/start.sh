#!/bin/bash
set -e
BIN_PATH="$GOPATH/src/github.com/hyperledger/fabric/release/linux-amd64/bin"
export PATH=$PATH:$BIN_PATH

CHANNEL_NAME="mychannel"

generateArtifacts(){
    mkdir -p channel-artifacts
    echo
    echo "##########################################################"
    echo "##### Generate certificates using cryptogen tool #########"
    echo "##########################################################"
    #using sm cryptogen or not
    cryptogen generate --config=./crypto-config.yaml
    #cryptogen generate --config=./crypto-config.yaml

    echo "##########################################################"
    echo "#########  Generating Orderer Genesis block ##############"
    echo "##########################################################"
    # Note: For some unknown reason (at least for now) the block file can't be
    # named orderer.genesis.block or the orderer will fail to launch!
    configtxgen -profile SampleMultiNodeEtcdRaft -outputBlock ./channel-artifacts/genesis.block

    echo
    echo "#################################################################"
    echo "### Generating channel configuration  'mychannel.tx'          ###"
    echo "#################################################################"
    configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/mychannel.tx -channelID $CHANNEL_NAME

    echo
    echo "#################################################################"
    echo "#######    Generating anchor peer update for Org1MSP   ##########"
    echo "#################################################################"
    configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

    echo
    echo "#################################################################"
    echo "#######    Generating anchor peer update for Org2MSP   ##########"
    echo "#################################################################"
    configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
    echo
}

generateArtifacts

docker-compose -f docker-compose-cli.yaml up -d 

docker logs -f cli 
