# ⚙️ Mempool Radar Core (Geth Fork)

**Mempool Radar Core**는 [Go-Ethereum](https://github.com/ethereum/go-ethereum) (Geth)을 기반으로 한 커스텀 포크입니다.
실시간 멤풀 분석을 위한 **Sensor Layer** 역할을 하며, [Mempool Radar Ecosystem](https://github.com/kyunghoon02/mempool-radar)의 핵심 구성 요소입니다.

### 심층 분석과 아키텍처 연구를 위한 커스텀 RPC 구현

---

## 📌 프로젝트 목표

기존 Ethereum JSON-RPC는 **트랜잭션 실행**과 **상태 검증**에 최적화되어 있으며,
과거 데이터 분석이나 복잡한 집계에는 적합하지 않습니다.

이 프로젝트는 일반 노드에서 **의도적으로 부담이 큰 기능**을 구현하여 다음을 보여줍니다:

1. Geth 내부 구조(블록 헤더/바디, 트랜잭션, 서명 복구, TxPool)에 대한 이해
2. 왜 **외부 인덱서(Etherscan, The Graph, Postgres 기반 인덱서)**가 필요한지 증명
3. Go 언어로 **실행 레이어 코어 코드**를 직접 수정할 수 있는 역량

> 별도 프로젝트에서 동일한 기능을 **Go 인덱서 + PostgreSQL**로 재구현하여
> - 노드 레벨 스캔 vs.
> - 인덱서 SQL 질의
> 를 비교하는 것을 목표로 합니다.

---

## ✨ 핵심 기능

### 1. Mempool 통계 — `debug_getMempoolStats`

현재 트랜잭션 풀의 통계를 빠르게 조회하는 RPC입니다.

- **문제**
  - `txpool_content`는 너무 무거움
  - `txpool_status`는 정보가 부족함
  - 네트워크 혼잡을 판단하려면 **가스비 분포**가 필요

- **해결**
  - TxPool 내부에 직접 접근
  - `pending`, `queued` 트랜잭션 통계 집계
  - 최소/최대/평균 가스비 계산

- **응답 예시**

```json
{
  "total": 1500,
  "pending": 1200,
  "queued": 300,
  "gasprice": {
    "minimumGasPrice": "0x3b9aca00",
    "maximumGasPrice": "0x2540be400",
    "averageGasPrice": "0x4a817c800"
  }
}
```

**사용 예시**

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"debug_getMempoolStats",
    "params":[],
    "id":1
  }' \
  http://localhost:28545
```

### 2. Mempool 트래픽 — `txpool_getMempoolTraffic`

실시간 레이더용 경량 RPC입니다. 필수 필드만 내려주고 트래픽 타입을 포함합니다.

- **목적**
  - `txpool_content` 대비 페이로드 최소화
  - `trafficType`(deploy/call/transfer)로 빠른 분류
  - `total`과 `data`를 함께 반환

- **응답 예시**

```json
{
  "total": 2,
  "data": [
    {
      "hash": "0x...",
      "from": "0x...",
      "to": "0x...",
      "selector": "0xa9059cbb",
      "trafficType": "call",
      "gasLimit": 21000,
      "gasFeeCap": "0x3b9aca00",
      "priorityFee": "0x77359400",
      "value": "0x0",
      "timestamp": 1710000000000000
    },
    {
      "hash": "0x...",
      "from": "0x...",
      "to": null,
      "selector": "0x",
      "trafficType": "deploy",
      "gasLimit": 1500000,
      "gasFeeCap": "0x59682f00",
      "priorityFee": "0x77359400",
      "value": "0x0",
      "timestamp": 1710000000000000
    }
  ]
}
```

- **노트**
  - `selector`는 항상 hex 문자열이며, 없으면 "0x"
  - `total`은 `data`에 포함된 pending tx 개수와 동일

**사용 예시**

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"txpool_getMempoolTraffic",
    "params":[],
    "id":1
  }' \
  http://localhost:28545
```

---

## 🧱 빌드 & 실행

**필수 조건**

- Go 1.24+
- C toolchain (gcc, clang 등)

1. **빌드**

```bash
go build -o geth ./cmd/geth
# 또는
make geth
```

2. **개발 모드 실행 (단일 노드 테스트넷)**

```bash
./geth --dev --http --http.api eth,debug,txpool,net,web3 --http.port 28545 --verbosity 3
```

Custom RPC는 `http://localhost:28545`에서 호출 가능합니다.

> **주의**
> 이 RPC들은 실험용이며 메인넷에서 매우 무거울 수 있습니다.
> 로컬 테스트와 아키텍처 비교 목적에 최적화되어 있습니다.

---

## 📊 벤치마크 (로컬 개발)

`scripts/bench_rpc.ps1` 실행 결과 (2026-01-26, localhost, Sepolia, warmup=5, iterations=30):

| 메서드 | 평균 (ms) | 중앙값 (ms) | P95 (ms) | 최소 (ms) | 최대 (ms) | 평균 크기 (bytes) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| txpool_getMempoolTraffic | 1.30 | 1.22 | 1.99 | 1.05 | 2.42 | 57 |
| txpool_content | 1.35 | 1.32 | 1.84 | 1.07 | 2.35 | 60 |

노트:
- 측정 당시 멤풀이 거의 비어 있어 페이로드가 매우 작았습니다.
- 실제 부하 환경에서 스크립트를 재실행해 의미 있는 비교값을 얻으세요.

---

## 📚 업스트림 프로젝트

Geth 본래 사용법과 문서는 아래를 참고하세요:

- https://github.com/ethereum/go-ethereum
- https://geth.ethereum.org/

**본 포크는 커스텀 RPC 실험을 위한 저장소이며, 업스트림을 대체하지 않습니다.**

---

## 🪪 라이선스

Core 로직은 [go-ethereum](https://github.com/ethereum/go-ethereum)에서 파생되었습니다 (LGPL-3.0 / GPL-3.0).

커스텀 RPC 구현은 교육 및 포트폴리오 목적입니다.
