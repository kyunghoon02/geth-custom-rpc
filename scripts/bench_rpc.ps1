param(
  [string]$RpcUrl = "http://localhost:28545",
  [int]$Warmup = 5,
  [int]$Iterations = 30
)

$methods = @(
  @{ Name = "txpool_getMempoolTraffic"; Params = @() },
  @{ Name = "txpool_content"; Params = @() }
)

function Invoke-Rpc {
  param(
    [string]$Url,
    [string]$Method,
    [object[]]$Params
  )

  $body = @{ jsonrpc = "2.0"; method = $Method; params = $Params; id = 1 } | ConvertTo-Json -Compress
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $resp = Invoke-RestMethod -Uri $Url -Method Post -ContentType "application/json" -Body $body -TimeoutSec 5
  $sw.Stop()

  $raw = $resp | ConvertTo-Json -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetByteCount($raw)
  return [pscustomobject]@{
    DurationMs = $sw.Elapsed.TotalMilliseconds
    Bytes = $bytes
  }
}

function Get-Stats {
  param([double[]]$Values)
  $sorted = $Values | Sort-Object
  $count = $sorted.Count
  $min = $sorted[0]
  $max = $sorted[$count - 1]
  $avg = ($sorted | Measure-Object -Average).Average
  $median = if ($count % 2 -eq 1) { $sorted[($count - 1) / 2] } else { ($sorted[$count/2 - 1] + $sorted[$count/2]) / 2 }
  $p95Index = [Math]::Ceiling($count * 0.95) - 1
  $p95 = $sorted[[Math]::Max(0, [Math]::Min($count - 1, $p95Index))]

  return [pscustomobject]@{
    Count = $count
    MinMs = [Math]::Round($min, 2)
    MaxMs = [Math]::Round($max, 2)
    AvgMs = [Math]::Round($avg, 2)
    MedianMs = [Math]::Round($median, 2)
    P95Ms = [Math]::Round($p95, 2)
  }
}

$results = @()

foreach ($m in $methods) {
  Write-Host "Warmup: $($m.Name)" -ForegroundColor Cyan
  for ($i=0; $i -lt $Warmup; $i++) {
    try {
      Invoke-Rpc -Url $RpcUrl -Method $m.Name -Params $m.Params | Out-Null
    } catch {
      Write-Host "RPC call failed. Check that Geth is running and RPC is reachable at $RpcUrl." -ForegroundColor Red
      Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
      exit 1
    }
  }

  Write-Host "Benchmark: $($m.Name)" -ForegroundColor Cyan
  $durations = @()
  $sizes = @()
  for ($i=0; $i -lt $Iterations; $i++) {
    try {
      $r = Invoke-Rpc -Url $RpcUrl -Method $m.Name -Params $m.Params
    } catch {
      Write-Host "RPC call failed during benchmark. Check that Geth is running and RPC is reachable at $RpcUrl." -ForegroundColor Red
      Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
      exit 1
    }
    $durations += $r.DurationMs
    $sizes += $r.Bytes
  }

  $timeStats = Get-Stats -Values $durations
  $sizeStats = Get-Stats -Values $sizes

  $results += [pscustomobject]@{
    Method = $m.Name
    RpcUrl = $RpcUrl
    Iterations = $Iterations
    Warmup = $Warmup
    TimeStats = $timeStats
    SizeStats = $sizeStats
  }
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$report = [pscustomobject]@{
  Timestamp = $timestamp
  RpcUrl = $RpcUrl
  Results = $results
}

$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 scripts/bench_report.json

$lines = @()
$lines += "# RPC Benchmark"
$lines += ""
$lines += "- Timestamp: $timestamp"
$lines += "- RPC URL: $RpcUrl"
$lines += "- Warmup: $Warmup"
$lines += "- Iterations: $Iterations"
$lines += ""
$lines += "| Method | Avg (ms) | Median (ms) | P95 (ms) | Min (ms) | Max (ms) | Avg Size (bytes) |"
$lines += "| :--- | ---: | ---: | ---: | ---: | ---: | ---: |"

foreach ($r in $results) {
  $lines += "| $($r.Method) | $($r.TimeStats.AvgMs) | $($r.TimeStats.MedianMs) | $($r.TimeStats.P95Ms) | $($r.TimeStats.MinMs) | $($r.TimeStats.MaxMs) | $($r.SizeStats.AvgMs) |"
}

$lines += ""
$lines += "Notes: Size is the UTF-8 byte size of the HTTP response body."
$lines | Set-Content -Encoding utf8 scripts/bench_report.md

Write-Host "\nSaved: scripts/bench_report.json, scripts/bench_report.md" -ForegroundColor Green
