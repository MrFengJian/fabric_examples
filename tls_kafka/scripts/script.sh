#!/bin/bash

SDIR="$(dirname ${BASH_SOURCE[0]})"

. ${SDIR}/utils.sh

verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
                echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
		echo
   		exit 1
	fi
}

checkOSNAvailability() {
	#Use orderer's MSP for fetching system channel config block
	CORE_PEER_LOCALMSPID="OrdererMSP"
	CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp

	local rc=1
	local starttime=$(date +%s)

	# continue to poll
	# we either get a successful response, or reach TIMEOUT
	while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
	do
		sleep 3
		echo "Attempting to fetch system channel 'testchainid' ...$(($(date +%s)-starttime)) secs"
	    peer channel fetch 0 0_block.pb -o orderer.example.com:7050 -c "testchainid" --tls --cafile $ORDERER_CA >&log.txt
		test $? -eq 0 && VALUE=$(cat log.txt | awk '/Received block/ {print $NF}')
		test "$VALUE" = "0" && let rc=0
	done
	cat log.txt
	verifyResult $rc "Ordering Service is not available, Please try again ..."
	echo "===================== Ordering Service is up and running ===================== "
	echo
}


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
	echo "#########  update anchors in org1             ############"
	echo "##########################################################"    

    peer channel update -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/Org1MSPanchors.tx --tls true --cafile $ORDERER_CA

}

e2eTest(){
	echo
	echo "##########################################################"
	echo "#########  install codes on all nodes         ############"
	echo "##########################################################"    
    switchToPeer 0 1
    peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/chaincode_example02/go/

	echo
	echo "##########################################################"
	echo "#########          instantiate codes          ############"
	echo "##########################################################"
    peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $ORDERER_CA -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}'

	echo
	echo "##########################################################"
	echo "#########   test chain code invoke&query      ############"
	echo "##########################################################"       

	sleep 10 
	
    peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'

    peer chaincode query -C mychannel -n mycc -c '{"Args":["query","b"]}'

    peer chaincode invoke -o orderer.example.com:7050  --tls true --cafile $ORDERER_CA -C mychannel -n mycc -c '{"Args":["invoke","b","a","10"]}'
    
	sleep 10

    peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'

    peer chaincode query -C mychannel -n mycc -c '{"Args":["query","b"]}'

}

if [ ! -f .success ];then
	prepareChannels
	touch .succcess
fi

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
