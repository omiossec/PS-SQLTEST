Import-Module dbatools

$jsonPath =  join-path  -path $PSScriptRoot  -childpath 'sqlsrvlist.json' -Resolve

$exclude = @("model","master","msdb")


$servers = (Get-Content $jsonPath -Raw | ConvertFrom-Json) 


 

Describe "Backup Check" {

    context "Last Backup Check" {

        foreach($srv in $servers.SqlServers)
        {
            
            $results =  get-DbaLastBackup -ExcludeDatabase $exclude  -SqlInstance $srv.ServerName 
    
    
    
                 foreach($result in $results)
                {
    
                    It "$($Result.Database) on $($Result.SqlInstance) Backup Should be less than $($srv.TimeTocheck)h old" {
                        [datetime]$Result.LastFullBackup| Should BeGreaterThan (Get-Date).AddHours(-$srv.BackupFrequency)
                    }
    
                }
    
        }

    }

 
}


