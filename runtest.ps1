$Date = Get-Date -Format yyyMMdd
$ReportFolder = 'C:\dashboard\'
Push-Location $ReportFolder
$XML = $ReportFolder + "SqlServerData_$Date.xml"
$script = 'C:\scripts\sqlbck.test.ps1'
Invoke-Pester -Script $Script -OutputFile $xml -OutputFormat NUnitXml


& C:\scripts\reportunit.exe $ReportFolder