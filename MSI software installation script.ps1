Write-Host "This script will install a software remotely on domain PC's using an .msi installation file and log all actions in a local log file."
Write-Host "Where would you like to save the log file to? (Please provide the full path ending with a '\'."
$LogFilePath = Read-Host
Write-Host "Where would you like to save the .msi installation file? (Please provide the full path ending with a '\'."
$SourceFileDestination = Read-Host
Write-Host "Enter the name of the software:"
$Software = Read-Host
$SourceFile = $SourceFileDestination + $Software +'.msi' # Defining the local path to the .msi installation file
Write-Host "Please provide the download link of the software:"
$DownloadLink = Read-Host
certutil -f -split -urlcache $DownloadLink $SourceFile # Downloading the .msi installation file
Start-Sleep -Seconds 30 # Allowing the download to complete
$PCs = Get-ADComputer -Filter 'primaryGroupID -eq "515" -and enabled -eq "true"' # Collecting all the computer names in the domain

foreach ($PC in $PCs.name)
{
 $PCStatus = Test-Connection -ComputerName $PC -Count 1 -Quiet  #Pinging each PC once to see if it's online
 if ($PCStatus -eq "True") 
 {
  Write-Output "$PC is online, checking if $Software is already installed."
  $Installed = [bool](Get-WmiObject -ComputerName "$PC" -Query "SELECT * FROM Win32_Product Where Name Like '%$Software%'") # Checking if the software is already installed on the PC and performing installation only if not.
  if ($Installed -eq "True")
  {
  Write-Output "$([datetime]::Now) $Software is already installed on $PC, checking next PC." | Out-File -Append -FilePath "$LogFilePath'$Software'_Installation_Log.txt"
  }
  else
  {
  Write-Output "$Software is not installed on $PC, performing installation."
  $DestinationFolder = "\\$PC\C$\Users\administrator\Appdata\Local\Temp\" #Defining the destination folder to copy the installation file to
  $InstallationFile = "\\$PC\C$\Users\administrator\Appdata\Local\Temp\$Software.msi" #Defining the path to the installation file
  Copy-Item -Path $SourceFile -Destination $DestinationFolder
  Start-Sleep -Seconds 5
  Invoke-WmiMethod -ComputerName $PC -Path win32_process -Name create -ArgumentList "powershell.exe -command msiexec.exe /i $InstallationFile /quiet" -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 30
  $Installed2 = [bool](Get-WmiObject -ComputerName "$PC" -Query "SELECT * FROM Win32_Product Where Name Like '%$Software%'") # Checking again if the software is installed, to determine if the installation was successful
  if ($Installed2 -eq "True")
  {
   Write-Output "$([datetime]::Now) Installation of $Software was successful on $PC." | Out-File -Append -FilePath "$LogFilePath'$Software'_Installation_Log.txt"
   Remove-Item -Path $InstallationFile -Force -erroraction SilentlyContinue #Removing the installation file from target PC
  }
  else
  {
   Write-Output "$([datetime]::Now) Installation of $Software on $PC has failed." | Out-File -Append -FilePath "$LogFilePath'$Software'_Installation_Log.txt"
   Remove-Item -Path $InstallationFile -Force -erroraction SilentlyContinue
  }
  }
 }
 else 
 {
  Write-Output "$([datetime]::Now) $PC is unreachable, checking next PC." | Out-File -Append -FilePath "$LogFilePath'$Software'_Installation_Log.txt"
 }
 }
Remove-Item $SourceFile
Read-Host "Script has finished, press any key to exit"