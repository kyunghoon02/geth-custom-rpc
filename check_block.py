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

block = rpc_call("eth_getBlockByNumber", [hex(4629921), False])
if block.get("result"):
    print(f"Block 4629921 found!")
    print(f"Timestamp: {int(block['result']['timestamp'], 16)}")
else:
    print(f"Block 4629921 NOT found or error: {block}")
