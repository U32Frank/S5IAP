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

Function Get-UserData{

$fullURi = "https://api.torn.com/user/" + $PlayerID + "?selections=&key=" + $global:YourAPIkey
$Playerdata = Invoke-WebRequest -Method get -uri $fullUri
$global:playerdata = ConvertFrom-Json $Playerdata

}

Function Write-PlayerDataToDB{

  $SQLParams = @{
  'Database' = 'S5IAP'
  'ServerInstance' =  's51apdb01.database.windows.net'
  'Username' = 'U32Frank'
  'Password' = 'Sp0ng3b0b!'
  'OutputSqlErrors' = $true
  }

  $script:YourData = Get-UserData -APIkey $global:YourAPIkey

  $Pname = $playerdata.name
  $Plevel = $playerdata.level
  $Page = $playerdata.age
  $pstatus = $playerdata.status
  $pPlayerId = $playerdata.player_id
  $pFactionID = $playerData.faction.faction_id
  $pPFactionIDName = $playerData.faction.faction_name
  $pAddedBy = $YourData.name

  $hatedstatus = Check-enemystatus -PlayerID $pPlayerId

  If ($hatedstatus -ne 'HATED')

  {

  $InsertParams = "INSERT INTO [S5IAP].[dbo].[Playerdata](Name,Level,Age,Status,PlayerID,FactionID,FactionName,addedby) VALUES ('$pname','$Plevel','$Page','$pstatus','$pPlayerId','$pFactionID','$pPFactionIDName','$pAddedBy')"
  Invoke-sqlcmd @SQLParams -Query $InsertParams
  }
 
}

Function Get-playerdata{

param ($PlayerID,$APIkey=$NULL)

if ($PlayerID -ne $null)
{
sleep 0.6
$fullURi = "https://api.torn.com/user/" + $PlayerID + "?selections=&key=" + $APIkey
$Playerdata = Invoke-WebRequest -Method get -uri $fullUri
$playerdata = ConvertFrom-Json $Playerdata

return $Playerdata
}
}


Function Get-FactionPlayerList{

param ($FactionID,$YourAPIkey)

$fullURi = "https://api.torn.com/faction/" + $FactionID + "?selections=&key=" + $YourAPIkey
write-host $fullURi4
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

Function Get-WholeFaction{

Param ($FactionID, $YourAPIkey)

$playerList = Get-FactionPlayerList -FactionID $FactionID -APIkey $YourAPIkey


foreach ($Player in $PlayerList)
{

$PlayerData =  Get-playerdata -PlayerID $player -APIkey $YourAPIkey
Write-PlayerDataToDB -playerdata $playerdata

sleep 0.6

}

}

Function Get-Target{

Param ($YourAPIkey)


$global:YourData = Get-Userdata -APIkey $YourAPIkey
  $SQLParams = @{
  'Database' = 'S5IAP'
  'ServerInstance' =  's51apdb01.database.windows.net'
  'Username' = 'U32Frank'
  'Password' = 'Sp0ng3b0b!'
  'OutputSqlErrors' = $true
  }
  
  [string]$age = $YourData.age
  [int]$Level = $YourData.level

$InsertParams = "SELECT * from Playerdata WHERE age < '$age'"
$Targets = Invoke-sqlcmd @SQLParams -Query $InsertParams
$Targets = $Targets | where level -lt $level
$global:PossTarget = get-random $Targets.PlayerID

$target = get-playerdata -APIkey $YourAPIkey -PlayerID $PossTarget
$targetURL= "https://www.torn.com/profiles.php?XID="+$target.player_id+"#/"


if ($target.status -eq 'Okay')
{
start $targetURL
}
Else { 
Get-Target
}
}

Function Check-enemystatus{

Param ($PlayerID)

$SQLParams = @{
  'Database' = 'S5IAP'
  'ServerInstance' =  's51apdb01.database.windows.net'
  'Username' = 'U32Frank'
  'Password' = 'Sp0ng3b0b!'
  'OutputSqlErrors' = $true
  }

  $YourData = Get-playerdata -APIkey $YourAPIkey

  $Pname = $playerdata.name
  $Plevel = $playerdata.level
  $Page = $playerdata.age
  $pstatus = $playerdata.status
  $pPlayerId = $playerdata.player_id
  $pFactionID = $playerData.faction.faction_id
  $pPFactionIDName = $playerData.faction.faction_name
  $pAddedBy = $YourData.name

  $InsertParams = "select PlayerID from Playerdata where PlayerID = '$pPlayerID'"
  
  $result = Invoke-sqlcmd @SQLParams -Query $InsertParams

  if ($result -eq $NULL)
  {
  return $result

  }Else {

  $Result = "HATED"

  return $result}

}

clear
get-APIkey

do {

$Selection = Read-Host -Prompt "What would you like to do?`n1. Get me a target `n2. Add someone to the shit list`n3. Add a faction to the shit list `n4. Quit! No one like a quiter"

If ($Selection -eq '1')
{

Get-target -YourAPIkey $YourAPIKey

}

If ($Selection -eq '2')
{
$PlayerID = Read-Host -Prompt 'Give me the player ID?'
$playerData = Get-playerdata -PlayerID $PlayerID -APIkey $YourAPIKey
Write-PlayerDataToDB -playerdata $playerData
Write-Host "Done. TMB will make sure the peasant pays for his sins."
}

If ($Selection -eq '3')
{

$FactionID = Read-Host -Prompt "I have to rate limit this due to torns shitty API. So this may take a while. Be patient `nGive me the faction ID?"
Get-WholeFaction -FactionID $FactionID -APIKey $YourAPIkey
Write-Host "Done. War has never been so much fun. MmMmmM so ruthless!"
}

} while ($Selection -ne 4)
