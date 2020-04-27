#/bin/bash

set -e

echo "==========Parepare ordererOrg============="
export FABRIC_CA_CLIENT_HOME=$HOME/cas/ica-ordererOrg
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/ordererOrg-ca-chain.pem
fabric-ca-client enroll -d -u https://admin:adminpw@ica-ordererOrg:7054

# ordererOrg组织只需要创建orderer节点用户和管理员用户
fabric-ca-client register -d --id.name orderer --id.secret password --id.type orderer

fabric-ca-client register -d --id.name admin-ordererOrg --id.secret password --id.attrs "admin=true:ecert"

export ORG_MSP_DIR=/data/orgs/ordererOrg/msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/ordererOrg-ca-chain.pem
fabric-ca-client getcacert -d -u https://ica-ordererOrg:7054 -M $ORG_MSP_DIR

cp -r /data/orgs/ordererOrg/msp/cacerts/ /data/orgs/ordererOrg/msp/tlscacerts
cp -r /data/orgs/ordererOrg/msp/intermediatecerts /data/orgs/ordererOrg/msp/tlsintermediatecerts 

export FABRIC_CA_CLIENT_HOME=/data/orgs/ordererOrg/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/ordererOrg-ca-chain.pem
fabric-ca-client enroll -d -u https://admin-ordererOrg:password@ica-ordererOrg:7054
cp -r /data/orgs/ordererOrg/admin/msp/signcerts /data/orgs/ordererOrg/msp/admincerts
cp -r /data/orgs/ordererOrg/admin/msp/signcerts /data/orgs/ordererOrg/admin/msp/admincerts

rm -rf /tmp/tls
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/ordererOrg-ca-chain.pem

fabric-ca-client enroll -d --enrollment.profile tls -u https://orderer:password@ica-ordererOrg:7054 -M /tmp/tls --csr.hosts orderer
mkdir -p /data/orgs/ordererOrg/orderer/tls

cp /tmp/tls/keystore/* /data/orgs/ordererOrg/orderer/tls/server.key
cp /tmp/tls/signcerts/* /data/orgs/ordererOrg/orderer/tls/server.crt

export FABRIC_CA_CLIENT_HOME=/data/orgs/ordererOrg/orderer
fabric-ca-client enroll -d -u https://orderer:password@ica-ordererOrg:7054

cp -r /data/orgs/ordererOrg/orderer/msp/cacerts/ /data/orgs/ordererOrg/orderer/msp/tlscacerts 
cp -r /data/orgs/ordererOrg/orderer/msp/intermediatecerts /data/orgs/ordererOrg/orderer/msp/tlsintermediatecerts

cp -r /data/orgs/ordererOrg/msp/admincerts /data/orgs/ordererOrg/orderer/msp

echo "==========End ordererOrg preparation==========="

echo "==========Prepare peerOrg1====================="

export FABRIC_CA_CLIENT_HOME=$HOME/cas/ica-peerOrg1
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg1-ca-chain.pem
fabric-ca-client enroll -d -u https://admin:adminpw@ica-peerOrg1:7054

# peer组织需要创建peer节点用户、管理员用户和普通用户
fabric-ca-client register -d --id.name peer0-peerOrg1 --id.secret password --id.type peer
fabric-ca-client register -d --id.name peer1-peerOrg1 --id.secret password --id.type peer
fabric-ca-client register -d --id.name admin-peerOrg1 --id.secret password --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"
fabric-ca-client register -d --id.name user-peerOrg1 --id.secret password

export ORG_MSP_DIR=/data/orgs/peerOrg1/msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg1-ca-chain.pem
fabric-ca-client getcacert -d -u https://ica-peerOrg1:7054 -M $ORG_MSP_DIR

cp /data/orgs/peerOrg1/msp/cacerts/ /data/orgs/peerOrg1/msp/tlscacerts -r 
cp /data/orgs/peerOrg1/msp/intermediatecerts /data/orgs/peerOrg1/msp/tlsintermediatecerts -r

export FABRIC_CA_CLIENT_HOME=/data/orgs/peerOrg1/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg1-ca-chain.pem
fabric-ca-client enroll -d -u https://admin-peerOrg1:password@ica-peerOrg1:7054
cp -r /data/orgs/peerOrg1/admin/msp/signcerts /data/orgs/peerOrg1/msp/admincerts
cp -r /data/orgs/peerOrg1/admin/msp/signcerts /data/orgs/peerOrg1/admin/msp/admincerts

export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg1-ca-chain.pem

#使用节点用户peer0-peerOrg1，准备节点的tls服务公私钥
rm -rf /tmp/tls
mkdir -p /data/orgs/peerOrg1/peer0/tls
fabric-ca-client enroll -d --enrollment.profile tls -u https://peer0-peerOrg1:password@ica-peerOrg1:7054 -M /tmp/tls --csr.hosts peer0-peerOrg1
cp /tmp/tls/keystore/* /data/orgs/peerOrg1/peer0/tls/server.key
cp /tmp/tls/signcerts/* /data/orgs/peerOrg1/peer0/tls/server.crt
#节点用户peer0-peerOrg1的msp目录准备
export FABRIC_CA_CLIENT_HOME=/data/orgs/peerOrg1/peer0
fabric-ca-client enroll -d -u https://peer0-peerOrg1:password@ica-peerOrg1:7054
cp /data/orgs/peerOrg1/peer0/msp/cacerts/ /data/orgs/peerOrg1/peer0/msp/tlscacerts -r 
cp /data/orgs/peerOrg1/peer0/msp/intermediatecerts /data/orgs/peerOrg1/peer0/msp/tlsintermediatecerts -r
#peer节点使用管理员用户的证书
cp -r /data/orgs/peerOrg1/msp/admincerts /data/orgs/peerOrg1/peer0/msp

#使用节点用户peer1-peerOrg1，准备节点的tls服务公私钥
rm -rf /tmp/tls
mkdir -p /data/orgs/peerOrg1/peer1/tls
fabric-ca-client enroll -d --enrollment.profile tls -u https://peer1-peerOrg1:password@ica-peerOrg1:7054 -M /tmp/tls --csr.hosts peer1-peerOrg1
cp /tmp/tls/keystore/* /data/orgs/peerOrg1/peer1/tls/server.key
cp /tmp/tls/signcerts/* /data/orgs/peerOrg1/peer1/tls/server.crt
#节点用户peer0-peerOrg1的msp目录准备
export FABRIC_CA_CLIENT_HOME=/data/orgs/peerOrg1/peer1
fabric-ca-client enroll -d -u https://peer1-peerOrg1:password@ica-peerOrg1:7054
cp /data/orgs/peerOrg1/peer1/msp/cacerts/ /data/orgs/peerOrg1/peer1/msp/tlscacerts -r 
cp /data/orgs/peerOrg1/peer1/msp/intermediatecerts /data/orgs/peerOrg1/peer1/msp/tlsintermediatecerts -r
#peer节点使用管理员用户的证书
cp -r /data/orgs/peerOrg1/msp/admincerts /data/orgs/peerOrg1/peer1/msp

export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg1-ca-chain.pem
mkdir /data/tls -p

#生成客户端校验证书
rm -rf /tmp/tls
fabric-ca-client enroll -d --enrollment.profile tls -u https://peer0-peerOrg1:password@ica-peerOrg1:7054 -M /tmp/tls --csr.hosts peer0-peerOrg1
cp /tmp/tls/keystore/* /data/tls/peer0-peerOrg1-clientauth.key
cp /tmp/tls/signcerts/* /data//tls/peer0-peerOrg1-clientauth.crt

#生成命令行使用的证书
rm -rf /tmp/tls
fabric-ca-client enroll -d --enrollment.profile tls -u https://peer0-peerOrg1:password@ica-peerOrg1:7054 -M /tmp/tls --csr.hosts peer0-peerOrg1
cp /tmp/tls/keystore/* /data/tls/peer0-peerOrg1-cli.key
cp /tmp/tls/signcerts/* /data//tls/peer0-peerOrg1-cli.crt

rm -rf /tmp/tls
fabric-ca-client enroll -d --enrollment.profile tls -u https://peer1-peerOrg1:password@ica-peerOrg1:7054 -M /tmp/tls --csr.hosts peer1-peerOrg1
cp /tmp/tls/keystore/* /data/tls/peer1-peerOrg1-clientauth.key
cp /tmp/tls/signcerts/* /data//tls/peer1-peerOrg1-clientauth.crt

rm -rf /tmp/tls
fabric-ca-client enroll -d --enrollment.profile tls -u https://peer1-peerOrg1:password@ica-peerOrg1:7054 -M /tmp/tls --csr.hosts peer1-peerOrg1
cp /tmp/tls/keystore/* /data/tls/peer1-peerOrg1-cli.key
cp /tmp/tls/signcerts/* /data//tls/peer1-peerOrg1-cli.crt

#准备普通用户的公私钥
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg1-ca-chain.pem
export FABRIC_CA_CLIENT_HOME=/data/orgs/peerOrg1/user-peerOrg1
fabric-ca-client enroll -d -u https://user-peerOrg1:password@ica-peerOrg1:7054
cp /data/orgs/peerOrg1/user-peerOrg1/msp/cacerts/ /data/orgs/peerOrg1/user-peerOrg1/msp/tlscacerts -r 
cp /data/orgs/peerOrg1/user-peerOrg1/msp/intermediatecerts /data/orgs/peerOrg1/user-peerOrg1/msp/tlsintermediatecerts -r
cp -r /data/orgs/peerOrg1/user-peerOrg1/msp/signcerts /data/orgs/peerOrg1/user-peerOrg1/msp/admincerts


echo "========End peerOrg1 preparation================="

echo "========Prepare peerOrg2========================="
export FABRIC_CA_CLIENT_HOME=$HOME/cas/ica-peerOrg2
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg2-ca-chain.pem
fabric-ca-client enroll -d -u https://admin:adminpw@ica-peerOrg2:7054

fabric-ca-client register -d --id.name peer0-peerOrg2 --id.secret password --id.type peer
fabric-ca-client register -d --id.name peer1-peerOrg2 --id.secret password --id.type peer
fabric-ca-client register -d --id.name admin-peerOrg2 --id.secret password --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"
fabric-ca-client register -d --id.name user-peerOrg2 --id.secret password

export ORG_MSP_DIR=/data/orgs/peerOrg2/msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg2-ca-chain.pem
fabric-ca-client getcacert -d -u https://ica-peerOrg2:7054 -M $ORG_MSP_DIR

cp /data/orgs/peerOrg2/msp/cacerts/ /data/orgs/peerOrg2/msp/tlscacerts -r 
cp /data/orgs/peerOrg2/msp/intermediatecerts /data/orgs/peerOrg2/msp/tlsintermediatecerts -r

export FABRIC_CA_CLIENT_HOME=/data/orgs/peerOrg2/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg2-ca-chain.pem
fabric-ca-client enroll -d -u https://admin-peerOrg2:password@ica-peerOrg2:7054
cp -r /data/orgs/peerOrg2/admin/msp/signcerts /data/orgs/peerOrg2/msp/admincerts
cp -r /data/orgs/peerOrg2/admin/msp/signcerts /data/orgs/peerOrg2/admin/msp/admincerts

export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg2-ca-chain.pem

#使用节点用户peer0-peerOrg2
rm -rf /tmp/tls
mkdir -p /data/orgs/peerOrg2/peer0/tls
fabric-ca-client enroll -d --enrollment.profile tls -u https://peer0-peerOrg2:password@ica-peerOrg2:7054 -M /tmp/tls --csr.hosts peer0-peerOrg2
cp /tmp/tls/keystore/* /data/orgs/peerOrg2/peer0/tls/server.key
cp /tmp/tls/signcerts/* /data/orgs/peerOrg2/peer0/tls/server.crt
#节点用户peer0-peerOrg2的msp目录准备
export FABRIC_CA_CLIENT_HOME=/data/orgs/peerOrg2/peer0
fabric-ca-client enroll -d -u https://peer0-peerOrg2:password@ica-peerOrg2:7054
cp /data/orgs/peerOrg2/peer0/msp/cacerts/ /data/orgs/peerOrg2/peer0/msp/tlscacerts -r 
cp /data/orgs/peerOrg2/peer0/msp/intermediatecerts /data/orgs/peerOrg2/peer0/msp/tlsintermediatecerts -r
#peer节点使用管理员用户的证书
cp -r /data/orgs/peerOrg2/msp/admincerts /data/orgs/peerOrg2/peer0/msp

#使用节点用户peer1-peerOrg2
rm -rf /tmp/tls
mkdir -p /data/orgs/peerOrg2/peer1/tls
fabric-ca-client enroll -d --enrollment.profile tls -u https://peer1-peerOrg2:password@ica-peerOrg2:7054 -M /tmp/tls --csr.hosts peer1-peerOrg2
cp /tmp/tls/keystore/* /data/orgs/peerOrg2/peer1/tls/server.key
cp /tmp/tls/signcerts/* /data/orgs/peerOrg2/peer1/tls/server.crt
#节点用户peer0-peerOrg2的msp目录准备
export FABRIC_CA_CLIENT_HOME=/data/orgs/peerOrg2/peer1
fabric-ca-client enroll -d -u https://peer1-peerOrg2:password@ica-peerOrg2:7054
cp /data/orgs/peerOrg2/peer1/msp/cacerts/ /data/orgs/peerOrg2/peer1/msp/tlscacerts -r 
cp /data/orgs/peerOrg2/peer1/msp/intermediatecerts /data/orgs/peerOrg2/peer1/msp/tlsintermediatecerts -r
#peer节点使用管理员用户的证书
cp -r /data/orgs/peerOrg2/msp/admincerts /data/orgs/peerOrg2/peer1/msp

export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg2-ca-chain.pem
mkdir /data/tls -p

#生成客户端校验证书
rm -rf /tmp/tls
fabric-ca-client enroll -d --enrollment.profile tls -u https://peer0-peerOrg2:password@ica-peerOrg2:7054 -M /tmp/tls --csr.hosts peer0-peerOrg2
cp /tmp/tls/keystore/* /data/tls/peer0-peerOrg2-clientauth.key
cp /tmp/tls/signcerts/* /data//tls/peer0-peerOrg2-clientauth.crt

#生成命令行使用的证书
rm -rf /tmp/tls
fabric-ca-client enroll -d --enrollment.profile tls -u https://peer0-peerOrg2:password@ica-peerOrg2:7054 -M /tmp/tls --csr.hosts peer0-peerOrg2
cp /tmp/tls/keystore/* /data/tls/peer0-peerOrg2-cli.key
cp /tmp/tls/signcerts/* /data//tls/peer0-peerOrg2-cli.crt

rm -rf /tmp/tls
fabric-ca-client enroll -d --enrollment.profile tls -u https://peer1-peerOrg2:password@ica-peerOrg2:7054 -M /tmp/tls --csr.hosts peer1-peerOrg2
cp /tmp/tls/keystore/* /data/tls/peer1-peerOrg2-clientauth.key
cp /tmp/tls/signcerts/* /data//tls/peer1-peerOrg2-clientauth.crt

rm -rf /tmp/tls
fabric-ca-client enroll -d --enrollment.profile tls -u https://peer1-peerOrg2:password@ica-peerOrg2:7054 -M /tmp/tls --csr.hosts peer1-peerOrg2
cp /tmp/tls/keystore/* /data/tls/peer1-peerOrg2-cli.key
cp /tmp/tls/signcerts/* /data//tls/peer1-peerOrg2-cli.crt

export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/peerOrg2-ca-chain.pem
export FABRIC_CA_CLIENT_HOME=/data/orgs/peerOrg2/user-peerOrg2
fabric-ca-client enroll -d -u https://user-peerOrg2:password@ica-peerOrg2:7054
cp /data/orgs/peerOrg2/user-peerOrg2/msp/cacerts/ /data/orgs/peerOrg2/user-peerOrg2/msp/tlscacerts -r 
cp /data/orgs/peerOrg2/user-peerOrg2/msp/intermediatecerts /data/orgs/peerOrg2/user-peerOrg2/msp/tlsintermediatecerts -r
cp -r /data/orgs/peerOrg2/user-peerOrg2/msp/signcerts /data/orgs/peerOrg2/user-peerOrg2/msp/admincerts

echo "========End peerOrg2 preparation========================"

echo "======Creating genesis block and channel artifacts=========="

echo "
Profiles:

  OrgsOrdererGenesis:
  
    Orderer:
      OrdererType: solo
      
      Addresses:
        - orderer:7050

      BatchTimeout: 2s

      BatchSize:

        MaxMessageCount: 10

        AbsoluteMaxBytes: 99 MB

        PreferredMaxBytes: 512 KB

      Kafka:
        Brokers:
          - 127.0.0.1:9092

      Organizations:
        - *ordererOrg

    Consortiums:

      SampleConsortium:

        Organizations:
          - *peerOrg1
          - *peerOrg2

  OrgsChannel:
    Consortium: SampleConsortium
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *peerOrg1
        - *peerOrg2

Organizations:

  - &ordererOrg

    Name: ordererOrg

    ID: ordererOrgMSP

    MSPDir: /data/orgs/ordererOrg/msp

  - &peerOrg1

    Name: peerOrg1

    ID: peerOrg1MSP

    MSPDir: /data/orgs/peerOrg1/msp

    AnchorPeers:
       - Host: peer0-peerOrg1
         Port: 7051

  - &peerOrg2

    Name: peerOrg2

    ID: peerOrg2MSP

    MSPDir: /data/orgs/peerOrg2/msp

    AnchorPeers:
       - Host: peer0-peerOrg2
         Port: 7051

Application: &ApplicationDefaults
    Organizations:
" >$FABRIC_CFG_PATH/configtx.yaml


configtxgen -profile OrgsOrdererGenesis -outputBlock /data/genesis.block
configtxgen -profile OrgsChannel -outputCreateChannelTx /data/channel.tx -channelID mychannel
configtxgen -profile OrgsChannel -outputAnchorPeersUpdate /data/peerOrg1Anchor.tx -channelID mychannel -asOrg peerOrg1
configtxgen -profile OrgsChannel -outputAnchorPeersUpdate /data/peerOrg2Anchor.tx -channelID mychannel -asOrg peerOrg2


echo "============================================"
echo "============================================"
echo "SETUP SUCCCESS!!!"
echo "============================================"
echo "============================================"
