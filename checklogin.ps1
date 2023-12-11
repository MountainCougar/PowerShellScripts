Param(
    [array]$ServersToQuery = @("ENTER MACHINE NAME HERE"),
    [datetime]$starttime = (Get-Date).AddYears(-1) 
)

[array]$Output = @() # Initialize $Output as an empty array

foreach ($Server in $ServersToQuery) {
    $LogFilter = @{
        LogName = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'
        ID = 21, 23, 24, 25
        StartTime = $StartTime
    }

    $AllEntries = Get-WinEvent -FilterHashtable $LogFilter -ComputerName $Server

    foreach ($Entry in $AllEntries) {
        $xmlEntry = [xml]$Entry.ToXml()
        $obj = New-Object PSObject -Property @{
            TimeCreated = $Entry.TimeCreated
            User = $xmlEntry.Event.UserData.EventXML.User
            IPAddress = $xmlEntry.Event.UserData.EventXML.Address
            EventID = $xmlEntry.Event.System.EventID
            ServerName = $Server
        }
        $Output += $obj
    }
}

$FilteredOutput = $Output | Select-Object TimeCreated, User, ServerName, IPAddress, @{Name='Action'; Expression={
        switch ($_.EventID) {
            '21' {'logon'}
            '22' {'Shell start'}
            '23' {'logoff'}
            '24' {'disconnected'}
            '25' {'reconnection'}
        }
    }
}

$Date = (Get-Date -Format s) -replace ":", "."
$FilePath = "$env:USERPROFILE\Desktop\$Date`_RDP_Report.csv"
$FilteredOutput | Sort-Object TimeCreated | Export-Csv $FilePath -NoTypeInformation -Encoding utf8

Write-host "Writing File: $FilePath" -ForegroundColor Cyan
Write-host "Done!" -ForegroundColor Cyan

