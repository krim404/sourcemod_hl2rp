//Roleplay v3.0 Furniture
//Idea and first implementations by Joe 'Pinkfairie' Maley
//Programmed by Christian 'Krim' Uhl 
//Licence: Creative Commons BY-NC-SA
//http://creativecommons.org/licenses/by-nc-sa/3.0/

#define MAXNPCS    3000 
#include roleplay/rp_wrapper


static String:NPCPath[128];
static lastID = 0;
static Entys[MAXNPCS];
public Plugin:myinfo =
{
	name = "Enitiy Manage Tool",
	author = "Krim",
	description = "Entity manage tools",
	version = "1.4.3",
	url = "http://www.wmchris.de"
};


public OnPluginStart()
{
	RegAdminCmd("rp_saveit", Command_Saveit, ADMFLAG_SLAY,"Save an prop");
	RegAdminCmd("rp_unsaveit", CommandRemoveEnt, ADMFLAG_SLAY,"delete a item");	
	RegAdminCmd("rp_freezeit", Command_Freezeit, ADMFLAG_SLAY,"Save an prop");
	RegAdminCmd("rp_unfreezeit", Command_UnFreezeit, ADMFLAG_SLAY,"delete a item");
	RegAdminCmd("rp_walkthru", Command_walkthru, ADMFLAG_SLAY,"walkthru");
	RegAdminCmd("rp_del", Command_delete, ADMFLAG_SLAY,"delete");
	
	
	RegAdminCmd("sm_color", CommandSaveColor, ADMFLAG_SLAY);
	
	CreateConVar("ker_version", "1.6", "Entitiy Manager Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY); 
}


public Action:CommandSaveColor(Client, args)
{
	
	if(args < 4)
	{
		PrintToChat(Client, "[SAVE] Usage: sm_color <red> <green> <blue> <alpha> <save 1/0>");
		return Plugin_Handled;
	}
	
	new Ent = rp_entclienttarget(Client,false);
	
	if(Ent != -1 && Ent > 0 && Ent > GetMaxClients())
	{
		new String:arg1[64], String:arg2[64], String:arg3[64], String:arg4[64], String:arg5[64], String:Save[255];
		GetCmdArg(1, arg1, 64)
		GetCmdArg(2, arg2, 64)
		GetCmdArg(3, arg3, 64)
		GetCmdArg(4, arg4, 64)
		GetCmdArg(5, arg5, 64)
		
		if(!Entys[Ent] && StringToInt(arg5) == 1)
		{
			PrintToChat(Client, "[SAVE] Error: You tried to save the color on a unsaved prop.");
			return Plugin_Handled;
		}
		else if(Entys[Ent] && StringToInt(arg5) == 1)
		{
			
			
			decl String:Buffer[20]
			IntToString(Entys[Ent],Buffer,20);
			Format(Save, 255, "%s %s %s %s", arg1, arg2, arg3, arg4)
			if(StringToInt(arg1) == 255 && StringToInt(arg2) == 255 && StringToInt(arg3) == 255)
			{
				PrintToChat(Client, "[SAVE] White is an invalid color for this game so it will be deleted.")
				SetEntityRenderMode(Ent, RENDER_GLOW);
				SetEntityRenderColor(Ent, 255, 255, 255, 255)
				return Plugin_Handled;
			}
			else
			{
				new Handle:Vault = CreateKeyValues("Vault");
				
				//Retrieve:
				FileToKeyValues(Vault, NPCPath);
				KvJumpToKey(Vault, "Color", true);
				
				KvSetString(Vault, Buffer, Save);
				KvRewind(Vault);
				
				//Store:
				KeyValuesToFile(Vault, NPCPath);
				
				//Close:
				CloseHandle(Vault);
			}
		}
		SetEntityRenderMode(Ent, RENDER_GLOW);
		SetEntityRenderColor(Ent, StringToInt(arg1), StringToInt(arg2), StringToInt(arg3), StringToInt(arg4))
		PrintToChat(Client, "\x01[SAVE] You set: red=\x04%d\x01 g=\x04%d\x01 b=\x04%d\x01 a=\x04%d\x01 saved=\x04%s\x01",StringToInt(arg1), StringToInt(arg2), StringToInt(arg3), StringToInt(arg4), StringToInt(arg5) == 1 ? "Yes" : "No")
	}
	
	//Return:
	return Plugin_Handled;
}

public Action:Command_delete(Client, args)
{ 
	new	Ent = rp_entclienttarget(Client,false); 
	new String:ClassName[32];
	
	GetEdictClassname(Ent, ClassName, 32);
	
	if(StrContains(ClassName, "prop_", false) != -1)
	{			
		if (IsValidEntity(Ent))
		{
			rp_entacceptinput(Ent, "kill", Ent)
		}		
	}
	else
	{
		PrintToChat(Client, "[SAVE]\x04%s\x01 is a wrong prop!", ClassName);	
	}
	
	return Plugin_Handled;
	
}





public Action:Command_Freezeit(Client,args)
{
	
	new Ent = rp_entclienttarget(Client,false);
	decl String:ClassName[22];
	GetEdictClassname(Ent, ClassName, 22);
	
	if(StrContains(ClassName, "prop_", false) != -1)
	{			
		if(IsValidEntity(Ent))
		{
			PrintToChat(Client, "\x04[Freezed Entity]\x04");
			rp_entacceptinput(Ent, "disablemotion", Ent);        
			SetEntityMoveType(Ent, MOVETYPE_CUSTOM); 
		}		
	}
	else
	{
		PrintToChat(Client, "[SAVE] \x04%s\x01 is a wrong prop!", ClassName);	
	} 
	return Plugin_Handled;	
}

public Action:Command_UnFreezeit(Client,args)
{
	new Ent = rp_entclienttarget(Client,false);
	decl String:ClassName[22];
	GetEdictClassname(Ent, ClassName, 22);
	
	if(StrContains(ClassName, "prop_", false) != -1)
	{			
		if(IsValidEntity(Ent))
		{
			PrintToChat(Client, "\x04[Unfreezed Entity]\x04");
			rp_entacceptinput(Ent, "enablemotion", Ent);        
			SetEntityMoveType(Ent, MOVETYPE_VPHYSICS);
		}		
	}
	else
	{
		PrintToChat(Client, "\x01[SAVE] \x04%s\x01 is a wrong prop!", ClassName);	
	} 
	return Plugin_Handled;	
}


stock LoadString(Handle:Vault, const String:Key[32], const String:SaveKey[255], const String:DefaultValue[255], String:Reference[255])
{
	
	//Jump:
	KvJumpToKey(Vault, Key, false);
	
	//Load:
	KvGetString(Vault, SaveKey, Reference, 255, DefaultValue);
	
	//Rewind:
	KvRewind(Vault);
}

stock SaveString(Handle:Vault, const String:Key[32], const String:SaveKey[255], const String:Variable[255])
{
	
	//Jump:
	KvJumpToKey(Vault, Key, true);
	
	//Save:
	KvSetString(Vault, SaveKey, Variable);
	
	//Rewind:
	KvRewind(Vault);
}

//Map Start:
public OnMapStart()
{
	decl String:Map[128], String:Path[64];
	GetCurrentMap(Map, 128);

	BuildPath(Path_SM, Path, 64, "data/roleplay/%s/", Map);
	CreateDirectory(Path,511);
	
	//Save Path
	BuildPath(Path_SM, NPCPath, 64, "data/roleplay/%s/furni.txt",Map);
	
	Command_lastID();
	CreateTimer(1.0, Command_drawItems);     
}

public Action:Command_walkthru(Client,args)
{
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	
	PrintToChat(Client,"Old Collision: %d",GetEntProp(Ent, Prop_Data, "m_CollisionGroup"));
	if(Ent != -1 && Ent < 0 && Ent > GetMaxClients())
	{
		decl String:level[255];
		GetCmdArg(1, level, sizeof(level));
		SetEntProp(Ent, Prop_Data, "m_CollisionGroup", StringToInt(level));	
	}
	return Plugin_Handled;
}

public Action:Command_Saveit(Client,args)
{
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
	
	decl String:ClassName[22];
	GetEdictClassname(Ent, ClassName, 22);
	
	if(StrContains(ClassName, "prop_", false) != -1)
	{			
		if(IsValidEntity(Ent))
		{
			decl String:modelname[128];
			decl String:Buffers[7][128];    
			decl Float:Origin[3];
			decl Float:Angels[3]; 
			decl String:SaveBuffer[255], String:NPCId[255];
			decl Handle:Vault;   
			
			GetEntPropString(Ent, Prop_Data, "m_ModelName", modelname, 128);
			if(strlen(modelname) < 5)
			{
				PrintToChat(Client,"\x01[SAVE] Model doesnt seem to be correct: \x04%s\x01.",modelname);
				return Plugin_Handled; 
			}
			
			GetEntPropVector(Ent, Prop_Data, "m_vecOrigin", Origin);
			GetEntPropVector(Ent, Prop_Data, "m_angRotation", Angels);
			
			
			IntToString(RoundFloat(Origin[0]), Buffers[0], 32);   
			IntToString(RoundFloat(Origin[1]), Buffers[1], 32);
			IntToString(RoundFloat(Origin[2]), Buffers[2], 32);
			IntToString(RoundFloat(Angels[0]), Buffers[4], 32);
			IntToString(RoundFloat(Angels[1]), Buffers[5], 32);
			IntToString(RoundFloat(Angels[2]), Buffers[6], 32);    
			Buffers[3] = modelname;
			
			ImplodeStrings(Buffers, 7, " ", SaveBuffer, 255);
			
			lastID++;
			
			//Name:
			new String:ClientName[32];
			GetClientName(Client, ClientName, 32);
			PrintToChat(Client,"[SAVE]: Save #%i: Properties: %s",lastID,SaveBuffer);
			Vault = CreateKeyValues("Vault");
			
			IntToString(lastID,NPCId,32);
			FileToKeyValues(Vault, NPCPath); 
			SaveString(Vault, "Furn", NPCId, SaveBuffer);
			KeyValuesToFile(Vault, NPCPath);
			CloseHandle(Vault);
			
			SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1)        
			rp_entacceptinput(Ent, "disablemotion", Ent);
			
			Entys[Ent] = lastID; 
			
		}		
	}
	else
	{
		PrintToChat(Client, "\x01[SAVE]\x04 %s\x01 is a wrong prop!", ClassName);	
	} 
	
	
	
	return Plugin_Handled;  
}

public bool:Command_lastID()
{
	decl Handle:Vault;
	
	//Initialize:
	Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, NPCPath);
	
	new Y = 0;
	decl String:Temp[15];
	
	KvJumpToKey(Vault, "Furn", true);
	KvGotoFirstSubKey(Vault,false);
	do
	{
		KvGetSectionName(Vault, Temp, 15);
		Y = StringToInt(Temp);
		if(Y > lastID) lastID = Y;
		
	} while (KvGotoNextKey(Vault,false));
	
	PrintToServer("[SAVE] new lastID: #%d",lastID);
	CloseHandle(Vault);
	return true;
}


public Action:Command_drawItems(Handle:Timer, any:Value)
{
	PrintToServer("SAVE: Loading Entities...");
	decl Handle:Vault;
	decl String:Props[255];
	
	//Initialize:
	Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, NPCPath);
	
	decl loadArray[2000];
	decl String:Temp[15];
	
	//Select Loader
	new Y = 0;
	KvJumpToKey(Vault, "Furn", true);
	KvGotoFirstSubKey(Vault,false);
	do
	{
		KvGetSectionName(Vault, Temp, 15);
		loadArray[Y] = StringToInt(Temp);	
		Y++;
		
	} while (KvGotoNextKey(Vault,false));
	
	PrintToServer("SAVE: Found %d Entities",Y);
	KvRewind(Vault);
	
	//Load:
	for(new X = 0; X < Y; X++)
	{
		if(loadArray[X] == 0)
		{
			PrintToServer("SAVE: Error at Entity #%d",X);
			CloseHandle(Vault);
			return Plugin_Handled;
		}
		
		//Declare:
		decl String:NPCId[255];
		
		//Convert:
		IntToString(loadArray[X], NPCId, 255);
		
		//Declare:
		decl String:NPCType[32];
		
		//Convert:
		NPCType = "Furn";
		
		//Extract:
		LoadString(Vault, NPCType, NPCId, "Null", Props);
		
		//Found in DB:
		if(StrContains(Props, "Null", false) == -1)
		{
			decl Ent; 
			decl String:Buffer[7][255];
			decl Float:FurnitureOrigin[3];
			decl Float:Angels[3];
			
			//Explode:
			ExplodeString(Props, " ", Buffer, 7, 255);
			
			FurnitureOrigin[0] = StringToFloat(Buffer[0]);
			FurnitureOrigin[1] = StringToFloat(Buffer[1]);
			FurnitureOrigin[2] = StringToFloat(Buffer[2]);
			Angels[0] = StringToFloat(Buffer[4]);
			Angels[1] = StringToFloat(Buffer[5]);
			Angels[2] = StringToFloat(Buffer[6]);
			
			if(strlen(Buffer[3]) > 5) 
			{
				//PrintToChat(Client,"[IMPORT]: %i %s",X,Buffer[3]);  
				PrecacheModel(Buffer[3],true);
				Ent = rp_createent("prop_physics_override"); 
				rp_dispatchkeyvalue(Ent, "model", Buffer[3]);
				rp_dispatchspawn(Ent);
				
				new String:TestBuffer[255], String:Color[4][255];				
				new Handle:Vault2 = CreateKeyValues("Vault");
				
				FileToKeyValues(Vault2, NPCPath);
				KvJumpToKey(Vault2, "color", false);
				
				KvGetString(Vault2, NPCId, TestBuffer, 255, "255 255 255 255");
				ExplodeString(TestBuffer, " ", Color, 4, 255);
				
				SetEntityRenderMode(Ent, RENDER_GLOW);
				SetEntityRenderColor(Ent, StringToInt(Color[0]), StringToInt(Color[1]) ,StringToInt(Color[2]), StringToInt(Color[3]))
				CloseHandle(Vault2);
				
				//PrintToChatAll("%s %d %d %d %d",NPCId, StringToInt(Color[0]), StringToInt(Color[1]) ,StringToInt(Color[2]), StringToInt(Color[3])
				
				//PrintToServer("SAVE: Loaded %d",loadArray[X]);
				rp_teleportent(Ent, FurnitureOrigin, Angels, NULL_VECTOR);
				SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1)        
				rp_entacceptinput(Ent, "disablemotion", Ent);
				SetEntProp(Ent, Prop_Data, "m_CollisionGroup", 0);
				
				Entys[Ent] = loadArray[X];
			}
			else
			{
				PrintToServer("[SAVE] Entry %d can not be a valid model",loadArray[X]);
			} 
		}
	}
	PrintToServer("SAVE: All Entities loaded");
	CloseHandle(Vault);
	return Plugin_Handled;
}

public Action:CommandRemoveEnt(Client, Args)
{
	new Ent = rp_entclienttarget(Client,false);
	decl String:ClassName[22];
	GetEdictClassname(Ent, ClassName, 22);
	
	if(StrContains(ClassName, "prop_", false) != -1)
	{			
		if(IsValidEntity(Ent))
		{
			
			if(Ent > GetMaxClients())
			{
				if(Entys[Ent])
				{
					//Vault:
					decl bool:Deleted; 
					new Handle:Vault = CreateKeyValues("Vault");
					
					//Retrieve:
					FileToKeyValues(Vault, NPCPath);
					
					new String:Buffer[20]
					IntToString(Entys[Ent],Buffer,20);
					
					//Delete:
					KvJumpToKey(Vault, "Furn", false);
					Deleted = KvDeleteKey(Vault, Buffer); 
					KvRewind(Vault);
					KvJumpToKey(Vault, "color", false);
					KvDeleteKey(Vault, Buffer); 
					KvRewind(Vault);
					//Store:
					KeyValuesToFile(Vault, NPCPath);
					
					//Print:
					if(!Deleted) PrintToChat(Client, "\x01[SAVE] Failed to remove Entity \x04%d\x01 from the database", Entys[Ent]);
					else 
					{
						
						//Print:
						PrintToConsole(Client, "\x01[SAVE] Removed Entity \x04%d\x01 from the database", Entys[Ent]);
						PrintToChat(Client, "\x04\x01[SAVE] Removed Entity \x04%d\x04\x01 from the database", Entys[Ent]);
						RemoveEdict(Ent);
						
					}
					
					//Close:
					CloseHandle(Vault);
				}
				else
				{
					PrintToChat(Client, "\x01[SAVE] Failed to remove \x04%d\x01, because it is not a saved prop", Ent);
				}
			}
		}		
	}
	else
	{
		PrintToChat(Client, "[SAVE]\x04 %s\x01 is a wrong prop!", ClassName);	
	} 
	
	//Return:
	return Plugin_Handled;
}

