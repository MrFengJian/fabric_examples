/*
Copyright IBM Corp. 2016 All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

		 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"encoding/json"
	"fmt"
	"strconv"
	//"bytes"
	//"math/big"
	//"crypto/x509"
	//"encoding/pem"
	"encoding/hex"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
	//msp_pb "github.com/hyperledger/fabric/protos/msp"
	//"github.com/hyperledger/fabric/protos/msp"
	//"github.com/golang/protobuf/proto"
	"github.com/hyperledger/fabric/core/chaincode/lib/cid"
)

var logger = shim.NewLogger("token_cc")

// TokenChaincode example simple Chaincode implementation
type TokenChaincode struct {
}

// type TransferHistory struct {
//    from string `json:"from"`
//}

const Token_PREFIX = "TOKEN-"
const Account_PREFIX = "ACC-"

type Token struct {
	TokenName string `json:"TokenName"`
	//TokenSymbol 	string	`json:"TokenSymbol"`
	TotalSupply int64 `json:"TotalSupply"`
	Decimal     int   `json:"Decimal"`
}

type Account struct {
	ID string `json:"ID"`
	//Frozen		bool	`json:"Frozen"`
	Balance     map[string]int64 `json:"Balance"`
	CreatorOrg  string           `json:"CreatorOrg"`
	CreatorName string           `json:"CreatorName"`
}

//func (t *TokenChaincode) getOrgFromCert(creatorByte []byte) []string {
//    certStart := bytes.IndexAny(creatorByte, "-----BEGIN")
//    if certStart == -1 {
//      fmt.Errorf("No certificate found")
//    }
//    //creatorMSP := string(creatorByte[0: certStart])
//
//
//    certText := creatorByte[certStart:]
//    bl, _ := pem.Decode(certText)
//    if bl == nil {
//      fmt.Errorf("Could not decode the PEM structure")
//    }
//
//    cert, err := x509.ParseCertificate(bl.Bytes)
//    if err != nil {
//      fmt.Errorf("ParseCertificate failed")
//    }
//    orgname := cert.Subject.Organization
//    //signature := cert.Signature
//    sId := &msp.SerializedIdentity{}
//    err = proto.Unmarshal(creatorByte, sId)
//    logger.Infof("GetMspid %s", sid.GetMspid())
//
//    return orgname
//}
//
//func (t *TokenChaincode) getNameFromCert(creatorByte []byte) string {
//    certStart := bytes.IndexAny(creatorByte, "-----BEGIN")
//    if certStart == -1 {
//      fmt.Errorf("No certificate found")
//    }
//    certText := creatorByte[certStart:]
//    bl, _ := pem.Decode(certText)
//    if bl == nil {
//      fmt.Errorf("Could not decode the PEM structure")
//    }
//
//    cert, err := x509.ParseCertificate(bl.Bytes)
//    if err != nil {
//      fmt.Errorf("ParseCertificate failed")
//    }
//    uname := cert.Subject.CommonName
//    // orgname := cert.Subject.Organization
//    return uname
//}

func (t *TokenChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

func (t *TokenChaincode) createAccount(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	// 0
	// ID (optional)
	// string
	//if len(args) != 1 {
	//	return shim.Error("Incorrect number of arguments. Expecting 1")
	//}

	cert, _ := cid.GetX509Certificate(stub)
	creatorOrg, _ := cid.GetMSPID(stub)
	creatorName := cert.Subject.CommonName
	//creatorOrg := t.getOrgFromCert(creatorByte)
	//creatorName := t.getNameFromCert(creatorByte)
	//logger.Infof("creatorOrg %s", creatorOrg)
	//logger.Infof("creatorName %s", creatorName)

	id := ""
	if len(args) == 1 {
		id = args[0]
	} else {
		id = hex.EncodeToString(cert.SubjectKeyId)
	}

	if id == "" {
		return shim.Error("Invalid ID")
	}

	accKey := Account_PREFIX + id

	existAsBytes, err := stub.GetState(accKey)
	fmt.Printf("GetState(%s) %s \n", accKey, string(existAsBytes))
	if string(existAsBytes) != "" {
		fmt.Println("Failed to create account, Duplicate key.")
		return shim.Error("Failed to create account, Duplicate key.")
	}

	account := Account{
		ID: id,
		//Frozen: false,
		Balance:     map[string]int64{},
		CreatorOrg:  creatorOrg,
		CreatorName: creatorName}

	accountAsBytes, _ := json.Marshal(account)
	err = stub.PutState(accKey, accountAsBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	logger.Infof("createAccount %s", string(accountAsBytes))
	return shim.Success(accountAsBytes)
}

func (t *TokenChaincode) issueToken(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	// 0                  1             2           3
	// TokenName          TotalSupply   decimal     toAccount
	// string             int64         int         string

	//START Check ARGS
	if len(args) != 4 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	TokenName := args[0]
	if TokenName == "" {
		return shim.Error("Invalid TokenName")
	}

	TotalSupply := args[1]
	TotalSupply_int64, err := strconv.ParseInt(TotalSupply, 10, 64)
	if TotalSupply_int64 <= 0 {
		return shim.Error("Invalid TotalSupply")
	}

	decimal := args[2]
	decimal_int, err := strconv.Atoi(decimal)
	if decimal_int < 0 {
		return shim.Error("Invalid decimal")
	}
	//END Check ARGS

	//Check Token existed
	token := Token{
		TokenName:   TokenName,
		TotalSupply: TotalSupply_int64,
		Decimal:     decimal_int}

	tokenKey := Token_PREFIX + TokenName
	existAsBytes, err := stub.GetState(tokenKey)
	if err != nil {
		return shim.Error(err.Error())
	}

	if existAsBytes != nil {
		return shim.Error("Token existed")
	}

	//Get account
	toAccID := args[3]
	toAccKey := Account_PREFIX + toAccID
	toAccBytes, err := stub.GetState(toAccKey)
	if err != nil {
		return shim.Error("Failed to get state")
	}
	if toAccBytes == nil {
		return shim.Error("Account not found")
	}

	fmt.Printf("toAccount %s \n", toAccKey)
	toAccount := &Account{}
	json.Unmarshal(toAccBytes, &toAccount)

	//append token to account balance list
	toAccount.Balance[TokenName] = TotalSupply_int64

	//Write token
	tokenAsBytes, err := json.Marshal(token)
	err = stub.PutState(tokenKey, tokenAsBytes)
	if err != nil {
		return shim.Error(err.Error())
	} else {
		logger.Infof("Write Token %s", string(tokenKey))
	}

	//Write account
	toAccBytes, err = json.Marshal(toAccount)
	err = stub.PutState(toAccKey, toAccBytes)
	if err != nil {
		return shim.Error(err.Error())
	} else {
		logger.Infof("Write Account %s", toAccKey)
	}

	//msg := &Msg{Status: true, Code: 0, Message: "代币初始化成功"}
	//rev, _ := json.Marshal(msg)

	return shim.Success(nil)

}

func (t *TokenChaincode) transferToken(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	// 0           1             2            3
	// From        To            TokenName    Amount
	// string      string        int          int64
	//START Check ARGS
	if len(args) != 4 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	Amount := args[3]
	Amount_int64, err := strconv.ParseInt(Amount, 10, 64)
	if Amount_int64 <= 0 {
		return shim.Error("Invalid amount of token to transfer")
	}
	//END Check ARGS

	TokenName := args[2]
	tokenKey := Token_PREFIX + TokenName

	//Check Token existed
	existAsBytes, err := stub.GetState(tokenKey)
	if err != nil {
		return shim.Error(err.Error())
	}

	if existAsBytes == nil {
		return shim.Error("Token not existed")
	}

	//token := &Token{}
	//fmt.Printf("Token %s \n", string(existAsBytes))
	//json.Unmarshal(existAsBytes, &token)

	//Get FROM account
	fromAccID := args[0]
	fromAccKey := Account_PREFIX + fromAccID
	fromAccBytes, err := stub.GetState(fromAccKey)
	if err != nil {
		return shim.Error("Failed to get state")
	}
	if fromAccBytes == nil {
		return shim.Error("From Account not found")
	}

	fmt.Printf("fromAccount %s \n", string(fromAccBytes))
	fromAccount := &Account{}
	json.Unmarshal(fromAccBytes, &fromAccount)

	cert, _ := cid.GetX509Certificate(stub)
	creatorOrg, _ := cid.GetMSPID(stub)
	creatorName := cert.Subject.CommonName

	if creatorOrg != fromAccount.CreatorOrg || creatorName != fromAccount.CreatorName {
		return shim.Error("Permission denied.")
	}

	//Get TO account
	toAccID := args[1]
	toAccKey := Account_PREFIX + toAccID
	toAccBytes, err := stub.GetState(toAccKey)
	if err != nil {
		return shim.Error("Failed to get state")
	}
	if toAccBytes == nil {
		return shim.Error("To Account not found")
	}

	fmt.Printf("toAccount %s \n", string(toAccBytes))
	toAccount := &Account{}
	json.Unmarshal(toAccBytes, &toAccount)

	//transfer
	if fromAccount.Balance[TokenName] >= Amount_int64 {
		fromAccount.Balance[TokenName] -= Amount_int64
		toAccount.Balance[TokenName] += Amount_int64
	} else {
		return shim.Error("Not enough balance")
	}
	fmt.Printf("New account balance %s:%d,  %s:%d\n", fromAccount.ID, fromAccount.Balance[TokenName], toAccount.ID, toAccount.Balance[TokenName])

	//Write FROM account
	fromAccBytes, err = json.Marshal(fromAccount)
	err = stub.PutState(fromAccKey, fromAccBytes)
	if err != nil {
		return shim.Error(err.Error())
	} else {
		logger.Infof("Write from Account %s", string(fromAccKey))
	}

	//Write TO account
	toAccBytes, err = json.Marshal(toAccount)
	err = stub.PutState(toAccKey, toAccBytes)
	if err != nil {
		return shim.Error(err.Error())
	} else {
		logger.Infof("Write to Account %s", string(toAccKey))
	}

	return shim.Success(nil)
}

func (t *TokenChaincode) query_token_by_name(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	TokenName := args[0]
	tokenKey := Token_PREFIX + TokenName

	// Get the state from the ledger
	valbytes, err := stub.GetState(tokenKey)
	if err != nil {
		return shim.Error("Get state error")
	}

	if valbytes == nil {
		return shim.Error("Key not existed")
	}

	return shim.Success(valbytes)
}

func (t *TokenChaincode) query_account_by_id(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	id := args[0]
	accKey := Account_PREFIX + id

	// Get the state from the ledger
	valbytes, err := stub.GetState(accKey)
	if err != nil {
		return shim.Error("Get state error")
	}

	if valbytes == nil {
		return shim.Error("Key not existed")
	}

	return shim.Success(valbytes)
}

func (t *TokenChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	logger.Info("########### example_cc0 Invoke ###########")

	function, args := stub.GetFunctionAndParameters()
	if function == "createAccount" {
		return t.createAccount(stub, args)
	}

	if function == "issueToken" {
		return t.issueToken(stub, args)
	}

	if function == "transferToken" {
		return t.transferToken(stub, args)
	}

	if function == "query_token_by_name" {
		return t.query_token_by_name(stub, args)
	}

	if function == "query_account_by_id" {
		return t.query_account_by_id(stub, args)
	}
	return shim.Error(fmt.Sprintf("Unknown action: %v", args[0]))
}

func main() {
	err := shim.Start(new(TokenChaincode))
	if err != nil {
		logger.Errorf("Error starting Simple chaincode: %s", err)
	}
}
