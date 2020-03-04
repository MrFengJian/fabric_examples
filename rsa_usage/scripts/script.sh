#!/bin/bash

set -e

SDIR="$(dirname ${BASH_SOURCE[0]})"

. ${SDIR}/utils.sh

prepareChannels(){

    switchToPeer 0 1

	echo
	echo "##########################################################"
	echo "#########  Create Channel ##############"
	echo "##########################################################"    

    peer channel create -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/mychannel.tx --tls true --cafile $ORDERER_CA

	echo
	echo "##########################################################"
	echo "#########  peer0.org1.example.com join channel############"
	echo "##########################################################"

    peer channel join -b mychannel.block

	echo
	echo "##########################################################"
	echo "#########  update anchors in org2             ############"
	echo "##########################################################"    

    peer channel update -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/Org1MSPanchors.tx --tls true --cafile $ORDERER_CA

    switchToPeer 1 1

	echo
	echo "##########################################################"
	echo "#########  peer1.org1.example.com join channel############"
	echo "##########################################################"

    peer channel join -b mychannel.block

    switchToPeer 0 2

	echo
	echo "##########################################################"
	echo "#########  peer0.org2.example.com join channel############"
	echo "##########################################################"

    peer channel join -b mychannel.block

	echo
	echo "##########################################################"
	echo "#########  update anchors in org2             ############"
	echo "##########################################################"    

    peer channel update -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/Org2MSPanchors.tx --tls true --cafile $ORDERER_CA

    switchToPeer 1 2

	echo
	echo "##########################################################"
	echo "#########  peer1.org2.example.com join channel############"
	echo "##########################################################"    

    peer channel join -b mychannel.block
}

e2eTest(){
    switchToPeer 0 1
	echo
	echo "##########################################################"
	echo "#########  install codes on all nodes         ############"
	echo "##########################################################"    
    switchToPeer 0 1
    peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/chaincode_example02/go/
    switchToPeer 1 1
    peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/chaincode_example02/go/
    switchToPeer 0 2
    peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/chaincode_example02/go/
    switchToPeer 1 2
    peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/chaincode_example02/go/

	echo
	echo "##########################################################"
	echo "#########          instantiate codes          ############"
	echo "##########################################################"
	switchToPeer 0 1   
    peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $ORDERER_CA -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}'

	echo
	echo "##########################################################"
	echo "#########   test chain code invoke&query      ############"
	echo "##########################################################"       

	sleep 10 
	
	switchToPeer 0 1
    peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'

    peer chaincode query -C mychannel -n mycc -c '{"Args":["query","b"]}'

    peer chaincode invoke -o orderer.example.com:7050  --tls true --cafile $ORDERER_CA -C mychannel -n mycc -c '{"Args":["invoke","b","a","10"]}'
    
	sleep 10

    peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'

    peer chaincode query -C mychannel -n mycc -c '{"Args":["query","b"]}'

}

# wait for etcdraft start
sleep 15

prepareChannels

e2eTest

echo
echo "===================== All GOOD, End-2-End execution completed ===================== "
echo

echo
echo " _____   _   _   ____            _____   ____    _____ "
echo "| ____| | \ | | |  _ \          | ____| |___ \  | ____|"
echo "|  _|   |  \| | | | | |  _____  |  _|     __) | |  _|  "
echo "| |___  | |\  | | |_| | |_____| | |___   / __/  | |___ "
echo "|_____| |_| \_| |____/          |_____| |_____| |_____|"
echo

exit 0
