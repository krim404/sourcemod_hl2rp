## CVARS

- `rp_propdmg` (0/1) - enables damage from properties like furniture (default: 1)
- `rp_tkcopkill` (0/1) - enables TK mode for cops (default: 1) 
- `rp_crowbardmg` (0/1) - enables the crowbar as weapon
- `rp_npcrob_interval` (number) - time in seconds until a register can be robbed again
- `rp_giveworkweapon` (0/1) - gives the working weapon (crowbar) to the players
- `rp_copdropmoney` (0/1) - let the cops drop money like every other player
- `rp_needfeed` (0/1) - enables/disables the feeding (default: 1)

## Commands

Console Command List. `RP_` commands require Admin Privileges, `SM_` commands don't.

### rp_admin

- `rp_name` - changes the name of the player
- `rp_setbank` - changes the money in the bank of the player
- `rp_setmoney` - changes the money of the player
- `rp_setincome` - changes the income of the player
- `rp_crime` - changes the crime level of the player
- `rp_cuff` - cuffs the player
- `rp_uncuff` - uncuffs the player
- `rp_status` - shows details of each player
- `rp_setcop` - changes the cop level of a player from 0 (no cop) to 10 (superadmin)
- `rp_setitem` - sets the amount of an item for a player
- `rp_remitem` - takes an item from a player
- `rp_additem` - gives the player an item
- `rp_setfeed` - changes the feed status of a player (anti AFK)  
- `rp_setsta` - changes the stamina of a player (for special actions - loads up over time)
- `rp_setint` - changes the intelligence of a player (for special items - can be leveled up)
- `rp_setstr` - changes the strength of a player (max HP increase - can be leveled up)
- `rp_setdex` - changes the dexterity of a player (allows special weapons - can be leveled up) 
- `rp_setspd` - changes the speed of a player (run speed - can be leveled up)
- `rp_setwgt` - changes the weight of a player (gravity - can be leveled up)
- `rp_sethate` - changes the hate level of a player (can only be leveled up by crime)
- `rp_setTrainTimer` - changes the timer for training (set when leveling up a skill, decreases over time)
- `rp_createjob` - creates a new job 
- `rp_removejob` - removes a job
- `rp_joblist` - shows all available jobs
- `rp_addvendoritem` - adds an item to a vendor for sale
- `rp_removevendoritem` - removes an item from a vendor
- `rp_note` - adds a note (HUD info) 
- `rp_rmnote` - removes all notes
- `sm_switch` - switches the cop status of a player (temporary - if too many cops online)

### rp_client

- `sm_stats` (or `/stats`) - shows the stats of a player (int, dex, spd, wgt, str, feed)
- `sm_tracers` (or `/tracers`) - toggles the tracers for the player

### rp_doors  

- `rp_givemainowner` - gives the main ownership of a door to a player
- `rp_takemainowner` - removes the main owner of a door
- `rp_setcopdoor` - makes a door accessible by cops
- `rp_deletecopdoor` - removes cop access from a door 
- `rp_setalldoors` - changes the number of doors assigned when buying a door
- `rp_binddoor` - binds a door to another main door
- `rp_makedoor` - creates a door
- `rp_setsold` - marks a door as sold
- `rp_setdoorprice` - changes the price of a door
- `rp_setsellprice` - changes the sell back price of a door
- `rp_setlocks` - changes the number of locks on a door
- `sm_givedoor` - gives a player door rights
- `sm_takedoor` - takes away a player's door rights  
- `sm_resetdoor` - resets a door
- `sm_doorname` - changes the name of a door
- `sm_buydoor` - buys a door
- `sm_selldoor` - sells a door 
- `sm_doorinfo` - gives detailed information about a door

### rp_furni

- `rp_saveit` - saves an entity to the database (restored after map reset)
- `rp_unsaveit` - deletes a saved entity 
- `rp_freezeit` - freezes an item in place
- `rp_unfreezeit` - unfreezes an item
- `rp_walkthru` - makes an item passable (players can walk through it)
- `rp_del` - removes an item immediately (use as last resort)

### rp_items

- `rp_createitem` - creates an item for sale
- `rp_removeitem` - removes an item 
- `rp_itemlist` - shows all available items
- `rp_lockdoor` - makes a door unlockable by doorhack/lockpick
- `rp_unlockdoor` - makes a door lockable again
- `sm_items` (or `/items`) - shows the item menu

### rp_jail 

- `rp_addjail` - adds a jail position
- `rp_setsuicide` - adds a suicide position

### rp_npcs

- `rp_createnpc` - creates a new NPC
- `rp_removenpc` - removes an NPC
- `rp_npclist` - lists all NPCs
- `rp_npcnotice` - sets the notice text of an NPC 
- `rp_npcwho` - shows the ID of an NPC

### rp_spawn

- `rp_createspawn` - creates a new spawn location
- `rp_removespawn` - removes a spawn location
- `rp_spawnlist` - lists all spawn locations

### rp_talkzone  

- `sm_call` - calls another player
- `sm_answer` (or `/answer`) - answers a call
- `sm_hangup` (or `/hangup`) - ends a call
- `rp_ooc` - toggles OOC chat (out-of-character chat)
- `rp_togglechat` - toggles local chat

### rp_tools

- `db_location` - returns current location 
- `db_info` - returns info about an entity
- `db_duplicate` - duplicates an entity
- `db_create` - creates an entity
- `db_create_throw` - creates and throws an entity (abusable!)
- `db_remove` - deletes an entity