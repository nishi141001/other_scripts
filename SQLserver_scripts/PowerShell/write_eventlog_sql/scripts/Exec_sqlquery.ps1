$Server = "YUUSUKE-VAIO\INS_NISHI2016"
$Database = "sales"
$User = "sa"
$Password = "system"

$Hostname = hostname
$Log_Level = "ERROR"

$Scriptpath = Split-Path $myInvocation.Mycommand.Path -Parent
$Scriptpath = Split-Path -Parent $Scriptpath
$Input_count = $Scriptpath + "\scripts\Sqlquery_count.sql"
$Input_detail = $Scriptpath +  "\scripts\Sqlquery_detail.sql"
$Output_detail = $Scriptpath + "\output\Sqlquery_detail.log"

# タイムスタンプはyyyy MMM dd HH:mm:ss形式
$us = New-Object system.globalization.cultureinfo("en-US")
$Date = (Get-date).ToString("yyyy MMM dd HH:mm:ss", $us)
$Message_header = "XXXXX"
$Message_body = "target_count is "

# 対象のカウント
$Resultset = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Username $User -Password $Password -InputFile $Input_count 

$Message = $Message_header + " " + $Date + " " + $Hostname + " " + $Log_Level + " " + $Message_body + [string]$Resultset['Count']

# 条件に応じてイベントログに出力
if ($Resultset['Count'] -eq 0 ){
  Write-Eventlog -Logname Application -Source Temp_alert -EntryType Information -EventId 9999 -Message $Message
}else{
  $Resultset = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Username $User -Password $Password -InputFile $Input_detail
  $Resultset | Out-File $Output_detail
  Foreach ($item in $Resultset){
    $items += ',' + $item['JOB_ID']
  }
$Message = $Message + $items
Write-Eventlog -Logname Application -Source Temp_alert -EntryType Warning -EventId 9999 -Message $Message
}

