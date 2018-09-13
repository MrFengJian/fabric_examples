package main

import (
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"fmt"
	pb "github.com/hyperledger/fabric/protos/peer"
	"github.com/hyperledger/fabric/core/chaincode/lib/cid"
	"encoding/json"
	"encoding/base64"
	"time"
)

type ExampleChainCode01 struct {
}

func main() {
	err := shim.Start(new(ExampleChainCode01))
	if err != nil {
		fmt.Printf("Error starting chain code: %s", err)
	}
}

func (code *ExampleChainCode01) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

func (code *ExampleChainCode01) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fun, args := stub.GetFunctionAndParameters()
	switch fun {
	case "getCreator":
		return code.getCreator(stub)
	case "callCode":
		return code.callChainCode(stub, args)
	case "put":
		return code.putValue(stub, args)
	case "get":
		return code.getValue(stub, args)
	case "rangeQuery":
		return code.getRange(stub, args)
	case "history":
		return code.getKeyHistory(stub, args)
	case "delete":
		return code.delete(stub, args)
	case "event":
		return code.sendEvent(stub, args)
	default:
		break
	}
	return shim.Error("unkown function is invoked")
}

func (code *ExampleChainCode01) getCreator(stub shim.ChaincodeStubInterface) pb.Response {
	id, _ := cid.GetID(stub)
	mspId, _ := cid.GetMSPID(stub)
	//获取证书上通过fabric-ca增加的额外自定义属性
	//cid.GetAttributeValue(stub,"")
	//读取整个证书，可用于获取其他属性
	certs, _ := cid.GetX509Certificate(stub)
	//creator字节码转换为字符串后，可见调用者身份和证书信息，使用protobuf解析后可获取这些身份
	bs, _ := stub.GetCreator()
	fmt.Println(string(bs))
	data := make(map[string]interface{})
	//需要base64解码获取cn
	idBytes, _ := base64.StdEncoding.DecodeString(id)
	data["id"] = string(idBytes)
	data["cn"] = certs.Subject.CommonName
	data["msp_id"] = mspId
	data["issuer"] = certs.Issuer
	data["validity_start"] = certs.NotBefore
	data["validity_end"] = certs.NotAfter
	data["subject"] = certs.Subject
	dataBytes, _ := json.Marshal(data)
	return shim.Success(dataBytes)
}

func (code *ExampleChainCode01) callChainCode(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 3 {
		return shim.Error("args is not enough")
	}
	channelName := args[0]
	codeName := args[1]
	codeArgs := make([][]byte, 0)
	if len(args) > 2 {
		l := len(args)
		for i := 2; i < l; i++ {
			codeArgs = append(codeArgs, []byte(args[i]))
		}
	}
	response := stub.InvokeChaincode(codeName, codeArgs, channelName)
	fmt.Println("call code ", codeName, "got message", response.Message)
	data := make(map[string]interface{})
	data["message"] = response.Message
	data["payload"] = string(response.Payload)
	dataBytes, _ := json.Marshal(data)
	return shim.Success(dataBytes)
}

func (code *ExampleChainCode01) getKeyHistory(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 1 {
		return shim.Error("invalid args length")
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
		m := map[string]interface{}{
			"is_delete": item.IsDelete,
			//时间需要通过time转换为可读时间字符串
			"timestamp": time.Unix(item.Timestamp.Seconds, int64(item.Timestamp.Nanos)),
			//修改值的交易ID
			"tx_id": item.TxId,
			"value": string(item.Value),
		}
		data = append(data, m)
	}
	resultBytes, _ := json.Marshal(data)
	return shim.Success(resultBytes)
}

func (code *ExampleChainCode01) putValue(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 2 {
		return shim.Error("invalid args length")
	}
	key, value := args[0], args[1]
	err := stub.PutState(key, []byte(value))
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}

func (code *ExampleChainCode01) getValue(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 1 {
		return shim.Error("invalid args length")
	}
	key := args[0]
	value, err := stub.GetState(key)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(value)
}

func (code *ExampleChainCode01) delete(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 1 {
		return shim.Error("invalid args length")
	}
	key := args[0]
	err := stub.DelState(key)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}

func (code *ExampleChainCode01) getRange(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 2 {
		return shim.Error("invalid args length")
	}
	start, end := args[0], args[1]
	//左开右闭原则，包含start值，不包含end值
	result, err := stub.GetStateByRange(start, end)
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
		m := map[string]interface{}{
			"key":   item.Key,
			"value": string(item.Value),
			//对简单key，namespace即为合约名称
			"namespace": item.Namespace,
		}
		data = append(data, m)
	}
	dataBytes, _ := json.Marshal(data)
	return shim.Success(dataBytes)
}

func (code *ExampleChainCode01) sendEvent(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	stub.SetEvent("testEvent", []byte("this is a test event"))
	return shim.Success(nil)
}
