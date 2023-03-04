$Global:PCExists = $Null
$Creds = Get-Credential
Function GetPCName {
    Do {
        $PCName = Read-Host "`nPlease enter the computer name or number"
        $Global:PCExists = @(Get-ADComputer -Filter * -Properties IPv4Address | Where-Object Name -Like "*$PCName*")
            Switch ($Global:PCExists.Count) {
                0 { Write-Host "`nCould not find the computer $PCName." -ForegroundColor Red }
                1 {
                    Write-Host "`nThe computer $($Global:PCExists.Name) IP: $($Global:PCExists.IPv4Address) matches the search."
                    Do {
                        $UserInput1 = Read-Host "`nIs this the correct computer? (Y/N)"
                        If ($UserInput1 -eq "N" -or $UserInput1 -eq "n") {
                            Write-Host "`nCould not find the computer you were looking for, try searching again." -ForegroundColor Yellow
                        } Elseif ($UserInput1 -eq "Y" -or $UserInput1 -eq "y") {
                            Write-Host "`nProceeding to the next step..." -ForegroundColor Green
                        } Else {
                            Write-Host "`nWrong input." -ForegroundColor Red
                        }
                    } Until ($UserInput1 -eq "N" -or $UserInput1 -eq "n" -or $UserInput1 -eq "Y" -or $UserInput1 -eq "y")
                }
                ({$_ -gt 1 -and $_ -le 5}) { Write-Output "`nA few computers were found that matched the search:`n"; $Global:PCExists.Foreach({"$($_.Name)  IP: $($_.IPv4Address)"}) }
                ({$_ -ge 6}) { Write-Output "`nFound more than 5 PC's, please refine the search." }
            }
    } Until (($Global:PCExists.Count -eq 1) -and ($UserInput1 -eq "Y" -or $UserInput1 -eq "y"))
}

Function Start-WinRM {
    Write-Output "`nChecking the Status of the WinRM service on $($Global:PCExists.Name)."
    Do {
        $WinRMInfo = Get-Service WinRM -ComputerName $Global:PCExists.Name
        If ($WinRMInfo.Status -ne "Running") {
            $UserInput2 = Read-Host "`nThe WinRM service is not running on the computer $($Global:PCExists.Name). Would you like to attempt to start the service? (Y/N)"
            If ($UserInput2 -eq "Y" -or $UserInput2 -eq "y") {
                Try {
                    Set-Service WinRM -ComputerName $Global:PCExists.Name -StartupType Automatic -Status Running
                } Catch {
                    $Error[0].Exception.Message
                }
            } Else {
                Write-Output "`nWrong input."
            }
        } Elseif ($WinRMInfo.Status -eq "Running") {
            Write-Host "`nThe WinRM service is running." -ForegroundColor Green
        }
    } Until (($WinRMInfo.Status -eq "Running") -or ($UserInput2 -eq "N" -or $UserInput2 -eq "n"))
}

GetPCName

If (Test-Connection -ComputerName $Global:PCExists.ipv4address -Count 2 -Quiet) {
    Start-WinRM
    Do {
        $UserInput2 = Read-Host "`nThe computer $($Global:PCExists.Name) is online, would you like to restart it now? (Y/N)"
        If ($UserInput2 -eq "Y" -or $UserInput2 -eq "y") {
            Try {
                Restart-Computer -ComputerName $Global:PCExists.Name -Credential $Creds -Force -Wait -Delay 2 -Timeout 300 -Protocol WSMan
            } Catch {
                Write-Warning $Error[0].Exception.Message
            }
            $LastBootTime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem -ComputerName $Global:PCExists.Name).LastBootUpTime
            If ($LastBootTime.Minutes -lt 10) {
                Write-Output "`nThe computer $($Global:PCExists.Name) has been restarted succesfully."
            } Else {
                Write-Output "`nThe computer $($Global:PCExists.Name) was not restarted. The computer uptime is $($LastBootTime.Days) days, $($LastBootTime.Hours) hours and $($LastBootTime.Minutes) minutes."
            }
        } Elseif ($UserInput2 -eq "N" -or $UserInput2 -eq "n") {
            Write-Output "`nAborting operation."
            Break
        } Else {
            Write-Output "`nWrong input."
        }
    } Until ($UserInput2 -eq "N" -or $UserInput2 -eq "n" -or $LastBootTime.Minutes -lt 10)
} Else {
    Write-Output "`nThe computer $($Global:PCExists.Name) is offline. Can't restart the computer if it's off."
}
Clear-Variable -Scope Global -Name PCExists
Read-Host "`nThe script is done, press any key to exit"