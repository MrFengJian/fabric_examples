#!/bin/bash

set -e

cd ./artifacts/demo

export PATH=$PATH:/home/fengjj/master/release/1.4.3/bin


echo "========generate all channels' tx files and anchor tx files========"
configtxgen --profile genesisProfile -outputBlock genesis.block  -channelID systemchain
if [ $? -ne 0 ];then
    echo "====failed to generate genesisblock==="
    exit 98
fi
    
# generate channel tx and anchor tx for SampleConsortium
        
configtxgen --profile channel1Profile -outputCreateChannelTx ./channels/channel1.tx -channelID channel1
if [ $? -ne 0 ];then
    echo "====failed to generate <models.Channel Value>.tx file==="
    exit 97
fi
            
#change channel mod policy,add org only signed by orderer msp
bash /home/fengjj/master/scripts/change_policy.sh 1.4.3 ./channels/channel1.tx
            
            
configtxgen -profile channel1Profile -outputAnchorPeersUpdate ./anchors/channel1-org1-anchors.tx -channelID channel1 -asOrg org1
if [ $? -ne 0 ];then
    echo "====failed to generate org1-anchors.tx file==="
    exit 96
fi
            
        
    

cd -