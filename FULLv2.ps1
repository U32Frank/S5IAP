Import-Module SqlServer

Function get-APIkey{
$DoesAPIexist = test-path -Path "C:\S5iaP\APIKey.txt"
sleep 0.5
if ($DoesAPIexist -eq $true) {
$global:YourAPIKey = ( Get-Content -Path "C:\S5iaP\APIKey.txt" )
} else {
$global:YourAPIkey = Read-Host -Prompt "I need your API key"
New-Item -Path 'C:\S5iaP\APIKey.txt' -ItemType File -Force | Out-Null
Add-Content C:\S5iaP\APIKey.txt $global:YourAPIkey | Out-Null
}
}

Function Get-PlayerData{

$fullURi = "https://api.torn.com/user/?selections=&key=" + $global:YourAPIkey
$Playerdata = Invoke-WebRequest -Method get -uri $fullUri
$global:PlayerData = ConvertFrom-Json $Playerdata

return

}

Function Write-PlayerDataToDB{

  param ($EnemyData)

  $SQLParams = @{
  'Database' = 'S5IAP'
  'ServerInstance' =  's51apdb01.database.windows.net'
  'Username' = 'U32Frank'
  'Password' = 'Sp0ng3b0b!'
  'OutputSqlErrors' = $true
  }
 
  $Pname = $EnemyData.name
  $Plevel = $EnemyData.level
  $Page = $EnemyData.age
  $pstatus = $EnemyData.status
  $pPlayerId = $EnemyData.player_id
  $pFactionID = $EnemyData.faction.faction_id
  $pPFactionIDName = $EnemyData.faction.faction_name
  $pAddedBy = $global:PlayerData.name

  $hatedstatus = Check-enemystatus -PlayerID $pPlayerId

  If ($hatedstatus -ne $TRUE)

  {
  $InsertParams = "INSERT INTO [S5IAP].[dbo].[Playerdata](Name,Level,Age,Status,PlayerID,FactionID,FactionName,addedby) VALUES ('$pname','$Plevel','$Page','$pstatus','$pPlayerId','$pFactionID','$pPFactionIDName','$pAddedBy')"
  Invoke-sqlcmd @SQLParams -Query $InsertParams
  }
 
}

Function Get-Enemydata{

param ($EnemyID)

$fullURi = "https://api.torn.com/user/" + $EnemyID + "?selections=&key=" + $global:YourAPIkey
$EnemyData = Invoke-WebRequest -Method get -uri $fullUri
$EnemyData = ConvertFrom-Json $EnemyData

return $EnemyData
}

Function Get-FactionPlayerList{

param ($FactionID)

$fullURi = "https://api.torn.com/faction/" + $FactionID + "?selections=&key=" + $global:YourAPIkey
$FactionData = Invoke-WebRequest -Method get -uri $fullUri
$FactionData = ConvertFrom-Json $FactionData

[string]$factiondatastr = $factiondata.members 

$factiondatastr = $factiondatastr.Replace('@{','')
$factiondatastr = $factiondatastr.Replace('=','')
$factiondatastr = $factiondatastr.Replace('}','')
$factiondatastr = $factiondatastr.Replace(' ','')

$MembersList = $factiondatastr.Split(';')

return $MembersList

}

Function Add-Faction {

param ($FactionID)

$FactionMemberList = Get-FactionPlayerList -FactionID $FactionID

foreach ($FactionMember in $FactionMemberList)
{

Write-PlayerDataToDB -EnemyData $FactionMember

}

}


Function Get-Target{

  $SQLParams = @{
  'Database' = 'S5IAP'
  'ServerInstance' =  's51apdb01.database.windows.net'
  'Username' = 'U32Frank'
  'Password' = 'Sp0ng3b0b!'
  'OutputSqlErrors' = $true
  }
  
  [string]$age = $global:PlayerData.age
  [int]$Level = $global:PlayerData.level

$InsertParams = "SELECT * from Playerdata WHERE age < '$age'"
$Targets = Invoke-sqlcmd @SQLParams -Query $InsertParams
$Targets = $Targets | where level -lt $level
$PossTarget = get-random $Targets.PlayerID


$target = get-Enemydata -APIkey $global:YourAPIkey -EnemyID $PossTarget 


$targetURL= "https://www.torn.com/profiles.php?XID="+$target.player_id+"#/"


if ($target.status -eq 'Okay')
{
start $targetURL
}
Else { 
write-host "The target was already down, try again"
}
}

Function Check-enemystatus{

Param ($EnemyID)

$Enemydata = Get-Enemydata -EnemyID $EnemyID

$SQLParams = @{
  'Database' = 'S5IAP'
  'ServerInstance' =  's51apdb01.database.windows.net'
  'Username' = 'U32Frank'
  'Password' = 'Sp0ng3b0b!'
  'OutputSqlErrors' = $true
  }

  $pPlayerId = $Enemydata.player_id

  $InsertParams = "select PlayerID from Playerdata where PlayerID =" + $pPlayerID
    
  $result = Invoke-sqlcmd @SQLParams -Query $InsertParams

  if ($result -eq $NULL)
  {

  $Result = $false

  return $result

  }Else {

  $Result = $true

  return $result}

}

clear
get-APIkey
Get-PlayerData

do {

$Selection = Read-Host -Prompt "What would you like to do?`n1. Get me a target `n2. Add someone to the shit list`n3. Add a faction to the shit list `n4. Quit! No one like a quiter"

If ($Selection -eq '1')
{

Get-target 

}

If ($Selection -eq '2')
{
$EnemyID = Read-Host -Prompt 'Give me the Enemys ID'

$EnemyData = get-Enemydata -enemyid $EnemyID
Write-PlayerDataToDB -EnemyData $EnemyData
Write-Host "Done. TMB will make sure the peasant pays for his sins."
}

If ($Selection -eq '3')
{
$FactionID = Read-Host -Prompt "I have to rate limit this due to torns shitty API. So this may take a while. Be patient `nGive me the faction ID?"
$EnemyList = Get-FactionPlayerList -factionID $factionID

foreach ($Enemy in $EnemyList)

{
sleep 0.6
$EnemyData = Get-Enemydata -EnemyID $Enemy
Write-PlayerDataToDB -EnemyData $Enemydata
}

Write-Host "Done. War has never been so much fun. MmMmmM so ruthless!"
}

} while ($Selection -ne 4)
