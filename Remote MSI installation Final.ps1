<# This script aims to automate installation of a given software on multiple computers in a given domain
   using the Get-ADComputer cmdlet which collects a list of the computers that are connected to the domain,
   however the script is very reliant on the users input to provide certain  
   values and to provide as exact values as possible
   for the script to perform properly.

   Note that this script is inteded to use towards remote computers that are running windows operating systems only.

   The script incorporates a few specifically written functions 
   to perform the installation with increased precision.
   A short description of each function is at the start of each one.

   This script is to be executed by a user of a given domain that has approprtiate credentials
   and best to be run as an administrator for the script to run properly.

   The script also creates a local text log file that collects certain
   outputs to gather a summarized report.
   
   Finally, the script will remove the downloaded installation file.
   


   Script writer: Dima Bell.
   
   E-mail: D1m419935@gmail.com 
#>

<# Declaration of global variables #>

$global:DownloadLink = $null
$global:StatusCode = $null
$global:MSIFileSizeGb = $null
$global:DriveLetter = $null
$global:MSIFilePath = $null
$global:FreeSpaceGB = $null
$global:IfDirectoryExists = $null
$global:IsFileCreated = $null
$global:Anwser = $null
$global:LogFilePath = $null
$global:PCs = $null
$global:PC = $null
$global:DestinationFolder = $null
$global:FinalDestinationFolder = $null
$global:IfFileCopied = $null
$global:IfDestinationExists = $null
$global:InstallationFile = $null
$global:DownloadedSize = $null
$global:SourceFile = $null
$global:SoftwareIsInstalled = $null
$global:SoftwareInstalledVersion = $null
$global:GetWinRMService = $null
$global:Software = $null

<# Start of functions #>

<# The next function will confirm that a download link was specified. #>

function Get-DownloadLink {
$global:DownloadLink = Read-Host "Please provide the download link of the software"
while ($global:DownloadLink.Length -eq "0") {
    $global:DownloadLink = Read-Host "A download link was not provided, please provide a link"
}
}

<# The next function checks the status code of the download link. #>

function Get-WebStatusCode {
try {
    $NewWebRequest = [System.Net.WebRequest]::Create($DownloadLink)
    $WebResponse = $NewWebRequest.GetResponse()
    $global:StatusCode = [int]$WebResponse.StatusCode
    $WebResponse.Close()
} catch {
    $Error1 = $_.Exception
    $Error2 = $_.Exception
    $Error3 = $_.Exception
    $Error4 = $_.Exception
}
if ($global:StatusCode -eq "200") {
    Write-Output "The download link is valid."
}
}

<# The next function will retrieve the size of the file to be downloaded based on the download link. #>

function Get-MSIFileSize {
$NewWebRequest = [System.Net.WebRequest]::Create($DownloadLink)
$WebResponse = $NewWebRequest.GetResponse()
$WebResponse.Close()
$MSIFileSize = $WebResponse.ContentLength
$global:MSIFileSizeGb = ($MSIFileSize /1Gb)
$global:MSIFileSizeMb = ($MSIFileSize /1Mb)
}

<# The next function will confirm that a path to a local directory to save the installation file to was specified,
test the path to determine whether it's existant and check if the directory is writeable if it does already exist.
Finally the function removes the created test file, if needed. #>

function Get-MSIFilePath {
$global:MSIFilePath = Read-Host "Where would you like to save the .msi installation file? (Please provide the full path ending with a '\'"
while ($global:MSIFilePath.Length -eq "0") {
    $global:MSIFilePath = Read-Host "A path was not provided, please provide the full path"
}
$global:IfMSIDirectoryExists = Test-Path -LiteralPath $MSIFilePath -ErrorAction Ignore
if ($global:IfMSIDirectoryExists -eq "True") {
    $NewTestPath = New-Item -Path $MSIFilePath -Name msifiletest -ItemType File -ErrorAction Ignore
    try {
        $IfPathWriteable = Test-Path -Path $NewTestPath.FullName -ErrorAction Ignore
    } catch {
        $Error1 = $_.Exception
    }
    while ($IfPathWriteable -eq $null -and $global:IfMSIDirectoryExists -eq "True") {
        Write-Output "The specified directory is not writeable."
        $global:MSIFilePath = Read-Host "Where would you like to save the .msi installation file? (Please provide the full path ending with a '\'"
        while ($global:MSIFilePath.Length -eq "0") {
            $global:MSIFilePath = Read-Host "A path was not provided, please provide the full path"
        }
        $global:IfMSIDirectoryExists = Test-Path -LiteralPath $MSIFilePath -ErrorAction Ignore
        $NewTestPath = New-Item -Path $MSIFilePath -Name msifiletest -ItemType File -ErrorAction Ignore
        try {
            $IfPathWriteable = Test-Path -Path $NewTestPath.FullName -ErrorAction Ignore
        } catch {
            $Error1 = $_.Exception
        }
    }
    if ([bool]$NewTestPath.FullName -eq "True") {
        Remove-Item -Path $NewTestPath.FullName -Force -ErrorAction Ignore > $null
    }
}
}

<# The next function will inform the user whether the path that was specified in the "Get-MSIFilePath" function
is existant or not, and will offer the user to create it or to choose a different path if not.
Finally the function will determine the free space in GB on that drive according to the drive letter specified in the path. #>

function Get-FreeDriveSpace {
if ($global:IfMSIDirectoryExists -eq "True") {
    Write-Output "The directory already exists, no need to create it."
} else {
    do {
    $global:IfMSIDirectoryExists = Test-Path -LiteralPath $global:MSIFilePath -ErrorAction Ignore
    $Anwser = Read-Host "The directory doesn't exist. Press 1 to create it or 2 to choose a different directory"
    if ($Anwser -eq "1") {
        New-Item -ItemType Directory -Path $global:MSIFilePath -Force -ErrorAction Ignore > $null
        $global:IfMSIDirectoryExists = Test-Path -LiteralPath $global:MSIFilePath -ErrorAction Ignore
        if ($global:IfMSIDirectoryExists -eq "True") {
            Write-Output "$([datetime]::Now) The directory $global:MSIFilePath was created successfully." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
        } else {
            Write-Output "Failed to create the specified directory."
        }
        } elseif ($Anwser -eq "2") {
            Get-MSIFilePath
            if ($global:IfMSIDirectoryExists -eq "True") {
                Write-Output "The directory already exists, no need to create it."
            }
        } else {
            Write-Output "Invalid input."
        }
    } until ($global:IfMSIDirectoryExists -eq "True")
}
$global:DriveLetter = $MSIFilePath.Substring(0,1)
$DriveSize = Get-PSDrive $DriveLetter -ErrorAction Ignore
$FreeDriveSpace = $DriveSize.Free
$global:FreeSpaceGB = ($FreeDriveSpace /1Gb)
}

<# The next function will download the installation file based on the download link that was specified,
check if the file was downloaded successfully and retry to download if the download has failed.
Note that the script will be aborted if you would choose not to retry downloading the installation file. #>

function Check-IfFileDownloaded {
Write-Output "Downloading $Software..."
Start-BitsTransfer -Source $DownloadLink -Destination $SourceFile -ErrorAction Ignore # Downloading the .msi installation file
$global:IsFileCreated = Test-Path -Path $SourceFile -ErrorAction Ignore
if ($IsFileCreated -eq "True") {
    $global:DownloadedSize = (((Get-Item $global:SourceFile).Length)/1mb)
    Write-Output "$([datetime]::Now) The download of $Software has completed, the file size is $global:DownloadedSize Mb." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
} else {
    do { 
        $Anwser = Read-Host "The download of $Software has failed. Would you like to try downloading the file again? (y / n)"
        if ($Anwser -eq "y") {
            Write-Output "Downloading $Software..."
            Start-BitsTransfer -Source $DownloadLink -Destination $SourceFile -ErrorAction Ignore
            $global:IsFileCreated = Test-Path -Path $SourceFile -ErrorAction Ignore
            if ($IsFileCreated -eq "True") {
                $global:DownloadedSize = (((Get-Item $global:SourceFile).Length)/1mb)
                Write-Output "$([datetime]::Now) The download of $Software has completed, the file size is $global:DownloadedSize Mb." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                break
            }
        } elseif ($Anwser -eq "n") {
            Write-Output "$([datetime]::Now) The download of $Software has been aborted. Cannot continue with script execution, aborting script." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
            exit
        } else {
            Write-Output "Invalid input."
        }
    } until ($IsFileCreated -eq "True")
}
}

<# The next function will confirm that a path to a local directory to save the log file to was specified,
test the path to determine whether the specified directory is existant and check if the directory is writeable if it does already exist.
Finally the function removes the created test file, if needed. #>

function Get-LogFilePath {
$global:LogFilePath = Read-Host "Where would you like to save the log file to? (Please provide the full path ending with a '\'"
while ($global:LogFilePath.Length -eq "0") {
    $global:LogFilePath = Read-Host "A path was not provided, please provide the full path ending with a '\'"
}
$global:IfLogDirectoryExists = Test-Path -LiteralPath $LogFilePath -ErrorAction Ignore
if ($global:IfLogDirectoryExists -eq "True") {
    $NewTestPath1 = New-Item -Path $LogFilePath -Name logfiletest -ItemType File -ErrorAction Ignore
    try {
        $IfPathWriteable1 = Test-Path -Path $NewTestPath1.FullName -ErrorAction Ignore
    } catch {
        $Error2 = $_.Exception
    }
    while ($IfPathWriteable1 -eq $null -and $global:IfLogDirectoryExists -eq "True") {
        Write-Output "The specified directory is not writeable."
        $global:LogFilePath = Read-Host "Where would you like to save the log file to? (Please provide the full path ending with a '\'"
        while ($global:LogFilePath.Length -eq "0") {
            $global:LogFilePath = Read-Host "A path was not provided, please provide the full path ending with a '\'"
        }
        $global:IfLogDirectoryExists = Test-Path -LiteralPath $LogFilePath -ErrorAction Ignore
        $NewTestPath1 = New-Item -Path $LogFilePath -Name logfiletest -ItemType File -ErrorAction Ignore
        try {
            $IfPathWriteable1 = Test-Path -Path $NewTestPath1.FullName -ErrorAction Ignore
        } catch {
            $Error2 = $_.Exception
        }
    }
    if ([bool]$NewTestPath1.FullName -eq "True") {
        Remove-Item -Path $NewTestPath1.FullName -Force -ErrorAction Ignore > $null
    }
}
}

<# The next function will try to create the directory that was specified in the "Get-LogFilePat" function if needed
and offer the user an option to specify a path to a different directory. #>

function Check-LogFilePath {
if ($global:IfLogDirectoryExists -eq "True") {
    Write-Output "The directory already exists, no need to create it."
} else {
    do {
    $Anwser = Read-Host "The directory doesn't exist. Press 1 to create it or 2 to choose a different directory"
    if ($Anwser -eq "1") {
        New-Item -ItemType Directory -Path $global:LogFilePath -Force -ErrorAction Ignore > $null
        $global:IfLogDirectoryExists = Test-Path -Path $global:LogFilePath -ErrorAction Ignore
        if ($global:IfLogDirectoryExists -eq "True") {
            Write-Output "$([datetime]::Now) The directory $global:LogFilePath was created successfully." #| Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
        } else {
            Write-Output "Failed to create the specified directory."
        }
        } elseif ($Anwser -eq "2") {
            Get-LogFilePath
            if ($global:IfLogDirectoryExists -eq "True") {
                Write-Output "The directory already exists, no need to create it."
            }
        } else {
            Write-Output "Invalid input."
        }
    } until ($IfLogDirectoryExists -eq "True")
}
}

<# The next function will confirm that a path to a directory of a given remote computer was specified,
adjust the path to be appropriate for remote access, test the path to determine whether it's existant
and check if the directory is writable if it does already exist.
Finally the function removes the created test file, if needed.  #>

function Get-DestinationFolder {
$DestinationFolder = Read-Host "Please specify the remote PC's full path of the directory you would like to copy the installation file to"
while ($DestinationFolder.Length -eq "0") {
    $DestinationFolder = Read-Host "A path was not provided, please provide the full path ending with a '\'"
}
$DestinationFolder = $DestinationFolder -replace ":", "$"
$global:FinalDestinationFolder = "\\" + $PC + "\" + $DestinationFolder
$global:IfDestinationExists = Test-Path -LiteralPath $global:FinalDestinationFolder -ErrorAction Ignore
if ($global:IfDestinationExists -eq "True") {
    $NewTestPath2 = New-Item -Path $FinalDestinationFolder -Name msifiletest -ItemType File -ErrorAction Ignore
    try {
        $IfPathWriteable2 = Test-Path -Path $NewTestPath2.FullName -ErrorAction Ignore
    } catch {
        $Error3 = $_.Exception
    }
    while ($IfPathWriteable2 -eq $null -and $global:IfDestinationExists -eq "True") {
        Write-Output "The specified directory is not writeable."
        $DestinationFolder = Read-Host "Please specify the remote PC's full path of the directory you would like to copy the installation file to"
        while ($DestinationFolder.Length -eq "0") {
            $DestinationFolder = Read-Host "A path was not provided, please provide the full path ending with a '\'"
        }
        $DestinationFolder = $DestinationFolder -replace ":", "$"
        $global:FinalDestinationFolder = "\\" + $PC + "\" + $DestinationFolder
        $global:IfDestinationExists = Test-Path -LiteralPath $global:FinalDestinationFolder -ErrorAction Ignore
        $NewTestPath2 = New-Item -Path $FinalDestinationFolder -Name msifiletest -ItemType File -ErrorAction Ignore
        try {
            $IfPathWriteable2 = Test-Path -Path $NewTestPath2.FullName -ErrorAction Ignore
        } catch {
            $Error3 = $_.Exception
        }
    }
    if ([bool]$NewTestPath2.FullName -eq "True") {
        Remove-Item -Path $NewTestPath2.FullName -Force -ErrorAction Ignore > $null
    }
}
}

<# The next function will try to create the directory that was specified in the "Get-DestinationFolder" function 
if needed and offer the user an option to specify a path to a different directory. #>

function Check-DestinationFolder {
if ($global:IfDestinationExists -ne "True") {
    Write-Output "The specified directory doesn't exist."
    do {
        $anwser = Read-Host "Press 1 to create the specified directory or 2 to specify a path to a different directory"
        if ($anwser -eq "1") {
            New-Item -ItemType Directory -path $global:FinalDestinationFolder -ErrorAction Ignore -Force > $null
            $global:IfDestinationExists = Test-Path -LiteralPath $global:FinalDestinationFolder -ErrorAction Ignore
            if ($global:IfDestinationExists -eq "True") {
                Write-Output "$([datetime]::Now) The directory $FinalDestinationFolder has been created." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
            } else {
                Write-Output "Failed to create a directory."
            }
        } elseif ($anwser -eq "2") {
            Get-DestinationFolder
        } else {
            Write-Output "Invalid input."
        }
    } until ($IfDestinationExists -eq "True")
} else {
    Write-Output "The directory already exists, no need to create it."
}
}

<# The next function will copy the installation file to a given remote computer,
check whether the file was copied successfully
and offer the user to try copying the file again or to choose a different directory if not. #>

function Copy-MSI {
Copy-Item -Path $SourceFile -Destination $FinalDestinationFolder -ErrorAction Ignore > $null
Start-Sleep -Seconds 5
$IfFileCopied = Test-Path -Path "$FinalDestinationFolder$Software $SoftwareVersion.msi" -ErrorAction Ignore
if ($IfFileCopied -ne "True") {
    do {
        $Anwser = Read-Host "The installation file was not copied. Press 1 to try again or 2 to choose a different directory"
        if ($Anwser -eq "1") {
            Copy-Item -Path $SourceFile -Destination $FinalDestinationFolder -ErrorAction Ignore > $null
            Start-Sleep -Seconds 5
            $IfFileCopied = Test-Path -Path "$FinalDestinationFolder$Software $SoftwareVersion.msi" -ErrorAction Ignore
            if ($IfFileCopied -eq "True") {
                Write-Output "The installation file was copied successfully to $FinalDestinationFolder."
                break
            }
        } elseif ($Anwser -eq "2") {
            Get-DestinationFolder
            Check-DestinationFolder
            Copy-Item -Path $SourceFile -Destination $FinalDestinationFolder -ErrorAction Ignore > $null
            Start-Sleep -Seconds 5
            $IfFileCopied = Test-Path -Path "$FinalDestinationFolder$Software $SoftwareVersion.msi" -ErrorAction Ignore
            if ($IfFileCopied -eq "True") {
                Write-Output "The installation file was copied successfully to $FinalDestinationFolder."
                break
            }
        } else {
            Write-Output "Invalid input."
        }
    } until ($IfFileCopied -eq "True")
} else {
    Write-Output "The installation file was copied successfully to $FinalDestinationFolder."
}
}

<# The next function will execute a command to perform an installation of the software on a given remote computer that the software is not installed on,
execute another function to determine whether the software was installed successfully and the version of the software that was installed (if it was installed successfully)
and check if the version of the software that was installed is the same version that was specified by the user that executes the script.
If the installation process is to initially fail, the function will then enter a loop and offer three options until the installation is successful or aborted by the user:
1) Wait for 10 more seconds (to allow the installation to finalize) and check again if the installation was successful.
2) Retry to perform the installation again and check again if the installation was successful.
3) Abort the installation on the given computer and proceed the next computer in the list.
Finally the function will remove the installation file from the given remote computer before proceeding to the next one.  #>

function Install-MSI {
Write-Output "$([datetime]::Now) Performing installation of $Software on $PC" | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
Invoke-WmiMethod -ComputerName $PC -Path win32_process -Name create -ArgumentList "powershell.exe -command msiexec.exe /i '$FinalDestinationFolder$Software $SoftwareVersion.msi' /qn /norestart" -ErrorAction Ignore > $null
Start-Sleep -Seconds 30
Get-InstalledSoftwareAndVersion
if ($global:SoftwareIsInstalled -eq "True" -and $global:SoftwareInstalledVersion -ge $SoftwareVersion) {
    Write-Output "$([datetime]::Now) Installation of $Software version $SoftwareVersion was successful on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
} else {
    do {
        $Anwser = Read-Host "The installation has failed or hasn't finished yet. Press 1 to wait 10 more seconds and check again, 2 to try installing again or 3 to abort installation on $PC"
        if ($Anwser -eq "1") {
            Write-Output "Waiting for 10 more sec..."
            Start-Sleep -Seconds 10
            Get-InstalledSoftwareAndVersion
            if ($global:SoftwareIsInstalled -eq "True") {
                Write-Output "$([datetime]::Now) Installation of $Software version $SoftwareVersion was successful on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                break
            }
        } elseif ($Anwser -eq "2") {
            Invoke-WmiMethod -ComputerName $PC -Path win32_process -Name create -ArgumentList "powershell.exe -command msiexec.exe /i '$FinalDestinationFolder$Software $SoftwareVersion.msi' /qn /norestart" -ErrorAction Ignore > $null
            Start-Sleep -Seconds 30
            Get-InstalledSoftwareAndVersion
            if ($global:SoftwareIsInstalled -eq "True") {
                Write-Output "$([datetime]::Now) Installation of $Software version $SoftwareVersion was successful on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                break
            }
        } elseif ($Anwser -eq "3") {
            Write-Output "$([datetime]::Now) Installation of $Software was aborted on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
            break
        } else {
            Write-Output "Invalid input"
        }
    } until ($global:SoftwareIsInstalled -eq "True")
}
Remove-Item -Path "$FinalDestinationFolder$Software $SoftwareVersion.msi" -Force -ErrorAction Ignore > $null
}

<# The next function is similar to the "Install-MSI" function above
but is designed to perform an installation on a given remote computer 
that the given software is already installed on, 
check afterwards that the installation process of the inteded version of the software was successfully
installed and enter a loop similar to the loop of the "Install-MSI" function. #>

function Upgrade-MSI {
Write-Output "$([datetime]::Now) Performing installation of $Software on $PC" | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
Invoke-WmiMethod -ComputerName $PC -Path win32_process -Name create -ArgumentList "powershell.exe -command msiexec.exe /i '$FinalDestinationFolder$Software $SoftwareVersion.msi' /qn /norestart" -ErrorAction Ignore > $null
Start-Sleep -Seconds 30
Get-InstalledSoftwareAndVersion
if ($global:SoftwareInstalledVersion -ge $SoftwareVersion) {
    Write-Output "$([datetime]::Now) Installation of $Software, version $SoftwareVersion was successful on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
} else {
    do {
        $Anwser = Read-Host "The installation has failed or hasn't finished yet. Press 1 to wait for 10 more seconds and check again, 2 to retry the installation or 3 to abort installation on $PC"
        if ($Anwser -eq "1") {
            Write-Output "Waiting for 10 more seconds..."
            Start-Sleep -Seconds 10
            Get-InstalledSoftwareAndVersion
            if ($global:SoftwareInstalledVersion -ge $SoftwareVersion) {
                Write-Output "$([datetime]::Now) Installation of $Software, version $SoftwareVersion was successful on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                break
            }
        } elseif ($Anwser -eq "2") {
            Invoke-WmiMethod -ComputerName $PC -Path win32_process -Name create -ArgumentList "powershell.exe -command msiexec.exe /i '$FinalDestinationFolder$Software $SoftwareVersion.msi' /qn /norestart" -ErrorAction Ignore > $null
            Start-Sleep -Seconds 30
            Get-InstalledSoftwareAndVersion
            if ($global:SoftwareInstalledVersion -ge $SoftwareVersion) {
                Write-Output "$([datetime]::Now) Installation of $Software, version $SoftwareVersion was successful on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                break
            }
        } elseif ($Anwser -eq "3") {
            Write-Output "$([datetime]::Now) Installation of $Software, version $SoftwareVersion was aborted on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
            break
        } else {
            Write-Output "Invalid input."
        }
    } until ($global:SoftwareInstalledVersion -ge $SoftwareVersion)
}
Remove-Item -Path "$FinalDestinationFolder$Software $SoftwareVersion.msi" -Force -ErrorAction Ignore > $null
}

<# The next function will check the status and the startup type of the WinRM service on a given remote computer,
and try to change the startup type to "Automatic" and the status to "Running" if they're not.
The WinRM service is needed to be running on the remote system
so that the next function "Get-InstalledSoftwareAndVersion" will perform properly. #>

function Enable-WinRM {
    $global:GetWinRMService = Get-Service -Name WinRM -ComputerName $PC -ErrorAction Ignore | Select-Object Status, StartType
    if ($global:GetWinRMService.StartType -eq "Automatic" -and $global:GetWinRMService.Status -eq "Running") {
        Write-Output "The WinRM service is up and running on $PC."
    } elseif ($global:GetWinRMService.StartType -eq "Automatic" -and $global:GetWinRMService.Status -eq "Stopped") {
        do {
            $global:GetWinRMService = Get-Service -Name WinRM -ComputerName $PC -ErrorAction Ignore | Select-Object Status
            $Anwser = Read-Host "The WinRM service is not running. Press 1 to try to start the service or 2 to abort check on $PC and move on the the next PC"
            if ($Anwser -eq "1") {
                Set-Service -Name WinRM -ComputerName $PC -Status Running > $null
                Start-Sleep -Seconds 5
                $global:GetWinRMService = Get-Service -Name WinRM -ComputerName $PC -ErrorAction Ignore | Select-Object Status
                if ($global:GetWinRMService.Status -eq "Running") {
                    Write-Output "The WinRM service has been started."
                } else {
                    Write-Output "Failed to start the WinRM service."
                }
            } elseif ($Anwser -eq "2") {
                Write-Output "Aborting check of WinRM service on $PC and moving on to next PC."
                break
            } else {
                Write-Output "Invalid input."
            }
        } until ($global:GetWinRMService.Status -eq "Running")
    } elseif ($global:GetWinRMService.StartType -ne "Automatic" -and $global:GetWinRMService.Status -ne "Running") {
        do {
            $global:GetWinRMService = Get-Service -Name WinRM -ComputerName $PC -ErrorAction Ignore | Select-Object Status, StartType
            $Anwser2 = Read-Host "The WinRM service on $PC is disabled and not running. Press 1 to try enable and start the service or 2 to abort check on $PC and move on the the next PC"
            if ($Anwser2 -eq "1") {
                Set-Service -Name WinRM -ComputerName $PC -StartupType Automatic > $null
                Set-Service -Name WinRM -ComputerName $PC -Status Running > $null
                $global:GetWinRMService = Get-Service -Name WinRM -ComputerName $PC -ErrorAction Ignore | Select-Object Status, StartType
                if ($global:GetWinRMService.StartType -eq "Automatic" -and $global:GetWinRMService.Status -eq "Running") {
                    Write-Output "The WinRM service has been enabled and started."
                } else {
                    do {
                    $Anwser3 = Read-Host "Failed to enable and start the WinRM service. Would you like to try running the 'Enable-PSRemoting' command on the target system? (Y/N)"
                    if ($Anwser3 -eq "Y") {
                        Invoke-WmiMethod -ComputerName $PC -Path win32_process -Name create -ArgumentList "powershell.exe -command Enable-PSRemoting -SkipNetworkProfileCheck -Force" -ErrorAction Ignore -InformationAction Ignore > $null
                        Start-Sleep -Seconds 5
                        $global:GetWinRMService = Get-Service -Name WinRM -ComputerName $PC -ErrorAction Ignore | Select-Object Status, StartType
                        if ($global:GetWinRMService.StartType -eq "Automatic" -and $global:GetWinRMService.Status -eq "Running") {
                            Write-Output "The WinRM service has been enabled and started."
                        }
                    } elseif ($Anwser3 -eq "N") {
                        Write-Output "Aborting check of WinRM service on $PC and moving on to next PC."
                        break
                    } else {
                        Write-Output "Invalid input."
                    }
                    } until ($global:GetWinRMService.StartType -eq "Automatic" -and $global:GetWinRMService.Status -eq "Running")
                }
            } elseif ($Anwser2 -eq "2") {
                Write-Output "Aborting check of WinRM service on $PC and moving on to next PC."
                break
            } else {
                Write-Output "Invalid input."
            }
        } until ($global:GetWinRMService.StartType -eq "Automatic" -and $global:GetWinRMService.Status -eq "Running")
    }
}

<# The next function will query the registry of a given remote computer
to determine whether the given software is already installed and the version of it, if it is. #>

function Get-InstalledSoftwareAndVersion {
    try {
        $reg = Invoke-Command -ComputerName $PC -ScriptBlock {Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'} -ErrorAction Ignore
        $regSoftware = $reg | Where-Object {$_.DisplayName -like "*$Software*"} | Select-Object DisplayName, DisplayVersion
    } catch {
        $Error1 = $_.Exception
    }
    if (!($reg)) {
        try {
            $reg = Invoke-Command -ComputerName $PC -ScriptBlock {Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'} -ErrorAction Ignore
            $regSoftware = $reg | Where-Object {$_.DisplayName -like "*$Software*"} | Select-Object DisplayName, DisplayVersion
        } catch {
            $Error2 = $_.Exception
        }
    }
    if ("$regSoftware.DisplayName" -like "*$Software*") {
        $global:SoftwareIsInstalled = "True"
        $global:SoftwareInstalledVersion = $regSoftware.DisplayVersion
    } else {
        $global:SoftwareIsInstalled = "False"
    }
}

<# Start of the main script block #>

$PCs = Get-ADComputer -Filter 'primaryGroupID -eq "515" -and enabled -eq "true"' -ErrorAction Ignore # Collecting all the computer names in the given domain.

if ($PCs -ne $null) {
$global:Software = Read-Host "Enter the name of the software (please make sure to provide the correct name)"

<# The next loop will confirm that the name of the software was specified. #>

while ($global:Software.Length -eq "0") {
    $global:Software = Read-Host "The name of the software was not provided, please enter it again"
}

$SoftwareVersion = Read-Host "Enter the exact version of the software you would like to install"

<# The next loop will confirm that the version of the software was specified. #>

while ($SoftwareVersion.Length -eq "0") {
    $SoftwareVersion = Read-Host "The version of the software was not provided, please enter it again"
}

Get-LogFilePath
Check-LogFilePath
$FullLogFilePath = $LogFilePath + $Software + "_Installation_Log.txt" # Declaring the path to the local log file

Get-DownloadLink
Get-WebStatusCode

<# The next loop will inform the user that the download link is not valid and will to specify it again. #>

while($global:StatusCode -ine "200") {
    Write-Output "The provided download link is not valid."
    Get-DownloadLink
    Get-WebStatusCode
}

Get-MSIFileSize
Get-MSIFilePath
Get-FreeDriveSpace

<# The next loop will confirm that there is enough free space on the chosen drive to download the installation file to. #>

if ($MSIFileSizeGb -lt $FreeSpaceGB) {
    Write-Output "There is enough free space on drive $DriveLetter, proceeding to download."
} else {
    while ($MSIFileSizeGb -ge $FreeSpaceGB) {
        Write-Output "There is not enough space on drive $DriveLetter to download $Software to, please select a different drive or try to free some space on the drive."
        Get-MSIFilePath
        Get-FreeDriveSpace
    }
}

$global:SourceFile = $MSIFilePath + $Software + " " + $SoftwareVersion + '.msi' # Defining the path to the local downloaded .msi installation file

Check-IfFileDownloaded

<# The next loop will cycle through every remote computer from the list and attempt to install the given software on each one. #>

foreach ($PC in $PCs.name) {
    $PCStatus = Test-Connection -ComputerName $PC -Count 2 -Quiet
    if ($PCStatus -eq "True") {
        Write-Output "$([datetime]::Now) $PC is online, checking the status of the WinRM service." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
        Enable-WinRM
        if ($global:GetWinRMService.StartType -eq "Automatic" -and $global:GetWinRMService.Status -eq "Running") {
            Write-Output "Checking if the software is already installed and what is the installed version."
            Get-InstalledSoftwareAndVersion
            if ($global:SoftwareIsInstalled -eq "True") {
                Write-Output "$([datetime]::Now) $Software is already installed on $PC, version $global:SoftwareInstalledVersion." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                if ($global:SoftwareInstalledVersion -ge $SoftwareVersion) {
                    Write-Output "$([datetime]::Now) The installed version of $Software on $PC is the latest, no need to upgrade." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                } else {
                    Write-Output "The installed version of $Software on $PC is not the latest."
                    Get-DestinationFolder
                    Check-DestinationFolder
                    Copy-MSI
                    Upgrade-MSI
                }
            } else {
                Write-Output "$([datetime]::Now) $Software is not installed on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                Get-DestinationFolder
                Check-DestinationFolder
                Copy-MSI
                Install-MSI
            }
        } else {
            Write-Output "$([datetime]::Now) The WinRM service is not set to automatic, cannot proceed to next steps of the script. Aborting check on $PC and checking next PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
        }
    } else {
        Write-Output "$([datetime]::Now) $PC is unreachable, checking next PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
    }   
}
} else {
    Write-Output "$([datetime]::Now) No domain computers found. Please make sure that this computer is part of the domain and that you have sufficient priviliges and run the script again." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
}
Remove-Item $global:SourceFile -Force -ErrorAction Ignore > $null
Write-Output "$([datetime]::Now) The installation file has been deleted and the script has finished. The log file has been saved to $FullLogFilePath." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
Read-Host "Press any key to exit"
