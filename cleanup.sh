#!/bin/bash

docker-compose down -v

rm -rf ./master/data/*
rm -rf ./slave1/data/*
rm -rf ./slave2/data/*