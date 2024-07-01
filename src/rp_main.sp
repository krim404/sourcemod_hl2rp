//Roleplay v3.0 Main
//Idea and first implementations by Joe 'Pinkfairie' Maley
//Programmed by Christian 'Krim' Uhl 
//Licence: Creative Commons BY-NC-SA
//http://creativecommons.org/licenses/by-nc-sa/3.0/

//Uses http://forums.alliedmods.net/showthread.php?t=106748 - SDK Hooks 1.31


//Includes:
#include <sdkhooks>
#include "roleplay/rp_wrapper"
#include "roleplay/COLORS"
#include "roleplay/rp_hl2dm"
#include "roleplay/rp_include"
#include "roleplay/rp_main"
#include "roleplay/rp_hud"
#include "roleplay/rp_doors"
#include "roleplay/rp_items"
#include "roleplay/rp_jail"
#include "roleplay/rp_logger"

//Defaults:
#define MAP				"rp_c18_v1"
#define LOGFILE			"rp_sql.log"
#define WEAPON_STUN				"weapon_stunstick"
#define WEAPON_DISTANCESTUN 	"weapon_pistol"
#define WEAPON_WORK				"weapon_crowbar"
#define VERSION 		"3.0b"
#define GAMEINFO		"HL2RP RolePlay V3" //DO NOT CHANGE THIS!!!
#define DEFAULTMONEY	0
#define DEFAULTBANK		0
#define DEFAULTWAGES	2
#define DEFAULTJOB		"Unemployed"
#define DEFAULTSTR	10
#define DEFAULTDEX	10
#define DEFAULTWGT	10
#define DEFAULTINT	10
#define DEFAULTSPD	10
#define DEFAULTFEED	100
#define DEFAULTSTAMINA	0

//Bounty
#define BTYMODIFIER 0.1
#define BTYSTART 1000
#define BTYJAIL 3000

//Misc:
#define bits_SUIT_DEVICE_SPRINT        0x00000001
#define PAYCHECKTIMER	60 	//Keep 60!
#define TICK		1.2
#define SHOCKTIME   10
#define MAXPLAYER 33
#define MAXENT 2000
#define MAXITEMS 667
#define	MAXJOBS		1000 

//Handles
new Handle:CV_NPCROBINTERVAL = INVALID_HANDLE;
new Handle:CV_CROWBARDMG = INVALID_HANDLE;

//CVARS
new Handle:CV_COPVSCOPKILL = INVALID_HANDLE;
new Handle:CV_PROPDMG = INVALID_HANDLE;
new Handle:CV_GIVEWORK = INVALID_HANDLE;
new Handle:CV_COPDROP = INVALID_HANDLE;
new Handle:CV_FEED = INVALID_HANDLE;
new bool:needfeed = true;


//DMG Types
#define DMG_CRUSH               (1 << 0)

//Database
new Handle:hSQL;
static bool:InQuery;
static bool:IsDisconnect[MAXPLAYER];   
public String:NPCPath[128];
public String:JobPath[128];
	
	
//Player Info
static Money[MAXPLAYER];
static Bank[MAXPLAYER];
static Wages[MAXPLAYER];
static Paycheck[MAXPLAYER];
static String:Job[MAXPLAYER][255];
static Minutes[MAXPLAYER];
static Hate[MAXPLAYER]; //Hatelevel
static Dex[MAXPLAYER]; //Weaponskill		- Required for obtaining several weapons
static Str[MAXPLAYER]; //HP					- HP Modifier (10*Str)
static Int[MAXPLAYER]; //Itemskill			- Skillmodifier (1.2*Int)-10
static Wgt[MAXPLAYER]; //Gravity			- 10.0/Wgt
static Spd[MAXPLAYER]; //Runspeed 			- Speed * Multiplikator (Cuffed 9, Shocked 5, General 19)
static Float:Trained[MAXPLAYER];

static TmpSpd[MAXPLAYER]; //Temporary		- Required for using temporary effects
static TmpWgt[MAXPLAYER]; //Temporary		- Required for using temporary effects
static TmpStr[MAXPLAYER]; //Temporary		- Required for using temporary effects
static TmpDex[MAXPLAYER]; //Temporary		- Required for using temporary effects
static TmpInt[MAXPLAYER]; //Temporary		- Required for using temporary effects

static TmpTimer[MAXPLAYER];

static Feeded[MAXPLAYER];  //anti AFK
static Stamina[MAXPLAYER]; //Item Reuse		- Stamina (Reuse of Cuffsaw (10) / Power to Kick Door(20*Locks) / Shock Resist(1 for 2sec)) - 0 on login

//Player System Info
static Cop[MAXPLAYER];
static CopSwitch[MAXPLAYER];
static bool:Loaded[MAXPLAYER];

//Law
static Crime[MAXPLAYER];
static Bounty[MAXPLAYER];
static bool:IsCuffed[MAXPLAYER];
static bool:ExploitJail[MAXPLAYER];
static bool:AutoBounty[MAXPLAYER];
static Float:TimeInJail[MAXPLAYER];
static bool:FreeAfterDeath[MAXPLAYER];
static bool:LooseMoney[MAXPLAYER];
static HP[MAXPLAYER];
static SelectedBuffer[7][MAXPLAYER];
static MenuTarget[MAXPLAYER];
static LastId[2][MAXPLAYER];
static NextKey[MAXPLAYER];

//MultiBuy
public SelectItem[MAXPLAYER]; 
public iMax[MAXPLAYER];  

//AllowedCheat
public ShockResist[MAXPLAYER];

//AntiCheat
public BlockE[MAXPLAYER];
public Float:lastpressedSH[MAXPLAYER];
public Float:lastpressedE[MAXPLAYER]; 
public pressedE[MAXPLAYER];
public UnBlockE[MAXPLAYER];
public bool:RunBuffer[MAXPLAYER];

//Temporary
static TempCrimeAdd[MAXPLAYER];

//Design
static CuffColor[4] = {0, 0, 255, 200};
public UserMsg:FadeID;
public UserMsg:ShakeID;

//Money & Items
static DroppedMoneyValue[MAXENT];
static DroppedItemValue[MAXENT];

//System
new bool:onTakeDamageHook;
new bool:MapRunning = false;

static bool:PrethinkBuffer[MAXPLAYER];
static bool:UseBuffer[MAXPLAYER];

//Misc
public GlobalVendorId[MAXPLAYER];

//Robbing:
public RobCash[MAXPLAYER];
public RobNPC[3][100];
public Float:RobTimerBuffer[3][100];
public Float:RobOrigin[MAXPLAYER][3];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("SDKHook");
	CreateNative("rp_cuff", cuff);
	CreateNative("rp_uncuff", uncuff);
	CreateNative("rp_iscuff", iscuff);
	
	CreateNative("rp_crime", crime);
	CreateNative("rp_uncrime", rmcrime);
	CreateNative("rp_setCrime",setCrime);
	CreateNative("rp_getCrime", getCrime);
	CreateNative("rp_setBty", setBty);
	CreateNative("rp_getBty", getBty);
	
	CreateNative("rp_iscop", iscop);

	CreateNative("rp_setStr", setStr);
	CreateNative("rp_getStr", getStr);
	CreateNative("rp_setWgt", setWgt);
	CreateNative("rp_getWgt", getWgt);
	CreateNative("rp_setInt", setInt);
	CreateNative("rp_getInt", getInt);
	CreateNative("rp_setDex", setDex);
	CreateNative("rp_getDex", getDex);
	CreateNative("rp_setSpd", setSpd);
	CreateNative("rp_getSpd", getSpd);
	CreateNative("rp_setSta", setSta);
	CreateNative("rp_getSta", getSta);
	CreateNative("rp_setHate", setHate);
	CreateNative("rp_getHate", getHate);
	
	CreateNative("rp_setTmpStr", setTmpStr);
	CreateNative("rp_getTmpStr", getTmpStr);
	CreateNative("rp_setTmpWgt", setTmpWgt);
	CreateNative("rp_getTmpWgt", getTmpWgt);
	CreateNative("rp_setTmpInt", setTmpInt);
	CreateNative("rp_getTmpInt", getTmpInt);
	CreateNative("rp_setTmpDex", setTmpDex);
	CreateNative("rp_getTmpDex", getTmpDex);
	CreateNative("rp_setTmpSpd", setTmpSpd);
	CreateNative("rp_getTmpSpd", getTmpSpd);
	CreateNative("rp_getTrainTime", getTrain);
	CreateNative("rp_setTrainTime", setTrain);
	
	CreateNative("rp_getItVal", getItVal);
	CreateNative("rp_getMonVal", getMonVal);
	CreateNative("rp_setDefault",setDefault);
	
	CreateNative("rp_setFeed", setFeed);
	CreateNative("rp_setDefaultSpeed", setDefaultSpeed);	
	CreateNative("rp_getFeed", getFeed);
	CreateNative("rp_getJob", getJob);
	CreateNative("rp_setJob", setJob);
	CreateNative("rp_getWage", getWages);
	CreateNative("rp_setWage", native_setWage);
	CreateNative("rp_getMoney", getMoney);
	CreateNative("rp_getBank", getBank);
	CreateNative("rp_getPaycheck",getPaycheck);
	CreateNative("rp_getMinutes",getMinutes);
	CreateNative("rp_getExploitJail",GetExploit);
	
	
	CreateNative("rp_addMoney", native_addMoney);
	CreateNative("rp_takeMoney", native_remMoney);
	CreateNative("rp_setMoney", native_setMoney);
	CreateNative("rp_createMoneyBoxes",native_CreateMoneyBoxes);
	
	CreateNative("rp_addBank", native_addBank);
	CreateNative("rp_takeBank", native_remBank);
	CreateNative("rp_setBank", native_setBank);
	
	CreateNative("rp_setLooseMoney", setLooseMoney);
	
	CreateNative("rp_setCop", setcop);
	CreateNative("rp_coponline", native_copOnline);
	
	CreateNative("rp_save", native_save);
	CreateNative("rp_saveItem", native_saveitem);
	CreateNative("rp_load", native_load);

	CreateNative("rp_looseWeapon", native_looseWeapon);
	CreateNative("rp_getDroppedMoneyValue", getDroppedMoneyValue);


	return APLRes_Success;
}


// ---- POLICE & CUFFING ----
public Action:CommandSwitch(Client,Args)
{
	if(Cop[Client] > 0)
	{
		if(CopSwitch[Client] == 1) CopSwitch[Client] = 0; else CopSwitch[Client] = 1;
		rp_forcesuicide(Client);
	
		CPrintToChat(Client, "{red}[RP]\x01 You switched your cop status\x01.");
	}
	return Plugin_Handled; 
}

public cuff(Handle:plugin, numParams)
{	
	new Client = GetNativeCell(1);
	if(!rp_iscop(Client)) 
	{
		//Speed:
		TmpSpd[Client] = Spd[Client] / 2;
		
		AutoBounty[Client] = false;
		
		//Cuff:
		IsCuffed[Client] = true;
		
		if(Bounty[Client] > 0)
		{
			//decl String:ClientName[80];
			//GetClientName(Client, ClientName, 80);
			//CPrintToChatAll("{red}[RP]\x04[ATTENTION]\x04\x01 The Bounty of \x04%s\x04\x01 got revoked!",ClientName);
			Bounty[Client] = 0;
		}
		
		//Save:
		ExploitJail[Client] = true;
		
		LooseWeapon(Client, true);
		
		SetSpeed(Client, 19.0 * TmpSpd[Client]);
		
		//Save Changes
		Save(Client);
	
		//Color:
		SetEntityRenderMode(Client, RENDER_GLOW);
		SetEntityRenderColor(Client, CuffColor[0], CuffColor[1], CuffColor[2], CuffColor[3]);
	}
}

//Uncuff:
public uncuff(Handle:plugin, numParams)
{	
	new Client = GetNativeCell(1);
	
	TmpSpd[Client] = Spd[Client];
	
	//Cuff:
	IsCuffed[Client] = false;

	//Save;
	ExploitJail[Client] = false;
	TimeInJail[Client] = 0.0;
	SetSpeed(Client, 19.0 * TmpSpd[Client]);

	DefaultWeapon(Client);
	
	//Color:
	SetEntityRenderMode(Client, RENDER_NORMAL);
	SetEntityRenderColor(Client, 255, 255, 255, 255);	
}



// ---- VARIABLE FUNCTIONS ----
//Defaults:
stock SetUpDefaults(Client, bool:ShouldLoad = false)
{
	//Loaded:
	if(!Loaded[Client])
	{
		Money[Client] = DEFAULTMONEY;
		Bank[Client] = DEFAULTBANK;
		Wages[Client] = DEFAULTWAGES;
		Job[Client] = DEFAULTJOB;
		Paycheck[Client] = PAYCHECKTIMER;
		Bounty[Client] = 0;
		Minutes[Client] = 0;
		Crime[Client] = 0;
		ExploitJail[Client] = false;
		TimeInJail[Client] = 0.0;
		Hate[Client] = 0;
		
		IsCuffed[Client] = false;
		
		Dex[Client] = DEFAULTDEX;
		Str[Client] = DEFAULTSTR;
		Wgt[Client] = DEFAULTWGT;
		Int[Client] = DEFAULTINT;
		Spd[Client] = DEFAULTSPD;
		TmpDex[Client] = DEFAULTDEX;
		TmpStr[Client] = DEFAULTSTR;
		TmpWgt[Client] = DEFAULTWGT;
		TmpInt[Client] = DEFAULTINT;
		TmpSpd[Client] = DEFAULTSPD;
		TmpTimer[Client] = 0;
		Feeded[Client] = DEFAULTFEED;
		Stamina[Client] = DEFAULTSTAMINA;
		FreeAfterDeath[Client] = false;
		ShockResist[Client] = 0;
		
		Cop[Client] = 0;
		CopSwitch[Client] = 0;
		
		//Load:
		if(ShouldLoad) CreateTimer(0.1, CreateSQLAccount, Client);
	}
}

// ---- MONEY ----
stock addMoney(Client,Amount)
{
	Money[Client] += Amount;
	
	new String:FormatBuffer[50];
	Format(FormatBuffer,50,"+ $%d",Amount);
	rp_hud_money(Client,FormatBuffer);
	
	Save(Client);
}

stock remMoney(Client,Amount)
{
	Money[Client] -= Amount;
	
	new String:FormatBuffer[50];
	Format(FormatBuffer,50,"- $%d",Amount);
	rp_hud_money(Client,FormatBuffer);
	
	Save(Client);
}

stock addBank(Client,Amount)
{	
	Bank[Client] += Amount;
	
	new String:FormatBuffer[50];
	Format(FormatBuffer,50,"+ $%d",Amount);
	rp_hud_bank(Client,FormatBuffer);
	
	Save(Client);
}

stock setBank(Client,Amount)
{	
	Bank[Client] = Amount;
	Save(Client);
}

stock setWage(Client,Amount)
{	
	Wages[Client] = Amount;
	Save(Client);
}

stock setMoney(Client,Amount)
{	
	Money[Client] = Amount;
	Save(Client);
}

stock remBank(Client,Amount)
{
	Bank[Client] -= Amount;
	
	new String:FormatBuffer[50];
	Format(FormatBuffer,50,"- $%d",Amount);
	rp_hud_bank(Client,FormatBuffer);
	Save(Client);
}


public native_CreateMoneyBoxes(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Amount = GetNativeCell(2);
	
	//Declare:
	decl Collision;
	decl Float:Position[3],Float:OrgPos[2];
	new Float:Angles[3] = {0.0, 0.0, 0.0};
	GetClientAbsOrigin(Client, Position);
	Position[2] += 30.0;
	OrgPos[0] = Position[0];
	OrgPos[1] = Position[1];
	
	
	while(Amount > 0)
	{
		//Initialize:
		new Ent = rp_createent("prop_physics_override");
		if(Amount > 1000) //goldbar
		{
			DroppedMoneyValue[Ent] = 1000;
			rp_dispatchkeyvalue(Ent, "model", "models/money/goldbar.mdl");
			Amount -= 1000;
		}
		else if(Amount > 200) //note
		{
			DroppedMoneyValue[Ent] = 200;
			rp_dispatchkeyvalue(Ent, "model", "models/money/note2.mdl");
			Amount -= 200;
		}
		else if(Amount > 100) //note
		{
			DroppedMoneyValue[Ent] = 100;
			rp_dispatchkeyvalue(Ent, "model", "models/money/note.mdl");
			Amount -= 100;
		}
		else if(Amount > 50) //note 3
		{
			DroppedMoneyValue[Ent] = 50;
			rp_dispatchkeyvalue(Ent, "model", "models/money/note3.mdl");
			Amount -= 50;
		}
		else if(Amount > 20) //golcoin
		{
			DroppedMoneyValue[Ent] = 20;
			rp_dispatchkeyvalue(Ent, "model", "models/money/goldcoin.mdl");
			Amount -= 20;
		}
		else if(Amount > 10) //silvcoin
		{
			DroppedMoneyValue[Ent] = 10;
			rp_dispatchkeyvalue(Ent, "model", "models/money/goldcoin.mdl");
			Amount -= 10;
		}
		else if(Amount > 5) //silvcoin
		{
			DroppedMoneyValue[Ent] = 5;
			rp_dispatchkeyvalue(Ent, "model", "models/money/silvcoin.mdl");
			Amount -= 5;
		}
		
		else if(Amount > 2) //silvcoin
		{
			DroppedMoneyValue[Ent] = 2;
			rp_dispatchkeyvalue(Ent, "model", "models/money/silvcoin.mdl");
			Amount -= 2;
		}
		else //broncoin
		{
			DroppedMoneyValue[Ent] = 1;
			rp_dispatchkeyvalue(Ent, "model", "models/money/broncoin.mdl");
			Amount -= 1;
		}
		
		
		//Spawn:
		rp_dispatchspawn(Ent);
		
		//Angles:
		Angles[1] = GetRandomFloat(0.0, 360.0);
		Position[0] = OrgPos[0] + GetRandomFloat(-50.0, 50.0);
		Position[1] = OrgPos[1] + GetRandomFloat(-50.0, 50.0);
		
		
		//Debris:
		Collision = GetEntSendPropOffs(Ent, "m_CollisionGroup");
		if(IsValidEntity(Ent)) SetEntData(Ent, Collision, 1, 1, true);
		
		//Send:
		rp_teleportent(Ent, Position, Angles, NULL_VECTOR);
	}
	return true;
}



// ---- MISC ----

stock Shake(Client, Float:Length, Float:Severity)
{
	
	//Connected:	
	if(IsClientInGame(Client))
	{
		
		//Declare:
		decl Handle:ViewMessage;
		
		//Clients:
		new SendClient[2];
		SendClient[0] = Client;
		
		//Write:
		ViewMessage = StartMessageEx(ShakeID, SendClient, 1);
		BfWriteByte(ViewMessage, 0);
		BfWriteFloat(ViewMessage, Severity);
		BfWriteFloat(ViewMessage, 10.0);
		BfWriteFloat(ViewMessage, Length);
		
		//Send:
		EndMessage();
	}
}

//Suicide Action
public Action:HandleKill(Client, args){
	
	if(IsCuffed[Client] || Crime[Client] > 100) 
	{
		CPrintToChat(Client, "{red}[RP]\x04 You can't kill yourself right now!\x04");
		return Plugin_Handled;
	}
	rp_hud_timer(Client,6,"Suicide");
	CreateTimer(6.0, killer, Client);
	CPrintToChat(Client, "{red}[RP]\x01 You will die in \x046\x04\x01 seconds.");
	return Plugin_Handled;
	
}

//Suicide Action Timer
public Action:killer(Handle:Timer, any:Client)
{
	LooseMoney[Client] = true;
	rp_forcesuicide(Client);
}

stock bool:isCopOnline()
{
	for(new X = 0; X < MaxClients; X++)
	{
		if(Cop[X] && CopSwitch[X] == 0 && IsClientInGame(X) && Loaded[X])
			return true;
	}
	return false;
}

public Action:Respawn(Handle:Timer, any:Client)
{
	rp_dispatchspawn(Client);
}

stock LooseWeapon(Client, bool:OnDeath = false)
{
	if(!IsClientInGame(Client)) return false;
	
	//Weapons:
	rp_removeweapons(Client);
	return true;	
}

// ---- SAVE AND LOAD (SQL FUNCTIONS) ----
//Starts the Loading of the User
public Action:CreateSQLAccount(Handle:Timer, any:Client)
{
	new String:SteamId[64];
	GetClientAuthString(Client, SteamId, 64);
	
	if(StrEqual(SteamId, "") || InQuery)
	{
		CreateTimer(2.0, CreateSQLAccount, Client);
	}
	else
	{	
		InQuery = true;
		Load(Client);
	}
}

//Inits the SQL Connection
public InitSQL()
{
	new String:error[512];
	new Handle:kv = INVALID_HANDLE;
	//hSQL=SQL_ConnectEx(SQL_GetDriver("sqlite"),"","","","RoleplayDB",error,sizeof(error));
	kv = CreateKeyValues(""); 
	KvSetString(kv, "driver", "sqlite"); 
	KvSetString(kv, "database", "RoleplayDB");
	hSQL = SQL_ConnectCustom(kv, error, sizeof(error), true);  
	CloseHandle(kv);
	
	if(hSQL==INVALID_HANDLE)
	{
		LogError("DB Error: %s", error);
	}
}

//Create the Databases
public createdb()
{   
	CreateTimer(0.1,createdbplayer);
	CreateTimer(1.0,createdbitems);
}

public Action:createdbitems(Handle:Timer) 
{
	new len = 0;
	decl String:query[1000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Items`");
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` text(25) NOT NULL, ");
	len += Format(query[len], sizeof(query)-len, " `ITEMID` int(25) NOT NULL DEFAULT 0, ");
	len += Format(query[len], sizeof(query)-len, " `AMOUNT` int(25) NOT NULL DEFAULT 0 );");
	LogMSG(LOGFILE,"SQL: Creating Items Database");
	SQL_FastQuery(hSQL, query);	
}
	
public Action:createdbplayer(Handle:Timer)
{
	new len = 0;
	decl String:query[20000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Player`");
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` varchar(25) NOT NULL, `NAME` varchar(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "  `LASTONTIME` int(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `Money` int(25) NOT NULL DEFAULT %d,", DEFAULTMONEY);
	len += Format(query[len], sizeof(query)-len, "  `Bank` int(25) NOT NULL DEFAULT %d,", DEFAULTBANK);
	len += Format(query[len], sizeof(query)-len, "  `Wages` int(25) NOT NULL DEFAULT %d,", DEFAULTWAGES);
	len += Format(query[len], sizeof(query)-len, "  `Job` varchar(25) NOT NULL DEFAULT '%s',", DEFAULTJOB);
	len += Format(query[len], sizeof(query)-len, "  `Paycheck` int(25) NOT NULL DEFAULT %d,", PAYCHECKTIMER);
	len += Format(query[len], sizeof(query)-len, "  `Bounty` int(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `Minutes` int(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `Crime` int(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `ExploitJail` int(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `TimeInJail` float(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `IsCuffed` int(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `Dex` int(25) NOT NULL DEFAULT %d,", DEFAULTDEX);
	len += Format(query[len], sizeof(query)-len, "  `Str` int(25) NOT NULL DEFAULT %d,", DEFAULTSTR);
	len += Format(query[len], sizeof(query)-len, "  `Wgt` int(25) NOT NULL DEFAULT %d,", DEFAULTWGT);
	len += Format(query[len], sizeof(query)-len, "  `Int` int(25) NOT NULL DEFAULT %d,", DEFAULTINT);
	len += Format(query[len], sizeof(query)-len, "  `Spd` int(25) NOT NULL DEFAULT %d,", DEFAULTSPD);
	len += Format(query[len], sizeof(query)-len, "  `Feeded` int(25) NOT NULL DEFAULT %d,", DEFAULTFEED);
	len += Format(query[len], sizeof(query)-len, "  `FreeAfterDeath` int(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `ShockResist` int(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `Cop` int(25) NOT NULL DEFAULT 0,");		
	len += Format(query[len], sizeof(query)-len, "  `IP` varchar(255) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `COUNTRY` varchar(255) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `MONEYHUD` int(25) NOT NULL DEFAULT 1,");
	len += Format(query[len], sizeof(query)-len, "  `CRIMEHUD` int(25) NOT NULL DEFAULT 1,");
	len += Format(query[len], sizeof(query)-len, "  `CRIMETRACER` int(25) NOT NULL DEFAULT 1,");
	len += Format(query[len], sizeof(query)-len, "  `AUTOFREE` int(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `LastTrained` float(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `LastOnline` float(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  `Hate` int(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  PRIMARY KEY (`STEAMID`));");
	
	//LogMSG(LOGFILE,"SQL: Creating Player Database");
	SQL_FastQuery(hSQL, query);

}

//Save
stock Save(Client)
{
	
	if(!IsClientConnected(Client))return true;
	if(InQuery)
	{
		CreateTimer(1.0, DBSave_ReDo, Client);
		return true;
	}
	
	if(Loaded[Client])
	{
		InQuery = true;
		
		//Declare:
		new String:ClientName[64],String:SteamId[32], String:query[5000], YN, String:Ip[64], String:CountryName[45];
		
		//Initialize:
		GetClientAuthString(Client, SteamId, 32);

		//Get Informations
		GetClientIP(Client, Ip, 64);
		GetClientName(Client, ClientName, 64);
		
		new String:NameBuffer[129];
		SQL_EscapeString(hSQL,ClientName,NameBuffer,129);
		
		new len = 0;	
		len += Format(query[len], sizeof(query)-len, "UPDATE Player SET NAME = '%s',",NameBuffer);
		len += Format(query[len], sizeof(query)-len, "Money = %d,", Money[Client]);
		len += Format(query[len], sizeof(query)-len, "Bank = %d,", Bank[Client]);
		len += Format(query[len], sizeof(query)-len, "Wages = %d,", Wages[Client]);
		len += Format(query[len], sizeof(query)-len, "Job = '%s',", Job[Client]);
		len += Format(query[len], sizeof(query)-len, "Paycheck = %d,", Paycheck[Client]);
		len += Format(query[len], sizeof(query)-len, "Bounty = %d,", Bounty[Client]);
		len += Format(query[len], sizeof(query)-len, "Minutes = %d,", Minutes[Client]);
		len += Format(query[len], sizeof(query)-len, "Crime = %d,", Crime[Client]);
		len += Format(query[len], sizeof(query)-len, "ExploitJail = %d,", bool2int(ExploitJail[Client]));
		len += Format(query[len], sizeof(query)-len, "TimeInJail = %d,", rp_jail_getTimeinJail(Client));
		len += Format(query[len], sizeof(query)-len, "IsCuffed = %d,", bool2int(IsCuffed[Client]));
		len += Format(query[len], sizeof(query)-len, "Dex = %d,", Dex[Client]);
		len += Format(query[len], sizeof(query)-len, "Str = %d,", Str[Client]);
		len += Format(query[len], sizeof(query)-len, "Wgt = %d,", Wgt[Client]);
		len += Format(query[len], sizeof(query)-len, "Hate = %d,", Hate[Client]);
		len += Format(query[len], sizeof(query)-len, "Int = %d,", Int[Client]);
		len += Format(query[len], sizeof(query)-len, "Spd = %d,", Spd[Client]);
		len += Format(query[len], sizeof(query)-len, "Feeded = %d,", Feeded[Client]);
		len += Format(query[len], sizeof(query)-len, "FreeAfterDeath = %d,", bool2int(FreeAfterDeath[Client]));
		len += Format(query[len], sizeof(query)-len, "ShockResist = %d,", ShockResist[Client]);
		len += Format(query[len], sizeof(query)-len, "Cop = %d,", Cop[Client]);
		len += Format(query[len], sizeof(query)-len, "IP = '%s',",Ip);
		len += Format(query[len], sizeof(query)-len, "COUNTRY = '%s',",CountryName);	
		len += Format(query[len], sizeof(query)-len, "LastTrained = %f,",Trained[Client]);	
		len += Format(query[len], sizeof(query)-len, "LastOnline = %f,",rp_gettime());	
		
		//Additional Configs for the "User Preferences"
		if(rp_hud_get_moneyhud(Client)) YN = 1; else YN = 0;	
		len += Format(query[len], sizeof(query)-len, "MONEYHUD = %d,",YN);
		if(rp_hud_get_crimehud(Client)) YN = 1; else YN = 0;
		len += Format(query[len], sizeof(query)-len, "CRIMEHUD = %d,", YN);
		if(rp_hud_get_crime(Client)) YN = 1; else YN = 0;
		len += Format(query[len], sizeof(query)-len, "CRIMETRACER = %d,", YN);
		
		len += Format(query[len], sizeof(query)-len, "AUTOFREE = %d WHERE STEAMID = '%s';",rp_jail_getAutoFree(Client), SteamId);

		//Do Query
		SQL_FastQuery(hSQL, query);

		if(IsDisconnect[Client])
		{
			Loaded[Client] = false;
			IsDisconnect[Client] = false;
		}
		
		InQuery = false;
	}
	return true;

}

public Action:DBSave_ReDo(Handle:Timer, any:Client)
{
	Save(Client);
	return Plugin_Handled;
}


public native_save(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Save(Client);
}

//Saves the Ownership of an Item
stock SaveItem(Client, ItemId, Amount) 
{
	if(!IsClientConnected(Client))return true;
	if(Loaded[Client])
	{
		new String:SteamId[255], String:Buffer[512];
		GetClientAuthString(Client, SteamId, sizeof(SteamId));
		
		if(Amount == 0)
		{
			Format(Buffer, sizeof(Buffer), "DELETE FROM Items WHERE STEAMID = '%s' AND ITEMID = %d;", SteamId, ItemId);
		}
		else
		{
			Format(Buffer, sizeof(Buffer), "SELECT AMOUNT FROM Items WHERE STEAMID = '%s' AND ITEMID = %d;", SteamId, ItemId);
			new Handle:query = SQL_Query(hSQL,Buffer);
			
			if(query)
			{
				SQL_Rewind(query);
				new bool:fetch=SQL_FetchRow(query);
				if(!fetch)
				{
					Format(Buffer, sizeof(Buffer), "INSERT INTO Items (`STEAMID`,`ITEMID`,`AMOUNT`) VALUES ('%s',%i, %i);", SteamId, ItemId, Amount);
				}
				else
				{
					Format(Buffer, sizeof(Buffer), "UPDATE Items SET AMOUNT = %d WHERE STEAMID = '%s' AND ITEMID = %d;", Amount, SteamId, ItemId);
				}
			}
			CloseHandle(query);
		}
		SQL_FastQuery(hSQL, Buffer);
	}
	return true;
}

//Inserts a NEW Player in the SQL Database
stock InsertPlayer(Client) 
{
	new String:ClientName[64], String:buffer[255];
	GetClientName(Client, ClientName, sizeof(ClientName));
	new String:SteamId[255];
	GetClientAuthString(Client, SteamId, sizeof(SteamId));
		
	rp_hud_set_calibrate(Client, false);
	rp_hud_set_police(Client, false);
	rp_hud_set_metal(Client, false);
	rp_hud_set_metal_tracer(Client, false);
	rp_hud_set_policeupgrade(Client, false);
	rp_hud_set_crime(Client, true);
	rp_hud_set_moneyhud(Client, true);
	rp_hud_set_crimehud(Client, true);
	
	new String:NameBuffer[129];
	SQL_EscapeString(hSQL,ClientName,NameBuffer,129);
		
	Format(buffer, sizeof(buffer), "INSERT INTO Player (`NAME`,`STEAMID`,`LASTONTIME`, `Job`) VALUES ('%s','%s',%i,'%s');", NameBuffer, SteamId, GetTime(), DEFAULTJOB);	
	SQL_FastQuery(hSQL,buffer);
}


//Load
stock Load(Client)
{
	new String:SteamId[255], String:buffer[255], String:buffer2[255];
	GetClientAuthString(Client, SteamId, sizeof(SteamId));
	Format(buffer, sizeof(buffer),"SELECT * FROM Player WHERE STEAMID = '%s';",SteamId);
	new Handle:query = SQL_Query(hSQL,buffer);
	if(query)
	{
	SQL_Rewind(query);
	new bool:fetch=SQL_FetchRow(query);
	if(!fetch)
		{
			InsertPlayer(Client);
		}
		else	  
		{
			new String:buffer3[256];				
			Money[Client] = SQL_FetchInt(query, 3); //MONEY
			Bank[Client] = SQL_FetchInt(query, 4); //BANK
			Wages[Client] = SQL_FetchInt(query, 5); //WAGES
			SQL_FetchString(query,6, buffer3, sizeof(buffer3)); //JOB
			strcopy(Job[Client], sizeof(Job[]), buffer3); //INSERT JOB
			Paycheck[Client] = SQL_FetchInt(query, 7); //PAYCHECK
			Bounty[Client] = SQL_FetchInt(query, 8); //BOUNTY
			Minutes[Client] = SQL_FetchInt(query, 9); //PLAYTIME
			Crime[Client] = SQL_FetchInt(query, 10); //CRIME
			ExploitJail[Client] = int2bool(SQL_FetchInt(query, 11)); //ExploitedJail
			rp_jail_setTimeinJail(Client,SQL_FetchInt(query, 12)); //Time in Jail
			IsCuffed[Client] = int2bool(SQL_FetchInt(query, 13)); //Actual Cuffed
			Dex[Client] = SQL_FetchInt(query, 14); //DEX
			Str[Client] = SQL_FetchInt(query, 15); //STR
			Wgt[Client] = SQL_FetchInt(query, 16); //WGT
			Int[Client] = SQL_FetchInt(query, 17); //INT
			Spd[Client] = SQL_FetchInt(query, 18); //SPD
			Feeded[Client] = SQL_FetchInt(query, 19); //Feeded
			FreeAfterDeath[Client] = int2bool(SQL_FetchInt(query, 20)); //Autofree
			ShockResist[Client] = SQL_FetchInt(query, 21); //ShockResistance
			Cop[Client] = SQL_FetchInt(query, 22); //Cop Status

			
			
			rp_hud_set_moneyhud(Client, int2bool(SQL_FetchInt(query,25)));
			rp_hud_set_crimehud(Client, int2bool(SQL_FetchInt(query,26)));
			rp_hud_set_crime(Client, int2bool(SQL_FetchInt(query,27)));
			rp_jail_setAutoFree(Client, SQL_FetchInt(query, 28));
			rp_jail_autofree(Client, SQL_FetchInt(query, 28) - SQL_FetchInt(query, 12));
			
			Trained[Client] = SQL_FetchFloat(query, 29);
			Hate[Client] = SQL_FetchInt(query, 30);
		}
	}
	
	//Loading all Items the Player owns
	for(new X = 1; X < MAXITEMS; X++)
	{
		Format(buffer2, sizeof(buffer2), "SELECT AMOUNT FROM Items WHERE STEAMID = '%s' AND ITEMID = '%d';", SteamId, X);
		query = SQL_Query(hSQL,buffer2);
		if(SQL_GetRowCount(query))
		{
			while (SQL_FetchRow(query))
			{
				new Test = SQL_FetchInt(query,0);				
				rp_setItem(Client, X, Test);				
			}
		} 

	}	
	
	IsDisconnect[Client] = false;
	InQuery = false;
	Loaded[Client] = true;
	CreateTimer(0.1, Ticker, Client);
	
	TmpDex[Client] = Dex[Client];
	TmpInt[Client] = Int[Client];
	TmpSpd[Client] = Spd[Client];
	TmpStr[Client] = Str[Client];
	TmpWgt[Client] = Wgt[Client];
	checkTeam(Client);
	
	CreateTimer(1.5, Respawn, Client);
	//Open Job Menu if Defaultjob
	if(StrEqual(Job[Client], DEFAULTJOB)) JobMenu(Client);
	
	CloseHandle(query);
	
}

// ---- TICK ----
stock TickPaycheck(Client)
{
	if(IsClientInGame(Client) && Loaded[Client] && (Feeded[Client] > 0 || !needfeed) && !IsCuffed[Client])
	{
		if(Paycheck[Client] <= 0)
		{
			addMoney(Client,Wages[Client]);
			Paycheck[Client] = PAYCHECKTIMER + 1;
			
			//Add:
			Minutes[Client] += 1;
			if(needfeed) Feeded[Client] -= 1;
		
			Stamina[Client] += 1;
			
			//Wages:
			if(Minutes[Client] >= Pow(float(Wages[Client]), 3.0))
			{
				//Add:
				Wages[Client] += 1;
				//Print:
				CPrintToChat(Client, "{red}[RP]\x01 You have recieved a raise for spending a total of \x04%d\x01 minutes in the server", Minutes[Client]);
			}
		
			//Remove ShockResist over Time
			if(ShockResist[Client] > 0) ShockResist[Client] -= 5;
			if(ShockResist[Client] < 0) ShockResist[Client] = 0;
			
			//Set Time in Tab Menu
			SetEntProp(Client, Prop_Data, "m_iFrags", Minutes[Client]/60);
			
			if(needfeed)
				SetEntProp(Client, Prop_Data, "m_iDeaths", Feeded[Client]);
			
			//Save:
			Save(Client);
		} else
		{	
			Paycheck[Client]--;
		}
		
		if(Crime[Client] > 0)
				Crime[Client] -= 1;
	}
}

public Action:Ticker(Handle:Timer, any:Client)
{
	if(IsClientInGame(Client))
	{
		checkTeam(Client);
		
		//Fix Negative Cash
		if(Money[Client] < 0) Money[Client] = 0;
		if(IsPlayerAlive(Client))
		{
			//Get Money
			TickPaycheck(Client);
		
			//Bounty System
			if(Crime[Client] > BTYSTART && BTYSTART != 0 && Bounty[Client] == 0)
			{
				Bounty[Client] = RoundToFloor(Crime[Client] * BTYMODIFIER);
				
				if(AutoBounty[Client] == false)
				{
					new String:FormatBuffer[255];
					Format(FormatBuffer,255,"The police set a bounty of %d on your head!",Bounty[Client]);
					rp_notice(Client,FormatBuffer);
				}
				
				AutoBounty[Client] = true;
			}
			
			else if(Crime[Client] < BTYSTART && BTYSTART != 0 && AutoBounty[Client] == true)
			{
				AutoBounty[Client] = false;
				Bounty[Client] = 0;
				rp_notice(Client,"The police removed the bounty on your head");
			}
		}
		
		if(needfeed)
		{
			if(Feeded[Client] == 0) rp_notice(Client,"You are starving. Eat something or you wont gain money"); 
			else if(Feeded[Client] < 10) rp_notice(Client,"You are hungry"); 
		} 
		CreateTimer(TICK, Ticker, Client);
	}	
}

stock checkTeam(Client)
{
	new plyteam = GetClientTeam(Client);
	
	//Combine
	if(rp_iscop(Client))
	{
		if(plyteam != 2)
			ChangeClientTeam(Client,2);
	}

	//Rebels
	if(!rp_iscop(Client))
	{
		if(plyteam != 3)
			ChangeClientTeam(Client,3);
	}
}


//Stunstick Shock remover
public Action:SSShockRem(Handle:Timer, any:Client)
{
	if(TmpTimer[Client] > 0)
	{	
		TmpTimer[Client]--;
		CreateTimer(1.0, SSShockRem, Client);
	}
	else
	{
		//Speed:
		ClientCommand(Client, "r_screenoverlay 0");
		TmpSpd[Client] = Spd[Client];
		SetSpeed(Client, 19.0 * TmpSpd[Client]);
	}
	
}

// ---- EVENTS ----
//Spawn:
public EventSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
	//Initialize:
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	if(IsClientInGame(Client))
	{
		CreateTimer(0.1, PhysGunTimer, Client);
		HP[Client] = GetClientHealth(Client);
	
		//Color:
		SetEntityRenderMode(Client, RENDER_NORMAL);
		SetEntityRenderColor(Client, 255, 255, 255, 255);
		
		SetEntityGravity(Client,12.0/TmpWgt[Client]);
		SetEntityHealth(Client,10*TmpStr[Client]);
		SetSpeed(Client, 19.0 * TmpSpd[Client]);
	
		ClientCommand(Client, "r_screenoverlay 0");
	
		SetEntProp(Client, Prop_Data, "m_iFrags", Minutes[Client]);
		if(ExploitJail[Client]) 
		{
			CreateTimer(1.5, SendJail, Client);
		}
	}
}

public Action:PhysGunTimer(Handle:Timer, any:Client)
{
	LooseWeapon(Client, false);
	DefaultWeapon(Client);
	
	if(GetConVarInt(CV_GIVEWORK) == 1)
		rp_giveplayeritem(Client, WEAPON_WORK);
		
	return Plugin_Handled;	
}

public Action:SendJail(Handle:Timer, any:Client) 
{
	rp_jail(Client, Client);
}

public EventActivate(Handle:Event,const String:name[],bool:dontBroadcast)
{	
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	ChangeClientTeam(Client, 1);
}

//Damage:
public Action:EventDamage(Handle:Event, const String:Name[], bool:Broadcast)
{
	
	//Declare:
	decl Client, Attacker;
	
	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	
	
	new damage = HP[Client] - GetClientHealth(Client);
	if(damage > Str[Client] * 10) damage = Str[Client] * 10; //No unlimited damage
	
	HP[Client] = GetClientHealth(Client);
	//World:
	if(Attacker == 0) return Plugin_Handled;
	if(Client == 0) return Plugin_Handled;
	
	//AddCrime
	if(Client != Attacker && Bounty[Client] == 0 && !rp_iscop(Attacker)) 
	{
		TempCrimeAdd[Attacker] = damage;
		CreateTimer(0.05, AddCrimeWithDelay, Attacker);
		return Plugin_Continue;
	}
	
	CloseHandle(Handle:Event);
	
	//Return:
	return Plugin_Handled;
}

public Action:AddCrimeWithDelay(Handle:Timer, any:Attacker)
{	
	rp_crime(Attacker, TempCrimeAdd[Attacker]);
}

public Action:OnTakeDamage(Client, &attacker, &inflictor, &Float:damage, &damageType) 
{
	//Weapon:
	new String:WeaponName[32];
	if(attacker != Client && Client != 0 && attacker != 0 && Client > 0 && Client < MaxClients && attacker > 0 && attacker < MaxClients)
	{
		GetClientWeapon(attacker, WeaponName, 32);
		
		if(rp_iscop(Client) && rp_iscop(attacker) && GetConVarInt(CV_COPVSCOPKILL) != 1)
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		
		if(damageType == DMG_CRUSH  && GetConVarInt(CV_PROPDMG) != 1)
		{
			damage = 0.0;
			return Plugin_Changed;
		}

		//Stunstick and Coppistol
		if(StrEqual(WeaponName, WEAPON_DISTANCESTUN, false) || StrEqual(WeaponName, WEAPON_STUN, false)) 
		{	
			if(rp_iscop(attacker) && StrEqual(WeaponName, WEAPON_DISTANCESTUN, false) || StrEqual(WeaponName, WEAPON_STUN, false))
			{
				if(ShockResist[Client] > 0)
				{
					ShockResist[Client]--;
				} else
				{
					TmpTimer[Client] = SHOCKTIME;
					TmpSpd[Client] = 5;
					SetSpeed(Client, 19.0 * TmpSpd[Client]);
					Shake(Client, float(SHOCKTIME), (5.0));
					ClientCommand(Client, "r_screenoverlay debug/yuv.vmt");
					CreateTimer(0.1, SSShockRem, Client);
				}
			}
				
			if(rp_iscop(attacker))
			{
				if(StrEqual(WeaponName, WEAPON_STUN, false))
				{
					if(IsCuffed[Client])
					{
						rp_uncuff(Client);		
					}
					else
					{					
						rp_cuff(Client);
						rp_log_cuff(Client, attacker, Crime[Client]);
					}
				}
				
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		
		
		
		//Crowbar
		if(StrEqual(WeaponName, WEAPON_WORK, false)) 
		{	
			if(GetConVarBool(CV_CROWBARDMG))
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		
	}
	return Plugin_Continue;	
}

//DOORBLOCK & OTHER HOOKS
public Action:OnPlayerRunCmd(Client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{
	//new Ent = rp_entclienttarget(Client,false);	
	if(BlockE[Client] == 1)
	{
		buttons &= ~IN_USE;
		if(UnBlockE[Client] == 0)
		{
			CreateTimer(10.0, UnLockUse, Client);
			UnBlockE[Client] = 1;
		}
	}
	
	if(IsCuffed[Client] || TmpTimer[Client] > 0 || TmpSpd[Client] < 9)
	{
		buttons &= ~IN_SPEED;
	}
	
	
	//E Key:
	if(buttons & IN_USE)
	{			
		//Overflow:
		if(!UseBuffer[Client])
		{
			//Action:
			CommandUse(Client);
			
			//UnHook:
			UseBuffer[Client] = true;
		}
	}
	else
	{
		UseBuffer[Client] = false;
	}
	
	if(IsCuffed[Client])
	{
		buttons &= ~IN_USE;
		buttons &= ~IN_ATTACK;
		buttons &= ~IN_ATTACK2;
	}
	
	//Uncommented - no SAVEPVP implemented yet
	//if(rp_getPvP(Client) >= 1)
	//{
	//	Crime[Client] = 0;
	//	if(rp_iscop(Client)) buttons &= ~IN_ATTACK2; 
	//	buttons &= ~IN_ATTACK;
	//	return Plugin_Continue;	
	//}	

	return Plugin_Continue;
}

public Action:UnLockUse(Handle:Timer, any:Client)
{
	BlockE[Client] = 0;
	pressedE[Client] = 0;
	lastpressedE[Client] = GetGameTime();	
	UnBlockE[Client] = 0;
	return Plugin_Handled;	
}

//Death:
public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	//Declare:
	decl Client, Attacker;
	
	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	
	//Sterbe Screen
	if(Client > 0) //Still connected?
	{
		if(IsClientInGame(Client))
		{
			ClientCommand(Client, "r_screenoverlay debug/yuv.vmt");
			LooseWeapon(Client, true);
			if(FreeAfterDeath[Client] == true)
			{
				rp_uncuff(Client);
				FreeAfterDeath[Client] = false;
			}
		}
	}
	
	//World killed the player - so we dont drop money and no crime
	if((Client == 0 || Attacker == 0 || Client == Attacker) && LooseMoney[Client] == false)
	{
		return Plugin_Handled;
	}
	
	//Addcrime to Killer
	if(Client != Attacker && rp_iscop(Client)) 				rp_crime(Attacker, 1000);
	else if(Client != Attacker && Bounty[Client] == 0) 	rp_crime(Attacker, 500);
	else if(Bounty[Client] > 0 && Client != Attacker)	//Player had bounty
	{
		rp_addMoney(Attacker,Bounty[Client]);
		CPrintToChat(Attacker, "{red}[RP]\x04\x01 You earned $\x04%d \x04\x01 bounty.", Bounty[Client]);
		
		rp_cuff(Client);
		ExploitJail[Client] = true;
		Crime[Client] = 0;
		Bounty[Client] = 0;
	}
	
	//Clear Crime if low and killed by a cop
	if(rp_iscop(Attacker) && Crime[Client] < 100) Crime[Client] = 0;
	if(rp_iscop(Attacker) && Crime[Client] > 100) Crime[Client] = Crime[Client] / 2;
	
	//Drop Money (no admin)
	if(Money[Client] > 0 && StrContains(Job[Client], "Admin", false) == -1)
	{
		//Combine:
		if(!rp_iscop(Attacker) || LooseMoney[Client] == true || Crime[Client] > 0)
		{
			//Money Lost
			new moneylost = 0;
			new moneydrop = 0;
			
			if(!rp_iscop(Client) || GetConVarInt(CV_COPDROP) == 1)
			{	//Player Loose all their money
				moneylost = Money[Client] / 10;
				moneydrop = Money[Client] - moneylost;
			}
			
			//Fallback Routines
			if((moneydrop + moneylost) <= Wages[Client] && Money[Client] > Wages[Client])
			{
				moneydrop = Wages[Client];
				moneylost = 0;
			}

			CPrintToChat(Client, "{red}[RP]\x04\x01 You have dropped $\x04%d \x04\x01 and lost $\x04%d \x04\x01.", moneydrop, moneylost);	
			
			Money[Client] = Money[Client] - (moneydrop + moneylost);
			Save(Client);
			
			rp_createMoneyBoxes(Client,moneydrop);
			
			if(Money[Client] < 0) Money[Client] = 0;
			LooseMoney[Client] = false;
		}
	}
	
	CloseHandle(Event);
	return Plugin_Handled;
}

// ---- Buttons ----
//Prethink:
public OnGameFrame()
{
	
	//Loop:
	for(new Client = 1; Client <= MaxClients; Client++)
	{
		//Connected:
		if(IsClientInGame(Client))
		{
			
			//Declare:
			decl Float:ClientOrigin[3];
			
			//Origin:
			if(IsClientInGame(Client)) GetClientAbsOrigin(Client, ClientOrigin);
			
			//Alive:
			if(IsPlayerAlive(Client))
			{
				//unlimited Run for Admins
				new m_bitsActiveDevices = GetEntProp(Client, Prop_Send, "m_bitsActiveDevices");
				if (m_bitsActiveDevices & bits_SUIT_DEVICE_SPRINT && rp_iscop(Client) > 9) 
				{
					SetEntPropFloat(Client, Prop_Data, "m_flSuitPowerLoad", 0.0);
					SetEntProp(Client, Prop_Send, "m_bitsActiveDevices", m_bitsActiveDevices & ~bits_SUIT_DEVICE_SPRINT);
				}


				//Loose Weapon on Cuff
				if(IsCuffed[Client]) 	
					LooseWeapon(Client, true);
	
				//Attack Key
				if(GetClientButtons(Client) & IN_ATTACK)
				{
					decl String:WeaponName[80];
					GetClientWeapon(Client, WeaponName, 32);
					
					//Unlimited Ammo for Pistol
					if(rp_iscop(Client) > 3 && StrEqual(WeaponName, WEAPON_DISTANCESTUN, false))
					{
						new prp = GetEntDataEnt2(Client, 1896);
						if(IsValidEntity(prp))
							SetEntData(prp, 1204, 50, 4, true);
					}
				}
				
				//Attack2 Key:
				else if(GetClientButtons(Client) & IN_ATTACK2)
				{    
					
					//Declare:
					decl Ent;    				
					decl String:WeaponName[80];
					
					Ent = rp_entclienttarget(Client,true); 
					
					//Weapon:
					GetClientWeapon(Client, WeaponName, 32);
					
					if(rp_iscop(Client) && StrEqual(WeaponName, WEAPON_STUN, false))
					{	
						//Cop Push					
						if(Ent < MaxClients && Ent > 0) //Ent ist ein Spieler
						{
							decl Float:EntOrigin[3], Float:Dist;
							
							//Initialize:
							GetClientAbsOrigin(Client, ClientOrigin);
							GetClientAbsOrigin(Ent, EntOrigin);
							Dist = GetVectorDistance(ClientOrigin, EntOrigin);
							
							if(Dist <= 100)
							{
								decl Float:Push[3];
								decl Float:EyeAngles[3], Float:EyeAngles2[3];
								rp_geteyes(Client, EyeAngles);
								rp_geteyes(Ent, EyeAngles2);
								Push[0] = (500.0 * Cosine(DegToRad(EyeAngles[1])));
								Push[1] = (500.0 * Sine(DegToRad(EyeAngles[1])));
								Push[2] = (-50.0 * Sine(DegToRad(EyeAngles[0])));
								rp_teleportent(Ent, EntOrigin, EyeAngles2, Push);
							}	
						}
					}
				}
				
				//Shift Key:
				else if(GetClientButtons(Client) & IN_SPEED)
				{
					if(!PrethinkBuffer[Client])
					{
						CommandSpeed(Client);
						PrethinkBuffer[Client] = true;
					}
				}
				//Nothing:
				else
				{
					PrethinkBuffer[Client] = false;
				}
			}
		}
	}
}


//E Key:
public Action:CommandUse(Client)
{
	decl Ent;
	Ent = rp_entclienttarget(Client,false);
			
	decl Float:Dist2;
	decl Float:ClientOrigin2[3];
	decl Float:EntOrigin[3];
	decl String:ClassName[64];
	
	if(Ent != -1 && Ent > 0)
	{
		//Initialize:
		GetClientAbsOrigin(Client, ClientOrigin2);
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", EntOrigin);
		Dist2 = GetVectorDistance(ClientOrigin2, EntOrigin);
		GetEdictClassname(Ent, ClassName, 64);
	}
	

		
	//Cuffed:
	if(IsCuffed[Client])
	{
		if(Ent > 0 && Ent < MaxClients && rp_iscop(Ent))
		{
			//Handeln mit Cop
			if(Dist2 <= 150 || Dist2 <= 150 && IsCuffed[Ent])
			{
				if(Ent <= MaxClients)
				{
					//Initialize:
					new String:Buffers3[7][64];
					Buffers3[0] = "Pay the Cop";
					Buffers3[1] = "Give Item to Cop";
					
					MenuTarget[Client] = Ent;
					rp_setItemMenuTarget(Client, Ent);
					
					//Draw:				
					DrawMenu(Client, Buffers3, HandlePlayer);
					
					//Return:
					return Plugin_Handled;
				}
			}
			return Plugin_Handled;
		} else
		{
			//Print:
			CPrintToChat(Client, "{red}[RP] You can't use anything while you are cuffed.");
			
			//Return:
			return Plugin_Handled;
		}
	}


	if(Ent != -1 && Ent > 0)
	{
		if(Dist2 <= 150)
		{	
		
			//Player Menu
			if(Ent <= MaxClients)
			{
				//Initialize:
				new String:Buffers2[7][64];
				Buffers2[0] = "Give Money";
				Buffers2[1] = "Give Item";
				
				
				if(rp_iscop(Client)) 
				{
					if(IsCuffed[Ent])
					{
							Buffers2[2] = "Jail";
							Buffers2[3] = "Release player";
							Buffers2[4] = "Execution Room";
					}
				}
				
				MenuTarget[Client] = Ent;
				rp_setItemMenuTarget(Client, Ent);
				
				//Draw:				
				DrawMenu(Client, Buffers2, HandlePlayer);
			
			
				//Quick Jail
				if(rp_iscop(Client) && IsCuffed[Ent])
				{
					if(lastpressedE[Client] > (GetGameTime() - 1.5))
					{
						rp_jail(Ent, Client);
						lastpressedE[Client] = 0.0;					
					}
					else	
					{
						CPrintToChat(Client, "{teamcolor}[RP]\x01 Press \x04USE\x01 again to put the person in jail.");
						lastpressedE[Client] = GetGameTime(); 
					} 
				}
			}
		}
		
		//Pick Up Money:
		if(DroppedMoneyValue[Ent] > 0 && StrEqual(ClassName, "prop_physics")) //prop_physics_override
		{
			//Range:
			if(Dist2 <= 300)
			{

				//Exchange:
				Money[Client] += DroppedMoneyValue[Ent];

				//Remove Ent:
				rp_entacceptinput(Ent, "Kill", Client);

				//Print:
				PrintToChat(Client, "[RP] You pick up $%d!", DroppedMoneyValue[Ent]);

				//Save:
				DroppedMoneyValue[Ent] = 0;

				//Return:
				return Plugin_Handled;
			}
		}
		
		
		//Pick Up Item:
		rp_CommandPickUpItem(Client, Ent);

		//Anti Doorslam
		if((StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating")) && !rp_iscop(Client))
		{
			if(lastpressedE[Client] > (GetGameTime()-2.0)) pressedE[Client]++;
			else
			{
				pressedE[Client] = 0;
				lastpressedE[Client] = GetGameTime();	
			}	
			
			if(pressedE[Client] > 5)
				BlockE[Client] = 1;
			else if(pressedE[Client] == 5)
			{
				BlockE[Client] = 1;
				CPrintToChat(Client, "{red}[RP]\x04 You can't use anything for the next 10sec!.\x04");
			} 
			else if(pressedE[Client] > 3)
			{
				CPrintToChat(Client, "{red}[RP]\x04 Stop blocking the door!.\x04");
			}
		}
	}

	//Interact with NPC
	if(Ent != -1 && Ent > MaxClients)
	{
		decl Handle:Vault;
		decl Float:Dist, Float:ClientOrigin[3], Float:Origin[3];
		decl String:NPCId[255], String:Props[255], String:Buffer[5][32];
		
		//Vault:
		Vault = CreateKeyValues("Vault");
		
		//Retrieve:
		FileToKeyValues(Vault, NPCPath);
		
		//Loop:
		for(new X = 0; X < 100; X++)
		{
			
			//Convert:
			IntToString(X, NPCId, 255);
			
			
			//Load:
			LoadString(Vault, "0", NPCId, "Null", Props);
			
			//Found in DB: JOBNPC
			if(StrContains(Props, "Null", false) == -1)
			{
				
				//Explode:
				ExplodeString(Props, " ", Buffer, 5, 32);
				
				//Origin:
				GetClientAbsOrigin(Client, ClientOrigin);
				Origin[0] = StringToFloat(Buffer[1]);
				Origin[1] = StringToFloat(Buffer[2]);
				Origin[2] = StringToFloat(Buffer[3]);
				
				//Distance:
				Dist = GetVectorDistance(ClientOrigin, Origin);
				
				//Check:
				if(Dist <= 150)
				{
					
					JobMenu(Client);
					CloseHandle(Vault);
					//Return:
					return Plugin_Handled;
				}
			}
			//Load:
			LoadString(Vault, "1", NPCId, "Null", Props);
			
			//Found in DB: BANKER
			if(StrContains(Props, "Null", false) == -1)
			{
				
				//Explode:
				ExplodeString(Props, " ", Buffer, 5, 32);
				
				//Origin:
				GetClientAbsOrigin(Client, ClientOrigin);
				Origin[0] = StringToFloat(Buffer[1]);
				Origin[1] = StringToFloat(Buffer[2]);
				Origin[2] = StringToFloat(Buffer[3]);
				
				//Distance:
				Dist = GetVectorDistance(ClientOrigin, Origin);
				
				//Check:
				if(Dist <= 150)
				{
					
					//Initialize:
					new String:Buffers[7][64];
					Buffers[0] = "Withdraw";
					Buffers[1] = "Deposit";
					
					//Draw:
					DrawMenu(Client, Buffers, HandleBank);
					
					//Return:
					CloseHandle(Vault);
					return Plugin_Handled;
				}
			}
			
			//Load: 
			LoadString(Vault, "2", NPCId, "Null", Props);
			
			//Found in DB: VENDOR
			if(StrContains(Props, "Null", false) == -1)
			{
				
				//Explode:
				ExplodeString(Props, " ", Buffer, 5, 32);
				
				//Origin:
				GetClientAbsOrigin(Client, ClientOrigin);
				Origin[0] = StringToFloat(Buffer[1]);
				Origin[1] = StringToFloat(Buffer[2]);
				Origin[2] = StringToFloat(Buffer[3]);
				
				//Distance:
				Dist = GetVectorDistance(ClientOrigin, Origin);
				
				//Check:
				if(Dist <= 80)
				{
					
					//Job Menu:
					VendorMenu(Client, X, false, false);
					
					//Return:
					CloseHandle(Vault);
					return Plugin_Handled;
				}
			}
			
			//Load: REVERSE VENDOR
			//LoadString(Vault, "3", NPCId, "Null", Props);
			//
			//Found in DB:
			//if(StrContains(Props, "Null", false) == -1)
			//{
			//	
			//	//Explode:
			//	ExplodeString(Props, " ", Buffer, 5, 32);
			//	
			//	//Origin:
			//	GetClientAbsOrigin(Client, ClientOrigin);
			//	Origin[0] = StringToFloat(Buffer[1]);
			//	Origin[1] = StringToFloat(Buffer[2]);
			//	Origin[2] = StringToFloat(Buffer[3]);
			//	
			//	//Distance:
			//	Dist = GetVectorDistance(ClientOrigin, Origin);
			//	
			//	//Check:
			//	if(Dist <= 150)
			//	{
			//		
			//		//Job Menu:
			//		VendorMenu(Client, X, true,false);
			//		
			//		//Return:
			//		CloseHandle(Vault);
			//		return Plugin_Handled;
			//	}
			//}
			
			//Load:
			//LoadString(Vault, "4", NPCId, "Null", Props);
			
			//Found in DB: AUCTIONATOR
			//if(StrContains(Props, "Null", false) == -1)
			//{
			//	
			//	//Explode:
			//	ExplodeString(Props, " ", Buffer, 5, 32);
			//	
			//	//Origin:
			//	GetClientAbsOrigin(Client, ClientOrigin);
			//	Origin[0] = StringToFloat(Buffer[1]);
			//	Origin[1] = StringToFloat(Buffer[2]);
			//	Origin[2] = StringToFloat(Buffer[3]);
			//	
			//	//Distance:
			//	Dist = GetVectorDistance(ClientOrigin, Origin);
			//	
			//	//Check:
			//	if(Dist <= 150)
			//	{
			//		
			//		//Job Menu:
			//		VendorMenu(Client, X, false, true);
			//		
			//		//Return:
			//		CloseHandle(Vault);
			//		return Plugin_Handled;
			//	}
			//}
			
			//Load:
			//LoadString(Vault, "5", NPCId, "Null", Props);
			
			//Found in DB: REVERSE AUCTIONATOR?
			//if(StrContains(Props, "Null", false) == -1)
			//{	
			//	
			//	//Explode:
			//	ExplodeString(Props, " ", Buffer, 5, 32);
			//	
			//	//Origin:
			//	GetClientAbsOrigin(Client, ClientOrigin);
			//	Origin[0] = StringToFloat(Buffer[1]);
			//	Origin[1] = StringToFloat(Buffer[2]);
			//	Origin[2] = StringToFloat(Buffer[3]);
			//	
			//	//Distance:
			//	Dist = GetVectorDistance(ClientOrigin, Origin);
			//	
			//	//Check:
			//	if(Dist <= 150)
			//	{
			//		
			//		//Job Menu:
			//		VendorMenu(Client, X, true, true);
			//		
			//		//Return:
			//		CloseHandle(Vault);
			//		return Plugin_Handled;
			//	}
			//}
			
	
		}
		
		//Close:
		CloseHandle(Vault);	
	}
	return Plugin_Handled;
}


//Shift Key:
public Action:CommandSpeed(Client)
{	
	//Cuffed:
	if(IsCuffed[Client])
	{
		//Return - Cuffed is not allowed ;)
		return Plugin_Handled;
	}
	
	//Declare:
	decl Ent;
	
	//Initialize:
	Ent = rp_entclienttarget(Client,false);
	
	//Check:
	if(Ent != -1 && Ent > MaxClients)
	{
		
		//Declare:	
		decl Handle:Vault;
		decl Float:Dist, Float:ClientOrigin[3], Float:Origin[3];
		decl String:NPCId[255], String:Props[255], String:Buffer[5][32];
		
		//Vault:
		Vault = CreateKeyValues("Vault");
		
		//Retrieve:
		FileToKeyValues(Vault, NPCPath);
		
		//Loop:
		for(new X = 0; X < 100; X++)
		{
			
			//Convert:
			IntToString(X, NPCId, 255);
			
			//Load:
			LoadString(Vault, "1", NPCId, "Null", Props);
			
			//Found in DB:
			if(StrContains(Props, "Null", false) == -1)
			{
				
				//Explode:
				ExplodeString(Props, " ", Buffer, 5, 32);
				
				//Origin:
				GetClientAbsOrigin(Client, ClientOrigin);
				Origin[0] = StringToFloat(Buffer[1]);
				Origin[1] = StringToFloat(Buffer[2]);
				Origin[2] = StringToFloat(Buffer[3]);
				
				//Distance:
				Dist = GetVectorDistance(ClientOrigin, Origin);
				
				
				//Check:
				if(Dist <= 150)
				{
					if(lastpressedSH[Client] >= GetGameTime()-3)
					{
						//Save
						RobOrigin[Client] = Origin;
						
						//Rob:
						BeginRob(Client, "Banker", 250, 1, StringToInt(NPCId));
					} else
					{
						CPrintToChat(Client, "{teamcolor}[RP]\x01 Press \x04Sprint\x01 again to start the robbery\x04");
					}
					lastpressedSH[Client] = GetGameTime();
					
				}
			}
			
			//Load:
			LoadString(Vault, "2", NPCId, "Null", Props);
			
			//Found in DB:
			if(StrContains(Props, "Null", false) == -1)
			{
				
				//Explode:
				ExplodeString(Props, " ", Buffer, 5, 32);
				
				//Origin:
				GetClientAbsOrigin(Client, ClientOrigin);
				Origin[0] = StringToFloat(Buffer[1]);
				Origin[1] = StringToFloat(Buffer[2]);
				Origin[2] = StringToFloat(Buffer[3]);
				
				//Distance:
				Dist = GetVectorDistance(ClientOrigin, Origin);
				
				//Check:
				if(Dist <= 150)
				{
					if(lastpressedSH[Client] >= GetGameTime()-3)
					{
						//Save
						RobOrigin[Client] = Origin;
						
						//Rob:
						BeginRob(Client, "Vendor", 200, 2, StringToInt(NPCId));
					} else
					{
						CPrintToChat(Client, "{teamcolor}[RP]\x01 Press \x04Sprint\x01 again to start the robbery\x04");
					}
					lastpressedSH[Client] = GetGameTime();
				}
			}
			
			//Load:
			//LoadString(Vault, "3", NPCId, "Null", Props);
			
			//Found in DB:
			//if(StrContains(Props, "Null", false) == -1)
			//{
			//	
			//	//Explode:
			//	ExplodeString(Props, " ", Buffer, 5, 32);
			////	
			//	//Origin:
			//	GetClientAbsOrigin(Client, ClientOrigin);
			//	Origin[0] = StringToFloat(Buffer[1]);
			//	Origin[1] = StringToFloat(Buffer[2]);
			//	Origin[2] = StringToFloat(Buffer[3]);
				
			//	//Distance:
			//	Dist = GetVectorDistance(ClientOrigin, Origin);
				
			//	//Check:
			//	if(Dist <= 150)
			//	{
			//		if(lastpressedSH[Client] >= GetGameTime()-3)
			//		{
			//			//Save
			//			RobOrigin[Client] = Origin;
			//			
			//			//Rob:
			//			BeginRob(Client, "Auctionator", 100, 2, StringToInt(NPCId));
			//		} else
			//		{
			//			CPrintToChat(Client, "{teamcolor}[RP]\x01 Press \x04Sprint\x01 again to start the robbery\x04");
			//		}
			//		lastpressedSH[Client] = GetGameTime();
			//	}
			//}
		}
		//Close:
		CloseHandle(Vault);
	}
	
	//Close:
	return Plugin_Handled;	
}

// --- ROBBING ---
public Action:BeginRob(Client, const String:Name[32], Cash, Type, Id)
{
	
	//Combine:
	if(rp_iscop(Client) > 0)
	{
		
		//Print:
		CPrintToChat(Client, "{teamcolor}[RP]\x04 Prevent crime, do not start it!\x04");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	decl bool:CombineInGame;
	
	//Initialize:
	CombineInGame = false;
	
	//Loop:
	for(new X = 1; X <= GetMaxClients(); X++) if(rp_iscop(X) > 0) CombineInGame = true;
	
	//Zero Combines:
	if(!CombineInGame)
	{
		
		//Easy Mode:
		CPrintToChat(Client, "{teamcolor}[RP]\x04 Try again later, there is no police online to stop you!\x04");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Ready:
	if(RobTimerBuffer[Type][Id] != 0 && RobTimerBuffer[Type][Id] >= (GetGameTime() - GetConVarInt(CV_NPCROBINTERVAL)))
	{
		//Calculate
		new Cache 	= RobNPC[Type][Id] / 60; 	//Minutes
		new Cache2 	= RobNPC[Type][Id] % 60; 	//Seconds
		
		//Workaround
		if(Cache != 0 && Cache2 != 0)
		{
			//Print:
			if(Cache < 10 && Cache2 < 10) CPrintToChat(Client, "{teamcolor}[RP]\x01 The register has been robbed too recently, \x040%d:0%d\x01 minutes left!",  Cache, Cache2);else
			if(Cache < 10) CPrintToChat(Client, "{teamcolor}[RP]\x01 The register has been robbed too recently, \x040%d:%d\x01 minutes left!",  Cache, Cache2);else
			if(Cache2 < 10) CPrintToChat(Client, "{teamcolor}[RP]\x01 The register has been robbed too recently, \x04%d:0%d\x01 minutes left!",  Cache, Cache2);else
			CPrintToChat(Client, "{teamcolor}[RP]\x01 The register has been robbed too recently, \x04%d:%d\x01 minutes left!",  Cache, Cache2);
			
			//Return:
			return Plugin_Handled;
		}
	}
	
	//Cuffed:
	if(IsCuffed[Client]) return Plugin_Handled;
	
	//Save:
	RobTimerBuffer[Type][Id] = GetGameTime();
	RobNPC[Type][Id] = GetConVarInt(CV_NPCROBINTERVAL);
	
	//Loop:
	for(new Y = 1; Y <= MaxClients; Y++)
	{
		
		//Connected:
		if(IsClientInGame(Y))
		{
			
			//Declare:
			new String:sType[32];
			
			//Initialize:
			if(Type == 1) sType = "Banker";
			if(Type == 2) sType = "Vendor";
			
			
			//Print:
			SetHudTextParams(-1.0, 0.015, 10.0, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
			ShowHudText(Y, -1, "[ATTENTION] %N is robbing a %s!", Client, sType);
			CPrintToChat(Y, "{teamcolor}[RP]\x04[ATTENTION] %N\x04\x01 is robbing a \x04%s\x01", Client, sType);
		}
	}
	
	//Start:
	RobCash[Client] = Cash;
	CreateTimer(1.0, BeginRobbery, Client, TIMER_REPEAT);
	CPrintToChat(Client, "{teamcolor}[RP]\x04 You have started the robbery, stay close to continue getting money\x04");
	
	
	//Return:
	return Plugin_Handled;
}

public Action:BeginRobbery(Handle:Timer, any:Client)
{
	
	//Cleared:
	if(RobCash[Client] <= 0)
	{
		
		//Print:
		CPrintToChat(Client, "{teamcolor}[RP]\x04 You have taken all of the money, run!\x04");
		
		//Kill:
		KillTimer(Timer);
		
		//Print:
		CPrintToChat(Client, "{teamcolor}[RP]\x04 You have moved too far from the register! Robbery aborted\x04");
		PrintRobberyAbort(Client);
		
		//Return:
		return Plugin_Handled;
	}
	
	//Return:
	if(!IsClientInGame(Client) || !IsClientConnected(Client) || !IsPlayerAlive(Client)) return Plugin_Handled;
	
	//Declare:
	decl Float:Dist;
	decl Float:ClientOrigin[3];
	
	//Initialize:
	GetClientAbsOrigin(Client, ClientOrigin);
	Dist = GetVectorDistance(RobOrigin[Client], ClientOrigin);
	
	//Too Far Away:
	if(Dist >= 150)
	{
		
		//Print:
		CPrintToChat(Client, "{teamcolor}[RP]\x04 You have moved too far from the register! Robbery aborted \x04");
		PrintRobberyAbort(Client);
		
		//Kill:
		RobCash[Client] = 0;
		KillTimer(Timer);
		
		//Return:
		return Plugin_Handled;
	}
	
	//Money:
	Money[Client] += 3;
	RobCash[Client] -= 3;
	Crime[Client] += 6;
	
	
	//Return:
	return Plugin_Handled;
}


// --- MENUS ---
//Draw Menu:
stock DrawMenu(Client, String:Buffers[7][64], MenuHandler:MenuHandle, Variables[7] = {0, 0, 0, 0, 0, 0, 0})
{

	//Declare:
	decl Handle:Panel;

	//Initialize:
	Panel = CreatePanel();

	//Print:
	OverflowMessage(Client, "[RP] Press <Escape> to access the menu");

	//Display:
	for(new X = 0; X < 7; X++) if(strlen(Buffers[X]) > 0)
	{

		//Add:
		DrawPanelItem(Panel, Buffers[X]);

		//Var:
		SelectedBuffer[X][Client] = Variables[X];
	}
 
	//Draw:
	SendPanelToClient(Panel, Client, MenuHandle, 30);

	//Close:
	CloseHandle(Panel);
}

//Transaction Handle:
public HandleGiveMoney(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Select:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl Amount;

		//Initialize:
		Amount = SelectedBuffer[Parameter-1][Client];
		if(SelectedBuffer[Parameter-1][Client] == 69) Amount = Money[Client];

		//Check:
		if(Money[Client] - Amount >= 0 && Amount >= 0)
		{

			//Transact:
			Money[Client] -= Amount;  
			Save(Client); 
	
			Money[MenuTarget[Client]] += Amount;
			Save(MenuTarget[Client]); 
	
	

			//Print:
			CPrintToChat(Client, "{teamcolor}[RP]\x01 You gave \x04%N $%d\x01", MenuTarget[Client], Amount);
			CPrintToChat(MenuTarget[Client], "{teamcolor}[RP]\x01 You recieve \x04$%d\x01 from \x04%N\x01", Amount, Client);

			//Initialize:
			new String:Buffers[7][64] = {"1", "5", "25", "100", "500", "1000", "All"};
			new Variables[7] = {1, 5, 25, 100, 500, 1000, 69};
				
			//Draw:
			DrawMenu(Client, Buffers, HandleGiveMoney, Variables);
		}
		else
		{

			//Print:
			PrintToChat(Client, "{teamcolor}[RP]\x01 You don't have that much money");
		}
	}
}



//PlayerMenu Handle:
public HandlePlayer(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{
	//Select:
	if(HandleAction == MenuAction_Select)
	{
		
		//Give Money:
		if(Parameter == 1)
		{

			//Initialize:
			new String:Buffers[7][64] = {"1", "5", "25", "100", "500", "1000", "All"};
			new Variables[7] = {1, 5, 25, 100, 500, 1000, 69};
				
			//Draw:
			DrawMenu(Client, Buffers, HandleGiveMoney, Variables);
		}

		//Give Item:
		if(Parameter == 2)
		{

			//Save:
			rp_SetIsGiving(Client, true);
	
			//Send:
			rp_ShowInvetory(Client, 0);
		}
		
		
		if(Parameter == 3 && rp_iscop(Client))
		{
			rp_jail(MenuTarget[Client], Client);
		}
		
		if(Parameter == 4 && rp_iscop(Client))
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x01 You released \x04%N\x01!", MenuTarget[Client]);
			CPrintToChat(MenuTarget[Client], "{teamcolor}[RP]\x04 %N released you!", Client);
			rp_jail_autoFreeTimerKill(MenuTarget[Client]);
		}
		
		if(Parameter == 5 && rp_iscop(Client))
		{
			rp_jail_suicidechamber(MenuTarget[Client], Client);	
		}
		
		
	}
}


//Job Menu Handle:
public HandleJob(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{
	//Select:
	if(HandleAction == MenuAction_Select)
	{
		
		//Next:
		if(Parameter == NextKey[Client])
		{
			
			//Update:
			LastId[1][Client] = LastId[0][Client];
			
			//Next:			
			if(!StrEqual(Job[Client], DEFAULTJOB)) JobMenu(Client);
		}
		
		else if(StrContains(Job[Client], "ASSHOLE", false) != -1)
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x04 You are not allowed to change your job\x04");
		}
		
		//Update:
		else
		{
			
			//Declare:
			decl Handle:Vault;
			decl String:JobId[255];
			
			decl String:ReferenceString[255];
			
			//Initialize:
			Vault = CreateKeyValues("Vault");
			
			//Load:
			FileToKeyValues(Vault, JobPath);
			
			//Convert:
			IntToString(SelectedBuffer[Parameter-1][Client], JobId, 255);
			
			
			//Variables (String):
			LoadString(Vault, "0", JobId, DEFAULTJOB, ReferenceString);
			
			//Close:
			CloseHandle(Vault);
			
			//Update:
			Job[Client] = ReferenceString;
		}
	}
}
	

//Job Menu:
public Action:JobMenu(Client)
{
	
	//Connected:
	if(!IsClientConnected(Client) || !IsClientInGame(Client))
	{	
		
		//Return:
		return Plugin_Handled;
	}
	
	//Alive:
	if(!IsPlayerAlive(Client))
	{
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	new ItemCount = 1;
	decl Handle:Panel, Handle:Vault;
	
	//Initialize:
	Panel = CreatePanel();
	Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, JobPath);
	
	//Loop:
	for(new X = (LastId[1][Client] + 1); X < MAXJOBS; X++)
	{
		
		//Declare:
		decl String:JobId[255];
		decl String:ReferenceJob[255];
		
		//Convert:
		IntToString(X, JobId, 255);
		
		//Load:
		LoadString(Vault, "0", JobId, "Null", ReferenceJob);
		
		//Found:
		if(!StrEqual(ReferenceJob, "Null"))
		{
			
			//Add:
			DrawPanelItem(Panel, ReferenceJob);
			
			//Save:
			SelectedBuffer[ItemCount-1][Client] = StringToInt(JobId);
			ItemCount++;
			LastId[0][Client] = X;
			
			//Check:
			if(ItemCount == 8) X = MAXJOBS;
		}
		
	}
	
	//Next:
	if(ItemCount != 8) LastId[0][Client] = 0;
	NextKey[Client] = ItemCount;
	DrawPanelItem(Panel, "Next");
	
	//Send:
	SendPanelToClient(Panel, Client, HandleJob, 15);

	//Close:
	CloseHandle(Panel);
	CloseHandle(Vault);
	
	//Return:
	return Plugin_Handled;
}




//Vendor Handle:
public HandleBuy(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{
	
	//Select:
	if(HandleAction == MenuAction_Select)
	{
		decl ItemId;
		ItemId = SelectedBuffer[Parameter - 1][Client];
				
		SelectItem[Client] = ItemId;
		
		new Handle:MoreItem = CreateMenu(MoreItemMenu);
		new String:MuchItem[255];	
		new String:Name[64];
		new ItemCost;
		new String:bMax[64];
		ItemCost = rp_itemCost(ItemId);
		
		rp_itemName(ItemId, Name);
		
		SetMenuTitle(MoreItem, "Select your ammount:");
		
		decl SaveMoney;
		
		SaveMoney = Money[Client];
		
		if(SaveMoney == rp_itemCost(ItemId))
		{
			iMax[Client] = 1;
		}
		
		if(SaveMoney < rp_itemCost(ItemId))
		{
			iMax[Client] = 0;
		}		
		else
		{
			for(new Max = 0;SaveMoney >= ItemCost; Max++){
				if(SaveMoney < ItemCost)break;
				SaveMoney -= ItemCost;
				iMax[Client] = Max + 1;
				if(SaveMoney < ItemCost)break;
			}
		}
		
		Format(MuchItem, 255, "All %d x %s(%d$)", iMax[Client], Name, ItemCost * iMax[Client]);
		Format(bMax, sizeof(bMax), "%d", iMax[Client]);
		AddMenuItem(MoreItem, bMax, MuchItem);
		Format(MuchItem, 255, "1 x %s(%d$)", Name, ItemCost);
		AddMenuItem(MoreItem, "1", MuchItem);
		Format(MuchItem, 255, "5 x %s(%d$)", Name, ItemCost * 5);
		AddMenuItem(MoreItem, "5", MuchItem);
		Format(MuchItem, 255, "10 x %s(%d$)", Name, ItemCost * 10);
		AddMenuItem(MoreItem, "10", MuchItem);
		Format(MuchItem, 255, "20 x %s(%d$)", Name, ItemCost * 20);
		AddMenuItem(MoreItem, "20", MuchItem);
		Format(MuchItem, 255, "50 x %s(%d$)", Name, ItemCost * 50);
		AddMenuItem(MoreItem, "50", MuchItem);
		Format(MuchItem, 255, "100 x %s(%d$)", Name, ItemCost * 100);
		AddMenuItem(MoreItem, "100", MuchItem);
		SetMenuExitButton(MoreItem, false);
		DisplayMenu(MoreItem, Client, 30);
		
	}
	return true;
}


public MoreItemMenu(Handle:menu, MenuAction:action, Client, Parameter)
{
	
	//Select:
	if(action == MenuAction_Select)
	{
		new ItemCost, String:Name[64], String:info[32], SItemCost;
		GetMenuItem(menu, Parameter, info, sizeof(info));					
		new Amount = StringToInt(info);	
		
		ItemCost = rp_itemCost(SelectItem[Client]);
		SItemCost = ItemCost * Amount;
		
		rp_itemName(SelectItem[Client], Name);
		
		if(Money[Client] >= SItemCost)
		{
			remMoney(Client,SItemCost);
			rp_addItem(Client, SelectItem[Client], Amount);
			rp_saveItem(Client, SelectItem[Client], Amount);
			CPrintToChat(Client, "{teamcolor}[RP]\x04\x01 You purchase \x04%d\x04\x01 x \x04%s\x04\x01 for \x04%d\x04\x01$.", Amount, Name, SItemCost);
			rp_log_purchase(Client, SelectItem[Client], Amount);
		}
		else
		{
			//Print:
			CPrintToChat(Client, "{teamcolor}[RP]\x04 You don't have enough money for this item\x04");
		}	

		//Display:
		VendorMenu(Client, GlobalVendorId[Client],false,false);
	}
	else if (action == MenuAction_End)
		{
			CloseHandle(menu);
			return true;
		}
	return true;
}


//Vendor Menus:
public VendorMenu(Client, iVendorId, isAuct, isBuy)
{
	
	//Declare:
	decl Handle:Vault;
	decl String:Props[255], String:VendorId[255];
	
	//Save:
	GlobalVendorId[Client] = iVendorId;
	
	//Initialize:
	IntToString(iVendorId, VendorId, 255);
	Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, NPCPath);
	
	//Load:
	LoadString(Vault, "VItems", VendorId, "Null", Props);
	
	//Found in DB:
	if(StrContains(Props, "Null", false) == -1)
	{
		
		//Declare:
		new Vars[7];
		new String:Buffer[7][32];
		new String:DisplayBuffer[7][64];
		new Price;
		new String:Name[64];
		//Explode:
		ExplodeString(Props, " ", Buffer, 7, 32);
		
		//Loop:
		for(new X = 0; X < 7; X++)
		{
			//Variables:
			Vars[X] = StringToInt(Buffer[X]);
			
			Price = rp_itemCost(Vars[X]);
			
			rp_itemName(Vars[X], Name);
			//Display:
			if(strlen(Name) > 0) Format(DisplayBuffer[X], 64, "%s - $%d", Name, Price);
		}
		
		
		CPrintToChat(Client, "{teamcolor}[RP]\x01 NPC is selling items\x04"); 
		DrawMenu(Client, DisplayBuffer, HandleBuy, Vars);
	}
	CloseHandle(Vault);
}


//BankMenu Handle:
public HandleBank(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{
	
	//Select:
	if(HandleAction == MenuAction_Select)
	{		
		
		//Withdraw:
		if(Parameter == 1)
		{			
			DrawWithdrawMenu(Client);			
		}
		
		//Deposit:
		if(Parameter == 2)
		{
			DrawDepositMenu(Client);			
		}
	}
}



public DrawWithdrawMenu(Client)
{
	new String:AllBank[255];
	new String:bAllBank[255];
	Format(AllBank, sizeof(AllBank), "All (%d$)", Bank[Client]);
	Format(bAllBank, sizeof(bAllBank), "%d", Bank[Client]);
	new Handle:menu = CreateMenu(Withdrawl);
	SetMenuTitle(menu, "How many money do you want to withdraw:");
	AddMenuItem(menu, bAllBank, AllBank);
	AddMenuItem(menu, "1", "1");
	AddMenuItem(menu, "5", "5");
	AddMenuItem(menu, "10", "10");
	AddMenuItem(menu, "20", "20");
	AddMenuItem(menu, "50", "50");
	AddMenuItem(menu, "100", "100");
	AddMenuItem(menu, "200", "200");
	AddMenuItem(menu, "500", "500");
	AddMenuItem(menu, "1000", "1000");
	AddMenuItem(menu, "10000", "10000");
	AddMenuItem(menu, "50000", "50000");
	AddMenuItem(menu, "100000", "100000");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, Client, 20);
	return true;
}


public DrawDepositMenu(Client)
{
	new String:AllMoney[255];	
	new String:bAllMoney[255];	
	Format(AllMoney, sizeof(AllMoney), "All (%d$)", Money[Client]);
	Format(bAllMoney, sizeof(bAllMoney), "%d", Money[Client]);
	new Handle:menu = CreateMenu(Deposits);
	SetMenuTitle(menu, "How many money do you want to deposid:");
	AddMenuItem(menu, bAllMoney, AllMoney);
	AddMenuItem(menu, "1", "1");
	AddMenuItem(menu, "5", "5");
	AddMenuItem(menu, "10", "10");
	AddMenuItem(menu, "20", "20");
	AddMenuItem(menu, "50", "50");
	AddMenuItem(menu, "100", "100");
	AddMenuItem(menu, "200", "200");
	AddMenuItem(menu, "500", "500");
	AddMenuItem(menu, "1000", "1000");
	AddMenuItem(menu, "10000", "10000");
	AddMenuItem(menu, "50000", "50000");
	AddMenuItem(menu, "100000", "100000");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, Client, 20);
	return true;
}

public Deposits(Handle:menu, MenuAction:action, Client, Parameter)
{
	
	//Select:
	if(action == MenuAction_Select)
	{
		
		new String:info[64];
		GetMenuItem(menu, Parameter, info, sizeof(info));					
		new Amount = StringToInt(info);	
		
		if(Amount >= 0 && Money[Client] >= Amount)
		{
			
			CPrintToChat(Client, "{teamcolor}[RP]\x04[Transaction]\x04\x01 You deposited \x04%s\x04\x01.", info);
			remMoney(Client,Amount);
			addBank(Client,Amount);
			DrawDepositMenu(Client);
			rp_log_deposit(Client, Amount);				
		} else
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x04[Transaction]\x04\x01 You dont have enough Money.");
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
		return true;
	}
	
	return true;
}

public Withdrawl(Handle:menu, MenuAction:action, Client, Parameter)
{
	if(action == MenuAction_Select)
	{
		
		new String:info[64];
		GetMenuItem(menu, Parameter, info, sizeof(info));					
		new Amount = StringToInt(info);	
		
		if(Amount >= 0 && Bank[Client] >= Amount){
			CPrintToChat(Client, "{teamcolor}[RP]\x04[Transaction]\x04\x01 You withdrawed \x04%s\x04\x01.", info);
			addMoney(Client, Amount);
			remBank(Client, Amount);
			DrawWithdrawMenu(Client);
			rp_log_withdraw(Client, Amount);
		}
		else
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x04[Transaction] You dont have enought Money.");
		}			
	}		
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
		return true;
	}
	return true;		
}	


// ---- CONNECT AND DISCONNECT ----

public bool:OnClientConnect(Client, String:Reject[], Len)
{
	Loaded[Client] = false;
	return true; 
}

//In-Game:
public OnClientPutInServer(Client)
{
	//Default Values:
	SetUpDefaults(Client, true);

	//Register:
	//Do not remove or edit the credits. See http://creativecommons.org/licenses/by-nc-sa/3.0/
	PrintToConsole(Client, 	"[RP] This Server is using Roleplay %s by Krim",VERSION);
	CPrintToChat(Client, 	"{red}[RP]\x01 Roleplay %s by Krim powered by SourceMod",VERSION);
	
	if(onTakeDamageHook) 
		SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
		
	
}

//Just in Case someone uses it...
public OnClientPostAdminCheck(Client)
{
	ClientCommand(Client,"bind i \"rp_items\"");
	ClientCommand(Client,"bind x \"sm_stats\"");
}

//Disconnect:
public OnClientDisconnect(Client)
{
	IsDisconnect[Client] = true;
	Save(Client);
	Loaded[Client] = false;
	Cop[Client] = false;
	
	new String:SteamId[32];
	GetClientAuthString(Client, SteamId, 64);
	
	PrintToChatAll("\x04%N (\x01%s\x04) disconnected.", Client, SteamId);
	
	if(onTakeDamageHook) 
		SDKUnhook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
	return true;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	PrintToConsole(0, "[SM] Roleplay %s loaded successfully!",VERSION);
	
	//Server Variable:
	CreateConVar("roleplay_version", VERSION, "Original Roleplay Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("roleplay_mod_krim", VERSION, "Roleplay Mod Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//Commands
	RegConsoleCmd("sm_switch", CommandSwitch);	
	
	CV_COPVSCOPKILL = CreateConVar("rp_tkcopkill","1","TK for cops enabled");
	CV_PROPDMG = CreateConVar("rp_propdmg","1","Activate prop damages");
	CV_GIVEWORK = CreateConVar("rp_giveworkweapon","1","Give the Workweapon by default");
	CV_COPDROP = CreateConVar("rp_copdropmoney","0","Do cops drop money on death");
	CV_FEED = CreateConVar("rp_needfeed","1","Enable/Disable Feeding routine");
	
	
	
	//Event Hooks
	HookEvent("player_death", EventDeath);
	HookEvent("player_hurt", EventDamage);
	HookEvent("player_spawn", EventSpawn);
	HookEvent("player_activate", EventActivate, EventHookMode_Pre);
	
	FadeID = GetUserMessageId("Fade");
	ShakeID = GetUserMessageId("Shake");
	
	//Command Hooks
	RegConsoleCmd("kill", HandleKill);
	RegConsoleCmd("jointeam", HandleKill);
	
	//Disable Cheats:
	SetCommandFlags("r_screenoverlay", (GetCommandFlags("r_screenoverlay") - FCVAR_CHEAT));
	
	//CVars
	CV_NPCROBINTERVAL = CreateConVar("rp_npcrob_interval", "1500", "Npc Robbing interval");
	CV_CROWBARDMG = CreateConVar("rp_crowbar_dmg", "1", "Disable/Enable Crowbar and Stunstick DMG");

	
	//Precache:
	PrecacheModel("models/Items/BoxMRounds.mdl", true); //ItemBoxes

	//OnDamageHook
	onTakeDamageHook = (GetExtensionFileStatus("sdkhooks.ext") == 1);	
	if (onTakeDamageHook) 
	{
		for (new Client=1; Client<=GetMaxClients(); Client++) 
		{
			if (!IsClientInGame(Client)) {
				continue;
			}
			SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	
	//Clear Value of the array for dropped money
	for(new x = 0; x < MAXENT; x++)
	{
		DroppedMoneyValue[x] = 0;
	}
	
	//Clear Value of the array for dropped items
	for(new x = 0; x < MAXENT; x++)
	{
		DroppedItemValue[x] = 0;
	}
	
	
	for(new X = 0;X < 3; X++)
	{
		
		for(new Y = 0; Y < 100; Y++)
		{
			RobNPC[X][Y] = GetConVarInt(CV_NPCROBINTERVAL);
		}		
	}
	
	CreateTimer(TICK, ServerTimer, 0, TIMER_REPEAT);

	InitSQL();
	createdb();	
	
	//Entity FIX (does the same as rp_settings)
	decl String:MapName[255];
	GetCurrentMap(MapName, 255);
	ServerCommand("mp_teamplay 1");
	ServerCommand("map %s", MapName);
}

public Action:ServerTimer(Handle:Timer)
{
	RobTimer();	
}

public RobTimer()
{
	for(new X = 0;X < 3; X++)
	{		
		for(new Y = 0; Y < 100; Y++)
		{
			if(RobNPC[X][Y] != 0) RobNPC[X][Y]--;			
		}		
	}
	return true;
}

public OnMapStart()
{	
	decl String:Map[128], String:Path[64];
	GetCurrentMap(Map, 128);

	BuildPath(Path_SM, Path, 64, "data/roleplay/%s/", Map);
	CreateDirectory(Path,511);
	
	//NPC DB:
	BuildPath(Path_SM, NPCPath, 64, "data/roleplay/%s/npcs.txt",Map);
	
	//JOB DB:
	BuildPath(Path_SM, JobPath, 64, "data/roleplay/jobs.txt");
	
	MapRunning = true;
	
	if(GetConVarInt(CV_FEED) == 0) needfeed = false; else needfeed = true;
	
	CreateTimer(1.0, rp_settings);
}

public OnMapEnd()
{
	MapRunning = false;
	cleanUpTimer();
}

//Cleans all Timers = fixing the wrong timer bugs
public cleanUpTimer()
{
	for(new i = 0;i < MAXPLAYER; i++)
	{
		lastpressedE[i] = 0.0;
		lastpressedSH[i] = 0.0;
	}
	
	for(new i=0; i<3; i++)
	{
		for(new j=0; j<100; j++)
		{
			RobTimerBuffer[i][j] = 0.0;	
		}
	}
}

public Action:rp_settings(Handle:Timer)
{
	//Micromod - i know i can just remove the check in FixMap, but it's in there for a reason.
	decl String:Map[255];
	GetCurrentMap(Map, 255);
	ServerCommand("sm_cvar physcannon_maxmass 10000");
	FixMap(Map);

}

// --- GETTER AND SETTER ---
//NATIVES
public GetExploit(Handle:plugin, numParams)
{	
	new Client = GetNativeCell(1);
	return ExploitJail[Client];
}

public getDroppedMoneyValue(Handle:plugin, numParams)
{	
	new Ent = GetNativeCell(1);
	return DroppedMoneyValue[Ent];
}


public setLooseMoney(Handle:plugin, numParams)
{	
	new Client = GetNativeCell(1);
	new Byte = GetNativeCell(2);
	
	if(Byte == 1)
	{
		LooseMoney[Client] = true;
	}
	else
	{
		LooseMoney[Client] = false;
	}
}

//IsCuffed
public iscuff(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return IsCuffed[Client];
}


//Is Cop
public iscop(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	if(CopSwitch[Client] == 1 && Cop[Client] > 0) return 0;
	
	return Cop[Client];
}

//Set Cop
public setcop(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Cop[Client] = GetNativeCell(2);
}

//Bounty
public setBty(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Bounty[Client] = GetNativeCell(2);
	AutoBounty[Client] = false;
	if(Hate[Client] < 0) Hate[Client] = 0;
}

public getBty(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Bounty[Client];
}

//Strenght
public setStr(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Str[Client] = GetNativeCell(2);
	if(Str[Client] < 0) Str[Client] = 0;
	TmpStr[Client] = Str[Client];
}

public getStr(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Str[Client];
}

//Dex
public setDex(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Dex[Client] = GetNativeCell(2);
	if(Dex[Client] < 0) Dex[Client] = 0;
	TmpDex[Client] = Dex[Client];
	
}

public getDex(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Dex[Client];
}

//Speed
public setSpd(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Spd[Client] = GetNativeCell(2);
	if(Spd[Client] < 0) Spd[Client] = 0;
	TmpSpd[Client] = Spd[Client];
	
}

public getSpd(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Spd[Client];
}

//Weight
public setWgt(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Wgt[Client] = GetNativeCell(2);
	if(Wgt[Client] < 0) Wgt[Client] = 0;
	TmpWgt[Client] = Wgt[Client];
}

public getWgt(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Wgt[Client];
}

//Intelligence
public setInt(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Int[Client] = GetNativeCell(2);
	if(Int[Client] < 0) Int[Client] = 0;
	TmpInt[Client] = Int[Client];
}

public getInt(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Int[Client];
}

//Strenght
public setTmpStr(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	TmpStr[Client] = GetNativeCell(2);
}

public getTmpStr(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return TmpStr[Client];
}

//Dex
public setTmpDex(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	TmpDex[Client] = GetNativeCell(2);
}

public getTmpDex(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return TmpDex[Client];
}


//Speed
public setTmpSpd(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	TmpSpd[Client] = GetNativeCell(2);
}

public getTmpSpd(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return TmpSpd[Client];
}

//Weight
public setTmpWgt(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	TmpWgt[Client] = GetNativeCell(2);
}

public getTmpWgt(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return TmpWgt[Client];
}

//Intelligence
public setTmpInt(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	TmpInt[Client] = GetNativeCell(2);
}

public getTmpInt(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return TmpInt[Client];
}

//Traintime
public setTrain(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Trained[Client] = rp_gettime() + Float:GetNativeCell(2);
}

public getTrain(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Float:Time;
	Time = Trained[Client] - rp_gettime();
	if(Time < 0.0) Time = 0.0;
	return _:Time;
}


//Hunger
public setFeed(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Feeded[Client] = GetNativeCell(2);
	if(Feeded[Client] < 0) Feeded[Client] = 0;
}

public getFeed(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Feeded[Client];
}

//Exhaust
public setSta(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Stamina[Client] = GetNativeCell(2);
	if(Stamina[Client] < 0) Stamina[Client] = 0;
}

public getSta(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Stamina[Client];
}

//Hate
public setHate(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Hate[Client] = GetNativeCell(2);
	if(Hate[Client] < 0) Hate[Client] = 0;
}

public getHate(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Hate[Client];
}

public getMonVal(Handle:plugin, numParams)	
{
	new Ent = GetNativeCell(1);
	return DroppedMoneyValue[Ent];
}

public getItVal(Handle:plugin, numParams)	
{
	new Ent = GetNativeCell(1);
	return DroppedItemValue[Ent];
}

public native_setMoney(Handle:plugin, numParams)	
{
	setMoney(GetNativeCell(1),GetNativeCell(2));
}
public native_setWage(Handle:plugin, numParams)	
{
	setWage(GetNativeCell(1),GetNativeCell(2));
}
public native_setBank(Handle:plugin, numParams)	
{
	setBank(GetNativeCell(1),GetNativeCell(2));
}
public native_addMoney(Handle:plugin, numParams)	
{
	addMoney(GetNativeCell(1),GetNativeCell(2));
}
public native_remMoney(Handle:plugin, numParams)	
{
	remMoney(GetNativeCell(1),GetNativeCell(2));
}
public native_addBank(Handle:plugin, numParams)	
{
	addBank(GetNativeCell(1),GetNativeCell(2));
}
public native_remBank(Handle:plugin, numParams)	
{
	remBank(GetNativeCell(1),GetNativeCell(2));
}


public getMoney(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Money[Client];
}

public getBank(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Bank[Client];
}

public getWages(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Wages[Client];
}


public getPaycheck(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Paycheck[Client];
}

public getJob(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new String:str[255];
	GetNativeString(2, str, sizeof(str));

	Format(str,sizeof(str),"%s",Job[Client]);
	SetNativeString(2, str, sizeof(str), false);
}

public setJob(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new String:str[255];
	GetNativeString(2, str, sizeof(str));
	Format(Job[Client],255,"%s",str);
}

public getMinutes(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Minutes[Client];
}

public getCrime(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	return Crime[Client];
}

public native_saveitem(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Item = GetNativeCell(2);
	new Amount = GetNativeCell(3);
	SaveItem(Client, Item, Amount);
}

public native_load(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Load(Client);
}

public native_copOnline(Handle:plugin, numParams)	
{
	return isCopOnline();
}

// --- OTHER NATIVES ---
public native_looseWeapon(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new bool:b = GetNativeCell(2);
	LooseWeapon(Client,b);
}

public setDefaultSpeed(Handle:plugin, numParams)
{	
	new Client = GetNativeCell(1);
	TmpSpd[Client] = Spd[Client];
	SetSpeed(Client, 19.0 * TmpSpd[Client]);
}

//Crime:
public crime(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Time = GetNativeCell(2);
	
	if(!rp_iscop(Client))
	{
		//Add:
		Crime[Client] += Time;
	}
}


public rmcrime(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Time = GetNativeCell(2);
	
	if(!rp_iscop(Client))
	{
		//Add:
		Crime[Client] -= Time;
	}
}


public setCrime(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Time = GetNativeCell(2);
	
	//Add:
	Crime[Client] = Time;
}

public setDefault(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	Dex[Client] = DEFAULTDEX;
	Str[Client] = DEFAULTSTR;
	Wgt[Client] = DEFAULTWGT;
	Int[Client] = DEFAULTINT;
	Spd[Client] = DEFAULTSPD;
	Hate[Client] = 0;
}

//SDK Functions
NoSDKHooks()
{
	SetFailState("SDKHooks is required for the roleplay plugin");
}

public OnAllPluginsLoaded()
{
	if(GetExtensionFileStatus("sdkhooks.ext") != 1)
	{
		NoSDKHooks();
	}
}

public OnLibraryRemoved(const String:name[])
{
	if(strcmp(name, "sdkhooks.ext") == 0)
	{
		NoSDKHooks();
	}
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	if(MapRunning)
	{
		strcopy(gameDesc, sizeof(gameDesc), GAMEINFO);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Plugin:myinfo =
{
	name = "Official Roleplay Plugin",
	author = "Krim",
	description = "Everything a server needs for extensive roleplaying",
	version = VERSION,
	url = "http://www.wmchris.de"
};