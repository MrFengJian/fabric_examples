package main

import (
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"fmt"
	pb "github.com/hyperledger/fabric/protos/peer"
	"encoding/json"
)

type ExampleChainCode02 struct {
}

type Board struct {
	Owner string `json:"owner"`
	Color string `json:"color"`
	Shape string `json:"shape"`
}

func main() {
	err := shim.Start(new(ExampleChainCode02))
	if err != nil {
		fmt.Printf("Error starting chain code: %s", err)
	}
}

func (code *ExampleChainCode02) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

func (code *ExampleChainCode02) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fun, args := stub.GetFunctionAndParameters()
	fmt.Println(fun, args)
	switch fun {
	case "create":
		return code.createBoard(stub, args)
	case "getByOwner":
		return code.getByOwner(stub, args)
	default:
		return shim.Error("unknown invoke function")
	}
	return shim.Error("unknown invoke function")
}

func (code *ExampleChainCode02) createBoard(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 3 {
		return shim.Error("not enough args")
	}
	owner, color, shape := args[0], args[1], args[2]
	//生成的复合key根据对象类型和属性列表用U+0000拼接成字符串作为key
	key, err := stub.CreateCompositeKey("owner_color", []string{owner, color})
	//预期输出U+0000owner_colorU+0000<owner>U+0000color
	if err != nil {
		return shim.Error(err.Error())
	}
	board := new(Board)
	board.Owner = owner
	board.Color = color
	board.Shape = shape
	boardBytes, _ := json.Marshal(board)
	err = stub.PutState(key, boardBytes)
	return shim.Success([]byte(key))
}

func (code *ExampleChainCode02) getByOwner(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 1 {
		return shim.Error("not enough args")
	}
	owner := args[0]
	//按对象类型和部分属性生成临时复合键，做前缀查询
	result, err := stub.GetStateByPartialCompositeKey("owner_color", []string{owner})
	if err != nil {
		return shim.Error(err.Error())
	}
	defer result.Close()
	boards := make([]map[string]interface{}, 0)
	for result.HasNext() {
		item, err := result.Next()
		if err != nil {
			return shim.Error(err.Error())
		}
		key := item.Key
		//分割后的复合键，可以按属性顺序读取
		objectType, args, err := stub.SplitCompositeKey(key)
		if err != nil {
			return shim.Error(err.Error())
		}
		value := item.Value
		board := new(Board)
		json.Unmarshal(value, board)
		data := map[string]interface{}{
			"object_type": objectType,
			"owner":       args[0],
			"color":       args[1],
			"shape":       board.Shape,
		}
		boards = append(boards, data)
	}
	boardsBytes, _ := json.Marshal(boards)
	return shim.Success(boardsBytes)
}
