#!/bin/bash

switchToPeer(){
    peerIndex=$1
    orgIndex=$2
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org${orgIndex}.example.com/peers/peer${peerIndex}.org${orgIndex}.example.com/tls/ca.crt
    CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org${orgIndex}.example.com/peers/peer${peerIndex}.org${orgIndex}.example.com/tls/server.key
    CORE_PEER_LOCALMSPID=Org${orgIndex}MSP
    CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org${orgIndex}.example.com/peers/peer${peerIndex}.org${orgIndex}.example.com/tls/server.crt
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org${orgIndex}.example.com/users/Admin@org${orgIndex}.example.com/msp
    CORE_PEER_ID=peer${peerIndex}.org${orgIndex}.example.com
    CORE_LOGGING_LEVEL=INFO
    CORE_PEER_ADDRESS=peer${peerIndex}.org${orgIndex}.example.com:7051
}