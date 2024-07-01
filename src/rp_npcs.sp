//Roleplay v3.0 NPCs
//Idea and first implementations by Joe 'Pinkfairie' Maley
//Programmed by Christian 'Krim' Uhl 
//Licence: Creative Commons BY-NC-SA
//http://creativecommons.org/licenses/by-nc-sa/3.0/


//Terminate:
#pragma semicolon 1

//Stocks:
#include "roleplay/rp_wrapper"
#include "roleplay/rp_include"
#include "roleplay/rp_hud"

//Definitions:
#define MAXNPCS	100

//Database:
static String:NPCPath[128];
static NPCList[MAXNPCS];
static NPCListInverse[4000];

//Create NPC:
public Action:CommandCreateNPC(Client, Args)
{

	//Error:
	if(Args < 3)
	{

		//Print:
		PrintToConsole(Client, "[RP] Usage: rp_createnpc <id> <NPC> <type> <opt model>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl Handle:Vault;
	decl String:Buffers[7][32];
	decl Float:Origin[3], Float:Angles[3];
	decl String:SaveBuffer[255], String:NPCId[255];

	//Initialize:
	GetCmdArg(1, NPCId, 32);
	GetCmdArg(2, Buffers[0], 32);
	GetCmdArg(3, Buffers[6], 32);
	GetCmdArg(4, Buffers[5], 32);
	GetClientAbsOrigin(Client, Origin);
	GetClientAbsAngles(Client, Angles);
	IntToString(RoundFloat(Origin[0]), Buffers[1], 32);
	IntToString(RoundFloat(Origin[1]), Buffers[2], 32);
	IntToString(RoundFloat(Origin[2]), Buffers[3], 32);
	IntToString(RoundFloat(Angles[1]), Buffers[4], 32);

	//Implode:
	ImplodeStrings(Buffers, 6, " ", SaveBuffer, 255);

	//Vault:
	Vault = CreateKeyValues("Vault");

	//Retrieve:
	FileToKeyValues(Vault, NPCPath);

	//Save:
	SaveString(Vault, Buffers[6], NPCId, SaveBuffer);

	//Store:
	KeyValuesToFile(Vault, NPCPath);

	//Print:
	PrintToConsole(Client, "[RP] Added NPC %s, npc_%s <%s, %s, %s> YAxis: %s", NPCId, Buffers[0], Buffers[1], Buffers[2], Buffers[3], Buffers[4]);
	PrintToConsole(Client, "[RP] Changes will take effect after map restart");
	
	//Close:
	CloseHandle(Vault);

	//Return:
	return Plugin_Handled;
}

//NPC notice:
public Action:CommandSetNotice(Client, Args)
{

	//Error:
	if(Args < 2)
	{
	
		//Print:
		PrintToConsole(Client, "[RP] Usage: rp_npcnotice <id> <text>");
		
		//Return:
		return Plugin_Handled;
	}
	decl String:Buffers[64],String:Buffers2[255],ID,Handle:Vault; 
	GetCmdArg(1, Buffers, 64);
	GetCmdArg(2, Buffers2, 255);  
	ID = StringToInt(Buffers);
	
	if(NPCList[ID])
		rp_setNpcNotice(NPCList[ID],Buffers2);
	
	//Save
	Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, NPCPath);
	
	new String:Buffers3[255];
	Buffers3 = Buffers;
	//Save:
	SaveString(Vault, "Notice", Buffers3, Buffers2);
	
	//Store:
	KeyValuesToFile(Vault, NPCPath);
	CloseHandle(Vault); 
	PrintToChat(Client, "[RP] Notice '%s' has been set to NPC #%d.", Buffers2, ID); 
	return Plugin_Handled;  
}

//See NPC ID from EntID
public Action:CommandNPCWho(Client, Args)
{
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	
	if(Ent > 0)
	{
		PrintToChat(Client, "[RP] NPC Id: #%d",NPCListInverse[Ent]); 
	}
	return Plugin_Handled;
}

//Remove NPC:
public Action:CommandRemoveNPC(Client, Args)
{

	//Error:
	if(Args < 2)
	{

		//Print:
		PrintToConsole(Client, "[RP] Usage: rp_removenpc <type> <id>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:	
	decl bool:Deleted;
	decl Handle:Vault;
	decl String:NPCId[255], String:Type[255];

	//Initialize:
	GetCmdArg(1, Type, sizeof(Type));
	GetCmdArg(2, NPCId, sizeof(NPCId));

	//Vault:
	Vault = CreateKeyValues("Vault");

	//Retrieve:
	FileToKeyValues(Vault, NPCPath);

	//Delete:
	KvJumpToKey(Vault, Type, false);
	Deleted = KvDeleteKey(Vault, NPCId); 
	KvRewind(Vault);
	KvJumpToKey(Vault, "Notice", false);
	Deleted = KvDeleteKey(Vault, NPCId);
	KvRewind(Vault);

	//Store:
	KeyValuesToFile(Vault, NPCPath);

	//Print:
	if(!Deleted) PrintToConsole(Client, "[RP] Failed to remove NPC %s (Type: %s) from the database", NPCId, Type);
	else 
	{

		//Print:
		PrintToConsole(Client, "[RP] Removed NPC %s (Type: %s) from the database", NPCId, Type);
		PrintToConsole(Client, "[RP] Changes will take effect after map restart");
	}

	//Close:
	CloseHandle(Vault);

	//Return:
	return Plugin_Handled;
}

//List NPCs:
public Action:CommandListNPCs(Client, Args)
{

	//Declare:	
	decl Handle:Vault;

	//Vault:
	Vault = CreateKeyValues("Vault");

	//Retrieve:
	FileToKeyValues(Vault, NPCPath);

	//Header:
	PrintToConsole(Client, "NPCs:");

	//Null NPCs:
	PrintNPC(Client, Vault, "-0: (Employer)", "0", MAXNPCS);

	//Bankers:
	PrintNPC(Client, Vault, "-1: (Bankers)", "1", MAXNPCS);

	//Vendors:
	PrintNPC(Client, Vault, "-2: (Vendors)", "2", MAXNPCS);
	
	//Vendors:
	PrintNPC(Client, Vault, "-4: (Decoration)", "4", MAXNPCS);
	
	
	//Store:
	KeyValuesToFile(Vault, NPCPath);

	//Close:
	CloseHandle(Vault);

	//Return:
	return Plugin_Handled;
}

//Create NPCs:
public Action:DrawNPCs(Handle:Timer, any:Value)
{

	//Declare:
	decl Handle:Vault;
	decl String:Props[255],String:Notice[255];

	//Initialize:
	Vault = CreateKeyValues("Vault");
    
	//Retrieve:
	FileToKeyValues(Vault, NPCPath);
	
	//Load:
	for(new X = 0; X < MAXNPCS; X++)
	{

		//Declare:
		decl String:NPCId[255];

		//Convert:
		IntToString(X, NPCId, 255);

		//Types:
		for(new Y = 0; Y < 8; Y++)
		{

			//Declare:
			decl String:NPCType[32];

			//Convert:
			IntToString(Y, NPCType, 32);

			//Extract:
			LoadString(Vault, NPCType, NPCId, "Null", Props);
			LoadString(Vault, "Notice", NPCId, "Null", Notice);

			//Found in DB:
			if(StrContains(Props, "Null", false) == -1)
			{

				//Declare:
				decl NPC;
				decl Float:Origin[3];
				decl String:Classname[32], String:AngleString[32], String:PrecacheString[64];
				new String:Buffer[6][32], Float:Angles[3];

				//Explode:
				ExplodeString(Props, " ", Buffer, 6, 32);
		
				//Initialize:
				Angles[1] = StringToFloat(Buffer[4]);
				Format(Classname, 32, "npc_%s", Buffer[0]);   
				if(Buffer[5][0])
					Format(PrecacheString, 64, "models/%s.mdl", Buffer[5]); 
				else
					Format(PrecacheString, 64, "models/%s.mdl", Buffer[0]); 

				//Precache:
				PrecacheModel(PrecacheString, true);

				//Initialize:
				NPC = rp_createent(Classname);

				//Spawn & Send:
				rp_dispatchspawn(NPC);

				//Invincible:
				SetEntProp(NPC, Prop_Data, "m_takedamage", 0, 1);

				//Origin:
				Origin[0] = StringToFloat(Buffer[1]);
				Origin[1] = StringToFloat(Buffer[2]);
				Origin[2] = StringToFloat(Buffer[3]);

				if(Buffer[5][0])
					rp_entmodel(NPC, PrecacheString);
				rp_setNpcNotice(NPC,Notice);
				NPCList[X] = NPC;   
				NPCListInverse[NPC] = X;
				
				Format(AngleString, 32, "0 %d 0", StringToInt(Buffer[4]));
				
				rp_dispatchkeyvalue(NPC, "angles", AngleString);
				
				//Teleport:
				rp_teleportent(NPC, Origin, Angles, NULL_VECTOR);
			}
		}
	}

	//Close:
	CloseHandle(Vault);
}

//Information:
public Plugin:myinfo =
{

	//Initation:
	name = "Roleplay NPCs",
	author = "Joe 'Pinkfairie' Maley & Wmchris/Krim",
	description = "Adds NPCs for RP",
	version = "2.2",
	url = "hiimjoemaley@hotmail.com"
}

//Map Start:
public OnMapStart()
{
	decl String:Map[128], String:Path[64];
	GetCurrentMap(Map, 128);

	BuildPath(Path_SM, Path, 64, "data/roleplay/%s/", Map);
	CreateDirectory(Path,511);
	
	//NPC DB:
	BuildPath(Path_SM, NPCPath, 64, "data/roleplay/%s/npcs.txt",Map);
	
	//Create NPCs:
	CreateTimer(1.0, DrawNPCs);	
}   

/*
* Prints NPC info
* @param Client Player to print to
* @param Vault Keyvalue handle to use
* @param Header Header to use
* @param Key Subkey to find inside the vault
* @param MaxNPCs Maximum number of NPCs
*/
stock PrintNPC(Client, Handle:Vault, const String:Header[255], const String:Key[32], MaxNPCs)
{
	
	//Declare:
	decl String:NPCId[255], String:Props[255];
	
	//Print:
	PrintToConsole(Client, Header);
	for(new X = 0; X < MaxNPCs; X++)
	{
		
		//Convert:
		IntToString(X, NPCId, 255);
		
		//Load:
		LoadString(Vault, Key, NPCId, "Null", Props);
		
		//Found in DB:
		if(StrContains(Props, "Null", false) == -1) PrintToConsole(Client, "--%s: %s", NPCId, Props);	
	}
}

//Initation:
public OnPluginStart()
{

	//Commands:
	RegAdminCmd("rp_createnpc", CommandCreateNPC, ADMFLAG_CUSTOM6, "<id> <NPC> <type> - Types: 0 = Job Lister, 1 = Banker, 2 = Vendor");
	RegAdminCmd("rp_removenpc", CommandRemoveNPC, ADMFLAG_CUSTOM6, "<id> - Removes an NPC from the database");
	RegAdminCmd("rp_npclist", CommandListNPCs, ADMFLAG_CUSTOM1, "- Lists all the NPCs in the database");
	RegAdminCmd("rp_npcnotice", CommandSetNotice, ADMFLAG_CUSTOM1, "- Lists all the NPCs in the database");
	RegAdminCmd("rp_npcwho", CommandNPCWho, ADMFLAG_CUSTOM1, "- Lists all the NPCs in the database");

	//Server Variable:
	CreateConVar("npc_version", "1.0", "NPC Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}