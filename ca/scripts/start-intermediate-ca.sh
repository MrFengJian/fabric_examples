#!/bin/bash

set -e

# 初始化中间ca
fabric-ca-server init -b admin:adminpw -u $PARENT_URL

# 将中间ca的证书链复制到/data，供其他容器使用
cp $FABRIC_CA_SERVER_HOME/ca-chain.pem $TARGET_CHAINFILE

# 增加peerOrg1,peerOrg2配置
aff="\n   peerOrg1:\n      - dev\n      - test\n   peerOrg2:\n      - ops\n      - market"

aff="${aff#\\n   }"

sed -i "/affiliations:/a \\   $aff" \
   $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml

# Start the intermediate CA
fabric-ca-server start
