#------------------------------------------------------------------------------
# AI Bandit dynamic patrol creator v1 (2026-06-29)
# Reads in:
#	- waypoints from DayZ Editor object spawner JSON files
#	- item slot and loot data from text files with list of valid types
# Writes out:
#	- new dynamic groupLocation array to insert into DynamicAIB.json
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# global input folders/output files - update these paths if structure changed 
$inputPatrolFolder = ".\sourcePatrolFiles"
$inputItemsFolder = ".\slotItemLists"
$outputJsonFile = "NewGroupLocations.json"

#------------------------------------------------------------------------------
# global min/max for randoms - set dog or grenade chance to zero to skip those
$minItemCount = 7
$maxItemCount = 14
$minNpcCount = 1
$maxNpcCount = 2
$minRandomAccuracyPercent = 30
$maxRandomAccuracyPercent = 80
$minRandomGrenadeChancePercent = 2
$maxRandomGrenadeChancePercent = 6
$chanceDogPercent= 6
$chanceBanditFactionPercent = 60

#------------------------------------------------------------------------------
# optional switch makes TWO patrols from each file, with new rand values and flipped waypoints
$flippyDippy = $true

#------------------------------------------------------------------------------
# helper function to read random types, with optional percent blank
function Get-RandomItems([string]$File, [int]$Count, [int]$percentBlank = 0) {
    $blankCount = [math]::Round($Count * ($percentBlank / 100))
    $itemCount = $Count - $blankCount
    $results = @()
    $file = (Join-Path $inputItemsFolder $file)
    if ($itemCount -gt 0 -and (Test-Path $File)) {
        $lines = (Get-Content $File) | Where-Object { 
            # lines with "//" or "#" are treated as comments
            [string]::IsNullOrWhiteSpace($_) -eq $false -and $_.Trim() -notmatch '^(//|#)' 
		}
        if ($null -ne $lines -and $lines.Count -gt 0) {
            $results = @($lines | Get-Random -Count $itemCount)
		}
	}
    for ($i = 0; $i -lt $blankCount; $i++) {
        $results += ""
	}
    #Write-Host "(read $($lines.Count) items from $($File) and returned $($results.Count) items with $($blankCount) blanks)" -ForegroundColor Cyan
    return $results
}

#------------------------------------------------------------------------------
# start main routine - testing the input first
if (-Not (Test-Path $inputPatrolFolder )) {
    Write-Warning "Patrol source folder '$($inputPatrolFolder)' not found?!"
    exit
}
if (-Not (Test-Path $inputItemsFolder )) {
    Write-Warning "Items source folder '$($inputItemsFolder)' not found?!"
    exit
}
if ((@(Get-ChildItem -Path "$PWD\$inputItemsFolder" -Filter "*.txt" -File).Count) -lt 13){
    Write-Warning "Didn't find 13+ text files in '$($inputItemsFolder)'?!" 
    exit
}
if ((Test-Path $outputJsonFile) -and (Read-Host "Output file already exists ('$($outputJsonFile)'). Overwrite? (Y/N)" ) -notin 'Y','y') {
    Write-Warning "$($outputJsonFile) already exists and user didn't overwrite.."
    exit
}
$newGroups = @()

#------------------------------------------------------------------------------
# bump the max counts by one because of powershell's exclusive get-rand thing
$maxItemCount += 1
$maxNpcCount += 1
$maxRandomAccuracy += 1
$maxRandomGrenadeChance += 1

#------------------------------------------------------------------------------
# primary loop
$spawnerFiles = Get-ChildItem -Path $inputPatrolFolder -Filter "*.json"
Write-Host "Found $($spawnerFiles.Count) spawner files for waypoints. Flippy-dippy switch is $($flippyDippy.ToString().ToUpper())." -ForegroundColor Cyan
foreach ($file in $spawnerFiles) {
    
    # get waypoints from the DayZ Editor json spawner files in inputPatrolFolder
    $spawnerData = Get-Content $file.FullName -Raw | ConvertFrom-Json
    $waypoints = @()
    $objects = if ($null -ne $spawnerData.Objects) { $spawnerData.Objects } else { $spawnerData }
    foreach ($obj in $objects) {
        if ($null -ne $obj.pos -and $obj.pos.Count -ge 3) {$waypoints += "{0:F3} {1:F3} {2:F3}" -f $obj.pos[0], $obj.pos[1], $obj.pos[2]}
	}
    if ($waypoints.Count -eq 0) {
        Write-Host "Something wrong with $($file.Basename)?! No coords found were found..." -ForegroundColor Yellow
        continue
	}
	
    # generate static random values per group (including doggo type if we get one of those)
    if ((Get-Random 100) -lt $chanceBanditFactionPercent) {$randomFaction = "Bandits"} else {$randomFaction = "Guards"}
    $randomNpcCount = Get-Random -Minimum $minNpcCount -Maximum $maxNpcCount
    $randomAccuracy = Get-Random -Minimum $minRandomAccuracyPercent -Maximum $maxRandomAccuracyPercent
    If ($minRandomGrenadeChancePercent+$maxRandomGrenadeChancePercent -eq 0) {$randomGrenadeChance = Get-Random -Minimum $minRandomGrenadeChancePercent -Maximum $maxRandomGrenadeChancePercent} else {$randomGrenadeChance = 0}
    if ($chanceDogPercent-gt 0 -and (Get-Random 100) -le $chanceDogPercent) {$randomDoggo = Get-Random -Minimum 1 -Maximum 36} else {$randomDoggo = 0}
	
    # use random percentages, item files for each slot, and JSON waypoints to create a patrol
    $newGroups += [ordered]@{
        name = $file.BaseName
        faction = $randomFaction
        waypoints = $waypoints
        npcclasses = Get-RandomItems "npcclasses.txt" $randomNpcCount
        accuracy = $randomAccuracy
        grenadechance = $randomGrenadeChance
        dog = $randomDoggo
        weaponpool = Get-RandomItems "weaponpool.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount)
        npcproperties = [ordered]@{
            #get random items for each set in each group, with percent blank chance for 'optional' slots
            headgear = Get-RandomItems "headgear.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount) 50
            masks = Get-RandomItems "masks.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount) 80
            vests = Get-RandomItems "vests.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount) 50
            backpacks = Get-RandomItems "backpacks.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount) 60
            bodywear = Get-RandomItems "bodywear.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount)
            belts = Get-RandomItems "belts.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount) 70
            pants = Get-RandomItems "pants.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount)
            shoes = Get-RandomItems "shoes.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount)
            gloves = Get-RandomItems "gloves.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount) 40
            armband = Get-RandomItems "armband.txt" 1
            # get up to 3*max item numbers for loot - AIB picks randomly from the pool anyway so bigger is better
            loot = Get-RandomItems "loot.txt" (Get-Random -Minimum $minItemCount -Maximum ($maxItemCount * 3))
		}
	}
	
    # secondary loop if flippyDippy is true
    If($flippyDippy){
		# flip the faction second time
		if ($randomFaction -eq "Guards") {$randomFaction = "Bandits"} else {$randomFaction = "Guards"}
		$randomNpcCount = Get-Random -Minimum $minNpcCount -Maximum $maxNpcCount
		$randomAccuracy = Get-Random -Minimum $minRandomAccuracyPercent -Maximum $maxRandomAccuracyPercent
        $randomGrenadeChance = Get-Random -Minimum $minRandomGrenadeChancePercent -Maximum $maxRandomGrenadeChancePercent
		if ($chanceDogPercent-gt 0 -and (Get-Random 100) -lt $chanceDogPercent) {$randomDoggo = Get-Random -Minimum 1 -Maximum 36} else {$randomDoggo = 0}
        
		# flip waypoints too
		$newGroups += [ordered]@{
			name = "$($file.BaseName)2"
			faction = $randomFaction
            waypoints = $waypoints[-1..-($waypoints.Count)]
			npcclasses = Get-RandomItems "npcclasses.txt" $randomNpcCount
			accuracy = $randomAccuracy
			grenadechance = $randomGrenadeChance
			dog = $randomDoggo
			weaponpool = Get-RandomItems "weaponpool.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount)
			npcproperties = [ordered]@{
				#get random items for each set in each group, with percent blank chance for 'optional' slots
                headgear = Get-RandomItems "headgear.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount) 50
                masks = Get-RandomItems "masks.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount) 80
                vests = Get-RandomItems "vests.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount) 50
                backpacks = Get-RandomItems "backpacks.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount) 60
                bodywear = Get-RandomItems "bodywear.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount)
                belts = Get-RandomItems "belts.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount) 70
                pants = Get-RandomItems "pants.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount)
                shoes = Get-RandomItems "shoes.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount)
                gloves = Get-RandomItems "gloves.txt" (Get-Random -Minimum $minItemCount -Maximum $maxItemCount) 40
                armband = Get-RandomItems "armband.txt" 1
                # get up to 3*max item numbers for loot - AIB picks randomly from the pool anyway so bigger is better
                loot = Get-RandomItems "loot.txt" (Get-Random -Minimum $minItemCount -Maximum ($maxItemCount * 3))
			}
		}
	}
}

#------------------------------------------------------------------------------
# loop complete!
Write-Progress -Activity "Generating Patrol" -Completed
Write-Host "Created $($newGroups.Count) dynamic patrol groups in '$($outputJsonFile)'." -ForegroundColor Cyan
$newGroups | ConvertTo-Json -Depth 10 | Set-Content $outputJsonFile