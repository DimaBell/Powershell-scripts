<#

    This script is used to try and decrypt a SHA1 hash using the webpage https://sha1.gromweb.com/?hash=.
    
    The hash value parameter is mandatory and specified with the -Hash switch followed by the hash value itself.

    Example: .\SHA1Decrypt.ps1 -Hash 0a4d55a8d778e5022fab701977c5d840bbc486d0

    I do not own the website https://sha1.gromweb.com, all rights of the website are reserved to the website owners.
    
    Script writer: Dima Bell.

    E-mail: D1m419935@gmail.com

#>

Param(
    [Parameter(Mandatory=$True)]
    [ValidateScript({ If ($_.Length -ne 40) { Throw "You have to supply a valid SHA-1 hash value! (40 character string)" } $True })]
    [String]$Hash
)

Function Decrypt-SHA1 {
    $URL = "https://sha1.gromweb.com/?hash="
    $Final_URL = $URL + $Hash
    $Response = Invoke-WebRequest -Uri $Final_URL
    If ($Response.StatusCode -eq 200) {
        If ($Response.Content.Contains("long-content string")) {
            $ResponseContent = $Response.Content.ToString().Split("`n")
            $DecryptedHash = ($ResponseContent.Split("`n") | Select-String -Pattern "long-content string").ToString().Split(">").Split("<")[2]
            If ($DecryptedHash -ne "") {
                Write-Host "Hash decryption was successful! `r`nThe decrypted hash is:"
                Write-Host $DecryptedHash -ForegroundColor Green
                $Anwser = Read-Host "Would you like to save the result to a text file? (Y)es / (N)o"
                Do {
                    If (($Anwser.ToLower() -eq "y") -or ($Anwser.ToLower() -eq "yes")) {
                        Write-Host "Saving result to $($env:USERPROFILE)\Desktop\SHA1_Hash.txt"
                        $Result = $Hash + " = " + $DecryptedHash | Tee-Object -FilePath "$($env:USERPROFILE)\Desktop\SHA1_Hash.txt" -Append
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
            Write-Host "The specified hash value was not found in the database." -ForegroundColor Red
        }
    } Else {
        Write-Host "The site did not return an OK (200) status code." -ForegroundColor Red
    }
}
Decrypt-SHA1