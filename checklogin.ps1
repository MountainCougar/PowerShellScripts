#>This is a powershell script that give you a an .csv output for all user logins on specified machine/s

Param(
    [array]$ServersToQuery = @(#"ENTER MACHINE NAME HERE"),
    [datetime]$starttime = (Get-Date).AddYears(-1)
)

    foreach ($Server in $ServersToQuery) {

        $LogFilter = @{
            LogName = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'
            ID = 21, 23, 24, 25
            StartTime = $StartTime
            }

        $AllEntries = Get-WinEvent -FilterHashtable $LogFilter -ComputerName $Server

        $AllEntries | Foreach-Object{ 
            $entry = [xml]$_.ToXml()
            [array]$Output = New-Object PSObject -Property @{
                TimeCreated = $_.TimeCreated
                User = $entry.Event.UserData.EventXML.User
                IPAddress = $entry.Event.UserData.EventXML.Address
                EventID = $entry.Event.System.EventID
                ServerName = $Server
                }        
            } 

    }

    $FilteredOutput += $Output | Select-Object TimeCreated, User, ServerName, IPAddress, @{Name='Action';Expression={
                if ($_.EventID -eq '21'){"logon"}
                if ($_.EventID -eq '22'){"Shell start"}
                if ($_.EventID -eq '23'){"logoff"}
                if ($_.EventID -eq '24'){"disconnected"}
                if ($_.EventID -eq '25'){"reconnection"}
                }
            }

    $Date = (Get-Date -Format s) -replace ":", "."
    $FilePath = "$env:USERPROFILE\Desktop\$Date`_RDP_Report.csv"
    $FilteredOutput | Sort-Object TimeCreated | Export-Csv $FilePath -NoTypeInformation -Encoding utf8

Write-host "Writing File: $FilePath" -ForegroundColor Cyan
Write-host "Done!" -ForegroundColor Cyan 
#
