<#    

    .SYNOPSIS
    Retrieve the biggest sub-directory in a path.

    .DESCRIPTION
    The script will compare the sizes of each sub-directory in the specified path
    and return the name of the biggest sub-directory and its size in MB (or in GB if the directory size is bigger than 1000 MB). 

    .PARAMETER Path
    (Mandatory) The full path of the directory that contains the sub-directories to be compared.

    .INPUTS
    None, you cannot pipe objects.

    .OUTPUTS
    System.String
    The script returns a message containing the name of the biggest sub-directory and its size.

    .EXAMPLE
    .\Get-BiggestFolder.ps1 -Path C:\Program Files

    Script writer: Dima Bell.

    E-mail: D1m419935@gmail.com 
#>

Param(
    [Parameter(Mandatory=$True)]
    [ValidateScript({
        If (!($_ | Test-Path)) { Throw "The specified path does not exist." }
        If (!($_ | Test-Path -PathType Container)) { Throw "The specified path is not a directory." }
        If (!($_ | Get-ChildItem -Directory -Force)) { Throw "The specified directory does not contain directories." }
        If (($_ | Get-ChildItem -Directory | Measure-Object | Select-Object Count).Count -lt 2) { Throw "There is less than two directories in the specified path." }
        Return $True })]
    [System.IO.FileInfo]$Path
)



Function Get-Size {
    [cmdletbinding()]
    param([parameter(ValueFromPipeline)]$Path)
    [Math]::Round(((Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue -Force | Measure-Object -Property Length -Sum).Sum /1MB),2)
}

$Folders = Get-ChildItem -Path $Path -Directory -Force
$BiggestFolder = $Folders[0]

ForEach ($Folder In $Folders) {
    $FolderSize = $Folder.FullName | Get-Size
    $BiggestFolderSizeMB = $BiggestFolder.FullName | Get-Size
    If ($FolderSize -gt $BiggestFolderSizeMB) {
        $BiggestFolder = $Folder
    }
    $BiggestFolderSizeMB = $BiggestFolder.FullName | Get-Size
}

If ($BiggestFolderSizeMB -gt 1000) {
    $BiggestFolderSizeGB = [Math]::Round(($BiggestFolderSizeMB/1KB),2)
    Write-Output "The directory $($BiggestFolder.Name) is the biggest directory. It's size is $BiggestFolderSizeGB GB."
} Else {
    Write-Output "The directory $($BiggestFolder.Name) is the biggest directory. It's size is $BiggestFolderSizeMB MB."
}
Read-Host "Press any key to exit"
