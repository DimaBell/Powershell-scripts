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
   
   E-mail: D1m419935@gmail.com #>

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
$global:obj = $null
$global:WinRMStatus = $null
$global:RemoteRegStatus = $null
$global:RemoteRegStartType = $null

<# Start of functions #>

<# The next function confirms that the download link was specified and then confirms that it is valid. #>

function Get-WebStatusCode {
$global:DownloadLink = Read-Host "Please provide the download link of the software"
$DownloadLinkLength = $DownloadLink.Length
while ($DownloadLinkLength -eq "0") {
    $global:DownloadLink = Read-Host "A download link was not provided, please provide a link"
    $DownloadLinkLength = $DownloadLink.Length
}
$NewWebRequest = [System.Net.WebRequest]::Create($DownloadLink)
$WebResponse = $NewWebRequest.GetResponse()
$WebResponse.Close()
$global:StatusCode = [int]$WebResponse.StatusCode
while($StatusCode -ine "200") {
    Write-Output "The provided download link is not valid, please provide a valid link."
    Get-WebStatusCode
}
if ($StatusCode -eq "200") {
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

<# The next function will confirm that a local path to a directory to save the installation file to was specified, 
retrieve the free space of that drive based on the specified drive letter in the path,
test the path to determine whether it's existant and attempt to create a new path if needed. #>

function Get-FreeDriveSpace {
$global:MSIFilePath = Read-Host "Where would you like to save the .msi installation file? (Please provide the full path ending with a '\'"
$MSIFilePathLength = $MSIFilePath.Length
while ($MSIFilePathLength -eq "0") {
    $global:MSIFilePath = Read-Host "A path was not provided, please provide the full path"
    $MSIFilePathLength = $MSIFilePath.Length
}
$global:DriveLetter = $MSIFilePath.Substring(0,1)
$DriveSize = Get-PSDrive $DriveLetter
$FreeDriveSpace = $DriveSize.Free
$global:FreeSpaceGB = ($FreeDriveSpace /1Gb)
$IfMSIDirectoryExists = Test-Path -Path $MSIFilePath -ErrorAction Ignore
if ($IfMSIDirectoryExists -eq "True") {
    Write-Output "The directory already exists, no need to create it."
} else {
    do {
    $Anwser = Read-Host "The directory doesn't exist. Press 1 to create it or 2 to choose a different directory"
    if ($Anwser -eq "1") {
        $null = New-Item -ItemType Directory -Path $MSIFilePath -Force -ErrorAction Ignore
        $IfMSIDirectoryExists = Test-Path -Path $MSIFilePath -ErrorAction Ignore
        if ($IfMSIDirectoryExists -eq "True") {
            Write-Output "$([datetime]::Now) The directory was created successfully." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
        } else {
        Write-Output "Failed to create the specified directory."
        }
        } elseif ($Anwser -eq "2") {
           Get-FreeDriveSpace 
        } else {
            Write-Output "Invalid input."
        }
    } until ($IfMSIDirectoryExists -eq "True")
}
}

<# The next function will download the installation file based on the download link that was specified,
check if the file was downloaded successfully and retry to download if the download has failed.
Note that the script will be aborted if you would choose not to retry downloading the file. #>

function Check-IfFileDownloaded {
$null = certutil -f -split -urlcache $DownloadLink $SourceFile # Downloading the .msi installation file
$global:IsFileCreated = Test-Path -Path $SourceFile -ErrorAction Ignore
if ($IsFileCreated -eq "True") {
    $global:DownloadedSize = (((Get-Item $global:SourceFile).Length)/1mb)
    Write-Output "$([datetime]::Now) The download of $Software has completed, the file size is $global:DownloadedSize Mb." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
} else {
    do {
        $Anwser = Read-Host "The download of $Software has failed. Would you like to try downloading the file again? (y / n)"
        if ($Anwser -eq "y") {
            Check-IfFileDownloaded
            if ($IsFileCreated -eq  "True") {
                $global:DownloadedSize = (((Get-Item $global:SourceFile).Length)/1mb)
                Write-Output "$([datetime]::Now) The download of $Software has completed, the file size is $global:DownloadedSize Mb." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
            }
        } elseif ($Anwser -eq "n") {
            Write-Output "$([datetime]::Now) The download of $Software has failed, Aborting script." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
            exit
        } else {
            Write-Output "Invalid input."
        }
        } until ($IsFileCreated -eq "True" -or $Anwser -eq "n")
}
}

<# The next function will confirm that a path to a local directory to save the log file to was specified, 
check whether the specified directory is existant,
try to create the directory if needed and offer an option to specify a path to a different directory. #>

function Check-LogFilePath {
$global:LogFilePath = Read-Host "Where would you like to save the log file to? (Please provide the full path ending with a '\'"
$LogFilePathLength = $LogFilePath.Length
while ($LogFilePathLength -eq "0") {
    $LogFilePath = Read-Host "A path was not provided, please provide the full path ending with a '\'"
    $LogFilePathLength = $LogFilePath.Length
}
$IfLogDirectoryExists = Test-Path -Path $LogFilePath -ErrorAction Ignore
if ($IfLogDirectoryExists -eq "True") {
    Write-Output "The directory already exists, no need to create it."
} else {
    do {
    $Anwser = Read-Host "The directory doesn't exist. Press 1 to create it or 2 to choose a different directory"
    if ($Anwser -eq "1") {
        $null = New-Item -ItemType Directory -Path $LogFilePath -Force -ErrorAction Ignore
        $IfLogDirectoryExists = Test-Path -Path $LogFilePath -ErrorAction Ignore
        if ($IfLogDirectoryExists -eq "True") {
            Write-Output "$([datetime]::Now) The directory $LogFilePath was created successfully." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
        } else {
            Write-Output "Failed to create the specified directory."
        }
        } elseif ($Anwser -eq "2") {
            Check-LogFilePath
        } else {
            Write-Output "Invalid input."
        }
    } until ($IfLogDirectoryExists -eq "True")
}
}

<# The next function will confirm that a path of a given remote computer to copy the installation file to was specified, 
adjust the path to be appropriate for remote access,
check whether the specified directory is existant, 
try to create the directory if needed and offer an option to specify a path to a different directory. #>

function Check-DestinationFolder {
$DestinationFolder = Read-Host "Please specify the remote PC's full path of the directory you would like to copy the installation file to"
$DestinationFolderLength = $DestinationFolder.Length
while ($DestinationFolderLength -eq "0") {
    $DestinationFolder = Read-Host "A path was not provided, please provide the full path ending with a '\'"
    $DestinationFolderLength = $DestinationFolder.Length
}
$DestinationFolder = $DestinationFolder -replace ":", "$"
$global:FinalDestinationFolder = "\\" + $PC + "\" + $DestinationFolder
$global:IfDestinationExists = Test-Path -LiteralPath $global:FinalDestinationFolder -ErrorAction Ignore
if ($global:IfDestinationExists -ne "True") {
    Write-Output "The specified directory doesn't exist."
    do {
    $anwser = Read-Host "Press 1 to create the specified directory or 2 to specify a path to a different directory"
        if ($anwser -eq "1") {
            $null = New-Item -ItemType Directory -path $global:FinalDestinationFolder -ErrorAction Ignore -Force
            $global:IfDestinationExists = Test-Path -LiteralPath $global:FinalDestinationFolder -ErrorAction Ignore
            if ($global:IfDestinationExists -eq "True") {
                Write-Output "$([datetime]::Now) The directory $FinalDestinationFolder has been created." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
            } else {
                Write-Output "Failed to create a directory."
            }
        } elseif ($anwser -eq "2") {
            Check-DestinationFolder
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
and retry to copy the file until it was copied successfully. #>

function Copy-MSI {
Copy-Item -Path $SourceFile -Destination $FinalDestinationFolder -ErrorAction Ignore
Start-Sleep -Seconds 5
$IfFileCopied = Test-Path -Path "$FinalDestinationFolder$Software $SoftwareVersion.msi" -ErrorAction Ignore
if ($IfFileCopied -ne "True") {
    Write-Output "The installation file was not copied."
    do {
        $Anwser = Read-Host "Press 1 to try again or 2 to choose a different directory"
        if ($Anwser -eq "1") {
            Copy-Item -Path $SourceFile -Destination $FinalDestinationFolder -ErrorAction Ignore
            Start-Sleep -Seconds 5
            $IfFileCopied = Test-Path -Path "$FinalDestinationFolder$Software $SoftwareVersion.msi" -ErrorAction Ignore
            if ($IfFileCopied -eq "True") {
                Write-Output "The installation file was copied successfully to $FinalDestinationFolder."
                break
            } else {
                Write-Output "The installation file was not copied."
            }
        } elseif ($Anwser -eq "2") {
            Check-DestinationFolder
            Copy-Item -Path $SourceFile -Destination $FinalDestinationFolder -ErrorAction Ignore
            Start-Sleep -Seconds 5
            $IfFileCopied = Test-Path -Path "$FinalDestinationFolder$Software $SoftwareVersion.msi" -ErrorAction Ignore
            if ($IfFileCopied -eq "True") {
                Write-Output "The installation file was copied successfully to $FinalDestinationFolder."
                break
            } else {
                Write-Output "The installation file was not copied."
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
Invoke-WmiMethod -ComputerName $PC -Path win32_process -Name create -ArgumentList "powershell.exe -command msiexec.exe /i '$FinalDestinationFolder$Software $SoftwareVersion.msi' /qn /norestart" -ErrorAction Ignore > $null
Start-Sleep -Seconds 30
Get-InstalledSoftwareAndVersion
if ($SoftwareIsInstalled -eq "True" -and $SoftwareInstalledVersion -ge $SoftwareVersion) {
    Write-Output "$([datetime]::Now) Installation of $Software version $SoftwareVersion was successful on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
} else {
    do {
        $Anwser = Read-Host "The installation has failed or hasn't finished yet. Press 1 to wait 10 more seconds and check again, 2 to try installing again or 3 to abort installation on $PC"
        if ($Anwser -eq "1") {
            Write-Output "Waiting for 10 more sec..."
            Start-Sleep -Seconds 10
            Get-InstalledSoftwareAndVersion
            if ($SoftwareIsInstalled -eq "True") {
                Write-Output "$([datetime]::Now) Installation of $Software version $SoftwareVersion was successful on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                break
            }
        } elseif ($Anwser -eq "2") {
            $null = Invoke-WmiMethod -ComputerName $PC -Path win32_process -Name create -ArgumentList "powershell.exe -command msiexec.exe /i '$FinalDestinationFolder$Software $SoftwareVersion.msi' /qn /norestart" -ErrorAction Ignore
            Start-Sleep -Seconds 30
            Get-InstalledSoftwareAndVersion
            if ($SoftwareIsInstalled -eq "True") {
                Write-Output "$([datetime]::Now) Installation of $Software version $SoftwareVersion was successful on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                break
            }
        } elseif ($Anwser -eq "3") {
            Write-Output "$([datetime]::Now) Installation of $Software was aborted on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
            break
        } else {
            Write-Output "Invalid input"
        }
    } until ($SoftwareIsInstalled -eq "True")
}
Remove-Item -Path "$FinalDestinationFolder$Software $SoftwareVersion.msi" -Force -ErrorAction Ignore
}

<# The next function is similar to the "Install-MSI" function above
but is designed to perform an installation on a given remote computer 
that the given software is already installed on, 
check afterwards that the installation process of the inteded version of the software was successfully
installed and enter a loop similar to the loop of the "Install-MSI" function. #>

function Upgrade-MSI {
$null = Invoke-WmiMethod -ComputerName $PC -Path win32_process -Name create -ArgumentList "powershell.exe -command msiexec.exe /i '$FinalDestinationFolder$Software $SoftwareVersion.msi' /qn /norestart" -ErrorAction Ignore
Start-Sleep -Seconds 30
Get-InstalledSoftwareAndVersion
if ($SoftwareInstalledVersion -ge $SoftwareVersion) {
    Write-Output "$([datetime]::Now) Installation of $Software, version $SoftwareVersion was successful on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
} else {
    do {
        $Anwser = Read-Host "The installation has failed or hasn't finished yet. Press 1 to wait for 10 more seconds and check again, 2 to retry the installation or 3 to abort installation on $PC"
        if ($Anwser -eq "1") {
            Write-Output "Waiting for 10 more seconds..."
            Start-Sleep -Seconds 10
            Get-InstalledSoftwareAndVersion
            if ($SoftwareInstalledVersion -ge $SoftwareVersion) {
                Write-Output "$([datetime]::Now) Installation of $Software, version $SoftwareVersion was successful on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                break
            }
        } elseif ($Anwser -eq "2") {
            $null = Invoke-WmiMethod -ComputerName $PC -Path win32_process -Name create -ArgumentList "powershell.exe -command msiexec.exe /i '$FinalDestinationFolder$Software $SoftwareVersion.msi' /qn /norestart" -ErrorAction Ignore
            Start-Sleep -Seconds 30
            Get-InstalledSoftwareAndVersion
            if ($SoftwareInstalledVersion -ge $SoftwareVersion) {
                Write-Output "$([datetime]::Now) Installation of $Software, version $SoftwareVersion was successful on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                break
            }
        } elseif ($Anwser -eq "3") {
            Write-Output "$([datetime]::Now) Installation of $Software, version $SoftwareVersion was aborted on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
            break
        } else {
            Write-Output "Invalid input."
        }
    } until ($SoftwareInstalledVersion -ge $SoftwareVersion)
}
Remove-Item -Path "$FinalDestinationFolder$Software $SoftwareVersion.msi" -Force -ErrorAction Ignore
}

<# The next function will check the status and the startup type of the remote registry service on a given remote computer,
and try to change the startup type to automatic if it's not.
The remote registry service is needed to be running or at least set to start automatically 
so that the next function "Get-InstalledSoftwareAndVersion" will perform properly. #>

function Check-RemoteRegistry {
$global:RemoteRegStatus = Get-Service -ComputerName $PC -Name RemoteRegistry | select -ExpandProperty Status -ErrorAction Ignore
$global:RemoteRegStartType = Get-Service -ComputerName $PC -Name RemoteRegistry | Select -ExpandProperty starttype -ErrorAction Ignore
if ($RemoteRegStatus -ne "Running" -and $RemoteRegStartType -ne "Automatic") {
    Write-Output "The remote registry service is not running and its not set to automatic. Setting the service to start automatically."
    Invoke-WmiMethod -ComputerName $PC -Path win32_process -Name create -ArgumentList "powershell.exe -command Set-Service -Name RemoteRegistry -StartupType Automatic" > $null
    Start-Sleep -Seconds 15
    if ($global:RemoteRegStartType -ne "Automatic") {
        Write-Output "The remote registry service is not set to start automatically yet."
        do {
            $global:RemoteRegStartType = Get-Service -ComputerName $PC -Name RemoteRegistry | Select -ExpandProperty starttype -ErrorAction Ignore
            $Anwser = Read-Host "Press 1 to wait 5 more seconds and check again, 2 to try again or 3 to abort"
            if ($Anwser -eq "1") {
                Write-Output "Waiting for 5 more seconds and checking again..."
                Start-Sleep -Seconds 5
                $global:RemoteRegStartType = Get-Service -ComputerName $PC -Name RemoteRegistry | Select -ExpandProperty starttype -ErrorAction Ignore
                if ($global:RemoteRegStartType -eq "Automatic") {
                    Write-Output "The remote registry service has been set to start automatically."
                }
            } elseif ($Anwser -eq "2") {
                Write-Output "Retrying to set the service to start automatically."
                Invoke-WmiMethod -ComputerName $PC -Path win32_process -Name create -ArgumentList "powershell.exe -command Set-Service -Name RemoteRegistry -StartupType Automatic" > $null
                $global:RemoteRegStartType = Get-Service -ComputerName $PC -Name RemoteRegistry | Select -ExpandProperty starttype -ErrorAction Ignore
                if ($global:RemoteRegStartType -eq "Automatic") {
                    Write-Output "The remote registry service has been set to start automatically."
                }
            } elseif ($Anwser -eq "3") {
                Write-Output "Aborting attempt to set the service to start automatically on $PC."
                break
            } else {
                Write-Output "Invalid input."
            }
        } until ($global:RemoteRegStartType -eq "Automatic")
    } else {
            Write-Output "The remote registry service has been set to start automatically."
    }
} elseif ($RemoteRegStatus -ne "Running" -and $RemoteRegStartType -eq "Automatic") {
    Write-Output "The remote registry service is set to start automatically."
} elseif ($RemoteRegStatus -eq "Running" -and $RemoteRegStartType -eq "Automatic") {
    Write-Output "The remote registry service is running."
}
}

<# The next function will query the registry of a given remote computer
to determine whether the given software is already installed the version of it, if it is. #>

function Get-InstalledSoftwareAndVersion {
$UninstallKey=”SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall”
$reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey(‘LocalMachine’,$global:PC)
$regkey=$reg.OpenSubKey($UninstallKey)
$subkeys=$regkey.GetSubKeyNames()
foreach($key in $subkeys) {
    $thisKey=$UninstallKey+”\\”+$key
    $thisSubKey=$reg.OpenSubKey($thisKey)
    $obj = New-Object PSObject
    $obj | Add-Member -MemberType NoteProperty -Name “DisplayName” -Value $($thisSubKey.GetValue(“DisplayName”))
    $obj | Add-Member -MemberType NoteProperty -Name “DisplayVersion” -Value $($thisSubKey.GetValue(“DisplayVersion”))
    if (($obj).DisplayName -like "*$global:Software*") {
        $global:SoftwareIsInstalled = "True"
        $global:SoftwareInstalledVersion = $obj.DisplayVersion
        break   
    } else {
        $global:SoftwareIsInstalled = "False"
    }
}
}

<# End of functions. #>

$PCs = Get-ADComputer -Filter 'primaryGroupID -eq "515" -and enabled -eq "true"' -ErrorAction Ignore # Collecting all the computer names in the given domain.

# Start of the main script block #

if ($PCs -ne $null) {
$global:Software = Read-Host "Enter the name of the software (please make sure to provide the correct name)"
$SoftwareNameLength = $Software.Length

<# The next loop will confirm that the name of the software was specified. #>

while ($SoftwareNameLength -eq "0") {
    $global:Software = Read-Host "The name of the software was not provided, please enter it again"
    $SoftwareNameLength = $Software.Length
}

$SoftwareVersion = Read-Host "Enter the exact version of the software you would like to install"
$SoftwareVersionLength = $SoftwareVersion.Length

<# The next loop will confirm that the version of the software was specified. #>

while ($SoftwareVersionLength -eq "0") {
    $SoftwareVersion = Read-Host "The version of the software was not provided, please enter it again"
    $SoftwareVersionLength = $SoftwareVersion.Length
}

Check-LogFilePath
$FullLogFilePath = $LogFilePath + $Software + "_Installation_Log.txt" # Declaring the path to the local log file

Get-WebStatusCode
Get-MSIFileSize
Get-FreeDriveSpace

<# The next loop will confirm that there is enough free space on the chosen drive to download the installation file to. #>

while ($MSIFileSizeGb -ge $FreeSpaceGB) {
Write-Output "There is not enough space on drive $DriveLetter to download $Software to, please select a different drive or try to free some space on the drive."
Get-FreeDriveSpace
}

Write-Output "There is enough free space on drive $DriveLetter, proceeding to download."

$global:SourceFile = $MSIFilePath + $Software + " " + $SoftwareVersion + '.msi' # Defining the path to the local downloaded .msi installation file

Check-IfFileDownloaded

<# The next loop will cycle throught every remote computer and attempt to install the given software on each one. #>

foreach ($PC in $PCs.name) {
    $PCStatus = Test-Connection -ComputerName $PC -Count 1 -Quiet
    if ($PCStatus -eq "True") {
        Write-Output "$([datetime]::Now) $PC is online, checking the status of the remote registry service." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
        Check-RemoteRegistry
        if ($global:RemoteRegStartType -eq "Automatic") {
            Write-Output "Checking if the software is already installed and what is the installed version."
            Get-InstalledSoftwareAndVersion
            if ($SoftwareIsInstalled -eq "True") {
                Write-Output "$([datetime]::Now) $Software is already installed on $PC, version $SoftwareInstalledVersion" | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                if ($SoftwareInstalledVersion -ge $SoftwareVersion) {
                    Write-Output "$([datetime]::Now) The installed version of $Software is the latest, no need to upgrade." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                } else {
                    Write-Output "The installed version of $Software is not the latest."
                    Check-DestinationFolder
                    Copy-MSI
                    Upgrade-MSI
                }
            } else {
                Write-Output "$([datetime]::Now) $Software is not installed on $PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
                Check-DestinationFolder
                Copy-MSI
                Install-MSI
            }
        } else {
            Write-Output "$([datetime]::Now) The remote registry service is not set to automatic, cannot proceed to next steps of the script. Aborting check on $PC and checking next PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
        }
    } else {
        Write-Output "$([datetime]::Now) $PC is unreachable, checking next PC." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
    }   
}
} else {
    Write-Output "$([datetime]::Now) No domain computers found. Please make sure that this computer is part of the domain and that you have sufficient priviliges and run the script again." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
}
Remove-Item $global:SourceFile -Force -ErrorAction Ignore
Write-Output "$([datetime]::Now) The installation file has been deleted and the script has finished." | Tee-Object -Append $FullLogFilePath -ErrorAction Ignore
Read-Host "Press any key to exit"