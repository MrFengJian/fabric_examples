fabric网络环境搭建的例子，所使用的yaml和各种配置。

# e2e_cli

参考[fabric官方e2e_cl](https://github.com/hyperledger/fabric/tree/release-1.1/examples/e2e_cli)，在其基础上修改为三组织三通道配置，且只有orderer节点对外暴露端口。

使用说明可参考[一步一步搭建hyperledger环境](https://swordboy.github.io/build_fabric_network_step_by_step.html)

# kafka

参考社区[fabric-sample-with-kafka](https://github.com/keenkit/fabric-sample-with-kafka)，在其基础上，修改为三组织三通道配置，只要orderer集群节点对容器外暴露接口。

使用说明可参考[kafka共识的orderer集群fabric网络环境搭建](https://swordboy.github.io/build_fabric_network_with_kafka_orders.html)

# ca

参考社区[fabric-ca](https://github.com/hyperledger/fabric-samples/tree/release-1.1/fabric-ca)，在其基础上，拆解复杂的脚本过程。

使用说明可参考[基于fabric-ca手动搭建fabric网络](https://swordboy.github.io/build_fabric_network_with_fabric_ca.html)



# isolated_network

通过docker，给每个组织建立单独的隔离网络，仅anchor节点可以跨组织互通，fabric网络能够正常工作。



# cc_example

测试智能合约开发接口的示例代码



# tls_kafka

orderer连接kafka集群时，启用tls，加强安全性