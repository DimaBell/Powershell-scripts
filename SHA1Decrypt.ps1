<#

    .SYNOPSIS
    Decrypt SHA1 hashes.

    .DESCRIPTION
    This script is used to try and decrypt a SHA1 hash value using the webpage https://sha1.gromweb.com/?hash=.
    I do not own the website https://sha1.gromweb.com, all rights of the website are reserved to the website owners.

    .PARAMETER Hash
    (Mandatory) The SHA1 hash value for the decryption attempt.

    .INPUTS
    None, you can not pipe objects.
    
    .OUTPUTS
    System.String
    The script returns a message containing the result of the decryption attempt.
    If the attempt was successful, the script will prompt the user with an option to save the decrypted hash in a txt file.

    .EXAMPLE
    .\SHA1Decrypt.ps1 -Hash 0a4d55a8d778e5022fab701977c5d840bbc486d0

    ---------------------------------------------------------------
    
    Script writer: Dima Bell.

    E-mail: D1m419935@gmail.com

#>

Param(
    [Parameter(Mandatory=$True)]
    [ValidatePattern('^[a-z A-Z 0-9]{40}$', ErrorMessage="This is not a valid hash value, either it is too short or too long. Only digits [0-9] and regular characters [a-z,A-Z] are allowed and the hash has to be 40 characters long.")]
    [String]$Hash
)

$URL = "https://sha1.gromweb.com/?hash="
$Final_URL = $URL + $Hash
$Response = Invoke-WebRequest -Uri $Final_URL
If ($Response.StatusCode -eq 200) {
    If ($Response.Content.Contains("long-content string")) {
        $ResponseContent = $Response.Content.ToString().Split("`n")
        $DecryptedHash = ($ResponseContent.Split("`n") | Select-String -Pattern "long-content string").ToString().Split(">").Split("<")[2]
        If ($DecryptedHash -ne "") {
            Write-Host "Hash decryption was successful!" -ForegroundColor Green
            Write-Host "The decrypted hash is: $DecryptedHash"
            $Anwser = Read-Host "Would you like to save the result to a text file? (Y)es / (N)o"
            Do {
                If (($Anwser.ToLower() -eq "y") -or ($Anwser.ToLower() -eq "yes")) {
                    Write-Host "Saving result to $($env:USERPROFILE)\Desktop\SHA1_Hash.txt"
                    $Hash + " = " + $DecryptedHash | Tee-Object -FilePath "$($env:USERPROFILE)\Desktop\SHA1_Hash.txt" -Append | Out-Null
                    Read-Host "Press any key to exit"
                    Exit
                } Elseif (($Anwser.ToLower() -eq "n") -or ($Anwser.ToLower() -eq "no")) {
                    Read-Host "Press any key to exit"
                    Exit
                } Else {
                    Clear-Host
                    $Anwser = Read-Host "Invalid input. Please anwser (Y)es or (N)o"
                }
            } While (($Anwser.ToLower() -ne "yes") -or ($Anwser.ToLower() -ne "y") -or ($Anwser.ToLower() -ne "no")-or ($Anwser.ToLower() -ne "n"))
        }
    } Elseif ($Response.Content.Contains("Invalid hash format")) {
        Write-Host "Invalid hash format." -ForegroundColor Red
    } Elseif ($Response.Content.Contains("no reverse string was found")) {
        Write-Host "The hash $Hash was not found in the database." -ForegroundColor Red
    }
} Else {
    Write-Host "The site did not return an OK (200) status code." -ForegroundColor Red
}
