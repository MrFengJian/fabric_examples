#!/bin/bash

docker-compose -f docker-compose-cli.yaml down -v 
rm -rf channel-artifacts crypto-config

