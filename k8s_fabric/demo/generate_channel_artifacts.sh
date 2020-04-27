#!/bin/bash

set -e

cd ./artifacts/demo

export PATH=$PATH:/home/fengjj/master/release/1.4.3/bin


echo "========generate channel channel2 tx and its anchor tx files========"
configtxgen --profile channel2Profile -outputCreateChannelTx ./channels/channel2.tx  -channelID channel2
    
#change channel mod policy,add org only signed by orderer msp
bash /home/fengjj/master/scripts/change_policy.sh 1.4.3 ./channels/channel2.tx
    
    
configtxgen -profile channel2Profile -outputAnchorPeersUpdate ./anchors/channel2-org1-anchors.tx -channelID channel2 -asOrg org1
    

cd -