import json
import urllib.request

RPC_URL = "http://127.0.0.1:18545"
HEADERS = {"Content-Type": "application/json"}

def rpc_call(method, params=[]):
    payload = {"jsonrpc": "2.0", "method": method, "params": params, "id": 1}
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(RPC_URL, data=data, headers=HEADERS)
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read())

print("--- Block Number ---")
print(json.dumps(rpc_call("eth_blockNumber"), indent=2))
print("\n--- Syncing ---")
print(json.dumps(rpc_call("eth_syncing"), indent=2))
