# Half-Life 2 RolePlay (HL2RP) for Deathmatch

Half-Life 2 RolePlay (HL2RP) is an extensive mod for HL2DM that adds roleplaying elements set in the Half-Life 2 universe. This mod has been developed between 2006-2010. This repository contains the latest code from 2010.

## Features

- Cuffing/Uncuffing/Jailing
- SWAT/Police Jobs
- Admin Jobs
- Crime List HUD
- Flawless Saving/Loading
- Dynamic Creation of NPCs/Items/Jobs/Spawns
- Stats HUD
- Job Menu
- Auto-Wages
- Criminal-Tracing beams for combines
- Incredible Inventory
  - Over 70 Preconfigured Items
  - Drugs, Guns, Food, Lockpicks, Etc
- Dynamic Vendors
- User Friendly
- Banking
- In-Depth Robbing
- Drop Money/Items
- Give Money/Items
- Weapon Restrictions
- Talkzone
- Incredible Phone Mod
- Doorkeys
  - Locking/Unlocking
- Random Spawn Locations

## Client Usage

### E Key

- On Players: Give Money/Give Item/Jail Menu
- On NPCs: Bank/Job/Vendor Menu
- On doors: Opens if client has the respective doorkey
- 2x On Cuffed: To Jail! :D

### Shift Key

- On Doors: Locks/Unlocks Door if client has the respective doorkey
- 2x On Vendors/Bankers: Robs them

### Commands

- `/Items`: Opens an inventory menu
- `/Call <Player>`: Calls a player
- `/Answer`: Answers a ringing phone
- `/Hangup`: Hangs up a phone call
- `/Tracers`: If police, toggles beams that show the location of criminals

### Talkzone

- OOC: Out Of Character Chat (Map wide)
- Yell: Yells for a longer chat radius
- Whisper: Whispers a chat message in a smaller radius
- Regular Chatting: Displays chat to players in a moderate chat range

## Admin Usage

### Main

- `Sm_CreateJob`: Adds a new job into the database
- `Sm_RemoveJob`: Removes a job from the database
- `Sm_JobList`: Prints all the jobs from the database into the console
- `Sm_Employ`: Employs a player with a privately flagged job
- `Sm_Name`: Changes the name of a player
- `Sm_Crime`: Sets the amount of time a player has on the crime list
- `Sm_CreateItem`: Adds a new item into the database
- `Sm_RemoveItem`: Removes an item from the database
- `Sm_ItemList`: Prints items from the database into the console
- `Sm_AddItem`: Adds an item into a player's inventory
- `Sm_AddVendorItem`: Adds an item to a vendor
- `Sm_RemoveVendorItem`: Removes an item from a vendor
- `Sm_Status`: Prints everyone's roleplay stats from the database to the console

### Doors

- `Sm_GiveDoor`: Gives doorkeys to the respective door
- `Sm_TakeDoor`: Takes doorkeys from the respective door

### Talkzone

- `Sm_OOC`: Enables/Disables OOC

### NPCs

- `Sm_CreateNPC`: Adds an NPC to the database
- `Sm_RemoveNPC`: Removes an NPC from the database
- `Sm_NPCList`: Prints all NPCs from the database into the console

### Spawn

- `Sm_CreateSpawn`: Creates a spawn point at the respective location
- `Sm_RemoveSpawn`: Removes a spawn point by ID
- `Sm_SpawnList`: Prints spawn points from the database into the console