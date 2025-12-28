import json
import urllib.request
import time

RPC_URL = "http://127.0.0.1:18545"
HEADERS = {"Content-Type": "application/json"}

def rpc_call(method, params=[]):
    payload = {"jsonrpc": "2.0", "method": method, "params": params, "id": 1}
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(RPC_URL, data=data, headers=HEADERS)
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read())

print("Monitoring sync progress for 30 seconds...")
for i in range(4):
    res = rpc_call("eth_syncing")
    if res.get("result"):
        curr = res["result"].get("currentBlock")
        highest = res["result"].get("highestBlock")
        print(f"{time.strftime('%H:%M:%S')} - Current: {int(curr, 16) if curr else 'N/A'} / Highest: {int(highest, 16) if highest else 'N/A'}")
    else:
        print(f"{time.strftime('%H:%M:%S')} - Not syncing or error: {res}")
    if i < 3:
        time.sleep(10)
