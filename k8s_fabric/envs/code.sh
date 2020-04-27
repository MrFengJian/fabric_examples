#!/bin/bash

source peer0.env

cd ../artifacts

peer channel create -f channel1.tx -c channel1 -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA

peer channel join -b channel1.block

peer channel update -f channel1-org1-anchors.tx -c channel1 -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA

cd -

export GOPATH=/root/chain_code

peer chaincode install -n map -l golang -p chain_code/go/map_1.0 -v 1.0

peer chaincode instantiate -C channel1 -n map -c '{"Args":["init"]}' -v 1.0 -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA

peer chaincode invoke -C channel1 -n map -c '{"Args":["put","a","bbb"]}'  -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA

peer chaincode query -C channel1 -n map -c '{"Args":["get","a"]}'
