/** Double-include prevention */
#if defined _rp_funcs_included_
  #endinput
#endif
#define _rp_funcs_included_

//Terminate:
#pragma semicolon 1

// Hud Element hiding flags
#define	HIDEHUD_WEAPONSELECTION		( 1<<0 )	// Hide ammo count & weapon selection
#define	HIDEHUD_FLASHLIGHT			( 1<<1 )
#define	HIDEHUD_ALL					( 1<<2 )
#define HIDEHUD_HEALTH				( 1<<3 )	// Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD			( 1<<4 )	// Hide when local player's dead
#define HIDEHUD_NEEDSUIT			( 1<<5 )	// Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS			( 1<<6 )	// Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT				( 1<<7 )	// Hide all communication elements (saytext, voice icon, etc)
#define	HIDEHUD_CROSSHAIR			( 1<<8 )	// Hide crosshairs
#define	HIDEHUD_VEHICLE_CROSSHAIR	( 1<<9 )	// Hide vehicle crosshair
#define HIDEHUD_INVEHICLE			( 1<<10 )
#define HIDEHUD_NAME			64
  
static Float:GameTime[33];
public String:ConVarValue[33][64];

//Change MAP if not already done and switch to TeamPlay Mode
stock FixMap(const String:DesiredMap[255])
{

	//Declare:
	decl String:MapName[64];

	//Initialize:
	GetCurrentMap(MapName, 64);
	
	new Handle:cvtp = FindConVar("mp_teamplay");

	//Check:
	if(!StrEqual(DesiredMap, MapName) || GetConVarInt(cvtp) != 1)
	{
		//Print:
		if(GetConVarInt(cvtp) != 1) PrintToConsole(0, "[RP] switching to teamplay mode with map '%s'", DesiredMap);
		if(!StrEqual(DesiredMap, MapName)) PrintToConsole(0, "[RP] Changing map to %s", DesiredMap);

		//Change:
		ServerCommand("mp_teamplay 1");
		ServerCommand("map %s", DesiredMap);
	}
}


/*
 * KEYVALUES : Saves an Integer
 * @param Vault Handle to the text file
 * @param Key The keyvalue name to use
 * @param SteamId The authid of the client
 * @param Variable Integer to store
 */
stock SaveInteger(Handle:Vault, const String:Key[32], const String:SaveKey[255], Variable)
{

	//Delete:
	if(Variable <= 0)
	{
		KvJumpToKey(Vault, Key, false);
		KvDeleteKey(Vault, SaveKey);
		KvRewind(Vault);
	}
	else
	{
		KvJumpToKey(Vault, Key, true);
		KvSetNum(Vault, SaveKey, Variable);
		KvRewind(Vault);
	}
}

/*
 * KEYVALUES : Saves a string
 * @param Vault Handle to the text file
 * @param Key The keyvalue name to use
 * @param SteamId The authid of the client
 * @param Variable String to store
 */
stock SaveString(Handle:Vault, const String:Key[32], const String:SaveKey[255], const String:Variable[255])
{
	KvJumpToKey(Vault, Key, true);
	KvSetString(Vault, SaveKey, Variable);
	KvRewind(Vault);
}

/*
 * KEYVALUES : Loads an integer
 * @param Vault Handle to the text file
 * @param Key The keyvalue name to use
 * @param SteamId The authid of the client
 * @param DefaultValue Integer to return if key not found
 */
stock LoadInteger(Handle:Vault, const String:Key[32], const String:SaveKey[255], DefaultValue)
{
	decl Variable;
	KvJumpToKey(Vault, Key, false);
	Variable = KvGetNum(Vault, SaveKey, DefaultValue);
	KvRewind(Vault);
	return Variable;
}

/*
 * KEYVALUES : Loads a string
 * @param Vault Handle to the text file
 * @param Key The keyvalue name to use
 * @param SteamId The authid of the client
 * @param DefaultValue String to return if key not found
 * @param Reference String to return through reference
 */
stock LoadString(Handle:Vault, const String:Key[32], const String:SaveKey[255], const String:DefaultValue[255], String:Reference[255])
{
	KvJumpToKey(Vault, Key, false);
	KvGetString(Vault, SaveKey, Reference, 255, DefaultValue);
	KvRewind(Vault);
}

stock Float:calcDistanceToTarget(Client,Player)
{
	decl Float:ClientOrigin[3], Float:PlayerOrigin[3];
	
	GetClientAbsOrigin(Client, ClientOrigin);
	ClientOrigin[2] += 40.0;
	
	if(Player > 0)
		GetClientAbsOrigin(Player, PlayerOrigin);
	return GetVectorDistance(ClientOrigin, PlayerOrigin);
}

stock FindPlayer(Client,String:idstr[])
{
	new uid = StringToInt(idstr);
	new id = GetClientOfUserId(uid);
	new MaxC = GetMaxClients();
	
	if(id == 0)
	{
		new numclients = 0;
		new numid = 0;
		new String:name[50];
		for(new i=1;i<MaxC;i++)
		{
			if(!IsClientInGame(i)) continue;
			GetClientName(i, name, 50);
			if(StrContains(name, idstr, false) != -1)
			{
				numclients++;
				if(numclients > 1) break;
				numid = i;
			}
		}
		if(numclients > 1)
		{
			PrintToConsole(Client,"There is more than one client matching that string, please be more specific.");
			return 0;
		}
		id = numid;
		if(id == 0)
		{
			//PrintToConsole(aid,"Client not found.");
			return 0;
		}
	}
	return id;
}


stock calcEnt(Ent)
{
	new MaxC = GetMaxClients();
	return MaxC + Ent;
}

stock calcSaveEnt(Ent)
{
	new MaxC = GetMaxClients();
	return Ent - MaxC;
}


stock PrintRobberyAbort(Client)
{
	
	//Declare:
	decl MaxPlayers;
	
	//Initialize:
	MaxPlayers = GetMaxClients();
	
	//Loop:
	for(new Y = 1; Y < MaxPlayers; Y++)
	{
		
		//Connected:
		if(IsClientConnected(Y) && IsClientInGame(Y))
		{
			
			//Declare:
			decl String:PlayerName[32];
			
			//Initialize:
			GetClientName(Client, PlayerName, 32);
			
			//Print:
			SetHudTextParams(-1.0, 0.015, 10.0, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
			ShowHudText(Y, -1, "\n\n[ATTENTION] %s is getting away!", PlayerName);
			CPrintToChat(Y, "{red}[RP]\x04[ATTENTION] %s\x04\x01 is getting away!", PlayerName);
		}
	}
}

//Functions for Casting
stock bool:int2bool(i)
{
	if(i == 1) return true; else return false;
}

stock bool2int(bool:i)
{
	if(i) return 1; else return 0;
}


//Mathematic funcs
stock bool:IsBetween(Value, min, max, bool:equal = false) 
{
	if(equal)
	{
		if(Value >= min && Value <= max) return true
	}
	else
	{
		if(Value > min && Value < max) return true;
	}
	return false;	
}


//Detect Teamkill
stock bool:TeamKill(Attacker, Client) 
{
	if(GetConVarInt(FindConVar("mp_teamplay")) == 1)
	{
		if(GetClientTeam(Attacker) == GetClientTeam(Client)) return true;
	}
	return false;	
}


//MISC
public bool:TraceEntityFilterPlayer(entity, contentsMask) {

	return entity <= 0;
}

//Check if player is looking at a wall using TraceRays
stock bool:LookAtWall(Client, Float:Dist) {


	decl Float:posEye[3], Float:posEyeAngles[3];
	new bool:isClientLookingAtWall = false;
	
	GetClientEyePosition(Client, posEye);
	GetClientEyeAngles(Client, posEyeAngles);
	


	posEyeAngles[0] = 0.0;
	new Handle:trace = TR_TraceRayFilterEx(posEye, posEyeAngles, CONTENTS_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	

	if (TR_DidHit(trace))
	{		
		if (TR_GetEntityIndex(trace) > 0) 
		{			
			return false;
		}
		
		decl Float:posEnd[3];
		TR_GetEndPosition(posEnd, trace);
		
		if (GetVectorDistance(posEye, posEnd) <= Dist ) 
		{		
			isClientLookingAtWall = true;
		}
	}
	
	CloseHandle(trace);
	
	return isClientLookingAtWall;
}


//Check if plugin is running
stock bool:IsPluginRuning(const String:plugin[])
{
	new Handle:Plugin_Roleplay = FindPluginByFile("plugin"); 		
	new PluginStatus:Plugin_Roleplay_Status = GetPluginStatus(Plugin_Roleplay);		
	
	if(Plugin_Roleplay == INVALID_HANDLE || Plugin_Roleplay_Status != Plugin_Running)
	{
		return false;
	}
	return true;
}

//Show/Hide Hud
stock HideHud(Client, flags)
{	
	SetEntProp(Client, Prop_Send, "m_iHideHUD", flags);
}

//Return m_iFrags of the Player
stock GetClientScore(Client)
{
	return GetEntProp(Client, Prop_Data, "m_iFrags");
}

//Sets the m_iFrags of the Player
stock SetClientScore(Client, score)
{
	SetEntProp(Client, Prop_Data, "m_iFrags", score);
}

//Changes the Deathcounter of the Player
stock SetClientDeath(Client, death)
{
	SetEntProp(Client, Prop_Data, "m_iDeaths", death); 
}

//Entity Funcs
stock GetEntityMaxs(entity, Float:vec[3])
{
    GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vec);    
}

stock GetEntityMins(entity, Float:vec[3])
{
    GetEntPropVector(entity, Prop_Send, "m_vecMins", vec);    
}

stock SetEntityMaxs(entity, Float:vec[3])
{
    SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vec);    
}

stock SetEntityMins(entity, Float:vec[3])
{
    SetEntPropVector(entity, Prop_Send, "m_vecMins", vec);    
}

stock SetEntitySolid(entity, solid)
{
	new Collision = GetEntSendPropOffs(entity, "m_CollisionGroup");
	SetEntData(entity, Collision, solid, 1, true);
}


stock bool:IsValidClient(Client)
{
	if(Client == 0) return false;
	if(!IsClientConnected(Client) || !IsClientInGame(Client))return false;
	if(IsFakeClient(Client)) return false;
	if(Client == 0)return false;
	return true;
}

stock GetClientConVar(Client, const String:Name[], String:Value[64])
{  
	QueryClientConVar(Client, Name, ConVarQueryFinished:ClientConVar, Client);
	
	Value = ConVarValue[Client]
	return Value
}


public ClientConVar(QueryCookie:cookie, Client, ConVarQueryResult:result, const String:cvarName[64], const String:cvarValue[64])
{
	ConVarValue[Client] = cvarValue;
	PrintToChatAll("%s", ConVarValue[Client]);
}

stock OverflowMessage(Client, String:Contents[])
{
	
	//Anti-Spam:
	if(GameTime[Client] <= (GetGameTime() - 10))
	{
		
		//Print:
		CPrintToChat(Client, Contents);
		
		//Save:
		GameTime[Client] = GetGameTime();
	}
	
}

stock GetRandomPlayer()
{
	new Online = 0;
	
	for(new X = 1;X <= GetMaxClients();X++)
	{
		if(IsClientConnected(X) && IsClientInGame(X))
		{
			Online++;
		}
	}	
	return GetRandomInt(1, Online);
}

stock bool:CheckAdminFlagsByString(Client, flagString)
{
	if (GetUserFlagBits(Client) & ADMFLAG_ROOT)
	{
		return true;
	} 
	
	if (GetUserFlagBits(Client) & flagString)
	{
		return true;
	} 
	return false;
}

stock AutoPreCacher(const String:FilePath[])
{
	//Declare
	new String:DownloadPath[64];
	//Download Path
	BuildPath(Path_SM, DownloadPath, 64, FilePath);
	if(FileExists(DownloadPath) == false) SetFailState("[SM] ERROR: Missing file '%s'", DownloadPath);
	
	//Auto Downloader
	new Handle:fileh = OpenFile(DownloadPath, "r");
	new String:buffer[256];
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		new len = strlen(buffer);
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0';
		TrimString(buffer);
		if (FileExists(buffer))
		{
			
			if(StrContains(buffer, ".mdl", false) != -1)
			{
				PrecacheModel(buffer)
			}
			
			if(StrContains(buffer, ".wav", false) != -1 || StrContains(buffer, ".mp3", false) != -1)
			{
				PrecacheSound(buffer, true)	
			}
			
		}
		
		if (IsEndOfFile(fileh))
			break;
	} 	
	
}
stock AutoDownloader(const String:FilePath[])
{
	//Declare
	new String:DownloadPath[64];
	//Download Path
	BuildPath(Path_SM, DownloadPath, 64, FilePath);
	if(FileExists(DownloadPath) == false) SetFailState("[SM] ERROR: Missing file '%s'", DownloadPath);
	
	//Auto Downloader
	new Handle:fileh = OpenFile(DownloadPath, "r");
	new String:buffer[256];
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		new len = strlen(buffer);
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0';
		TrimString(buffer);
		if (FileExists(buffer))
		{
			AddFileToDownloadsTable(buffer);
		}
		
		if (IsEndOfFile(fileh))
			break;
	} 	
	
}

stock LogMSG(const String:file[], const String:format[])
{
	PrintToServer(format);
	LogToFile(file,format);
}	