# Script khởi động lại backend sạch sẽ
# Chạy với: powershell -ExecutionPolicy Bypass -File restart_backend.ps1

Write-Host "===== SMART SERVICE BACKEND RESTART =====" -ForegroundColor Cyan

# Kill tất cả Python process đang bind port 8000
$pids = (netstat -ano | Select-String ":8000") | ForEach-Object {
    ($_ -split '\s+')[-1]
} | Sort-Object -Unique

foreach ($pid in $pids) {
    if ($pid -match '^\d+$' -and $pid -ne '0') {
        try {
            $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
            if ($proc -and $proc.ProcessName -like 'python*') {
                Stop-Process -Id $pid -Force
                Write-Host "  Killed PID $pid ($($proc.ProcessName))" -ForegroundColor Yellow
            }
        } catch {}
    }
}

Start-Sleep -Seconds 2

# Kiểm tra port đã được giải phóng chưa
$remaining = netstat -ano | Select-String ":8000 "
if ($remaining) {
    Write-Host "  WARNING: Port 8000 still in use. Trying taskkill..." -ForegroundColor Yellow
    foreach ($line in $remaining) {
        $pid = ($line -split '\s+')[-1]
        if ($pid -match '^\d+$') {
            taskkill /PID $pid /F 2>$null
        }
    }
    Start-Sleep -Seconds 1
}

Write-Host "  Port 8000 cleared. Starting backend..." -ForegroundColor Green

# Khởi động uvicorn
Set-Location $PSScriptRoot
& ".\venv_win\Scripts\uvicorn.exe" main:app --host 0.0.0.0 --port 8000 --reload
