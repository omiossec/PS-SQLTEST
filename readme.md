**PS SQL TEST**
====================

A few weeks ago I had to resolve several problems.

* Make sure that all user database on all SqlServer was backup correctly while having different schedule
* Create a dashboard for the team, so we can correct a problem when it occurs
* Archive test results for future compliance audits.
* The tools should be simple enough so a non PowerShell user could add or remove a server
* The tools should be extensible so the team can add some tests without rebuilding the tool


I did not want to put the SQL server Name and other data inside the code. A junior admin with no PowerShell background should be able to read and update the list.
More I need something flexible. I need to add properties to an object without changing the code.
I need to associate properties with the list. One server can perform a backup every day and on other only once a week. In the same way, I want to be able to add some tests without rethinks the script.

**JSON**
Json is a human-readable format popular for exchanging data across different systems. It can serialize complex data such array and hashmap.

**PESTER**
Pester is The PowerShell Unit Testing tool. It's the perfect tool not only to test your code but also to perform tests against an infrastructure. Pester is useful to test several points in an infrastructure by asking some basic questions (like is the Database size Larger than 10Gb) and it can output the result on screen but also in different format

**DBATOOLS** (<https://dbatools.io/>)
Dbatool is an open source and powerful PowerShell modules with more than 300 commands for SQL Server administration and maintenance.

**How to start**
----------------

First, we need to build our Json file. Remember, The goal is to make a list of server readable and extensible.
We can use an array, in a Json document an array looks like:

```json
{
    "MyArray" : ["One", "Two"]
}
```

Json let you create an object with multiple Key/value pairs. Json object is surrounded by curly braces

```json
{
    "ServerName":"MyServer",
    "Localisation":"DC1"
}
```

Combined together, array and Json object let you create extensible list like this :

```json
{
    "SqlServer":  [
                     {
                             "ServerName":"MyServer",
                             "Localisation":"DC1"
                     },
                     {
                             "ServerName":"Srv02",
                             "Localisation":"DC1"
                     },
                    {
                             "ServerName":"Srv04",
                             "Localisation":"DC2"
                     }
                ]
}
```

If you remember I need to address the case when the backup occurs every day for some server and every week for other.
Translated into hour, it give  24h or 168h

```json
{
    "SqlServers":  [
                     {
                             "ServerName":"MyServer",
                             "BackupFrequency":24
                     },
                     {
                             "ServerName":"Srv02",
                             "BackupFrequency":24
                     },
                    {
                             "ServerName":"Srv04",
                             "BackupFrequency":168
                     }
                ]
}
```

You can add properties to server name (backup location, instance name). You can also add another array of objects.
Starting with PowerShell 3+ you can easaly manipulate Json data.

```PowerShell
$servers = (Get-Content "MyFile.json" -Raw | ConvertFrom-Json)

```

the result is a PSCustomObject. It's easy to browse this object.

```PowerShell
foreach($srv in $servers.SqlServers)
{
    write-host $srv.ServerName
}
```

With the server list and all the data, we can build the test script.

The goal is to make sure that all databases were backup according to the server's backup frequency.
[Dbatools](https://dbatools.io/) is a collection of more than 300 commands for SQL DBA.

The command [get-DbaLastBackup](https://dbatools.io/functions/get-dbalastbackup/) retrieves the date/time for the last known backups.
Comparing the last backup date from each database with the server's backup frequency is the test we can make. Before we need to exclude system database.

```PowerShell
$exclude = @("model","master","msdb")

foreach($srv in $servers.SqlServers)
{
    results =  get-DbaLastBackup -ExcludeDatabase $exclude  -SqlInstance $srv.nodename
    foreach($result in $results)
    {
        # Do the test on each database
    }
}
```

Pester is a PowerShell unit test tool. If you need more information about what is Pester and how to use it <https://github.com/pester/Pester>

A basic test in pester start with Describe Keyword. It creates a logical group of tests. I use also Context to group It tests as I may add some other tests later.

```PowerShell
$exclude = @("model","master","msdb")

Describe "Backup Check" {

    context "Last Backup Check" {
        foreach($srv in $servers.SqlServers)
        {
            results =  get-DbaLastBackup -ExcludeDatabase $exclude  -SqlInstance $srv.nodename
            foreach($result in $results)
            {
                    It "$($Result.Database) on $($Result.SqlInstance) Backup Should be less than $($srv.TimeTocheck)h old" {
                                [datetime]$Result.LastFullBackup| Should BeGreaterThan (Get-Date).AddHours(-$srv.TimeTocheck)
                        }
            }
        }
    }

}


```

For each databases on each servers we have an It block testing if the las backup reported by the server is compliant with the server frequency.
Alone this script will not create a Dashboard and it may be difficult to archive it for auditors.
Pester is able to export the result in a NUnitXML format in an external file.


```PowerShell
Invoke-Pester -Script pesterTest.ps1 -OutputFile result.xml -OutputFormat NUnitXml
```

This will be the archive file.

For dashboard, [ReportUnit](https://github.com/reportunit/reportunit) application creates HTML report from Nunit file.
Creating a report is simple, invoke reportunit.exe with the path of the HTML file you want to create for argument, make sure that the NUnit XML file is present inside the folder.

To put all things together :
sqlsrvlist.json : the json file with Sql Server data
sqlbck.test.ps1 : the Pester Test
runtest.ps1 : The tool to run the test and create the archive and the report


