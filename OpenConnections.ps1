<#
    A powershell script that outputs information of all the running processes that have established connections
    
    including the remote IP address and remote port to which each process is connected to.
    
    Script writer: Dima Bell.
   
    E-mail: D1m419935@gmail.com 
#>

$OpenConnections = Get-NetTCPConnection -State Established | Where-Object { ($_.RemoteAddress -ne "127.0.0.1") -and ($_.RemoteAddress -ne "::1") } | Select-Object RemoteAddress, RemotePort, OwningProcess
Foreach ($OpenConnection in $OpenConnections) {
    $ProgramName = (Get-Process -Id $OpenConnection.OwningProcess | Select-Object ProcessName).ProcessName
    Write-Output "`r`nThe program $ProgramName is connected to the IP $($OpenConnection.RemoteAddress) on port $($OpenConnection.RemotePort)."
}
Read-Host "Press any key to exit"
