#!/bin/bash
# Geth 실행 스크립트 (Lighthouse 연결용 정석 옵션)

# 1. WSL/Linux 대응: 빌드된 리눅스 바이너리와 WSL 경로를 사용합니다.
JWT_PATH="/mnt/c/Github/geth-custom-rpc/jwt.hex"
GETH_BIN="./build/bin/geth"
# 윈도우 Geth 데이터 기본 경로를 WSL에서 접근 가능한 경로로 지정 (사용자 확인 경로로 수정)
DATADIR="/mnt/c/Users/PC/AppData/Local/Ethereum/sepolia"

echo "Starting Geth (Execution Client) on Sepolia in WSL..."

$GETH_BIN --sepolia \
  --datadir "$DATADIR" \
  --ipcdisable \
  --http --http.addr 0.0.0.0 --http.port 18545 --http.vhosts "*" \
  --http.api eth,net,web3,debug,txpool \
  --authrpc.addr 0.0.0.0 --authrpc.port 18551 \
  --authrpc.jwtsecret "$JWT_PATH" \
  --authrpc.vhosts "*" \
  --cache 12288 \
  --maxpeers 100 \
  --verbosity 3
