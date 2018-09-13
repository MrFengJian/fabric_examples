package main

import (
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"fmt"
	pb "github.com/hyperledger/fabric/protos/peer"
	"encoding/json"
)

var docType = "board"

type ExampleChainCode03 struct {
}

type Board struct {
	DocType string `json:"docType"`
	Owner   string `json:"owner"`
	Color   string `json:"color"`
	Shape   string `json:"shape"`
}

func main() {
	err := shim.Start(new(ExampleChainCode03))
	if err != nil {
		fmt.Printf("Error starting chain code: %s", err)
	}
}

func (code *ExampleChainCode03) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

func (code *ExampleChainCode03) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fun, args := stub.GetFunctionAndParameters()
	fmt.Println(fun, args)
	switch fun {
	case "create":
		return code.createBoard(stub, args)
	case "getByOwner":
		return code.getByOwner(stub, args)
	case "getByQuery":
		return code.getByQuery(stub, args)
	default:
		return shim.Error("unknown invoke function")
	}
	return shim.Error("unknown invoke function")
}

func (code *ExampleChainCode03) createBoard(stub shim.ChaincodeStubInterface, args []string) pb.Response {
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
	board.DocType = docType
	board.Owner = owner
	board.Color = color
	board.Shape = shape
	boardBytes, _ := json.Marshal(board)
	err = stub.PutState(key, boardBytes)
	return shim.Success([]byte(key))
}

func (code *ExampleChainCode03) getByOwner(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 1 {
		return shim.Error("not enough args")
	}
	owner := args[0]
	queryString := fmt.Sprintf("{\"selector\":{\"docType\":\"%s\",\"owner\":\"%s\"}}", docType, owner)
	boards, err := code.query(stub, queryString)
	if err != nil {
		return shim.Error(err.Error())
	}
	boardsBytes, _ := json.Marshal(boards)
	return shim.Success(boardsBytes)
}

func (code *ExampleChainCode03) query(stub shim.ChaincodeStubInterface, query string) ([]*Board, error) {
	result, err := stub.GetQueryResult(query)
	if err != nil {
		return nil, err
	}
	defer result.Close()
	boards := make([]*Board, 0)
	for result.HasNext() {
		item, err := result.Next()
		if err != nil {
			return nil, err
		}
		value := item.Value
		board := new(Board)
		json.Unmarshal(value, board)
		boards = append(boards, board)
	}
	return boards, nil
}

func (code *ExampleChainCode03) getByQuery(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 1 {
		return shim.Error("not enough args")
	}
	query := args[0]
	boards, err := code.query(stub, query)
	if err != nil {
		return shim.Error(err.Error())
	}
	boardsBytes, _ := json.Marshal(boards)
	return shim.Success(boardsBytes)
}
