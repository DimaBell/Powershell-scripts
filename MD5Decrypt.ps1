<#    
    This script is used to try and decrypt an MD5 hash value using the nitrxgen's site API (https://www.nitrxgen.net/md5db/)
    
    that has a database of over 1 trillion hash values and their decrypted strings.

    The hash value parameter is mandatory and specified using the -Hash switch followed by the hash value itself.
    
    Example: .\MD5Decrypt.ps1 -Hash b10a8db164e0754105b7a99be72e3fe5

    I do not own the website https://www.nitrxgen.net, all rights of the website are reserved to the website owners.

    Script writer: Dima Bell.

    E-mail: D1m419935@gmail.com 
#>

Param(
    [Parameter(Mandatory=$True)]
    [ValidateScript({ If ($_.Length -ne 32) { Throw "You have to supply a valid MD5 hash value! (32 character string)" } $True })]
    [String]$Hash
)

Function Decrypt-MD5 {
    $URL = "https://www.nitrxgen.net/md5db/"
    $Final_URL = $URL + $Hash
    $Response = Invoke-WebRequest -Uri $Final_URL
    If ($Response.StatusCode -eq 200) {
        $DecryptedHash = $Response.Content
        If ($DecryptedHash -eq "") {
            Write-Host "Hash was not found in the database." -ForegroundColor Red
        } Else {
            Write-Host "Hash decryption was successful! `r`nThe decrypted value is:"
            Write-Host $DecryptedHash -ForegroundColor Green
            $Anwser = Read-Host "Would you like to save the result to a text file? (Y)es / (N)o"
            Do {
                If (($Anwser.ToLower() -eq "y") -or ($Anwser.ToLower() -eq "yes")) {
                    Write-Host "Saving result to $($env:USERPROFILE)\Desktop\MD5_Hash.txt"
                    $Result = $Hash + " = " + $DecryptedHash | Tee-Object -FilePath "$($env:USERPROFILE)\Desktop\MD5_Hash.txt" -Append
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
        Write-Host "The site did not return an OK (200) status code." -ForegroundColor Red
    }
}
Decrypt-MD5