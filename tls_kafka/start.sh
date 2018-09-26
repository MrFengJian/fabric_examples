#!/bin/bash
export PATH=$PATH:/home/fengjj/Workspaces/go_work/src/fabric_booter/release/1.1.0/bin

CHANNEL_NAME="mychannel"

generateArtifacts(){
    mkdir -p channel-artifacts
    echo
	echo "##########################################################"
	echo "##### Generate certificates using cryptogen tool #########"
	echo "##########################################################"
	cryptogen generate --config=./crypto-config.yaml

	echo "##########################################################"
	echo "#########  Generating Orderer Genesis block ##############"
	echo "##########################################################"
	# Note: For some unknown reason (at least for now) the block file can't be
	# named orderer.genesis.block or the orderer will fail to launch!
	configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block

	echo
	echo "#################################################################"
	echo "### Generating channel configuration  'mychannel.tx'          ###"
	echo "#################################################################"
	configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/mychannel.tx -channelID $CHANNEL_NAME

	echo
	echo "#################################################################"
	echo "#######    Generating anchor peer update for Org1MSP   ##########"
	echo "#################################################################"
	configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

	echo
	echo "#################################################################"
	echo "#######    Generating anchor peer update for Org2MSP   ##########"
	echo "#################################################################"
	configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
	echo
}

generateKafkaArtifacts(){
	mkdir -p ./kafka-artifacts

	CWD=$(pwd)
	cd ./kafka-artifacts
	
	echo "# 0.生成自签发ca证书"
	openssl req -new -x509 -keyout ca-key.pem -out ca-cert.pem -days 365 -subj "/CN=ca.kafka" -nodes

	echo "# 1.生成所有服务器的keystore"
	keytool -keystore kafka1.keystore.jks -alias kafka -validity 365 -genkey -keyalg RSA -keysize 2048 -storepass test1234 -dname "cn=kafka1" -keypass test1234

	keytool -keystore kafka2.keystore.jks -alias kafka -validity 365 -genkey -keyalg RSA -keysize 2048 -storepass test1234 -dname "cn=kafka2" -keypass test1234

	keytool -keystore kafka3.keystore.jks -alias kafka -validity 365 -genkey -keyalg RSA -keysize 2048 -storepass test1234 -dname "cn=kafka3" -keypass test1234

	keytool -keystore kafka4.keystore.jks -alias kafka -validity 365 -genkey -keyalg RSA -keysize 2048 -storepass test1234 -dname "cn=kafka4" -keypass test1234

	echo "# 2.导入ca证书到服务器和客户端的truststore"
	keytool -keystore kafka1.truststore.jks -alias CARoot -import -file ca-cert.pem -storepass test1234 -noprompt
	keytool -keystore kafka2.truststore.jks -alias CARoot -import -file ca-cert.pem -storepass test1234 -noprompt
	keytool -keystore kafka3.truststore.jks -alias CARoot -import -file ca-cert.pem -storepass test1234 -noprompt
	keytool -keystore kafka4.truststore.jks -alias CARoot -import -file ca-cert.pem -storepass test1234 -noprompt

	echo "# 3.创建所有服务器的csr"
	keytool -keystore kafka1.keystore.jks -alias kafka -certreq -file kafka1-server.csr -storepass test1234
	keytool -keystore kafka2.keystore.jks -alias kafka -certreq -file kafka2-server.csr -storepass test1234
	keytool -keystore kafka3.keystore.jks -alias kafka -certreq -file kafka3-server.csr -storepass test1234
	keytool -keystore kafka4.keystore.jks -alias kafka -certreq -file kafka4-server.csr -storepass test1234

	echo "# 4.使用自签发ca签发所有服务器的证书"
	openssl x509 -req -CA ca-cert.pem -CAkey ca-key.pem -in kafka1-server.csr -out kafka1-server.cert -days 365 -CAcreateserial -passin pass:test1234
	openssl x509 -req -CA ca-cert.pem -CAkey ca-key.pem -in kafka2-server.csr -out kafka2-server.cert -days 365 -CAcreateserial -passin pass:test1234
	openssl x509 -req -CA ca-cert.pem -CAkey ca-key.pem -in kafka3-server.csr -out kafka3-server.cert -days 365 -CAcreateserial -passin pass:test1234
	openssl x509 -req -CA ca-cert.pem -CAkey ca-key.pem -in kafka4-server.csr -out kafka4-server.cert -days 365 -CAcreateserial -passin pass:test1234

	echo "# 5.导入根证书和服务器证书到各自的keystore"
	keytool -keystore kafka1.keystore.jks -alias CARoot -import -file ca-cert.pem -storepass test1234 -noprompt
	keytool -keystore kafka1.keystore.jks -alias kafka -import -file kafka1-server.cert -storepass test1234 -noprompt
	keytool -keystore kafka2.keystore.jks -alias CARoot -import -file ca-cert.pem -storepass test1234 -noprompt
	keytool -keystore kafka2.keystore.jks -alias kafka -import -file kafka2-server.cert -storepass test1234 -noprompt
	keytool -keystore kafka3.keystore.jks -alias CARoot -import -file ca-cert.pem -storepass test1234 -noprompt
	keytool -keystore kafka3.keystore.jks -alias kafka -import -file kafka3-server.cert -storepass test1234 -noprompt
	keytool -keystore kafka4.keystore.jks -alias CARoot -import -file ca-cert.pem -storepass test1234 -noprompt
	keytool -keystore kafka4.keystore.jks -alias kafka -import -file kafka4-server.cert -storepass test1234 -noprompt

	echo "# 6.生成所有客户端的keystore"
	keytool -keystore client.keystore.jks -alias orderer -validity 365 -genkey -keyalg RSA -keysize 2048 -storepass test1234 -dname "cn=orderer.example.com" -keypass test1234

	echo "# 7.生成客户端csr"
	keytool -keystore client.keystore.jks -alias orderer -certreq -file client.csr -storepass test1234

	echo "# 8.使用自签发ca签发客户端证书"
	openssl x509 -req -CA ca-cert.pem -CAkey ca-key.pem -in client.csr -out client-cert.pem -days 365 -CAcreateserial -passin pass:test1234

	echo "# 9.转换客户端keystore为PKCS12格式"
	keytool -importkeystore -srckeystore client.keystore.jks -destkeystore client.keystore.p12 -deststoretype PKCS12 -storepass test1234 -srcstorepass test1234

	echo "# 10.导出客户端pkcs12证书"
	openssl pkcs12 -in client.keystore.p12 -nodes -nocerts -out client-key.pem -passin pass:test1234

	cd ${CWD}
}

generateKafkaArtifacts

generateArtifacts

docker-compose -f docker-compose-cli.yaml up -d 

docker logs -f cli 
