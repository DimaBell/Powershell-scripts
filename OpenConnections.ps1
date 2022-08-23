$OpenConnections = Get-NetTCPConnection -State Established | Where-Object { ($_.RemoteAddress -ne "127.0.0.1") -and ($_.RemoteAddress -ne "::1") } | Select-Object RemoteAddress, RemotePort, OwningProcess
Foreach ($OpenConnection in $OpenConnections) {
    $ProgramName = (Get-Process -Id $OpenConnection.OwningProcess | Select-Object ProcessName).ProcessName
    Write-Output "`r`nThe program $ProgramName is connected to the IP $($OpenConnection.RemoteAddress) on port $($OpenConnection.RemotePort)."
}
Read-Host "Press any key to exit"