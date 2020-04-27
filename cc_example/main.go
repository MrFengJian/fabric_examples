package main

import (
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"fmt"
	pb "github.com/hyperledger/fabric/protos/peer"
)

type FoozyCode struct {
}

func main() {
	err := shim.Start(new(FoozyCode))
	if err != nil {
		fmt.Printf("Error starting chain code: %s", err)
	}
}

func (fuzzy *FoozyCode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

//peer的invoke和query都是调用此方法实现的
func (fuzzy *FoozyCode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	//shim.Error产生异常响应，通知操作失败
	//shim.Error("error test")
	//shim.Success产生正常响应，通知操作成功
	return shim.Success(nil)
}
