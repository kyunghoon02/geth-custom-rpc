# RPC Benchmark

- Timestamp: 2026-01-26 20:43:41
- RPC URL: http://localhost:28545
- Warmup: 5
- Iterations: 30

| Method | Avg (ms) | Median (ms) | P95 (ms) | Min (ms) | Max (ms) | Avg Size (bytes) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| txpool_getMempoolTraffic | 1.3 | 1.22 | 1.99 | 1.05 | 2.42 | 57 |
| txpool_content | 1.35 | 1.32 | 1.84 | 1.07 | 2.35 | 60 |

Notes: Size is the UTF-8 byte size of the HTTP response body.
