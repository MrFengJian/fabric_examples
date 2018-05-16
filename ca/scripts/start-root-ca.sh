#!/bin/bash

set -e

# 初始化root ca
fabric-ca-server init -b admin:adminpw

# 复制生成根证书到/data，供其他容器使用
cp $FABRIC_CA_SERVER_HOME/ca-cert.pem $TARGET_CERTFILE

# 增加peerOrg1,peerOrg2配置
aff="\n   peerOrg1:\n      - dev\n      - test\n   peerOrg2:\n      - ops\n      - market"

aff="${aff#\\n   }"

sed -i "/affiliations:/a \\   $aff" \
   $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml

# 启动root ca
fabric-ca-server start
