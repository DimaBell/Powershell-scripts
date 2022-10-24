<#    
    
    .SYNOPSIS
    Decrypt MD5 hashes.

    .DESCRIPTION
    This script is used to try and decrypt an MD5 hash value using the nitrxgen's site API (https://www.nitrxgen.net/md5db/)
    that has a database of over 1 trillion hash values and their decrypted strings.
    I do not own the website https://www.nitrxgen.net, all rights of the website are reserved to the website owners.

    .PARAMETER Hash
    (Mandatory) The MD5 hash string for the decryption attempt.

    .INPUTS
    None, you can not pipe objects.

    .OUTPUTS
    System.String
    The script returns a message containing the result of the decryption attempt.
    If the attempt was successful, the script will prompt the user with an option to save the decrypted hash in a txt file.
    
    .EXAMPLE
    MD5Decrypt.ps1 -Hash b10a8db164e0754105b7a99be72e3fe5

    ---------------------------------------------------------------

    Script writer: Dima Bell.

    E-mail: D1m419935@gmail.com 
#>

Param(
    [Parameter(Mandatory=$True)]
    [ValidatePattern('^[a-z A-Z 0-9]{32}$'<#, ErrorMessage="This is not a valid hash string, either it is too short or too long. Only digits [0-9] and regular characters [a-z,A-Z] are allowed and the hash has to be 32 characters long."#>)]
    [String]$Hash
)

$URL = "https://www.nitrxgen.net/md5db/"
$Final_URL = $URL + $Hash
$Response = Invoke-WebRequest -Uri $Final_URL
If ($Response.StatusCode -eq 200) {
    $DecryptedHash = $Response.Content
    If ($DecryptedHash -eq "") {
        Write-Host "The hash $Hash was not found in the database." -ForegroundColor Red
    } Else {
        Write-Host "The hash decryption was successful!" -ForegroundColor Green
        Write-Host "The decrypted value is: $DecryptedHash"
        $Anwser = Read-Host "Would you like to save the result to a text file? (Y)es / (N)o"
        Do {
            If (($Anwser.ToLower() -eq "y") -or ($Anwser.ToLower() -eq "yes")) {
                Write-Host "Saving result to $($env:USERPROFILE)\Desktop\MD5_Hash.txt"
                $Hash + " = " + $DecryptedHash | Tee-Object -FilePath "$($env:USERPROFILE)\Desktop\MD5_Hash.txt" -Append | Out-Null
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
} Else {
    Write-Host "The site did not return an OK (200) status code, something must have gone wrong. Please try again." -ForegroundColor Red
}
