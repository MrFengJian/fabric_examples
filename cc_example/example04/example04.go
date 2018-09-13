package main

import (
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"fmt"
	pb "github.com/hyperledger/fabric/protos/peer"
	"encoding/json"
	"time"
)

type ExampleChainCode04 struct {
}

func main() {
	err := shim.Start(new(ExampleChainCode04))
	if err != nil {
		fmt.Printf("Error starting chain code: %s", err)
	}
}

func (code *ExampleChainCode04) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

func (code *ExampleChainCode04) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fun, args := stub.GetFunctionAndParameters()
	fmt.Println(fun, args)
	switch fun {
	case "put":
		return code.put(stub, args)
	case "get":
		return code.get(stub, args)
	case "history":
		return code.history(stub, args)
	case "delete":
		return code.delete(stub, args)
	case "getByRange":
		return code.getByRange(stub, args)
	default:
		return shim.Error("unknown invoke function")
	}
	return shim.Error("unknown invoke function")
}
func (code *ExampleChainCode04) put(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 3 {
		return shim.Error("not enough args")
	}
	collection, key, value := args[0], args[1], args[2]
	err := stub.PutPrivateData(collection, key, []byte(value))
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}

func (code *ExampleChainCode04) get(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 2 {
		return shim.Error("not enough args")
	}
	collection, key := args[0], args[1]
	value, err := stub.GetPrivateData(collection, key)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(value)
}

func (code *ExampleChainCode04) history(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 1 {
		return shim.Error("not enough args")
	}
	key := args[0]
	result, err := stub.GetHistoryForKey(key)
	if err != nil {
		return shim.Error(err.Error())
	}
	defer result.Close()
	data := make([]map[string]interface{}, 0)
	for result.HasNext() {
		item, err := result.Next()
		if err != nil {
			return shim.Error(err.Error())
		}
		data = append(data, map[string]interface{}{
			"value":     string(item.Value),
			"timestamp": time.Unix(item.Timestamp.Seconds, int64(item.Timestamp.Nanos)),
			"is_delete": item.IsDelete,
		})
	}
	dataBytes, _ := json.Marshal(data)
	return shim.Success(dataBytes)
}

func (code *ExampleChainCode04) delete(stub shim.ChaincodeStubInterface, args [] string) pb.Response {
	if len(args) < 2 {
		return shim.Error("not enough args")
	}
	collection, key := args[0], args[1]
	err := stub.DelPrivateData(collection, key)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}

func (code *ExampleChainCode04) getByRange(stub shim.ChaincodeStubInterface, args [] string) pb.Response {
	if len(args) < 3 {
		return shim.Error("not enough args")
	}
	collection, start, end := args[0], args[1], args[2]
	result, err := stub.GetPrivateDataByRange(collection, start, end)
	if err != nil {
		return shim.Error(err.Error())
	}
	defer result.Close()
	data := make([]map[string]interface{}, 0)
	for result.HasNext() {
		item, err := result.Next()
		if err != nil {
			return shim.Error(err.Error())
		}
		data = append(data, map[string]interface{}{
			"key":   item.Key,
			"value": string(item.Value),
		})
	}
	dataBytes, _ := json.Marshal(data)
	return shim.Success(dataBytes)
}
