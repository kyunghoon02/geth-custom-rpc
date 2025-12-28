# Geth Custom RPC 🔬

### Custom RPC Implementation for Deep Analysis & Architecture Research

> **Note**  
> This repository is a **fork of [go-ethereum](https://github.com/ethereum/go-ethereum)**  
> specifically designed for **portfolio & research**.  
> It implements custom RPC endpoints to illustrate the performance trade-offs  
> between direct node queries and external indexing solutions.

---

## 🎯 Project Motivation

The standard Ethereum JSON-RPC API is optimized for **transaction execution** and **state verification**,  
not for historical data analysis or complex aggregation.

This project implements functionality that is **intentionally heavy** for a normal node to handle, in order to:

1. Demonstrate a deep understanding of Geth's internal data structures  
   (block headers/bodies, tx, signer recovery, txpool).
2. Prove why **external indexers (Etherscan, The Graph, custom Postgres indexers)**  
   are architecturally necessary for historical analytics.
3. Showcase the ability to modify **core client (execution layer) code in Go**.

> In a separate project, the same features will be re-implemented using  
> **a custom Go indexer + PostgreSQL**, to compare:
>
> - Node-level scans vs.
> - Indexer-level SQL queries

---

## 🚀 Key Features

### 1. Account Activity Summary — `eth_getAccountActivitySummary`

A heavy-duty RPC that scans historical blocks to summarize an account's activity over a recent time range
(e.g. last 14 days).

- **Problem**  
  Geth indexes blocks by **number** and **hash**, but not by **time** or **account**.  
  There is no native way to “get all transactions for this address from 2 weeks ago”.

- **Solution Implemented (Node-level)**

  - **Binary search on block headers**  
    Finds the starting block for a target timestamp (e.g. “14 days ago”).
  - **Sequential block iteration**  
    Iterates from `startBlock` to the latest block.
  - **On-the-fly signer recovery (ecrecover)**  
    Since `from` is not indexed per address historically,  
    the method derives the sender for each transaction using `types.Sender`.

- **Insight**  
  This RPC is intentionally expensive (O(N) over blocks/txs) and demonstrates why:
  - Production dApps should not rely on node-level historical scans.
  - **Event/tx indexing in a separate database** is the right architectural layer.

**Usage**

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_getAccountActivitySummary",
    "params":["0xYourAddressHere"],
    "id":1
  }' \
  http://localhost:18545
```

### 2. Mempool Statistics — `debug_getMempoolStats`

A debugging/monitoring RPC that provides statistical insights into the current transaction pool.

- **Problem**
  - `txpool_content` returns detailed raw data → **too heavy** for quick checks.
  - `txpool_status` returns only counts → **too limited**.
  - Developers and node operators often need **gas price distribution** to understand congestion.

- **Solution Implemented**
  - Directly accesses the internal TxPool backend.
  - Iterates through `pending` and `queued` stats.
  - Calculates:
    - Total tx count (Pending / Queued)
    - Min / Max / Avg gas price

- **Response Example**

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

- **Insight**
  Shows how to safely expose internal in-memory structures over RPC for:
  - Monitoring dashboards
  - Local debugging of network conditions

**Usage**

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"debug_getMempoolStats",
    "params":[],
    "id":1
  }' \
  http://localhost:18545
```

---

## 🛠 Building & Running

**Prerequisites**

- Go 1.23+
- C toolchain (gcc, clang, etc.)

1. **Build**

   ```bash
   go build -o geth ./cmd/geth
   # or
   make geth
   ```

2. **Run in Dev Mode (single-node testnet)**
   ```bash
   ./geth \
     --dev \
     --http \
     --http.api eth,debug,txpool,net,web3 \
     --http.port 18545 \
     --verbosity 3
   ```
   Custom RPCs will then be available over HTTP on `http://localhost:18545`.

> **⚠️ Warning**  
> These RPCs are experimental and can be very expensive on mainnet.  
> They are designed for local testing, research, and architectural comparison with indexers.

---

## 👤 Author

- **Name**: Evan
- **Handle**: 0x_Aven
- **Focus**: Ethereum client internals, custom RPC design, indexer vs node trade-offs

---

## 📚 Upstream Project

For general Geth usage, documentation, and production guidance, please refer to the official repository:

- https://github.com/ethereum/go-ethereum
- https://geth.ethereum.org/

**This fork only highlights the custom RPC experiments and does not replace the upstream project in any way.**

---

## 📝 License

Core logic and client implementation are derived from [go-ethereum](https://github.com/ethereum/go-ethereum) (LGPL-3.0 / GPL-3.0).

Custom RPC implementations in this fork are provided for educational and portfolio purposes.
