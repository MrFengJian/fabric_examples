#!/usr/bin/env bash

export ARTIFACTS_PATH=/home/fengjj/master/artifacts/demo
export FABRIC_CFG_PATH=/home/fengjj/master/artifacts/demo
export PATH=$PATH:/home/fengjj/master/release/1.4.3/bin
ORDERER_CA=/home/fengjj/master/artifacts/demo/crypto-config/ordererOrganizations/demo.com/orderers/orderer0.demo.com/tls/ca.crt
ORDERER_ADDRESS=orderer0.demo.com:7050

switchToOrdererAdmin () {
    export CORE_PEER_LOCALMSPID=OrdererOrg
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_MSPCONFIGPATH=/home/fengjj/master/artifacts/demo/crypto-config/ordererOrganizations/demo.com/users/Admin@demo.com/msp
    export CORE_PEER_ID=cli
    export CORE_LOGGING_LEVEL=DEBUG
}

    
switchTopeer0.org1.demo.com () {
    export CORE_PEER_LOCALMSPID=org1
    export CORE_PEER_MSPCONFIGPATH=/home/fengjj/master/artifacts/demo/crypto-config/peerOrganizations/org1.demo.com/users/Admin@org1.demo.com/msp
    
    export CORE_PEER_ADDRESS=peer0.org1.demo.com:7051
    
    export CORE_PEER_TLS_ROOTCERT_FILE=/home/fengjj/master/artifacts/demo/crypto-config/peerOrganizations/org1.demo.com/peers/peer0.org1.demo.com/tls/ca.crt
    export CORE_PEER_TLS_ENABLED=true
    export CORE_LOGGING_LEVEL=INFO
    export FABRIC_LOGGING_SPEC=INFO
    export CORE_PEER_LOCALMSPTYPE=bccsp
}
    


