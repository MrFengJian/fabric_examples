#!/bin/bash

#0.切换至管理员身份，吊销用户证书，生成CRL文件。
export CORE_PEER_LOCALMSPID=peerOrg2MSP
export CORE_PEER_MSPCONFIGPATH=/data/orgs/peerOrg2/admin/msp
export CORE_PEER_ADDRESS=peer0-peerOrg2:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/data/peerOrg2-ca-chain.pem
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_ADDRESS=peer0-peerOrg2:7051
#只想到管理员的msp目录
export FABRIC_CA_CLIENT_HOME=/data/orgs/peerOrg2/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg2-ca-chain.pem
#吊销用户，生成CRL，会在msp下生成crls/crl*.pem文件
fabric-ca-client revoke -d --revoke.name user-peerOrg2 --gencrl


cd /data
#1.获取channel配置，生成一个protobuff格式的文件
peer channel fetch config mychannel_block.pb -c mychannel -o orderer:7050 --tls --cafile /data/ordererOrg-ca-chain.pem

#2.启动configtxlator，解析pb文件。会产生一个7059的监听服务
configtxlator start &
configtxlator_pid=$!

#3.转换channel配置的protobuff格式为json
curl -X POST --data-binary @mychannel_block.pb http://127.0.0.1:7059/protolator/decode/common.Block > mychannel_block.json

#4.修改配置json，增加吊销证书信息
jq .data.data[0].payload.data.config mychannel_block.json > config.json
crl=$(cat $CORE_PEER_MSPCONFIGPATH/crls/crl*.pem | base64 | tr -d '\n')
cat config.json | jq '.channel_group.groups.Application.groups.peerOrg2.values.MSP.value.config.revocation_list = ["'"${crl}"'"]' > updated_config.json

#5.生成配置块的更新diff protobuff文件
curl -X POST --data-binary @config.json http://127.0.0.1:7059/protolator/encode/common.Config > config.pb
curl -X POST --data-binary @updated_config.json http://127.0.0.1:7059/protolator/encode/common.Config > updated_config.pb
curl -X POST -F original=@config.pb -F updated=@updated_config.pb http://127.0.0.1:7059/configtxlator/compute/update-from-configs -F channel=mychannel > channel_update.pb

#6.转换配置块更新protobuff为json
curl -X POST --data-binary @channel_update.pb http://127.0.0.1:7059/protolator/decode/common.ConfigUpdate >channel_update.json

#7.生成peer channel update命令所需要的envelope protobuff文件
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat channel_update.json)'}}}' > channel_update_envelope.json
curl -X POST --data-binary @channel_update_envelope.json http://127.0.0.1:7059/protolator/encode/common.Envelope > channel_update_envelope.pb

kill -9 $configtxlator_pid

#8.更新channel配置
peer channel update -f channel_update_envelope.pb -c mychannel -o orderer:7050 --tls --cafile /data/ordererOrg-ca-chain.pem

#9.以被吊销用户身份再查询，按预期失败
export CORE_PEER_MSPCONFIGPATH=/data/orgs/peerOrg2/user-peerOrg2/msp
peer chaincode query -C mychannel -n abac -c '{"Args":["query","b"]}'