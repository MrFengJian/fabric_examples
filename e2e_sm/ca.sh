#!/bin/bash
ca_key=`basename $(ls ./crypto-config/peerOrganizations/org1.example.com/ca/*_sk)`
ca_cert=`basename $(ls ./crypto-config/peerOrganizations/org1.example.com/ca/*.pem)`
tls_key=`basename $(ls ./crypto-config/peerOrganizations/org1.example.com/tlsca/*_sk)`
tls_cert=`basename $(ls ./crypto-config/peerOrganizations/org1.example.com/tlsca/*.pem)`

CA_NAME="ca.org1"
docker rm -fv $CA_NAME

docker run -itd --restart always --name ${CA_NAME} --privileged \
      -p 7054:7054 \
      -e FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server \
      -e FABRIC_CA_SERVER_CA_NAME=${CA_NAME} \
      -e FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/server-ca/${ca_cert} \
      -e FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/server-ca/${ca_key} \
      -e FABRIC_CA_SERVER_TLS_ENABLED=true \
      -e FABRIC_CA_SERVER_TLS_CERTFILE=/etc/hyperledger/server-tls/${tls_cert} \
      -e FABRIC_CA_SERVER_TLS_KEYFILE=/etc/hyperledger/server-tls/${tls_key} \
      -e GOPATH=/root/gopath\
      --volume $PWD/crypto-config/peerOrganizations/org1.example.com/ca:/etc/hyperledger/server-ca \
      --volume $PWD/crypto-config/peerOrganizations/org1.example.com/tlsca:/etc/hyperledger/server-tls \
      --volume /home/fengjj/Workspaces/go_work:/root/gopath \
      --label aliyun.logs.fabric=stdout \
      hyperledger/fabric-ca:1.4.0-sm sleep 36000
      #hyperledger/fabric-ca:1.4.0-sm fabric-ca-server start -b admin:adminpw
