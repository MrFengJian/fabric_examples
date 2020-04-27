#!/bin/bash

set -e
cd ./artifacts/demo
export PATH=$PATH:/home/fengjj/master/release/1.4.3/bin

cryptogen generate --config=./crypto-config.yaml
