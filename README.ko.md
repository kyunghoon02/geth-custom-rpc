# ⚙️ Mempool Radar Core (포크된 Geth)

**Mempool Radar Core**는 실시간 멤풀 분석을 위해 최적화된 [Go-Ethereum](https://github.com/ethereum/go-ethereum) (Geth)의 커스텀 포크 버전입니다.  
[Mempool Radar 에코시스템](https://github.com/kyunghoon02/mempool-radar-ops) 내에서 **센서 레이어(Sensor Layer)** 역할을 수행합니다.

### 심층 분석 및 아키텍처 연구를 위한 커스텀 RPC 구현

---

## 🎯 프로젝트 동기

표준 이더리움 JSON-RPC API는 **트랜잭션 실행**과 **상태 검증**에 최적화되어 있으며, 이력 데이터 분석이나 복잡한 집계 작업에는 적합하지 않습니다.

본 프로젝트는 일반적인 노드가 처리하기에는 **의도적으로 무거운** 기능을 직접 구현함으로써 다음을 목표로 합니다:

1. Geth 내부 데이터 구조(Block Header/Body, Tx, Signer Recovery, TxPool 등)에 대한 깊은 이해 입증.
2. 왜 **외부 인덱서(Etherscan, The Graph, 커스텀 Postgres 인덱서 등)**가 아키텍처적으로 필수적인지 증명.
3. Go 언어를 이용한 **코어 클라이언트(Execution Layer) 코드 수정** 능력 과시.

---

## 🚀 주요 기능

### 1. 멤풀 통계 — `debug_getMempoolStats`

현재 트랜잭션 풀의 통계적 통찰력을 제공하는 모니터링 RPC입니다.

- **문제점**

  - `txpool_content`: 전체 원시 데이터를 반환하므로 너무 무거움.
  - `txpool_status`: 단순 개수만 반환하므로 정보가 부족함.
  - 노드 운영자는 네트워크 혼잡도를 파악하기 위해 **가스비 분포**를 알 필요가 있음.

- **구현 솔루션**

  - 내부 TxPool 백엔드에 직접 접근.
  - `pending` 및 `queued` 트랜잭션을 순회하며 통계 산출.
  - 계산 항목:
    - 총 트랜잭션 수 (Pending / Queued)
    - 최소 / 최대 / 평균 가스 가격 (Gas Price)

- **사용 예시**

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

### 2. 멤풀 트래픽 — `txpool_getMempoolTraffic`

실시간 멤풀 레이더를 위한 경량 RPC입니다. 최소한의 트랜잭션 헤더와 타입 태그를 반환합니다.

- **목적**

  - `txpool_content` 대비 페이로드 크기 대폭 축소.
  - 트랜잭션 분류(deploy/call/transfer)를 위한 `trafficType` 제공.
  - 데이터와 함께 전체 개수(`total`)를 즉시 반환.

- **사용 예시**

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

## 🛠 빌드 및 실행

**사전 요구 사항**

- Go 1.24+
- C 툴체인 (gcc, clang 등)

1. **빌드**

   ```bash
   make geth
   ```

2. **개발 모드 실행**
   ```bash
   ./geth --dev --http --http.api eth,debug,txpool,net,web3 --http.port 28545
   ```
