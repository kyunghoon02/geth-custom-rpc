import json
import urllib.request
import time

RPC_URL = "http://localhost:8545"
HEADERS = {"Content-Type": "application/json"}

# Test Address (Sepolia Faucet or any active address)
TARGET_ADDRESS = "0x05df05a82eb60a7436bfee5ec5101cff20e747f3"

def rpc_call(method, params=[]):
    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params,
        "id": 1
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(RPC_URL, data=data, headers=HEADERS)
    
    try:
        with urllib.request.urlopen(req) as response:
            res_body = response.read()
            return json.loads(res_body)
    except Exception as e:
        return {"error": str(e)}

def print_section(title):
    print("\n" + "="*50)
    print(f" [Test] {title}")
    print("="*50)

def main():
    print(f"[*] Connecting to Custom Geth Node at {RPC_URL}...")

    # 0. Check Sync Status
    print_section("Sync Status")
    sync_res = rpc_call("eth_syncing")
    if "result" in sync_res:
        if sync_res["result"] is False:
             print("[+] Node is FULLY SYNCED!")
        else:
             sync_data = sync_res["result"]
             current = int(sync_data.get('currentBlock', '0'), 16)
             highest = int(sync_data.get('highestBlock', '0'), 16)
             percent = 0
             if highest > 0:
                 percent = (current / highest) * 100
             print(f"[-] Syncing... {percent:.2f}% ({current} / {highest})")
             print("   (Data will be incomplete until sync finishes)")
    
    # 1. Test debug_getMempoolStats
    print_section("debug_getMempoolStats")
    res = rpc_call("debug_getMempoolStats")
    
    if "result" in res:
        stats = res["result"]
        print(f"[+] Success!")
        print(f" - Pending Txs : {stats.get('pending', 'N/A')}")
        print(f" - Queued Txs  : {stats.get('queued', 'N/A')}")
        print(f" - Total       : {stats.get('total', 'N/A')}")
        
        gp = stats.get("gasprice", {})
        print(f" - Gas Price (Wei):")
        print(f"    - Min: {gp.get('minimumGasPrice', '0')}")
        print(f"    - Avg: {gp.get('averageGasPrice', '0')}")
        print(f"    - Max: {gp.get('maximumGasPrice', '0')}")
    else:
        print(f"[-] Failed: {res}")

    # 2. Test eth_getAccountActivitySummary
    print_section("eth_getAccountActivitySummary")
    print(f"Target Address: {TARGET_ADDRESS}")
    res = rpc_call("eth_getAccountActivitySummary", [TARGET_ADDRESS])

    if "result" in res:
        summary = res["result"]
        print(f"[+] Success!")
        print(json.dumps(summary, indent=2))
    elif "error" in res and "not enough data" in str(res):
         print(f"⚠️  Node suggests not enough data (Less than 14 days synced).")
         print(f"   Error Msg: {res['error']}")
    else:
        print(f"[-] Failed or Syncing: {res}")

if __name__ == "__main__":
    main()
