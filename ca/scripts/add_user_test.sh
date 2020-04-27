#/bin/bash

#注册新用户
export FABRIC_CA_CLIENT_HOME=$HOME/cas/ica-peerOrg1
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg1-ca-chain.pem
fabric-ca-client enroll -d -u https://admin:adminpw@ica-peerOrg1:7054
fabric-ca-client register -d --id.name user2-peerOrg1 --id.secret password

#生成新用户msp目录
rm -rf /tmp/user2
export FABRIC_CA_CLIENT_HOME=/tmp/user2
fabric-ca-client enroll -d -u https://user2-peerOrg1:password@ica-peerOrg1:7054
cp -r /tmp/user2/msp/cacerts /tmp/user2/msp/cacerts 
cp -r /tmp/user2/msp/cacerts/ /tmp/user2/msp/tlscacerts
cp -r /tmp/user2/msp/intermediatecerts /tmp/user2/msp/tlsintermediatecerts
cp -r /tmp/user2/msp/signcerts /tmp/user2/msp/admincerts

#切换至新用户身份，调用chaincode
export CORE_PEER_LOCALMSPID=peerOrg1MSP
export CORE_PEER_MSPCONFIGPATH=/tmp/user2/msp
export CORE_PEER_ADDRESS=peer0-peerOrg1:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/data/peerOrg1-ca-chain.pem
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_ADDRESS=peer0-peerOrg1:7051

#转账
peer chaincode invoke -o orderer:7050 --tls true --cafile /data/ordererOrg-ca-chain.pem -C mychannel -n mycc -c '{"Args":["invoke","b","a","10"]}'

#分别再查询
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","b"]}'