<#    

    This script is used to retrieve the biggest directory in a specified directory path.
    

    Script writer: Dima Bell.

    E-mail: D1m419935@gmail.com 
#>

$Path = Read-Host "Please enter the path to the directory"
$BiggestFolder = $null
$Folders = Get-ChildItem -Path $Path -Exclude *.* | Where-Object Mode -Like "d*****"

Function Get-Size {
    Param([string]$Path)
    [math]::Round(((Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum /1MB),2)
}

ForEach ($Folder In $Folders) {
    $FolderSize = Get-Size $Folder
    $BiggestFolderSizeMB = Get-Size $BiggestFolder
    If ($FolderSize -gt $BiggestFolderSizeMB) {
        $BiggestFolder = $Folder
    }
}

$BiggestFolderSizeMB = Get-Size $BiggestFolder
$BiggestFolderName = $BiggestFolder.Name

If ($BiggestFolderSizeMB -gt 1000) {
    $BiggestFolderSizeGB = [math]::Round(($BiggestFolderSizeMB/1KB),2)
    Write-Output "The Folder $BiggestFolderName is the biggest folder. It's size is $BiggestFolderSizeGB GB."
} Else {
    Write-Output "The Folder $BiggestFolderName is the biggest folder. It's size is $BiggestFolderSizeMB MB."
}