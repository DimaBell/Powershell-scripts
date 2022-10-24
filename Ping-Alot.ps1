<#

    .SYNOPSIS
    Ping multiple destinations.

    .DESCRIPTION
    The script checks connectivity with multiple destinations using the 'Test-Connection' Cmdlet
    based on a file containing a list of IP's or hostnames and outputs a summary of the results to a csv file
    in the same directory that contains the file with the list of the destinations for the test under the name 'PingResults.csv'.

    .PARAMETER List
    (Mandatory) The full path to the file containing the list of the IP's/hostnames for the test.

    .INPUTS
    None, you can not pipe objects.

    .OUTPUTS
    The script outputs a CSV file containing a summary of the results.

    .EXAMPLE
    .\Ping-Alot.ps1 -List C:\List.txt

    Script writer: Dima Bell

    E-mail: D1m419935@gmail.com

#>

Param(
    [parameter(Mandatory=$true, HelpMessage="Please specify the full file path of a list of IP's\computer names.")]
    [validatescript({
        If (!($_ | Test-Path)) { Throw "The specified path does not exist or it is not a valid path." }
        If (!($_ | Test-Path -PathType Leaf)) { Throw "The specified path is not a file." }
        If (!([bool](Get-Content -Path $_) -eq "True")) { Throw "The specified file has no content."}
        Return $true
    })]
    [System.IO.FileInfo]$List
)
$Computers = Get-Content -Path $List | Where-Object {$_ -ne ""}
$Results = @()
$Counter = 0
Foreach ($Computer in $Computers) {
        $Counter++
        Write-Progress -Activity "Pinging $Computer" -Status "$([math]::round((($Counter/$Computers.count)*100)))% completed" -PercentComplete ([math]::round((($Counter/$Computers.count)*100)))
        If ((Test-Connection -ComputerName $Computer -Count 3 -Quiet) -eq "True") {
            $PingResult = "Host is up"
        } Else {
            $PingResult = "Host is down or unreachable"
        }
        $Results += [pscustomobject]@{HostName = $Computer; PingStatus = $PingResult}
}
Write-Progress -Activity " " -Completed
$Results | Export-Csv -Path "$($List.DirectoryName)\PingResults.csv" -NoTypeInformation
Write-Host "The script has finished. A list of the results was saved to $($List.DirectoryName)\PingResults.csv."
Read-Host "Press any key to exit" 