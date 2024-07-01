//Roleplay v3.0 JAIL
//Idea and first implementations by Joe 'Pinkfairie' Maley
//Programmed by Christian 'Krim' Uhl & Benni
//Licence: Creative Commons BY-NC-SA
//http://creativecommons.org/licenses/by-nc-sa/3.0/

//Includes:
#include <sdkhooks>
#include "roleplay/rp_wrapper"
#include "roleplay/COLORS"
#include "roleplay/rp_include"
#include "roleplay/rp_main"
#include "roleplay/rp_hud"
#include "roleplay/rp_doors"
#include "roleplay/rp_items"
#include "roleplay/rp_jail"

#define MAXPLAYER 33
#define HUDTICK 1.2

//Origions
public Float:OrderOrigin[3];  

//Jail Origin:
public Float:JailOrigin[7][3];
public Float:PDOrigin[7][3];

public Float:VIPJailOrigin[3];

static TimeInJail[MAXPLAYER];
static Autofree[MAXPLAYER];
static bool:TimerExec[MAXPLAYER];

public String:JailPath[64];

//Design
static CuffColor[4] = {0, 0, 255, 200};


public OnMapStart()
{
		
	decl String:Map[128], String:Path[64];
	GetCurrentMap(Map, 128);

	BuildPath(Path_SM, Path, 64, "data/roleplay/%s/", Map);
	CreateDirectory(Path,511);
	
	//Jail DB:
	BuildPath(Path_SM, JailPath, 64, "data/roleplay/%s/jail.txt",Map);
	
	//Declare:
	decl Handle:Vault;
	
	//Initialize:
	Vault = CreateKeyValues("Vault");

	
	//Retrieve:
	FileToKeyValues(Vault, JailPath);
	new String:Key[32];
	//Load:
	for(new X = 0; X < 7; X++)
	{
		
		//Convert:
		IntToString(X, Key, 32);
		
		//Find:
		KvJumpToKey(Vault, "Jail", false);
		KvGetVector(Vault, Key, JailOrigin[X]);
		KvRewind(Vault);
	}
	
	//Load:
	for(new X = 0; X < 7; X++)
	{
		
		//Convert:
		IntToString(X, Key, 32);
		
		//Find:
		KvJumpToKey(Vault, "Combine", false);
		KvGetVector(Vault, Key, PDOrigin[X]);
		KvRewind(Vault);
	}
	
	
	KvJumpToKey(Vault, "General", false);  
	KvGetVector(Vault, "vipjail", VIPJailOrigin);
	KvGetVector(Vault, "suicide", OrderOrigin);
	
	CloseHandle(Vault);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("rp_jail_vipjail", vipjailplayer);
	CreateNative("rp_jail_suicidechamber", suicidechamberplayer);
	CreateNative("rp_jail_autoFreeTimerKill", autoFreeTimerKillplayer);
	CreateNative("rp_jail_autofree", autofreeplayer);
	CreateNative("rp_jail", jailPlayer);
	CreateNative("rp_jail_setAutoFree", setAutoFreeTime);
	CreateNative("rp_jail_getAutoFree", getAutoFreeTime);
	
	CreateNative("rp_jail_setTimeinJail", setTimeinJail);
	CreateNative("rp_jail_getTimeinJail", getTimeinJail);

	return APLRes_Success;
}

public OnPluginStart()
{
	RegAdminCmd("rp_addjail", CommandAddJail, ADMFLAG_CUSTOM3, "<Id>");
	RegAdminCmd("rp_setexit", CommandSetExit, ADMFLAG_CUSTOM3, "Set exit coord.");
	RegAdminCmd("rp_setsuicide", CommandSetSui, ADMFLAG_CUSTOM3, "Set suicide coord.");
	RegAdminCmd("rp_setvipjail", CommandSetVip, ADMFLAG_CUSTOM3, "Set vipjail coord.");
}


//Disconnect:
public OnClientDisconnect(Client)
{
	TimerExec[Client] = false;
}


public jailPlayer(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Combine = GetNativeCell(2);
	
	Jail(Client, Combine);
}

public autofreeplayer(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Time = GetNativeCell(2);
	autofree(Client, Time);
}

public autoFreeTimerKillplayer(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	autoFreeTimerKill(Client);
}



public suicidechamberplayer(Handle:plugin, numParams)	
{
	new Player = GetNativeCell(1);
	new Client = GetNativeCell(2);
	suicidechamber(Player,Client);
}


public vipjailplayer(Handle:plugin, numParams)	
{
	new Player = GetNativeCell(1);
	new Client = GetNativeCell(2);
	vipjail(Player,Client);
}


public getTimeinJail(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return TimeInJail[Client];
}

public setTimeinJail(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Amount = GetNativeCell(2);
	TimeInJail[Client] = Amount;
}



public setAutoFreeTime(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Amount = GetNativeCell(2);
	Autofree[Client] = Amount;
}

public getAutoFreeTime(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Autofree[Client];
}


//Jail:
stock Jail(Client, Combine)
{
	decl String:ClientName[32], String:CombineName[32];
	
	if(Combine == 0) Combine = Client;
	
	//Names:
	GetClientName(Combine, CombineName, 32);
	GetClientName(Client, ClientName, 32);
	
	//Declare:
	decl RandomInt;
	
	//Initialize:
	RandomInt = GetRandomInt(0, 6);

	rp_looseWeapon(Client,true);
	rp_setCrime(Client, 0);
	
	rp_teleportent(Client, JailOrigin[RandomInt], NULL_VECTOR, NULL_VECTOR);
	SetEntProp(Client, Prop_Data, "m_iFrags", 0); //TK Kaschieren
	
	//Check:
	if(Client != Combine)
	{
		//Print:
		CPrintToChat(Combine, "{teamcolor}[RP]\x04\x01 You send \x04%s\x04\x01 to jail!\x04", ClientName);
		CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 You have been sent to jail by \x04%s\x04\x01!", CombineName);
	}

	//Color:
	SetEntityRenderMode(Client, RENDER_GLOW);
	SetEntityRenderColor(Client, CuffColor[0], CuffColor[1], CuffColor[2], CuffColor[3]);
	
	if(!TimerExec[Client]) rp_jail_autofree(Client, 1800);
	
	if(!TimerExec[Client]) CreateTimer(HUDTICK, JailTimer, Client);
	TimerExec[Client] = true;

}

public Action:JailTimer(Handle:Timer, any:Player)
{
	if(IsClientInGame(Player)) 
	{
		if(TimerExec[Player])
		{
			if(rp_iscuff(Player))
			{
				TimeInJail[Player]++;
				if(Autofree[Player] > 0)
				{  
					if(TimeInJail[Player] >= Autofree[Player])
					{   
						autofreeExec(Player); 
					}   
				}
			} else
			{
				TimeInJail[Player] = 0;   
			}
			CreateTimer(HUDTICK, JailTimer, Player);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}



stock vipjail(Player,Client)
{
	if(Player == -1)
	{ 
		if(!rp_iscuff(Player))
		{
			CPrintToChat(Client, "{red}[RP]\x01 target is not cuffed.");
		} 
		else
		{ 
			rp_setCrime(Player, 0);
			CPrintToChat(Player, "{red}[RP]\x04\x01 You've been sent to the \x04vip Jail\x04\x01!");
			rp_teleportent(Player, VIPJailOrigin, NULL_VECTOR, NULL_VECTOR);
			
			if(TimeInJail[Player] == 0) jailtimerstart(Player);
			
		}
	} else
	{
		CPrintToChat(Client, "{red}[RP]\x01 Target is not a player");
	}
}


stock suicidechamber(Player,Client)
{
	if(Player > 0 && Player <= GetMaxClients())
	{ 
		if(!rp_iscuff(Player))
		{
			CPrintToChat(Client, "{red}[RP]\x01 Target is not cuffed");
		} 
		else
		{ 
			SetEntityHealth(Player, 100);
			CPrintToChat(Player, "{red}[RP]\x04\x01 You've been sent to the \x04excution room\x04\x01!");
			rp_teleportent(Player, OrderOrigin, NULL_VECTOR, NULL_VECTOR);
			rp_setTmpSpd(Player,0);
			rp_uncuff(Player);
		}
	} else
	{
		CPrintToChat(Client, "{red}[RP]\x01 Target is not a player");
	}
}


public Action:autofreeExec(Client)
{
	if(rp_iscuff(Client))
	{
		Autofree[Client] = 0;
		TimeInJail[Client] = 0; 
		rp_uncuff(Client);
		rp_dispatchspawn(Client);
		TimerExec[Client] = false;
	}
} 

stock jailtimerstart(Player)
{
	TimeInJail[Player] = 1; 
}


stock autoFreeTimerKill(Player)
{
	autofreeExec(Player);
	CPrintToChat(Player, "{red}[RP]\x04 You are realeased!");
}

stock autofree(Player,Time)
{
	if(Player > 0 && Player <= GetMaxClients())
	{ 
		if(rp_iscuff(Player))
		{
			Autofree[Player] = Time;
			rp_setCrime(Player, 0);
			CPrintToChat(Player, "{red}[RP]\x01 You'll get free in \x04%d\x01 minutes \x04",Time / 60);
		}
	}
}

//Code based of Nicks Mod (Addjail, AddVIP, AddExit & Addsuicide)
public Action:CommandAddJail(Client, Args)
{
	if(Args < 1)
	{
		PrintToConsole(Client, "[RP] Usage: sm_addjail <0-6>");
		return Plugin_Handled;
	}
	decl String:Tax1[32];
	GetCmdArg(1, Tax1, sizeof(Tax1));
	decl Var;
	Var = StringToInt(Tax1);
	if(Var > 6 || Var < 0)
	{
		PrintToChat(Client, "[RP] sm_addjail <0-6>");
		return Plugin_Handled;
	}
	
	decl Float:Origin[3];
	GetClientAbsOrigin(Client, Origin);

	decl Handle:Fig;
	Fig = CreateKeyValues("Vault");
	FileToKeyValues(Fig, JailPath);
	KvJumpToKey(Fig, "Jail", true);
	
	KvSetVector(Fig, Tax1, Origin);
	KvRewind(Fig);
	KeyValuesToFile(Fig, JailPath);
	CloseHandle(Fig);

	PrintToChat(Client, "[RP] Jail Cell [ID: %s] has been edited for coord [%f %f %f]", Tax1, Origin[0], Origin[1], Origin[2]);
	PrintToChat(Client, "[RP] Restart the map in order for this jail coordinate to work with this map!");
	return Plugin_Handled;
}

public Action:CommandSetSui(Client, Args)
{
	if(Args > 0)
	{
		PrintToConsole(Client, "[RP] Usage: sm_setsuicide <NO ARGS>");
		return Plugin_Handled;
	}
	decl Float:Origin[3];
	GetClientAbsOrigin(Client, Origin);

	decl Handle:Fig;
	Fig = CreateKeyValues("Vault");
	FileToKeyValues(Fig, JailPath);
	KvJumpToKey(Fig, "General", true);
	
	KvSetVector(Fig, "suicide", Origin);
	KvRewind(Fig);
	KeyValuesToFile(Fig, JailPath);
	CloseHandle(Fig);

	PrintToChat(Client, "[RP] Suicide Cell has been edited for coord [%f %f %f]", Origin[0], Origin[1], Origin[2]);
	PrintToChat(Client, "[RP] Restart the map in order for this suicide coordinate to work with this map!");
	return Plugin_Handled;
}

public Action:CommandSetExit(Client, Args)
{
	if(Args > 0)
	{
		PrintToConsole(Client, "[RP] Usage: sm_setexit <NO ARGS>");
		return Plugin_Handled;
	}
	decl Float:Origin[3];
	GetClientAbsOrigin(Client, Origin);

	decl Handle:Fig;
	Fig = CreateKeyValues("Vault");
	FileToKeyValues(Fig, JailPath);
	KvJumpToKey(Fig, "General", true);
	
	KvSetVector(Fig, "exit", Origin);
	KvRewind(Fig);
	KeyValuesToFile(Fig, JailPath);
	CloseHandle(Fig);

	PrintToChat(Client, "[RP] Exit has been edited for coord [%f %f %f]", Origin[0], Origin[1], Origin[2]);
	PrintToChat(Client, "[RP] Restart the map in order for this exit coordinate to work with this map!");
	return Plugin_Handled;
}

public Action:CommandSetVip(Client, Args)
{
	if(Args > 0)
	{
		PrintToConsole(Client, "[RP] Usage: sm_setvipjail <NO ARGS>");
		return Plugin_Handled;
	}
	decl Float:Origin[3];
	GetClientAbsOrigin(Client, Origin);

	decl Handle:Fig;
	Fig = CreateKeyValues("Vault");
	FileToKeyValues(Fig, JailPath);
	KvJumpToKey(Fig, "General", true);
	
	KvSetVector(Fig, "vipjail", Origin);
	KvRewind(Fig);
	KeyValuesToFile(Fig, JailPath);
	CloseHandle(Fig);

	PrintToChat(Client, "[RP] VipJail has been edited for coord [%f %f %f]", Origin[0], Origin[1], Origin[2]);
	PrintToChat(Client, "[RP] Restart the map in order for this vipjail coordinate to work with this map!");
	return Plugin_Handled;
}

