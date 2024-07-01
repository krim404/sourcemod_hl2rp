
//Includes:
#include <sourcemod>
#include <sdktools>
#include <roleplay/COLORS>  

//Terminate:
#pragma semicolon 1

//Stocks:
#include "roleplay/rp_include"

//Definitions:
#define MAXSPAWNS	25
#define MAXCOPSPAWNS	15

//Database:
static String:SpawnPath[128];
static Float:SpawnPoints[MAXSPAWNS][3];
static Float:CopSpawnPoints[MAXCOPSPAWNS][3];


//Random Spawn:
stock RandomizeCopSpawn(Client)
{

	//Roll:
	decl Roll;
	decl bool:Legit;

	//Initialize:
	Roll = GetRandomInt(0, MAXCOPSPAWNS - 1);
	
	//Check:
	Legit = false;
	if(CopSpawnPoints[Roll][0] != 69.0) Legit = true;

	//Try Again:
	if(!Legit) RandomizeCopSpawn(Client);
	else
	{

		//Declare:
		new Float:RandomAngles[3];

		//Vectors:
		GetClientAbsAngles(Client, RandomAngles);
		RandomAngles[1] = GetRandomFloat(0.0, 360.0);

		//Spawn:
		TeleportEntity(Client, CopSpawnPoints[Roll], RandomAngles, NULL_VECTOR);
	}
}


//Create NPC:
public Action:CommandCreateSpawn(Client, Args)
{

	//Error:
	if(Args < 1)
	{

		//Print:
		PrintToConsole(Client, "[RP] - Usage: sm_createspawn <id>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl Handle:Vault;
	decl String:SpawnId[32];
	decl Float:ClientOrigin[3];

	//Initialize:
	GetCmdArg(1, SpawnId, 32);
	GetClientAbsOrigin(Client, ClientOrigin);

	//Vault:
	Vault = CreateKeyValues("Vault");

	//Retrieve:
	FileToKeyValues(Vault, SpawnPath);

	//Save:
	KvJumpToKey(Vault, "Spawns", true);
	KvSetVector(Vault, SpawnId, ClientOrigin);
	KvRewind(Vault);

	//Store:
	KeyValuesToFile(Vault, SpawnPath);

	//Print:
	PrintToConsole(Client, "[RP] - Created spawn #%s @ <%f, %f, %f>", SpawnId, ClientOrigin[0], ClientOrigin[1], ClientOrigin[2]);
	PrintToConsole(Client, "[RP] - Changes will take effect after map restart");
	
	//Close:
	CloseHandle(Vault);

	LogAction(Client, -1, "\"%L\" added spawnpoint", Client);

	//Return:
	return Plugin_Handled;
}
//Create NPC:
public Action:CommandCreateCopSpawn(Client, Args)
{

	//Error:
	if(Args < 1)
	{

		//Print:
		PrintToConsole(Client, "[RP] - Usage: sm_createCopspawn <id>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl Handle:Vault;
	decl String:SpawnId[32];
	decl Float:ClientOrigin[3];

	//Initialize:
	GetCmdArg(1, SpawnId, 32);
	GetClientAbsOrigin(Client, ClientOrigin);

	//Vault:
	Vault = CreateKeyValues("Vault");

	//Retrieve:
	FileToKeyValues(Vault, SpawnPath);

	//Save:
	KvJumpToKey(Vault, "CopSpawns", true);
	KvSetVector(Vault, SpawnId, ClientOrigin);
	KvRewind(Vault);

	//Store:
	KeyValuesToFile(Vault, SpawnPath);

	//Print:
	PrintToConsole(Client, "[RP] - Created spawn #%s @ <%f, %f, %f>", SpawnId, ClientOrigin[0], ClientOrigin[1], ClientOrigin[2]);
	PrintToChat(Client, "[RP] - Changes will take effect after map restart");
	
	//Close:
	CloseHandle(Vault);

	LogAction(Client, -1, "\"%L\" added spawnpoint", Client);

	//Return:
	return Plugin_Handled;
}


//Remove Spawn:
public Action:CommandRemoveCopSpawn(Client, Args)
{

	//Error:
	if(Args < 1)
	{

		//Print:
		PrintToConsole(Client, "[RP] - Usage: sm_createspawn <id>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:	
	decl bool:Deleted;
	decl Handle:Vault;
	decl String:SpawnId[32];

	//Initialize:
	GetCmdArg(1, SpawnId, sizeof(SpawnId));

	//Vault:
	Vault = CreateKeyValues("Vault");

	//Retrieve:
	FileToKeyValues(Vault, SpawnPath);

	//Delete:
	KvJumpToKey(Vault, "CopSpawns", false);
	Deleted = KvDeleteKey(Vault, SpawnId); 
	KvRewind(Vault);

	//Store:
	KeyValuesToFile(Vault, SpawnPath);

	//Print:
	if(!Deleted) PrintToChat(Client, "[RP] - Failed to remove Spawn %s from the database", SpawnId);
	else 
	{

		//Print:
		PrintToConsole(Client, "[RP] - Removed Spawn %s from the database", SpawnId);
		CPrintToChat(Client, "[RP] - Changes will take effect after map restart");
	}

	//Close:
	CloseHandle(Vault);

	LogAction(Client, -1, "\"%L\" removed spawnpoint", Client);

	//Return:
	return Plugin_Handled;
}

//Remove Spawn:
public Action:CommandRemoveSpawn(Client, Args)
{

	//Error:
	if(Args < 1)
	{

		//Print:
		PrintToConsole(Client, "[RP] - Usage: sm_createspawn <id>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:	
	decl bool:Deleted;
	decl Handle:Vault;
	decl String:SpawnId[32];

	//Initialize:
	GetCmdArg(1, SpawnId, sizeof(SpawnId));

	//Vault:
	Vault = CreateKeyValues("Vault");

	//Retrieve:
	FileToKeyValues(Vault, SpawnPath);

	//Delete:
	KvJumpToKey(Vault, "Spawns", false);
	Deleted = KvDeleteKey(Vault, SpawnId); 
	KvRewind(Vault);

	//Store:
	KeyValuesToFile(Vault, SpawnPath);

	//Print:
	if(!Deleted) PrintToChat(Client, "[RP] - Failed to remove Spawn %s from the database", SpawnId);
	else 
	{

		//Print:
		PrintToConsole(Client, "[RP] - Removed Spawn %s from the database", SpawnId);
		PrintToChat(Client, "[RP] - Changes will take effect after map restart");
	}

	//Close:
	CloseHandle(Vault);

	LogAction(Client, -1, "\"%L\" removed spawnpoint", Client);

	//Return:
	return Plugin_Handled;
}

//List Spawns:
public Action:CommandListSpawns(Client, Args)
{

	//Declare:	
	decl Handle:Vault;

	//Vault:
	Vault = CreateKeyValues("Vault");

	//Retrieve:
	FileToKeyValues(Vault, SpawnPath);

	//Header:
	PrintToConsole(Client, "Spawns:");

	//Loop:
	for(new X = 0; X < MAXSPAWNS; X++)
	{

		//Check:
		if(SpawnPoints[X][0] != 69.0) PrintToConsole(Client, "%d: <%f, %f, %f>", X, SpawnPoints[X][0], SpawnPoints[X][1], SpawnPoints[X][2]);
	}

	//Close:
	CloseHandle(Vault);

	//Return:
	return Plugin_Handled;
}


//List Spawns:
public Action: CommandCopListSpawns(Client, Args)
{

	//Declare:	
	decl Handle:Vault;

	//Vault:
	Vault = CreateKeyValues("Vault");

	//Retrieve:
	FileToKeyValues(Vault, SpawnPath);

	//Header:
	PrintToConsole(Client, "Spawns:");

	//Loop:
	for(new X = 0; X < MAXSPAWNS; X++)
	{

		//Check:
		if(SpawnPoints[X][0] != 69.0) PrintToConsole(Client, "%d: <%f, %f, %f>", X, CopSpawnPoints[X][0], CopSpawnPoints[X][1], CopSpawnPoints[X][2]);
	}

	//Close:
	CloseHandle(Vault);

	//Return:
	return Plugin_Handled;
}

//Load Spawn:
public Action:LoadSpawns(Handle:Timer, any:Client)
{

	//Declare:
	decl Handle:Vault;
	decl String:Key[32];

	//Initialize:
	Vault = CreateKeyValues("Vault");
	new Float:DefaultSpawn[3] = {69.0, 69.0, 69.0};

	//Retrieve:
	FileToKeyValues(Vault, SpawnPath);

	//Load:
	for(new X = 0; X < MAXSPAWNS; X++)
	{

		//Convert:
		IntToString(X, Key, 32);
		
		//Find:
		KvJumpToKey(Vault, "Spawns", false);
		KvGetVector(Vault, Key, SpawnPoints[X], DefaultSpawn);
		KvRewind(Vault);
	}

	//Close:
	CloseHandle(Vault);
}


//Random Spawn:
stock RandomizeSpawn(Client)
{

	//Roll:
	decl Roll;
	decl bool:Legit;

	//Initialize:
	Roll = GetRandomInt(0, MAXSPAWNS - 1);
	
	//Check:
	Legit = false;
	if(SpawnPoints[Roll][0] != 69.0) Legit = true;

	//Try Again:
	if(!Legit) RandomizeSpawn(Client);
	else
	{

		//Declare:
		new Float:RandomAngles[3];

		//Vectors:
		GetClientAbsAngles(Client, RandomAngles);
		RandomAngles[1] = GetRandomFloat(0.0, 360.0);

		//Spawn:
		TeleportEntity(Client, SpawnPoints[Roll], RandomAngles, NULL_VECTOR);
	}
}

//Load Spawn:
public Action:LoadCopSpawns(Handle:Timer, any:Client)
{

	//Declare:
	decl Handle:Vault;
	decl String:Key[32];

	//Initialize:
	Vault = CreateKeyValues("Vault");
	new Float:DefaultCopSpawn[3] = {69.0, 69.0, 69.0};

	//Retrieve:
	FileToKeyValues(Vault, SpawnPath);

	//Load:
	for(new X = 0; X < MAXCOPSPAWNS; X++)
	{

		//Convert:
		IntToString(X, Key, 32);
		
		//Find:
		KvJumpToKey(Vault, "CopSpawns", false);
		KvGetVector(Vault, Key, CopSpawnPoints[X], DefaultCopSpawn);
		KvRewind(Vault);
	}

	//Close:
	CloseHandle(Vault);
}

//Spawn:
public EventSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
	decl Client;

	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	if (GetClientTeam(Client) == 2)
	{
		//Load:
		RandomizeCopSpawn(Client);
	}
	else if (GetClientTeam(Client) == 3)
	{
		//Load:
		RandomizeSpawn(Client);
	}

	//Close:
	CloseHandle(Event);
}

//Information:
public Plugin:myinfo =
{

	//Initation:
	name = "SpawnPoints.",
	author = "Joe 'Pinkfairie' Maley, Christian 'Krim' Uhl && Master(D) Aka Master53",
	description = "Spawns rebals and cops in different spawnpoints",
	version = "1.5",
	url = "dj_jonezy@live.co.uk"
}


//Map Start:
public OnMapStart()
{
	decl String:Map[128], String:Path[64];
	GetCurrentMap(Map, 128);

	BuildPath(Path_SM, Path, 64, "data/roleplay/%s/", Map);
	CreateDirectory(Path,511);
	
	//Spawn DB:
	BuildPath(Path_SM, SpawnPath, 64, "data/roleplay/%s/spawn.txt",Map);
	
	//Create Spawns:
	CreateTimer(1.5, LoadCopSpawns);
	CreateTimer(1.0, LoadSpawns);	
}

//Initation:
public OnPluginStart()
{
	
	//Commands:
	RegAdminCmd("rp_createspawn", CommandCreateSpawn, ADMFLAG_CUSTOM4, "<id> - Creates a spawn point");
	RegAdminCmd("rp_removespawn", CommandRemoveSpawn, ADMFLAG_CUSTOM4, "<id> - Removes a spawn point");
	RegAdminCmd("rp_spawnlist", CommandListSpawns, ADMFLAG_CUSTOM1, "- Lists all the Spawnss in the database");
	
	RegAdminCmd("rp_createcopspawn", CommandCreateCopSpawn, ADMFLAG_CUSTOM6, "<id> - Creates a spawn point");
	RegAdminCmd("rp_removecopspawn", CommandRemoveCopSpawn, ADMFLAG_CUSTOM6, "<id> - Removes a spawn point");
	RegAdminCmd("rp_copspawnlist", CommandCopListSpawns, ADMFLAG_CUSTOM5, "- Lists all the Spawns in the database");

	//Events:
	HookEvent("player_spawn", EventSpawn);
	
	//Server Variable:
	CreateConVar("spawn_version", "1.0", "Spawn Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}