#!/bin/bash

set -e

#在peer0-peerOrg1上安装和实例化chaincode
export CORE_PEER_LOCALMSPID=peerOrg1MSP
export CORE_PEER_MSPCONFIGPATH=/data/orgs/peerOrg1/admin/msp
export CORE_PEER_ADDRESS=peer0-peerOrg1:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/data/peerOrg1-ca-chain.pem
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_ADDRESS=peer0-peerOrg1:7051
#安装chaincode，无须设置，系统限制只能管理员来安装chaincode
peer chaincode install -n abac -v 1.0 -p github.com/chaincode/abac/go/

#实例化，增加背书策略
peer chaincode instantiate -o orderer:7050 --tls true --cafile /data/ordererOrg-ca-chain.pem -C mychannel -n abac -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P 'OR('\''peerOrg1MSP.member'\'','\''peerOrg2MSP.member'\'')' 

#转账
peer chaincode invoke -o orderer:7050 --tls true --cafile /data/ordererOrg-ca-chain.pem -C mychannel -n abac -c '{"Args":["invoke","b","a","100"]}'

#分别再查询
peer chaincode query -C mychannel -n abac -c '{"Args":["query","a"]}'
#切换至用户身份，再转账
export CORE_PEER_MSPCONFIGPATH=/data/orgs/peerOrg1/user-peerOrg1/msp
#会因为用户证书不存在属性而失败Attribute 'abac.init' was not found
peer chaincode invoke -o orderer:7050 --tls true --cafile /data/ordererOrg-ca-chain.pem -C mychannel -n abac -c '{"Args":["invoke","b","a","1"]}'
#用户可以正常查询信息
peer chaincode query -C mychannel -n abac -c '{"Args":["query","b"]}'

#在peer0-peerOrg2上安装
export CORE_PEER_LOCALMSPID=peerOrg2MSP
export CORE_PEER_MSPCONFIGPATH=/data/orgs/peerOrg2/admin/msp
export CORE_PEER_ADDRESS=peer0-peerOrg2:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/data/peerOrg2-ca-chain.pem
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_ADDRESS=peer0-peerOrg2:7051
#安装chaincode
peer chaincode install -n abac -v 1.0 -p github.com/chaincode/abac/go/
#每个channel中，同名chaincode只能实例化一次，无须再执行
#通过peer0-peerOrg2执行chaincode
peer chaincode invoke -o orderer:7050 --tls true --cafile /data/ordererOrg-ca-chain.pem -C mychannel -n abac -c '{"Args":["invoke","b","a","10"]}'
#分别再查询
peer chaincode query -C mychannel -n abac -c '{"Args":["query","a"]}'
#切换至用户身份再查询
export CORE_PEER_MSPCONFIGPATH=/data/orgs/peerOrg2/user-peerOrg2/msp
peer chaincode query -C mychannel -n abac -c '{"Args":["query","b"]}'