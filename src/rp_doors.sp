//Roleplay v3.0 Doors
//Idea and first implementations by Joe 'Pinkfairie' Maley
//Programmed by Christian 'Krim' Uhl & Joe 'Pinkfairie' Maley
//Buydoor Mod by Benni
//Licence: Creative Commons BY-NC-SA
//http://creativecommons.org/licenses/by-nc-sa/3.0/

//Stocks:
#include "roleplay/rp_wrapper"
#include "roleplay/rp_include"
#include "roleplay/rp_hud"
#include "roleplay/rp_main"
#include "roleplay/COLORS"
#include "roleplay/rp_doors"

//Definitions:
#define	MAXDOORS 2000
#define MAXPLAYER 33

//Databases:
public String:LockPath[128]; 
public String:NamePath[128];
public String:DoorPricePath[128];

//Variables:
public Sold[MAXDOORS];
public OwnsDoor[MAXPLAYER][MAXDOORS];
public PoliceDoors[64];
public AllowedFlats[MAXPLAYER];
public MainOwner[MAXPLAYER][MAXDOORS];
public Member[MAXPLAYER][MAXDOORS];
public AllDoors[MAXDOORS];
public ButtonBuffer[MAXPLAYER];
public DoorPrice[MAXDOORS];
public SellPrice[MAXDOORS];
public Locked[MAXDOORS];
public String:Notice[MAXDOORS][255];
public String:NPCNotice[MAXDOORS][255];
public String:HouseName[MAXDOORS][255];
public String:DoorName[MAXDOORS][255];
public String:Status[MAXDOORS][255];
public DoorLocks[MAXDOORS] = 0;

//Misc:
static bool:PrethinkBuffer[MAXPLAYER];


//Spawn:
public EventSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
	//Initialize:
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	saveUserName(Client);
	for(new X = 0; X < 64; X++)
	{
		if(PoliceDoors[X] && rp_iscop(Client) > 0)
		{
			OwnsDoor[Client][PoliceDoors[X]] = 1;
		} 
		else
		{
			OwnsDoor[Client][PoliceDoors[X]] = 0;
		}
	}
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("rp_addLock", addLock);
	CreateNative("rp_getLock", getLock);
	CreateNative("rp_setDoorOwner", setDoorOwner);
	CreateNative("rp_getDoorOwner", getDoorOwner);
	CreateNative("rp_breakLock", breakLock);
	CreateNative("rp_getLocked",getLocked);
	CreateNative("rp_SetDoorStatus", SetDoorStatus);
	
	return APLRes_Success;
}

stock SetNoticeName(Ent, String:Text[])
{
	Notice[Ent] = Text;	
}
stock SetDoorName(Ent, String:Text[])
{
	DoorName[Ent] = Text;	
}
stock SetHouseName(Ent, String:Text[])
{
	HouseName[Ent] = Text;	
}

//UserID Save
stock saveUserName(Client)
{
	
	decl String:SteamId[255], String:LastSeen[255], String:Name[255];
	new Handle:Vault = CreateKeyValues("Vault");
	GetClientAuthString(Client, SteamId, 255);
	GetClientName(Client, Name, 255);
	IntToString(GetTime(), LastSeen, 255);
	
	//Retrieve:
	FileToKeyValues(Vault, NamePath);
	
	//Save:
	SaveString(Vault, "name", SteamId, Name);
	SaveString(Vault, "seen", SteamId, LastSeen);
	
	//Store:
	KeyValuesToFile(Vault, NamePath);
	
	//Close:
	CloseHandle(Vault);
	
	//Return:
	return true;
}

public Action:Command_setdoorprice(Client,Args)
{
	
	if(Args != 1)
	{
		CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 rp_setdoorprice <amount>\x04");
		return Plugin_Handled;
	}
	
	decl String:Amount[255];
	//Initialize:
	GetCmdArg(1, Amount, sizeof(Amount));
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	
	new String:KeyBuffer[255];
	IntToString(Ent, KeyBuffer, 255);	
	decl Handle:Vault;	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DoorPricePath);	
	KvJumpToKey(Vault, "DoorPrice", true);	
	KvSetString(Vault, KeyBuffer, Amount);	
	KvRewind(Vault);	
	KeyValuesToFile(Vault, DoorPricePath);	
	CloseHandle(Vault);
	
	new String:Text[255];
	Format(Text, sizeof(Text), "DoorPrice |%d $", StringToInt(Amount));
	
	CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 Price has been set to: %s!\x04", Amount);

	rp_setfirst(Ent, Text);
	ClientCommand(Client, "rp_setsellprice %d",StringToInt(Amount) / 2);
	return Plugin_Handled;
}

public Action:Command_setsellprice(Client,Args)
{
	
	if(Args != 1)
	{
		CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 rp_setsellprice <amount>\x04");
		return Plugin_Handled;
	}
	
	decl String:Amount[255];
	//Initialize:
	GetCmdArg(1, Amount, sizeof(Amount));
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	
	new String:KeyBuffer[255];
	IntToString(Ent, KeyBuffer, 255);
	
	decl Handle:Vault;
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DoorPricePath);
	KvJumpToKey(Vault, "SellPrice", true);
	KvSetString(Vault, KeyBuffer, Amount);
	KvRewind(Vault);
	KeyValuesToFile(Vault, DoorPricePath);
	CloseHandle(Vault);
	

	CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 Sell price has been set to: %s!\x04", Amount);
	return Plugin_Handled;	
}



public Action:Command_setlocks(Client,Args)
{
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	if(Args != 1)
	{
		CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 rp_setlocks <amount>\x04");
		return Plugin_Handled;
	}
	
	new Munny = 0; 
	decl String:Muny[32];
	
	GetCmdArg(1, Muny, sizeof(Muny));
	Munny = StringToInt(Muny);  
	decl Handle:Vault;
	decl String:DoorId[255];
	decl String:LockNr[255];
	
	DoorLocks[Ent] = Munny;		
	Vault = CreateKeyValues("Vault");
	IntToString(Ent,DoorId,20);
	IntToString(DoorLocks[Ent],LockNr,20);
	FileToKeyValues(Vault, LockPath); 
	SaveString(Vault, "2", DoorId, LockNr);
	KeyValuesToFile(Vault, LockPath);
	CloseHandle(Vault);
	
	CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 Locks has been set to: \x04%d\x04\x01!\x04", Munny);
	return Plugin_Handled;
}

public Action:Command_doorinfo(Client,Args)
{
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	
	GetDoorPrice(Client, Ent);
	GetSellPrice(Client, Ent);
	
	decl Handle:Vault,Handle:Vault2,String:ClassName[20];
	GetEdictClassname(Ent, ClassName, 20);
	
	if(!(StrEqual(ClassName, "func_door") || StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating")  || StrEqual(ClassName, "func_movelinear") || StrEqual(ClassName, "func_brush")))
	{
		PrintToConsole(Client, "[RP] No door selected");
		return Plugin_Handled;
	}
	
	new Handle:Menu = CreateMenu(DoorMenu);
	SetMenuTitle(Menu, "You can choose one of this commands:");
	
	AddMenuItem(Menu, "0", "Buy this door");
	if(MainOwner[Client][Ent] == 1)
	{
		AddMenuItem(Menu, "1", "Sell this door");
		AddMenuItem(Menu, "2", "Give door keys to...");
		AddMenuItem(Menu, "3", "Take door keys from");
		AddMenuItem(Menu, "4", "Reset this door");
	}
	
	
	SetMenuExitButton(Menu, false);
	DisplayMenu(Menu, Client, 20);
	
	GetDoorStatus(Client, Ent);
	
	if(Locked[Ent] || StrEqual(ClassName, "func_door"))
	{
		Status[Ent] = "Locked";
	}
	else
	{
		Status[Ent] = "Unlocked";
	}
	
	CPrintToChat(Client, "{teamcolor}[RP]\x04 See console for output");
	PrintToConsole(Client, "[RP] Door ID: %d", Ent);
	PrintToConsole(Client, "[RP] Doorprice: %d", DoorPrice[Ent]);
	PrintToConsole(Client, "[RP] Sellprice: %d", SellPrice[Ent]);
	PrintToConsole(Client, "[RP] Locks: %d", DoorLocks[Ent]);
	PrintToConsole(Client, "[RP] Status: %s", Status[Ent]);
	PrintToConsole(Client, "[RP] Acceslist:");
	
	
	Vault = CreateKeyValues("Vault");
	Vault2 = CreateKeyValues("Vault");
	decl String:EntS[40];
	decl String:buffer[255],String:Name[255],String:LastSeen[255],TimeStamp;
	IntToString(Ent,EntS,40);
	
	//Load:
	FileToKeyValues(Vault, DoorPricePath);
	FileToKeyValues(Vault2, NamePath);
	KvJumpToKey(Vault, "Member", true);
	KvJumpToKey(Vault, EntS, true);
	KvGotoFirstSubKey(Vault,false);
	do
	{
		KvGetSectionName(Vault, buffer, sizeof(buffer));
		LoadString(Vault2, "name", buffer, "Not in the Database", Name);
		LoadString(Vault2, "seen", buffer, "0", LastSeen);
		TimeStamp = StringToInt(LastSeen);
		FormatTime(LastSeen,255,"%d.%m.%Y",TimeStamp);
		
		if(StrContains(buffer, "STEAM", false) != -1)
		{
			PrintToConsole(Client, "[RP] %s (%s) - Last Online: %s",buffer,Name,LastSeen);
		}
		
	} while (KvGotoNextKey(Vault,false));
	CloseHandle(Vault);
	CloseHandle(Vault2);
	return Plugin_Handled;
	
}

public ShowPlayers(Client)
{
	decl Ent,Handle:Vault,Handle:Vault2, String:SteamId[32];
	Ent = rp_entclienttarget(Client,false);
	
	Vault = CreateKeyValues("Vault");
	Vault2 = CreateKeyValues("Vault");
	GetClientAuthString(Client, SteamId, 32);
	decl String:EntS[40];
	decl String:buffer[255],String:Name[255];
	IntToString(Ent,EntS,40);
	decl String:display[255];
	new Handle:menu = CreateMenu(GiveDoorMenu);
	SetMenuTitle(menu, "Take door keys from:");
	
	
	//Load:
	FileToKeyValues(Vault, DoorPricePath);
	FileToKeyValues(Vault2, NamePath);
	KvJumpToKey(Vault, "Member", true);
	KvJumpToKey(Vault, EntS, true);
	KvGotoFirstSubKey(Vault,false);
	do
	{
		
		
		KvGetSectionName(Vault, buffer, sizeof(buffer));
		LoadString(Vault2, "name", buffer, "Not in the Database", Name);
		if(StrContains(buffer, "STEAM", false) != -1)
		{
			if(!StrEqual(buffer, SteamId))
			{
				
				Format(display, sizeof(display), "%s", Name);
				AddMenuItem(menu, buffer, display);
			}
		}
		
	} while (KvGotoNextKey(Vault,false));
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, Client, 20);
	CloseHandle(Vault);
	CloseHandle(Vault2);
	return true;	
	
}

public ShowOnlineClient(Client)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	new Ent = rp_entclienttarget(Client,false);
	if(MainOwner[Client][Ent] == 1)
	{
		new Handle:menu = CreateMenu(GiveDoorMenu);
		SetMenuTitle(menu, "Give door to:");
		for(new X = 1; X <= GetMaxClients(); X++) 
		{
			if(IsClientConnected(X) && !IsFakeClient(X) && X != Client)
			{
				GetMember(Client, Ent);
				if(Member[X][Ent] != 1)
				{
					
					IntToString(GetClientUserId(X), user_id, sizeof(user_id));
					GetClientName(X, name, sizeof(name));
					
					AddMenuItem(menu, user_id, name);
				}
			}
		}
		
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, Client, 20);
	}
}

public DoorMenu(Handle:menu, MenuAction:action, Client, Parameter)
{
	
	if(action == MenuAction_Select)
	{
		ButtonBuffer[Client] = 0;
		if(Parameter == 0)
		{
			ClientCommand(Client, "sm_buydoor");
			return true;
		}
		if(Parameter == 1)
		{
			ClientCommand(Client, "sm_selldoor");
			return true;
		}
		if(Parameter == 2)
		{
			ShowOnlineClient(Client);
			ButtonBuffer[Client] = 1;
			return true;
		}
		if(Parameter == 3)
		{
			ShowPlayers(Client);
			ButtonBuffer[Client] = 2;
			return true;
		}
		if(Parameter == 4)
		{
			ClientCommand(Client, "sm_resetdoor");
			return true;
		}
		
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	return true;
}





public GiveDoorMenu(Handle:menu, MenuAction:action, Client, param2)
{	
	new Ent = rp_entclienttarget(Client,false);
	if(Ent > 0 && (MainOwner[Client][Ent] == 1 || CheckAdminFlagsByString(Client,ADMFLAG_ROOT)))
	{
		new String:KeyBuffer[255];
		IntToString(Ent, KeyBuffer, 255);	
		/* If an option was selected, tell the client about the item. */
		if (action == MenuAction_Select)
		{
			new String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if(ButtonBuffer[Client] == 1)
			{
				new buff = StringToInt(info);
				new player = GetClientOfUserId(buff);
				new String:ClientName[64];
				GetClientName(player, ClientName, 64);
				ClientCommand(Client, "rp_givedoor \"%s\"", ClientName);			
			}
			
			if(ButtonBuffer[Client] == 2)
			{
				GetMainOwner(Client, Ent);
				
				if(MainOwner[Client][Ent] == 1 || CheckAdminFlagsByString(Client,ADMFLAG_ROOT))
				{
					decl Handle:Vault;	
					Vault = CreateKeyValues("Vault");
					
					FileToKeyValues(Vault, DoorPricePath);	
					KvJumpToKey(Vault, "Member", true);
					KvJumpToKey(Vault, KeyBuffer, true);	
					KvDeleteKey(Vault, info);	
					KvRewind(Vault);	
					KeyValuesToFile(Vault, DoorPricePath);	
					CloseHandle(Vault);
					CPrintToChat(Client, "{teamcolor}[RP]\x01 You took \x04%s\x01 doorkeys!", info);
					
					new String:ClientName[32], String:SteamId[32];
					GetClientAuthString(Client, SteamId, sizeof(SteamId));
					GetClientName(Client, ClientName, sizeof(ClientName));
					
				}
				else
				{
					CPrintToChat(Client, "{teamcolor}[RP]\x01Sorry, but you are not the owner of this door!");	
				}
			}
			
		}
		else if (action == MenuAction_End)
		{
			CloseHandle(menu);
		}
	}
	
}


public Action:Command_ResetDoor(Client, Args)
{
	new Ent = rp_entclienttarget(Client,false);
	
	if(Ent > 0)
	{
		GetMainOwner(Client, Ent);
		GetMember(Client, Ent);	
		
		if(Args > 1)
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x01 Invalid Syntax.");
			return Plugin_Handled;
		}
		if((MainOwner[Client][Ent] == 1 || CheckAdminFlagsByString(Client,ADMFLAG_ROOT)) && Ent > 0)
		{
			if(CheckAdminFlagsByString(Client,ADMFLAG_ROOT))
			{
				CPrintToChat(Client, "{teamcolor}[RP]\x01 As admin are able to reset this door completly by rp_resetdoor 1.");
			}
			
			MainOwner[Client][Ent] = 0;
			Member[Client][Ent] = 0;		
			AllowedFlats[Client] = 0;
			Sold[Ent] = 0;
			DoorSave(Client, Ent, 1);
			if(Args == 0)
			{
				MainOwner[Client][Ent] = 1;
				Member[Client][Ent] = 1;
				Sold[Ent] = 1;
				AllowedFlats[Client] = 1;
				DoorSave(Client, Ent, 0);
				ClientCommand(Client, "sm_doorname \"\"");
			}
			else if(Args == 1 && CheckAdminFlagsByString(Client,ADMFLAG_ROOT))
			{
				GetDoorPrice(Client, Ent);
				Sold[Ent] = 0;
				MainOwner[Client][Ent] = 0;
				Member[Client][Ent] = 0;		
				AllowedFlats[Client] = 0;
				DoorSave(Client, Ent, 1);
			
				new String:Text[255];
				Format(Text, sizeof(Text), "Doorprice | %d $", DoorPrice[Ent]);
				rp_setsub(Ent, Text);
				rp_setthird(Ent, "");
			}
			
			
			new String:ClientName[32], String:SteamId[32], String:File[PLATFORM_MAX_PATH];
			GetClientAuthString(Client, SteamId, sizeof(SteamId));
			GetClientName(Client, ClientName, sizeof(ClientName));
			BuildPath(Path_SM, File, sizeof(File), "data/logging/door.log");	
			LogToFileEx(File, "%s <%s> reseted door #%d", ClientName, SteamId, Ent);
			
			CPrintToChat(Client, "{teamcolor}[RP]\x04 This door has been reseted succesful");
		}
		else
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x04 Sorry, You aren't the owner of this door.");
			
		}
	}
	return Plugin_Handled;
}


public Action:Command_TakeDoorPlayer(Client, Args)
{
	//Error:
	if(Args < 1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_takedoor <name> ");
		ButtonBuffer[Client] = 2;
		ShowPlayers(Client);
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	decl String:PlayerName[64];
	decl String:ClientName[64];
	
	
	GetCmdArg(1, PlayerName, 64);
	
	//Find:
	new Player = FindTarget(Client,PlayerName, true, false);
	GetClientName(Client, ClientName, 64);
	GetClientName(Player, PlayerName, 64);
	
	//Invalid Name:
	if(Player == -1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Could not find client %s", PlayerName);
		
		//Return:
		return Plugin_Handled;
	}
	
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	
	if(Ent > 0)
	{
		if(CheckAdminFlagsByString(Client,ADMFLAG_ROOT))
		{
			if(Args == 2)
			{
				rp_setfirst(Ent, "");
			}
			
		}
		
		GetMainOwner(Client, Ent);
		GetMember(Client, Ent);	
		
		if(Player == Client && !(CheckAdminFlagsByString(Client,ADMFLAG_ROOT)))
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x04 You cannot remove your own doorkeys.");
			return Plugin_Handled;	
		}
		if(Member[Player][Ent] == 0){
			
			CPrintToChat(Client, "{teamcolor}[RP]\x04 He doesn't own this Door.");
			return Plugin_Handled;
		}
		
		if(MainOwner[Client][Ent] == 1 || CheckAdminFlagsByString(Client,ADMFLAG_ROOT)){
			
			
			
			Member[Player][Ent] = 0;
			
			
			CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 You took \x04%s\x04\x01 doorkeys from \x04%s\x04.", PlayerName, DoorName[Ent]);
			CPrintToChat(Player, "{teamcolor}[RP] \x04%s\x04\x01 has taken your doorkeys from \x04%s\x04 .", ClientName, DoorName[Ent]);
			
			new String:SteamId[32], String:SteamId2[32], String:File[PLATFORM_MAX_PATH];
			GetClientAuthString(Client, SteamId, sizeof(SteamId));
			GetClientAuthString(Client, SteamId2, sizeof(SteamId2));
			
			BuildPath(Path_SM, File, sizeof(File), "data/logging/door.log");	
			LogToFileEx(File, "%s <%s> took %s <%s> doorkeys from door #%d", ClientName, SteamId, PlayerName, SteamId2, Ent);
			
			DoorSave(Player, Ent, 0);
			
			//Return:
			return Plugin_Handled;
			
		}
		CPrintToChat(Client, "{teamcolor}[RP]\x04 Sorry, but you are not the owner of this door!\x04");
	}
	return Plugin_Handled;
}






public Action:Command_GiveDoorPlayer(Client, Args)
{
	//Error:
	if(Args < 1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_givedoor <name> ");
		
		ButtonBuffer[Client] = 1;
		ShowOnlineClient(Client);
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	decl String:PlayerName[255];
	decl String:ClientName[255];
	
	
	GetCmdArg(1, PlayerName, 255);
	
	//Find:
	new Player = FindTarget(Client,PlayerName, true, false);
	GetClientName(Client, ClientName, 255);
	GetClientName(Player, PlayerName, 255);
	
	//Invalid Name:
	if(Player == -1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Could not find client %s", PlayerName);
		
		//Return:
		return Plugin_Handled;
	}
	
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	
	if(Ent > 0)
	{
		if(CheckAdminFlagsByString(Client,ADMFLAG_ROOT))
		{
			if(Args == 2)
			{
				rp_setfirst(Ent, PlayerName);
			}
			
		}
		
		GetMember(Client, Ent);
		GetMember(Player, Ent);
		GetMainOwner(Client, Ent);
		
		
		if(Member[Player][Ent] == 1)
		{	
			CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 He is already the owner of this door!");
			return Plugin_Handled;
		}
		
		if(MainOwner[Client][Ent] == 1 || CheckAdminFlagsByString(Client,ADMFLAG_ROOT)){
			
			Member[Player][Ent] = 1;
	
			CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 You gave \x04%s\x04\x01 doorkeys from \x04%s (%s)\x04.", PlayerName, DoorName[Ent], HouseName[Ent]);
			CPrintToChat(Player, "{teamcolor}[RP] \x04%s\x04\x01 has given you owner from \x04%s\x04 .", ClientName, DoorName[Ent]);
			
			
			new String:SteamId[32], String:SteamId2[32], String:File[PLATFORM_MAX_PATH];
			GetClientAuthString(Client, SteamId, sizeof(SteamId));
			GetClientAuthString(Player, SteamId2, sizeof(SteamId2));
			BuildPath(Path_SM, File, sizeof(File), "data/logging/door.log");	
			LogToFileEx(File, "%s <%s> gave %s <%s> doorkeys from door #%d", ClientName, SteamId, PlayerName, SteamId2, Ent);
			DoorSave(Player, Ent, 0);
			
			
		}
		else
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x04 Sorry, but you are not the owner of this door!\x04");
			
		}
	}
	return Plugin_Handled;
}




public Action:CommandSetCopDoor(Client, Args)
{
	
	//Error:
	if(Args < 1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_setcopdoor <id>");
		return Plugin_Handled;
	}
	
	
	decl String:Buffert[5];
	GetCmdArg(1, Buffert, sizeof(Buffert));
	
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	
	if(Ent > 0)
	{
		new String:KeyBuffer[255];
		IntToString(Ent, KeyBuffer, 255);
		decl Handle:Vault;	
		Vault = CreateKeyValues("Vault");
		FileToKeyValues(Vault, DoorPricePath);	
		KvJumpToKey(Vault, "PoliceDoor", true);
		KvSetString(Vault, Buffert, KeyBuffer);
		
		KvRewind(Vault);	
		KeyValuesToFile(Vault, DoorPricePath);	
		CloseHandle(Vault);
		CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 Door \x04#%d\x04\x01 is now a police door.", Ent);
		PoliceDoors[StringToInt(Buffert)] = Ent;
	}
	return Plugin_Handled;
}


public Action:CommandDeleteCopDoor(Client, Args)
{
	
	//Error:
	if(Args < 1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_deletecopdoor <id>");
		return Plugin_Handled;
	}
	
	
	decl String:Buffert[5];
	GetCmdArg(1, Buffert, sizeof(Buffert));
	
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	
	
	if(Ent > 0)
	{
		new String:KeyBuffer[255];
		IntToString(Ent, KeyBuffer, 255);	
		
		
		decl Handle:Vault6;	
		Vault6 = CreateKeyValues("Vault6");
		FileToKeyValues(Vault6, DoorPricePath);	
		KvJumpToKey(Vault6, "PoliceDoor", true);
		KvDeleteKey(Vault6, Buffert);
		
		KvRewind(Vault6);	
		KeyValuesToFile(Vault6, DoorPricePath);	
		CloseHandle(Vault6);
		
		PoliceDoors[StringToInt(Buffert)] = 0;
		
		CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 Door \x04#%d\x04\x01 has been removed as a police door", Ent);
	}
	
	return Plugin_Handled;
}




//Take Door:
public Action:CommandTakeMainOwner(Client, Args)
{
	
	//Error:
	if(Args < 1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_takemainowner <name> ");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	decl String:PlayerName[64];
	decl String:ClientName[64];
	
	
	GetCmdArg(1, PlayerName, 64);
	
	//Find:
	new Player = FindTarget(Client,PlayerName);
	GetClientName(Client, ClientName, 64);
	GetClientName(Player, PlayerName, 64);
	//Invalid Name:
	if(Player == -1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Could not find client %s", PlayerName);
		
		//Return:
		return Plugin_Handled;
	}
	
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	
	if(Ent > 0)
	{
		GetMainOwner(Player, Ent);
		if(MainOwner[Player][Ent] == 0)
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x04 He isn't the owner of this door!");
			return Plugin_Handled;
		}
		
		
		MainOwner[Player][Ent] = 0;

		CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 You took \x04%s\x04\x01 mainowner from \x04#%d\x04.", PlayerName, Ent);
		CPrintToChat(Player, "{teamcolor}[RP] \x04%s\x04\x01 has taken you mainowner from \x04#%d\x04 .", ClientName, Ent);
		
		DoorSave(Player, Ent, 0);
	}
	return Plugin_Handled;
}





//Take Door:
public Action:CommandGiveMainOwner(Client, Args)
{
	
	//Error:
	if(Args < 1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_givemainowner <name> ");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	decl String:PlayerName[64];
	decl String:ClientName[64];
	
	
	GetCmdArg(1, PlayerName, 64);
	
	//Find:
	new Player = FindTarget(Client,PlayerName);
	GetClientName(Client, ClientName, 64);
	GetClientName(Player, PlayerName, 64);
	
	//Invalid Name:
	if(Player == -1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Could not find client %s", PlayerName);
		
		//Return:
		return Plugin_Handled;
	}
	
	
	
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	
	if(Ent > 0)
	{
		GetMainOwner(Player, Ent);	
		if(MainOwner[Player][Ent] == 1)
		{
			CPrintToChat(Client, "[RP] He already is the owner of this door!");
			return Plugin_Handled;
		}
		
		
		MainOwner[Player][Ent] = 1;
		
		
		CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 You gave \x04%s\x04\x01 mainowner from \x04#%d\x04.", PlayerName, Ent);
		CPrintToChat(Player, "{teamcolor}[RP] \x04%s\x04\x01 has given you mainowner from \x04#%d\x04 .", ClientName, Ent);
		
		
		DoorSave(Player, Ent, 0);
	}
	return Plugin_Handled;
}




public Action:Command_doorname(Client,Arguments)
{
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	//Arguments:
	if(Arguments < 1 || Ent <= 0)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_doorname <String>");
		
		//Return:
		return Plugin_Handled;
	}
	
	
	GetMainOwner(Client, Ent);
	
	if(MainOwner[Client][Ent] == 1)
	{
		decl String:Text[255];
		GetCmdArg(1, Text, sizeof(Text));
		DoorName[Ent] = Text;
		

		rp_setthird(Ent, Text);
		CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 Doorname has been changed to:\x04%s\x01.", Text);
		return Plugin_Handled; 
	}
	CPrintToChat(Client, "{teamcolor}[RP]\x04 Sorry, but you are not the owner of this door!\04");
	return Plugin_Handled;
}




public Action:Command_selldoor(Client, args)
{
	new Ent = rp_entclienttarget(Client,false);
	GetMainOwner(Client, Ent);
	GetDoorPrice(Client, Ent);
	
	if(MainOwner[Client][Ent] == 1 && Ent > 0)
	{
		if(DoorPrice[Ent] == 0)
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x04 You can only sell the maindoor!");		
			return Plugin_Handled;	
		}
		GetDoorPrice(Client, Ent);
		GetSellPrice(Client, Ent);
		
		rp_addMoney(Client, SellPrice[Ent]);
		Sold[Ent] = 0;
		MainOwner[Client][Ent] = 0;
		Member[Client][Ent] = 0;	
		AllowedFlats[Client] = 0;

		rp_setfirst(Ent, "");
		rp_setthird(Ent, "");

		DoorSave(Client, Ent, 1);
		GetAllDoors(Client, Ent);
		new DoorAll = AllDoors[Ent];
		for(new X = 1; X <= DoorAll; X++)
		{	
			GiveBindDoor(Client, Ent, X, 0, 1,  "");
		}
		
		new String:Text[255];
		Format(Text, sizeof(Text), "Doorprice | %d $", DoorPrice[Ent]);
		rp_setfirst(Ent, Text);
		rp_setthird(Ent, "");
		CPrintToChat(Client, "{teamcolor}[RP]\x04 This door has been sold succesful!");
		DoorSave(Client, Ent, 1);
		
		
	}
	else
	{
		
		CPrintToChat(Client, "{teamcolor}[RP]\x04 Sorry, but you are not the owner of this door!");	
	}
	return Plugin_Handled;
}

public Action:Command_buydoor(Client, args)
{	
	new String:ClientName[80];	
	new Ent = rp_entclienttarget(Client,false);
	if(Ent > 0)
	{
		GetClientName(Client,ClientName, 80);
		GetSold(Client, Ent);
		GetDoorPrice(Client, Ent);
		GetMaxFlat(Client);
		if(DoorPrice[Ent] != 0)
		{
			if(AllowedFlats[Client] == 1)
			{
				CPrintToChat(Client, "{teamcolor}[RP]\x04 You can't buy more than one door!");	
				return Plugin_Handled;
			}
			if(rp_getMoney(Client) < DoorPrice[Ent])
			{
				CPrintToChat(Client, "{teamcolor}[RP]\x04 You don't have enough money to purchase this door.");	
				return Plugin_Handled;
			}
			if(Sold[Ent] == 1)
			{
				CPrintToChat(Client, "{teamcolor}[RP]\x04 This door is already bought");	
			}
			else
			{
				if(rp_getMoney(Client) >= DoorPrice[Ent])
				{
					
					rp_takeMoney(Client, DoorPrice[Ent]);
					Sold[Ent] = 1;
					MainOwner[Client][Ent] = 1;
					Member[Client][Ent] = 1;	
					AllowedFlats[Client] = 1;
					new String:Text[255];
					Format(Text, sizeof(Text), "Doorprice | %d $", DoorPrice[Ent]);
					rp_setfirst(Ent, ClientName);
					DoorSave(Client, Ent, 0);
					GetAllDoors(Client, Ent);
					new DoorAll = AllDoors[Ent];
					
					for(new X = 1; X <= DoorAll; X++)
					{	
						GiveBindDoor(Client, Ent, X, 1,0, ClientName);
					}
					
					CPrintToChat(Client, "{teamcolor}[RP]\x04 You bought this door succesful!");	
					
					new String:SteamId[32], String:File[PLATFORM_MAX_PATH];
					GetClientAuthString(Client, SteamId, sizeof(SteamId));
					BuildPath(Path_SM, File, sizeof(File), "data/logging/door.log");	
					LogToFileEx(File, "%s <%s> bought door #%d", ClientName, SteamId, Ent);
				}
			}
		}
		else
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x04 This door cannot be bought!");
		}	
	}
	return Plugin_Handled;
}

public GiveBindDoor(Client, Ent, X, what, OnSellDoor,String:ClientName[])
{
	new String:KeyBuffer[255];
	IntToString(Ent, KeyBuffer, 255);	
	new String:DoorBuffer[255];
	IntToString(X, DoorBuffer, 255);	
	
	decl Handle:Vault;	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DoorPricePath);	
	
	KvJumpToKey(Vault, "BindDoors", true);
	KvJumpToKey(Vault, KeyBuffer, true);
	new buffer = KvGetNum(Vault, DoorBuffer);
	KvRewind(Vault);
	
	Sold[Ent] = what;
	MainOwner[Client][buffer] = what;
	Member[Client][buffer] = what;	
	AllowedFlats[Client] = what;
	//PrintToChatAll("Ent: %d X: %d buffer: %d what:%d Mainowner: %d Member: %d", Ent, X, buffer, what, MainOwner[Client][buffer], Member[Client][buffer])

	
	rp_setfirst(buffer, ClientName);
	CloseHandle(Vault);
	if(OnSellDoor == 1)	rp_setthird(buffer, ""); 
	DoorSave(Client, buffer, OnSellDoor);
	return true;
}

public GetDoorStatus(Client, Ent)
{
	decl Handle:Vault;
	Vault = CreateKeyValues("Vault");
	decl String:DoorId[255];
	IntToString(Ent, DoorId, 255); 				
	FileToKeyValues(Vault, DoorPricePath);
	Locked[Ent] = LoadInteger(Vault, "Locked", DoorId, 0);	
	KvRewind(Vault);
	CloseHandle(Vault);
	return true;
}


public Action:CommandAllDoors(Client, args)
{
	if(args != 1)
	{
		PrintToConsole(Client, "[SM] Usage: sm_setalldoors <number>");
		return Plugin_Handled;
	}
	
	new String:arg1[64];
	GetCmdArg(1, arg1, 64);
	new Ent = rp_entclienttarget(Client,false);
	AllDoors[Ent] = StringToInt(arg1);
	
	CPrintToChat(Client, "{teamcolor}[RP]\x01 Doors of \x04#%d\x01 has been set to:\x04%d\x01.", Ent, AllDoors[Ent]);
	SetAllDoors(Client, Ent);
	return Plugin_Handled;
}

public Action:CommandBindDoor(Client, args)
{
	if(args != 2)
	{
		PrintToConsole(Client, "[SM] Usage: sm_binddoor <Door Number> <Id of the Maindoor>");
		return Plugin_Handled;
	}
	
	new String:arg1[64];
	new String:arg2[64];
	
	GetCmdArg(1, arg1, 64);
	GetCmdArg(2, arg2, 64);	
	
	new Ent = rp_entclienttarget(Client,false);
	
	
	CPrintToChat(Client, "{teamcolor}[RP]\x01 Door \x04#%s\x01 has been binded with:\x04%d\x01.", arg2, Ent);
	SetBindDoors(Client, arg1, arg2 , Ent);
	return Plugin_Handled;
}

public Action:CommandSetSold(Client, args)
{
	if(args != 1)
	{
		PrintToConsole(Client, "[SM] Usage: sm_setsold <1/0>");
		return Plugin_Handled;
	}
	
	new String:arg1[64];	
	GetCmdArg(1, arg1, 64);
	
	new Ent = rp_entclienttarget(Client,false);
	if(Ent > 0)
	{
		Sold[Ent] = StringToInt(arg1);
		DoorSave(Client, Ent, 0);
		CPrintToChat(Client, "{teamcolor}[RP]\x04 Door has been set to \x04%d\x01", StringToInt(arg1));
	}
	return Plugin_Handled;
}
public Action:CommandMakedoor(Client, args)
{
	if(args != 1)
	{
		PrintToConsole(Client, "[SM] Usage: sm_makedoor <name>");
		return Plugin_Handled;
	}
	
	new String:arg1[64];
	
	GetCmdArg(1, arg1, 64);
	
	new Ent = rp_entclienttarget(Client,false);
	if(Ent > 0)
	{
		new Player = FindTarget(Client, arg1);
		Sold[Ent] = 1;
		MainOwner[Player][Ent] = 1;
		Member[Player][Ent] = 1;	
		AllowedFlats[Player] = 1;
		DoorSave(Player, Ent, 0);
		CPrintToChat(Client, "{teamcolor}[RP]\x04 Door has been restored successful");
	}
	return Plugin_Handled;
}

public SetBindDoors(Client, String:DoorNumber[], String:DoorId[], Ent)
{
	
	
	decl Handle:Vault;	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DoorPricePath);	
	KvJumpToKey(Vault, "BindDoors", true);
	KvJumpToKey(Vault, DoorId, true);
	KvSetNum(Vault, DoorNumber, Ent);	
	KvRewind(Vault);	
	KeyValuesToFile(Vault, DoorPricePath);	
	CloseHandle(Vault);		
	return true;
}

public SetAllDoors(Client, Ent)
{
	
	new String:KeyBuffer[255];
	IntToString(Ent, KeyBuffer, 255);	
	decl Handle:Vault;	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DoorPricePath);	
	KvJumpToKey(Vault, "AllDoors", true);
	KvSetNum(Vault, KeyBuffer, AllDoors[Ent]);	
	KvRewind(Vault);	
	KeyValuesToFile(Vault, DoorPricePath);	
	CloseHandle(Vault);	
	return true;
}



public GetAllDoors(Client, Ent)
{
	
	new String:KeyBuffer[255];
	IntToString(Ent, KeyBuffer, 255);	
	decl Handle:Vault;	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DoorPricePath);	
	KvJumpToKey(Vault, "AllDoors", true);
	AllDoors[Ent] = KvGetNum(Vault, KeyBuffer);	
	KvRewind(Vault);	
	CloseHandle(Vault);	
	return true;
}

public GetMainOwner(Client, Ent)
{
	decl String:SteamId[64];
	GetClientAuthString(Client, SteamId, 64);	
	new String:KeyBuffer[255];
	IntToString(Ent, KeyBuffer, 255);	
	decl Handle:Vault;	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DoorPricePath);	
	KvJumpToKey(Vault, "MainOwner", true);
	KvJumpToKey(Vault, KeyBuffer, true);
	MainOwner[Client][Ent] = KvGetNum(Vault, SteamId);	
	KvRewind(Vault);	
	CloseHandle(Vault);	
	return true;
}

public GetMaxFlat(Client)
{
	decl String:SteamId[64];
	GetClientAuthString(Client, SteamId, 64);	
	decl Handle:Vault;	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DoorPricePath);	
	KvJumpToKey(Vault, "MaxFlats", true);
	AllowedFlats[Client] = KvGetNum(Vault, SteamId);	
	KvRewind(Vault);	
	KeyValuesToFile(Vault, DoorPricePath);	
	CloseHandle(Vault);		
	return true;
}

public GetMember(Client, Ent)
{
	if(Ent > 0 && IsValidClient(Client))
	{
		new String:KeyBuffer[255];
		IntToString(Ent, KeyBuffer, 255);	
		decl String:SteamId[64];
		GetClientAuthString(Client, SteamId, 64);	
		decl Handle:Vault;	
		Vault = CreateKeyValues("Vault");
		FileToKeyValues(Vault, DoorPricePath);	
		KvJumpToKey(Vault, "Member", true);
		KvJumpToKey(Vault, KeyBuffer, true);	
		Member[Client][Ent] = KvGetNum(Vault, SteamId);	
		KvRewind(Vault);	
		KeyValuesToFile(Vault, DoorPricePath);	
		CloseHandle(Vault);		
	}
	return true;
}

public GetSold(Client, Ent)
{
	new String:KeyBuffer[255];
	IntToString(Ent, KeyBuffer, 255);	
	decl Handle:Vault;	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DoorPricePath);	
	KvJumpToKey(Vault, "Sold", true);	
	Sold[Ent] = KvGetNum(Vault, KeyBuffer, 0);		
	KvRewind(Vault);	
	CloseHandle(Vault);
	return true;
}

public GetSellPrice(Client, Ent)
{
	new String:KeyBuffer[255];
	IntToString(Ent, KeyBuffer, 255);	
	decl Handle:Vault;	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DoorPricePath);	
	KvJumpToKey(Vault, "SellPrice", true);	
	SellPrice[Ent] = KvGetNum(Vault, KeyBuffer, 0);		
	KvRewind(Vault);	
	CloseHandle(Vault);
	return true;
}

public GetDoorPrice(Client, Ent)
{
	new String:KeyBuffer[255];
	IntToString(Ent, KeyBuffer, 255);	
	decl Handle:Vault;	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DoorPricePath);	
	KvJumpToKey(Vault, "DoorPrice", true);	
	DoorPrice[Ent] = KvGetNum(Vault, KeyBuffer, 0);		
	KvRewind(Vault);	
	CloseHandle(Vault);
	return true;
}



public DoorSave(Client, Ent, OnSelldoor)
{
	if(Ent <= 0) return false;
	
	new String:KeyBuffer[255];
	IntToString(Ent, KeyBuffer, 255);	
	decl String:SteamId[64];
	GetClientAuthString(Client, SteamId, 64);	
	decl Handle:Vault;	
	Vault = CreateKeyValues("Vault6");
	
	FileToKeyValues(Vault, DoorPricePath);	
	if(MainOwner[Client][Ent] == 1)
	{
		KvJumpToKey(Vault, "MainOwner", true);
		KvJumpToKey(Vault, KeyBuffer, true);	
		KvSetNum(Vault, SteamId, MainOwner[Client][Ent]);	
		KvRewind(Vault);
	}
	else
	{
		KvJumpToKey(Vault, "MainOwner", true);
		KvJumpToKey(Vault, KeyBuffer, true);	
		KvDeleteKey(Vault, SteamId);	
		KvRewind(Vault);
	}
	
	if(Member[Client][Ent] == 1)
	{
		KvJumpToKey(Vault, "Member", true);
		KvJumpToKey(Vault, KeyBuffer, true);	
		KvSetNum(Vault, SteamId, Member[Client][Ent]);	
		KvRewind(Vault);
	}
	else
	{
		KvJumpToKey(Vault, "Member", true);
		KvJumpToKey(Vault, KeyBuffer, true);
		KvDeleteKey(Vault, SteamId);	
		KvRewind(Vault);		
	}
	if(Sold[Ent] == 1)
	{
		KvJumpToKey(Vault, "Sold", true);
		KvSetNum(Vault, KeyBuffer, Sold[Ent]);	
		KvRewind(Vault);
	}
	else
	{
		KvJumpToKey(Vault, "Sold", true);	
		KvDeleteKey(Vault, KeyBuffer);
		KvRewind(Vault);
	}
	if(AllowedFlats[Client] == 1)
	{
		KvJumpToKey(Vault, "MaxFlats", true);
		KvSetNum(Vault, SteamId, AllowedFlats[Client]);	
		KvRewind(Vault);
	}
	else
	{
		
		KvJumpToKey(Vault, "MaxFlats", true);	
		KvDeleteKey(Vault, SteamId);	
		KvRewind(Vault);
	}
	
	if(OnSelldoor == 1)
	{
		KvJumpToKey(Vault, "Member", true);
		KvDeleteKey(Vault, KeyBuffer);	
		KvRewind(Vault);
		KvJumpToKey(Vault, "MainOwner", true);	
		KvDeleteKey(Vault, KeyBuffer);	
		KvRewind(Vault);	
	}
	KeyValuesToFile(Vault, DoorPricePath);	
	CloseHandle(Vault);
	return true;
}



public SetDoorStatus(Handle:plugin, numParams)
{	
	new String:DoorEnt[255];
	IntToString(GetNativeCell(1), DoorEnt, sizeof(DoorEnt));
	new Handle:Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DoorPricePath);	
	SaveInteger(Vault, "Locked", DoorEnt, GetNativeCell(2));
	KeyValuesToFile(Vault, DoorPricePath);
	KvRewind(Vault);
	CloseHandle(Vault);
	return true;
}


stock SaveLocks(Ent) 
{
	decl Handle:Vault;
	decl String:DoorId[255];
	decl String:LockNr[255];
	
	Vault = CreateKeyValues("Vault");
	IntToString(Ent,DoorId,20);
	IntToString(DoorLocks[Ent],LockNr,20);
	FileToKeyValues(Vault, LockPath); 
	SaveString(Vault, "2", DoorId, LockNr);
	KeyValuesToFile(Vault, LockPath);
	CloseHandle(Vault);
	
	
}

//Get amount of Locks:
public getLock(Handle:plugin, numParams)
{	
	new Lock = GetNativeCell(1);
	return DoorLocks[Lock];
}

//get actual locked status:
public getLocked(Handle:plugin, numParams)
{	
	new Lock = GetNativeCell(1);
	return Locked[Lock];
}

//AppendLock:
public setDoorOwner(Handle:plugin, numParams)
{	
	new Ent = GetNativeCell(1);
	new Client = GetNativeCell(2);
	new Val = GetNativeCell(3);
	MainOwner[Client][Ent] = Val;
	DoorSave(Client, Ent, 0);
}

//AppendLock:
public getDoorOwner(Handle:plugin, numParams)
{	
	new Client = GetNativeCell(1);
	new Ent = GetNativeCell(1);
	GetMainOwner(Client, Ent);
	//for(new I = 0;I < MAXPLAYER; I++)
	//{
	if(MainOwner[Client][Ent] == 1)
		return 1;
	else 
		return 0;
	//}
}

//AppendLock:
public addLock(Handle:plugin, numParams)
{	
	new Client = GetNativeCell(1);
	new Ent = GetNativeCell(2);
	
	if(DoorLocks[Ent] >= 10)
	{
		CPrintToChat(Client,"{red}[RP]\x01 There is no more space for additional locks");
	} else
	{
		DoorLocks[Ent]++;
		SaveLocks(Ent);
	}
}

//Break Locks
public breakLock(Handle:plugin, numParams)
{	
	new Ent = GetNativeCell(1);
	DoorLocks[Ent]--;
	SaveLocks(Ent);
}

public Action:breakDoorTimer(Handle:Timer, any:Client)
{
	rp_setDefaultSpeed(Client);
	rp_crime(Client,150);
}

public Action:breakDoorTimerOpen(Handle:Timer, any:Ent)
{
	DoorLocks[Ent] = 0;
	//rp_entacceptinput(Ent, "Unlock", Client);
}

stock breakDoor(Ent)
{	
	for(new X = 0; X<MAXPLAYER; X++)
	{
		SetSpeed(X,0.0);
		rp_hud_timer(X,30,"Breaking Door");
		CreateTimer(30.0, breakDoorTimer, X);
	}
	CreateTimer(30.0, breakDoorTimerOpen, Ent);
}


//Shift Key:
public Action:CommandShift(Client)
{
	decl String:SteamId[255];
	
	
	//Initialize:
	GetClientAuthString(Client, SteamId, 32);
	
	//Declare:
	decl Ent;
	decl String:ClassName[255];
	
	//Initialize:
	Ent = rp_entclienttarget(Client,false);	
	
	//Valid:
	if(IsValidEdict(Ent) && IsValidEntity(Ent))
	{
		
		
		//Class Name:
		GetEdictClassname(Ent, ClassName, 255);		
		GetMember(Client, Ent);
		
		//Ownership:
		if(OwnsDoor[Client][Ent] == 1 || Member[Client][Ent] == 1)
			
		
		//Valid:
		if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
		{
			decl Float:ClientOrigin[3], Float:EntOrigin[3];  
			decl Float:Dist; 
			GetClientAbsOrigin(Client, ClientOrigin);
			GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", EntOrigin);
			Dist = GetVectorDistance(ClientOrigin, EntOrigin);
			
			
			if(Dist <= 130)
			{
				
				//Lock:
				if(Locked[Ent] != 1)
				{
					
					//Lock:
					Locked[Ent] = 1;
					
					//Print:
					CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 You \x04lock\x04\x01 the door");
					
					//Lock:
					rp_entacceptinput(Ent, "Lock");
					
					rp_SetDoorStatus(Ent, Locked[Ent]);
					
				}
				else
				{
					
					//Unlock:
					Locked[Ent] = 0;
					
					//Print:
					CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 You \x04unlock\x04\x01 the door");
					
					//Unlock:
					rp_entacceptinput(Ent, "Unlock");
					
					rp_SetDoorStatus(Ent, Locked[Ent]);
				}	
			}
			
		}
	}	
	return Plugin_Handled;
}



//E Key:
public CommandOpen(Client)
{
	
	//Declare:
	decl Ent;
	decl String:ClassName[255];
	
	//Initialize:
	Ent = rp_entclienttarget(Client,false);
	decl String:SteamId[255];
	
	//Initialize:
	GetClientAuthString(Client, SteamId, 32);
	
	//Valid:
	if(IsValidEdict(Ent) && IsValidEntity(Ent) && IsValidClient(Client))
	{
		
		GetEdictClassname(Ent, ClassName, 255);		
		GetMember(Client, Ent);		
		
		//Ownership:
		if(OwnsDoor[Client][Ent] == 1 || Member[Client][Ent] == 1)
		{
			
			//Valid:
			if(StrEqual(ClassName, "func_door"))
			{
				//Open:
				rp_entacceptinput(Ent, "Toggle", Client);
			}
		}
	}	
}


public Action:OnPlayerRunCmd(Client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{
	if(buttons & IN_USE)
	{
		if(!PrethinkBuffer[Client])
		{
			if(!rp_iscuff(Client))CommandOpen(Client);
			PrethinkBuffer[Client] = true;
		}
	}
	else if(buttons & IN_SPEED)
	{
		if(!PrethinkBuffer[Client])
		{
		if(!rp_iscuff(Client)) CommandShift(Client);
		PrethinkBuffer[Client] = true;
		}
	}
	else
	{
		PrethinkBuffer[Client] = false;
	}
	return Plugin_Continue;	
}


//Information:
public Plugin:myinfo =
{

	//Initation:
	name = "Doors",
	author = "Joe 'Pinkfairie' Maley and Krim",
	description = "Doormod for RP",
	version = "1.5",
	url = "hiimjoemaley@hotmail.com & wmchris.de"
}

//Map Start:
public OnMapStart()
{
	
	decl String:Map[128], String:Path[64];
	GetCurrentMap(Map, 128);

	BuildPath(Path_SM, Path, 64, "data/roleplay/%s/", Map);
	CreateDirectory(Path,511);
	
	//Name DB:
	BuildPath(Path_SM, NamePath, 64, "data/roleplay/names.txt");
	BuildPath(Path_SM, DoorPricePath, 64, "data/roleplay/%s/doorprice.txt",Map);
	
	//Lock DB:
	BuildPath(Path_SM, LockPath, 64, "data/roleplay/%s/lock.txt",Map);
	
	
	//Declare:
	decl Handle:Vault;
	
	//Initialize:
	Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, DoorPricePath);
	
	
	new String:Entity[255];
	for(new X = 0; X < 64; X++)
	{
		IntToString(X, Entity, 255);
		
		PoliceDoors[X] = LoadInteger(Vault, "PoliceDoor", Entity, 0);
		KvRewind(Vault);
	}
	
	
	//Close:
	CloseHandle(Vault);
	
	
	//Load Locks
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, LockPath);
	
	decl String:ReferenceString[255], String:ItemId[255];
	
	//Loop:
	for(new X = 0; X < MAXDOORS; X++)
	{
		//Convert:
		IntToString(X, ItemId, sizeof(ItemId));
		
		//Load:
		LoadString(Vault, "2", ItemId, "Null", ReferenceString);
		
		//Check:
		if(!StrEqual(ReferenceString, "Null"))
		{
			DoorLocks[X] = StringToInt(ReferenceString);
		}
	}
	CloseHandle(Vault);
	
	Vault = CreateKeyValues("Vault");
	decl String:DoorId[255];
	for(new X = 0; X < MAXDOORS; X++)
	{
		IntToString(X, DoorId, 255); 				
		FileToKeyValues(Vault, DoorPricePath);
		Locked[X] = LoadInteger(Vault, "Locked", DoorId, 0);
		if(Locked[X] == 1) rp_entacceptinput(X, "Lock");	
		KvRewind(Vault);
	}
	
	CloseHandle(Vault);
	
	
}


public Action:CommandDoorCop(Client, args)
{
	
	//Arguments:
	if(args < 2)
	{
		
		//Print:
		CPrintToChat(Client, "{teamcolor}[RP]\x01 Usage: sm_copdoor <#id|name> <1|0>");
		
		//Return:
		return Plugin_Handled;
	}
	new String:PlayerName[32], String:Buffer[5];
	GetCmdArg(1, PlayerName, sizeof(PlayerName));
	GetCmdArg(2, Buffer, sizeof(Buffer));
	
	new Player = FindTarget(Client, PlayerName);
	if(Player == -1)
	{
		CPrintToChat(Client, "{teamcolor}[RP]\x01 Could not find Client \x04%s\x01", PlayerName);
		return Plugin_Handled;
	}
	
	for(new X = 0; X < 64; X++)
	{
		if(PoliceDoors[X] != 0)	OwnsDoor[Player][PoliceDoors[X]] = 1;
	}
	
	//Return:
	return Plugin_Handled;
}



//Initation:
public OnPluginStart()
{

	//DoorSystem - Admin
	RegAdminCmd("rp_givemainowner", CommandGiveMainOwner, ADMFLAG_ROOT, "<SteamID> - Remove user by SteamId");
	RegAdminCmd("rp_takemainowner", CommandTakeMainOwner, ADMFLAG_ROOT, "Take Main Owner");
	RegAdminCmd("rp_deletecopdoor", CommandDeleteCopDoor, ADMFLAG_ROOT, "Give Main Owner");
	RegAdminCmd("rp_setcopdoor", CommandSetCopDoor, ADMFLAG_ROOT, "Set cop door");
	RegAdminCmd("rp_copdoor", CommandDoorCop, ADMFLAG_ROOT, "<SteamID> - Gives the Cop door permissions");
	RegAdminCmd("rp_setalldoors", CommandAllDoors, ADMFLAG_ROOT, "<SteamID> - Remove user by SteamId");
	RegAdminCmd("rp_binddoor", CommandBindDoor, ADMFLAG_ROOT, "<SteamID> - Remove user by SteamId");	
	RegAdminCmd("rp_makedoor", CommandMakedoor, ADMFLAG_ROOT, "<SteamID> - Remove user by SteamId");	
	RegAdminCmd("rp_setsold", CommandSetSold, ADMFLAG_ROOT, "<SteamID> - Remove user by SteamId");	
	RegAdminCmd("rp_setdoorprice", Command_setdoorprice, ADMFLAG_ROOT, "- Set the Doors Price!");
	RegAdminCmd("rp_setsellprice", Command_setsellprice, ADMFLAG_ROOT, "- Set the Doors Sell Price!");
	RegAdminCmd("rp_setlocks", Command_setlocks, ADMFLAG_ROOT, "- Set the doorlocks!");
	
	//DoorSystem - Console
	RegConsoleCmd("sm_givedoor", Command_GiveDoorPlayer);
	RegConsoleCmd("sm_takedoor", Command_TakeDoorPlayer);
	RegConsoleCmd("sm_resetdoor", Command_ResetDoor);
	RegConsoleCmd("sm_doorname", Command_doorname);
	RegConsoleCmd("sm_buydoor", Command_buydoor);
	RegConsoleCmd("sm_selldoor", Command_selldoor);
	RegConsoleCmd("sm_doorinfo", Command_doorinfo);

	HookEvent("player_spawn", EventSpawn);
	
	//Server Variable:
	CreateConVar("door_version", "3.0", "Doors Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	LoadTranslations("common.phrases");
}