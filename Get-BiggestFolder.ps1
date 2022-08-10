<#    

    This script is used to retrieve the biggest directory in a specified directory path.
    
    Example: .\Get-BiggestFolder.ps1 -Path 'C:\Program Files'

    Script writer: Dima Bell.

    E-mail: D1m419935@gmail.com 
#>

Param(
    [Parameter(Mandatory=$True)]
    [ValidateScript({
        If (!($_ | Test-Path)) { Throw "The specified path does not exist." }
        If (!($_ | Test-Path -PathType Container)) { Throw "The specified path is not a directory." }
        If (!($_ | Get-ChildItem -Directory -Force)) { Throw "The specified directory does not contain directories." }
        If (($_ | Get-ChildItem -Directory | Measure-Object | Select-Object Count).Count -eq 1) { Throw "There is only one directory in the specified path." }
        Return $True })]
    [System.IO.FileInfo]$Path
)

Function Get-Size {
    Param([String]$Path)
    [Math]::Round(((Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue -Force | Measure-Object -Property Length -Sum).Sum /1MB),2)
}

$Folders = Get-ChildItem -Path $Path -Exclude *.* -Force | Where-Object Mode -Like "d*****"
$BiggestFolder = $Folders[0]

ForEach ($Folder In $Folders) {
    $FolderSize = Get-Size $Folder
    $BiggestFolderSizeMB = Get-Size $BiggestFolder
    If ($FolderSize -gt $BiggestFolderSizeMB) {
        $BiggestFolder = $Folder
    }
    $BiggestFolderSizeMB = Get-Size $BiggestFolder
}

If ($BiggestFolderSizeMB -gt 1000) {
    $BiggestFolderSizeGB = [Math]::Round(($BiggestFolderSizeMB/1KB),2)
    Write-Output "The directory $($BiggestFolder.Name) is the biggest directory. It's size is $BiggestFolderSizeGB GB."
} Else {
    Write-Output "The directory $($BiggestFolder.Name) is the biggest directory. It's size is $BiggestFolderSizeMB MB."
}
