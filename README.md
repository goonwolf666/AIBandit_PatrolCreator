# AI Bandit Patrol Creator

**Version:** 1.0 (2026-06-29)

A PowerShell script that generates randomized dynamic patrol groups for the [Hunterz's AI Bandit mod for DayZ](https://steamcommunity.com/sharedfiles/filedetails/?id=3628006769).

## Human-drafted instructions:
- Download this repo and save the files somewhere convenient
- Use [Dab's DayZ Edtior mod](https://steamcommunity.com/sharedfiles/filedetails/?id=2250764298) to place items as waypoints and export as JSON object-spawner file. Do this many times over for each patrol, naming each exported JSON with your preferred patrol name.
- Copy your exported patrol JSON files into the \sourcePatrolFiles folder. _(I have left some Namalsk patrol files as examples, delete those before running the script with your patrols)_
- The \slotItemLists folder stores a collection of text files named for each bandit loadout slot, the list of AI Bandit NPC types, the list of weaponpool items and a random list of global loot. _(You can edit, add, remove or comment things in the text files as you like. These have Namalsk *and* DayZ Expansion types in there which are easy to remove)_
- Open the AIB_PatrolCreator.ps1 script file for editing to adjust the randomisation limits, dog and grenade settings (etc.). _(Note there is also a "Flip" switch that will make a *second* patrol for each JSON file with reversed waypoints, re-randomised loadouts and opposite bandit class)_
- Run the script to read the waypoints from each file, randomly select from the loot/weapons/NPC (etc.) and create a procedurally-generated patrol JSON file in the same folder
- Review that output and carefully insert this array into your server profile's `\AI_Bandits\DynamicAIB.json` file. _(*Don't* include the leading "[" or trailing "]" characters from the output file. *Do* copy from the first "{" to last "}" character and paste into your DynamicAIB file after your last GroupLocation (right before the SniperLocations line)_
- Check your JSON file(s) at https://jsonlint.com/ to confirm the structure is correct. _(Syntax errors, stray commas or unclosed brackets are the most common cause of problems)_

---

#Github AI slop overview:

The AI Bandit Patrol Creator automates the creation of complex patrol group configurations by:
- Extracting waypoint coordinates from DayZ Editor spawner JSON files
- Randomizing patrol parameters (accuracy, grenade chance, faction, NPC count)
- Populating NPC equipment slots with items from curated item pool lists
- Optionally generating mirrored patrols with reversed waypoints and randomized values
- Outputting valid JSON ready for integration into your DayZ server's dynamic AI configuration

## Repository Structure

```
AI Bandit Patrol Creator/
├── AIB_PatrolCreator.ps1         # Main PowerShell script
├── sourcePatrolFiles/             # Input folder for DayZ Editor JSON spawner files
└── slotItemLists/                 # Input folder for item pool text files
    ├── npcclasses.txt            # NPC class types
    ├── weaponpool.txt            # Weapon options
    ├── headgear.txt              # Head equipment
    ├── masks.txt                 # Face masks
    ├── vests.txt                 # Body armor
    ├── backpacks.txt             # Backpack options
    ├── bodywear.txt              # Torso clothing
    ├── belts.txt                 # Belt equipment
    ├── pants.txt                 # Leg clothing
    ├── shoes.txt                 # Footwear
    ├── armband.txt               # Armbands (faction indicators)
    ├── loot.txt                  # Loot pool (ground items)
    └── (additional pool files)
```

## Configuration

Edit the following variables in `AIB_PatrolCreator.ps1` to customize behavior:

### Folders & Output
```powershell
$inputPatrolFolder = ".\sourcePatrolFiles"    # Where to read spawner JSONs from
$inputItemsFolder = ".\slotItemLists"         # Where item pool .txt files are located
$outputJsonFile = "NewGroupLocations.json"    # Generated output file
```

### Randomization Ranges
```powershell
$minItemCount = 7                             # Minimum items per equipment slot
$maxItemCount = 14                            # Maximum items per equipment slot
$minNpcCount = 1                              # Minimum NPCs per patrol
$maxNpcCount = 2                              # Maximum NPCs per patrol
$minRandomAccuracyPercent = 30                # Minimum NPC aim accuracy (%)
$maxRandomAccuracyPercent = 80                # Maximum NPC aim accuracy (%)
$minRandomGrenadeChancePercent = 2            # Minimum grenade use chance (%)
$maxRandomGrenadeChancePercent = 6            # Maximum grenade use chance (%)
$chanceDogPercent = 6                         # Chance patrol includes a dog (set to 0 to disable)
$chanceBanditFactionPercent = 60              # Chance patrol is "Bandits" vs "Guards" (%)
```

### Optional Features
```powershell
$flippyDippy = $true                          # Generate TWO patrols per input file
```

When enabled, `$flippyDippy` creates a second patrol from each spawner file with:
- Reversed waypoint order (patrol travels backwards)
- Randomly re-rolled all parameters (new accuracy, grenades, items, etc.)
- Opposite faction (if first is "Bandits", second is "Guards")
- Appended name (e.g., "PatrolName2")

## Input Files

### Spawner JSON Files (`sourcePatrolFiles/`)

DayZ Editor object spawner exports in JSON format. Each file should contain waypoint coordinates under `pos` keys:

```json
{
  "Objects": [
    {"pos": [1234.567, 45.678, 2345.890]},
    {"pos": [1244.567, 45.234, 2355.890]},
    {"pos": [1254.567, 45.456, 2365.890]}
  ]
}
```

The script extracts all `pos` arrays and converts them into formatted waypoint strings.

### Item Pool Text Files (`slotItemLists/`)

Plain text files listing valid item classnames. One item per line. Lines starting with `//` or `#` are treated as comments and ignored. Blank lines are also skipped.

**Required files (13+ minimum):**
- `npcclasses.txt` – NPC character types
- `weaponpool.txt` – Weapon classnames  
- `headgear.txt` – Head slot items
- `masks.txt` – Face mask items
- `vests.txt` – Chest armor items
- `backpacks.txt` – Backpack types
- `bodywear.txt` – Shirt/jacket items
- `belts.txt` – Waist slot items
- `pants.txt` – Leg clothing items
- `shoes.txt` – Foot slot items
- `gloves.txt` – Hand slot items
- `armband.txt` – Armband/faction identifier
- `loot.txt` – Loot pool (can be very large)

**Example item file:**
```
// Headgear options for AI patrols
Beret_ColorBase
CombatHelm_ColorBase
BalaclavaMask_ColorBase

# This is also a comment
MilitaryCap
```

### Blank Slot Probability

Each slot has a configurable "percent blank" chance to make equipment optional:

| Slot | Blank % | Purpose |
|------|---------|---------|
| headgear | 50% | Half of NPCs go bareheaded |
| masks | 80% | Most NPCs have visible faces |
| vests | 50% | Armor not always present |
| backpacks | 60% | Minimal pack gear expected |
| bodywear | 0% | Always have shirts |
| belts | 70% | Belts are uncommon |
| pants | 0% | Always have pants |
| shoes | 0% | Always have shoes |
| gloves | 40% | Gloves less common |
| armband | 0% | Always has faction armband |

## Output

The script generates `NewGroupLocations.json` (or configured filename) containing an array of patrol group objects:

```json
[
  {
    "name": "PatrolName",
    "faction": "Bandits",
    "waypoints": ["1234.567 45.678 2345.890", "1244.567 45.234 2355.890"],
    "npcclasses": ["SurvivorM_Mirek", "SurvivorM_Boris"],
    "accuracy": 65,
    "grenadechance": 4,
    "dog": 0,
    "weaponpool": ["AKM", "UMP45", "Mosin9130"],
    "npcproperties": {
      "headgear": ["Beret_ColorBase", "CombatHelm_ColorBase"],
      "masks": ["", "BalaclavaMask_ColorBase"],
      "vests": ["PlateCarrier_ColorBase", ""],
      "backpacks": ["AssaultBag_ColorBase"],
      "bodywear": ["TacticalShirt_ColorBase"],
      "belts": ["MilitaryBelt"],
      "pants": ["CargoPants_ColorBase"],
      "shoes": ["CombatBoots_ColorBase"],
      "gloves": ["WorkingGloves_ColorBase", ""],
      "armband": ["Armband_Red"],
      "loot": ["Mag_AKM_30Rnd", "Bandage_Gauze", ...]
    }
  }
]
```

This output is ready to be integrated into your `DynamicAIB.json` under the `groupLocation` array.

## Usage

1. **Prepare input files:**
   - Export waypoint data from DayZ Editor as JSON spawner files → `sourcePatrolFiles/`
   - Create or obtain item pool .txt files → `slotItemLists/`
   - Ensure at least 13 item pool files exist

2. **Configure the script:**
   - Review and edit parameters at the top of `AIB_PatrolCreator.ps1`
   - Adjust min/max item counts, NPC counts, and faction chances as needed

3. **Run the script:**
   ```powershell
   cd "AI Bandit Patrol Creator"
   .\AIB_PatrolCreator.ps1
   ```

4. **Review output:**
   - Check `NewGroupLocations.json` for generated patrol data
   - If the file already exists, you'll be prompted to confirm overwrite
   - Validate JSON syntax before inserting into your server config

## Features

- **Waypoint Extraction:** Reads JSON spawner files and extracts coordinate data
- **Randomized Parameters:** Each patrol gets randomized accuracy, grenade chance, NPC count, and faction
- **Flexible Item Pools:** Uses text-based item lists that can be easily customized
- **Optional Blank Slots:** Makes certain equipment slots optional with configurable probability
- **Dual Patrol Generation:** Optional "Flippy-Dippy" mode creates reversed-waypoint variants
- **Comment Support:** Item pool files support `//` and `#` style comments
- **Validation:** Checks for required folders and minimum file count before processing
- **Safe Overwrite:** Prompts before overwriting existing output files

## Requirements

- PowerShell 3.0 or later
- Read access to source folders
- Write access to output directory

## Notes

- The script bumps max randomization values by 1 internally to account for PowerShell's exclusive upper bound in `Get-Random`
- Large loot pools are created at 3× the max item count to give the AIB system more variety to randomly select from
- Dog spawn chance is independent per patrol (0 = no dogs, values 1-36 are dog classname variants)
- All generated patrols default to the configured faction or are randomly assigned based on `$chanceBanditFactionPercent`
