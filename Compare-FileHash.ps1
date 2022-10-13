<#

    .SYNOPSIS
    Validates file hash.

    .DESCRIPTION
    Validates that the hash of a file matches the expected hash.

    .PARAMETER FilePath
    (Mandatory) The full path to the file to be tested. Only one file per test is supported.

    .PARAMETER Algorithm
    (Optional) The algorithm for the test, SHA256 is default.
    Supports the following hashing algorithms: MD5, SHA1, SHA256, SHA384 and SHA512.

    .PARAMETER ExpectedHash
    (Mandatory) The expected hash of the file. 

    .INPUTS
    None, you cannot pipe objects.

    .OUTPUTS
    System.String
    The script returns a message whether the hashes match.

    .EXAMPLE
    .\Compare-FileHash.ps1 -FilePath C:\Hello World.jpg -Algorithm SHA1 -ExpectedHash DA39A3EE5E6B4B0D3255BFEF95601890AFD80709

    Script writer: Dima Bell

    E-mail: D1m419935@gmail.com

#>

Param(
    [parameter(Mandatory=$true, HelpMessage="Please specify the full file path.")]
    [validatescript({
        If (!($_ | Test-Path)) { Throw "The specified path does not exist." }
        If (!($_ | Test-Path -PathType Leaf)) { Throw "The specified path is not a file." }
        Return $true
    })]
    [System.IO.FileInfo]$FilePath,
    [parameter(Mandatory=$false, HelpMessage="Please select the algorithm: MD5, SHA1, SHA256, SHA384 or SHA512.")]
    [validateset('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
    [string]$Algorithm = 'SHA256',
    [parameter(Mandatory=$true, HelpMessage="Please supply the expected file hash.")]
    [ValidatePattern('^[a-z A-Z 0-9]{32,128}$', ErrorMessage="This is not a valid hash string either it is too short or too long. Only digits [0-9] and regular characters [a-z,A-Z] are allowed and the hash has to be at least 32 characters long and 128 characters long at most.")]
    [string]$ExpectedHash
)
$ExpectedHash.ToUpper()
$FilePathHash = ((Get-FileHash -Path $FilePath -Algorithm $Algorithm | Select-Object Hash).Hash).ToUpper()
$HashComparison = Compare-Object -ReferenceObject $ExpectedHash -DifferenceObject $FilePathHash -IncludeEqual
If ($HashComparison.SideIndicator -eq "==") {
    Write-Host "File hashes match!" -ForegroundColor Green
} Else {
    Write-Host "File hashes do not match! Files integrity may have been compromised!" -ForegroundColor Red
}
Read-Host "Press any key to exit"
