//Roleplay v3.0 HUD
//Idea and first implementations by Joe 'Pinkfairie' Maley
//Programmed by Christian 'Krim' Uhl 
//Modified and Improoved by Monkeys and Samantha
//Licence: Creative Commons BY-NC-SA
//http://creativecommons.org/licenses/by-nc-sa/3.0/

//Includes:
#include "roleplay/rp_wrapper"
#include "roleplay/rp_include"
#include "roleplay/rp_hud"
#include "roleplay/rp_main"
#include "roleplay/rp_items"
#include "roleplay/rp_jail"

#define HUDTICK		1.2
#define VERSION 	"2.0.1"
#define INFODIST 	250
#define MAXPLAYER 	33
#define MAXENT 		2000

//Notice Buffer
static String:BankBuffer[MAXPLAYER][50];
static String:MoneyBuffer[MAXPLAYER][50];

//User defined notes
public String:Notice[MAXENT][255];
public String:SubNotice[MAXENT][255];
public String:ThirdNotice[MAXENT][255];
public String:NpcNotice[MAXENT][255];

//Saved Notes
static String:NamePath[64];

//Timer
static Doing[MAXPLAYER];
static Working[MAXPLAYER];
static String:WorkInfo[MAXPLAYER][255];

//Design
public LaserCache;
static HudColor[MAXPLAYER][3];

//User
public bool:Lasers[MAXPLAYER];
public bool:MetalDetector[MAXPLAYER];
public bool:TracerDetector[MAXPLAYER];
public bool:PoliceDetectorUpgrade[MAXPLAYER];
public bool:PoliceDetector[MAXPLAYER];
public bool:CrimeTracer[MAXPLAYER];
public bool:MoneyHud[33];
public bool:CrimeHud[33];
public bool:Calibrate[33];

public ShowStats[MAXPLAYER];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("rp_hud_bank", bankmod);
	CreateNative("rp_hud_money", moneymod);
	CreateNative("rp_hud_stats", showStats);
	CreateNative("rp_hud_timer", do_timer);
	
	CreateNative("rp_hud_laser", setshowLasers);
	
	CreateNative("rp_hud_set_crime", setshowCrime);
	CreateNative("rp_hud_set_police", setshowPolice);
	CreateNative("rp_hud_set_metal", setshowMetal);
	CreateNative("rp_hud_set_metal_tracer", setshowMetalTracer);	
	CreateNative("rp_hud_set_moneyhud", setmoneyhud);
	CreateNative("rp_hud_set_crimehud", setcrimehud);
	CreateNative("rp_hud_set_policeupgrade", setpoliceupgrade);
	CreateNative("rp_hud_set_calibrate", setshowcalibrate);
	

	CreateNative("rp_hud_get_calibrate", getshowcalibrate);
	CreateNative("rp_hud_get_policeupgrade", getpoliceupgrade);
	CreateNative("rp_hud_get_moneyhud", getmoneyhud);
	CreateNative("rp_hud_get_crimehud", getcrimehud);
	CreateNative("rp_hud_get_crime", getshowCrime);
	CreateNative("rp_hud_get_police", getshowPolice);
	CreateNative("rp_hud_get_metal", getshowMetal);
	CreateNative("rp_hud_get_metal_tracer", getshowMetalTracer);
	

	CreateNative("rp_hud_stats_enabled", setshowStats);
	CreateNative("rp_hud_show_stats", setshowStatsTime);
	CreateNative("rp_hud_set_color", setHudColor);
	
	//User Notices
	CreateNative("rp_notice", notice);
	CreateNative("rp_notice_all", notice_all);
	CreateNative("rp_notice_all_except_client", notice_all_except_client);
	
	//Entity Notices
	CreateNative("rp_setNotice", entNotice);
	CreateNative("rp_setNpcNotice", entNpcNotice);
	CreateNative("rp_saveNotice", entsaveNotice);
	CreateNative("rp_saveNpcNotice", entsaveNpcNotice);
	CreateNative("rp_remNotice", entremNotice);
	
	CreateNative("rp_setfirst", setfirst);
	CreateNative("rp_setsub", setsub);
	CreateNative("rp_setthird", setthird);
	
	//Chat Notices
	CreateNative("rp_notify",notify);
	
	return APLRes_Success;
}

public notify(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	
	new Len;
	GetNativeStringLength( 2, Len );
	
	decl String:Text[Len];
	GetNativeString( 2, Text, Len );
	
	decl String:Message[255];
	Format( Message, 255, "[RP] %s", Text );
	PrintToChat(Client, Message);
}

public setfirst(Handle:plugin, numParams)
{
	new Ent = GetNativeCell(1);
	
	
	new String:str[255];
	GetNativeString(2, str, 255);	
	
	Notice[Ent] = str;
	rp_saveNotice(0, Ent);
}

public setsub(Handle:plugin, numParams)
{
	new Ent = GetNativeCell(1);
	
	
	new String:str[255];
	GetNativeString(2, str, 255);	
	SubNotice[Ent] = str;
	rp_saveNotice(0, Ent);
}


public setthird(Handle:plugin, numParams)
{
	new Ent = GetNativeCell(1);
	
	
	new String:str[255];
	GetNativeString(2, str, 255);	
	ThirdNotice[Ent] = str;
	rp_saveNotice(0, Ent);
}



public getshowcalibrate(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	
	return Calibrate[Client];
}


public setshowcalibrate(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Value = GetNativeCell(2);
	
	Calibrate[Client] = int2bool(Value);
}


stock ShowPvP(Client)
{
	new PvP = rp_getPvP(Client);
	if(PvP > 0) 
	{
		PvP--;
		rp_setPvP(Client, PvP);
		if(rp_getCrime(Client) == 0)
		{
			SetHudTextParams(0.675, 0.075, HUDTICK, 0, 255, 0, 200, 1, 60.0, 0.1, 0.2); 			
			ShowHudText(Client, -1, "Security PvP: %d",  rp_getPvP(Client));
			SetEntProp(Client, Prop_Data, "m_takedamage", 0, 1);
			SetEntityRenderMode(Client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(Client, 0, 255, 0, 180);
		}
		else
		{
			SetHudTextParams(-1.0, 0.075, HUDTICK, 100, 149, 237, 200, 1, 60.0, 0.1, 0.2); 
			SetEntityRenderColor(Client, 255, 255, 255, 200);
			ShowHudText(Client, -1, "Security PvP  (Player vs. Player) has been disabled while you have crime!");
			SetEntProp(Client, Prop_Data, "m_takedamage", 2, 1);
			SetEntityRenderMode(Client, RENDER_NORMAL);
			SetEntityRenderColor(Client, 255, 255, 255, 255);  
		}	
	}
	
}


// ---- HUD ----
public Action:HUDTicker(Handle:Timer, any:Client)
{
	if(Client > 0 && IsClientInGame(Client))
	{
		decl Player, Float:Dist;
		Player = rp_entclienttarget(Client,true);
		
		if(Player > 0 && Player <= MaxClients)
		{
			new Float:COrg[3], Float:POrg[3];
			GetClientAbsOrigin(Player, POrg);
			GetClientAbsOrigin(Client, COrg);
			Dist = GetVectorDistance(POrg, COrg);
			if(IsClientConnected(Player) && IsClientInGame(Player) && IsPlayerAlive(Player))
			{
				if(Dist <= INFODIST)
					showPlayerInfo(Client,Player);
			}
		}
		
		showPersonalInfos(Client);
		showNotice(Client);
		showCrime(Client);
		showDoor(Client);
		ShowPvP(Client);
		ShowMetal(Client);
		PoliceDetector2(Client);
		rp_hud_stats(Client);
		CreateTimer(HUDTICK-0.05, HUDTicker, Client);
	}
}


stock showDoor(Client)
{
	new Ent = rp_entclienttarget(Client,false);
	if(Ent > 0 && Ent < MAXENT && !StrEqual(Notice[Ent], "", false))
	{ 
		decl Float:ClientOrigin[3], Float:EntOrigin[3];  
		decl Float:Dist; 
		GetClientAbsOrigin(Client, ClientOrigin);
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", EntOrigin);
		Dist = GetVectorDistance(ClientOrigin, EntOrigin);
		
		if(Dist <= 300)
		{
			new String:Output[510];
			SetHudTextParams(-1.0, -1.0, HUDTICK, 255,255,255, 200, 0, 6.0, 0.1, 0.2); 
			
			if(!StrEqual(SubNotice[Ent], "", false))
				Format(Output,510,"Housename: %s",SubNotice[Ent]);
			if(!StrEqual(ThirdNotice[Ent], "", false))
				Format(Output,510,"%s\nDoorname: %s",Output,ThirdNotice[Ent]);
				
			ShowHudText(Client, -1, "This door belongs to:\n%s\n%s", Notice[Ent],Output);
		}
	}
}
stock showPlayerInfo(Client,Player)
{
	SetHudTextParams(-1.0, -0.900, HUDTICK, 255,255,255, 200, 0, 6.0, 0.1, 0.2);
	new String:Job[255];
	rp_getJob(Player,Job);
	
	if(rp_iscop(Client))
	{
		ShowHudText(Client, -1, "Job: %s\nWages: $%d\nBounty: $%d\nMoney: $%d\nBank: $%d\nJail:%ds", Job,rp_getWage(Player),rp_getBty(Player),rp_getMoney(Player), rp_getBank(Player),rp_jail_getTimeinJail(Player));
	}
	else
	{
		ShowHudText(Client, -1, "Job: %s\nWages: $%d\nBounty: $%d", Job ,rp_getWage(Player),rp_getBty(Player));
	}
}

stock showCrime(Client)
{
	if(rp_iscop(Client) || rp_getCrime(Client) > 0)
	{
		new BeamColor[4] = {0, 0, 255, 200}; //3300FF 
		decl Float:CriminalOrigin[3];
		decl Float:ClientOrigin[3];
		
		GetClientAbsOrigin(Client, ClientOrigin);
		ClientOrigin[2] += 40.0;
			 
		//Declare:
		new bool:IsCrime = false;
		new String:FormatHud[255] = "\n\n\nCrime:  \n";
	
		//Loop:
		for(new X = 1; X <= MaxClients; X ++)
		{
			//Connected:
			if(IsClientInGame(X) && rp_getCrime(X) > 0)
			{
						
				//Save:
				IsCrime = true;
				
				//Declare:
				decl String:XName[32];
				decl String:TempSave[255];
				
				//Initialize:
				TempSave = FormatHud;
				GetClientName(X, XName, 32);
				GetClientAbsOrigin(X, CriminalOrigin);
				CriminalOrigin[2] += 40.0;
				
				//Format: 
				Format(FormatHud, 255, "%s%s (%d)  \n", TempSave, XName, rp_getCrime(X));
				
				//Beam:
				if(rp_iscop(Client) && Lasers[Client])
				{
					BeamColor = {50, 0, 255, 200}; //3300FF
					//Start:
					if(rp_getCrime(X) < 100)
					{
						BeamColor[2] = rp_getCrime(X); 
						BeamColor[0] = rp_getCrime(X) / 4;
						BeamColor[1] = 100 - rp_getCrime(X);    
					} else
					{
						BeamColor[1] = rp_getCrime(X) / 10;
						if(BeamColor[1] > 250) BeamColor[1] = 250;
					}
					rp_setupbeampoint(ClientOrigin, CriminalOrigin, LaserCache, 0, 0, 66, 0.5, 3.0, 3.0, 0, 0.0, BeamColor, 0);
					if(rp_hud_get_crime(Client)) rp_sendtoclient(Client);
				} 
				
				if(PoliceDetector[Client])
				{
					PoliceDetector2(Client);
				}
			}
		}
		
		//Display:
		if(IsCrime)
		{
			SetHudTextParams(0.95, 0.015, HUDTICK, 255, 0, 0, 255, 0, 6.0, 0.1, 0.2);
			if(rp_hud_get_crimehud(Client))ShowHudText(Client, -1, "%s ", FormatHud);  
		}
	}
}

stock showPersonalInfos(Client)
{
	if(rp_hud_get_moneyhud(Client))
	{
		new String:Text[255];
		new String:Job[60];
		rp_getJob(Client,Job);
		
		if(rp_getCrime(Client) > 0)	SetHudTextParams(0.015, 0.015, HUDTICK, 255, 0, 0, 200, 0, 6.0, 0.1, 0.2); 
		else if(rp_iscuff(Client)) SetHudTextParams(0.015, 0.015, HUDTICK, HudColor[Client][0], HudColor[Client][1],HudColor[Client][2], 200, 0, 6.0, 0.1, 0.2);
		else
			SetHudTextParams(0.015, 0.015, HUDTICK, 0, 0, HudColor[Client][0], HudColor[Client][1],HudColor[Client][2], 6.0, 0.1, 0.2);

		Format(Text,255,"Money: $%d",rp_getMoney(Client));
		if(!StrEqual(MoneyBuffer[Client], "", false))
		{
			Format(Text,255,"%s %s",Text,MoneyBuffer[Client]);
			Format(MoneyBuffer[Client],255,"");
		}
		Format(Text,255,"%s\nBank: $%d",Text,rp_getBank(Client));
		if(!StrEqual(BankBuffer[Client], "", false))
		{
			Format(Text,255,"%s %s",Text,BankBuffer[Client]);
			Format(BankBuffer[Client],255,"");
		}
		
		Format(Text,255,"%s\nStamina: %d\nJob: %s\nWages: $%d in %d",Text, rp_getSta(Client), Job, rp_getWage(Client), rp_getPaycheck(Client));
		
		if(rp_getBty(Client) > 0)
			ShowHudText(Client, -1, "%s\nBounty: $%d", Text ,rp_getBty(Client));
		else if(rp_jail_getTimeinJail(Client) > 0.0 && rp_iscuff(Client))
			ShowHudText(Client, -1, "%s\nJail: %ds", Text ,rp_jail_getTimeinJail(Client));
		else
		{
			decl Munny;
			Munny = RoundToCeil(Pow(float(rp_getWage(Client)), 3.0)) - rp_getMinutes(Client);
			ShowHudText(Client, -1, "%s\nNext Raise: %d min", Text ,Munny);
		}
	}
	
}

stock showNotice(Client)
{
	new Ent = rp_entclienttarget(Client,false);
	
	if(Ent > 0 && Ent < MAXENT && !StrEqual(NpcNotice[Ent], "", false) && !StrEqual(NpcNotice[Ent], "null", false))
	{ 
		decl Float:ClientOrigin[3], Float:EntOrigin[3];  
		decl Float:Dist; 
		GetClientAbsOrigin(Client, ClientOrigin);
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", EntOrigin);
		Dist = GetVectorDistance(ClientOrigin, EntOrigin);
		
		if(Dist <= 300)
		{
			SetHudTextParams(-1.0, -1.0, HUDTICK, 255, 0, 0, 150, 0, 6.0, 0.1, 0.2); 
			ShowHudText(Client, -1, "%s", NpcNotice[Ent]);
		}
	}
}

public getpoliceupgrade(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	return PoliceDetectorUpgrade[Client];
}

public setpoliceupgrade(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Value = GetNativeCell(2);
	PoliceDetectorUpgrade[Client] = int2bool(Value);
}
	
public setmoneyhud(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Value = GetNativeCell(2);
	MoneyHud[Client] = int2bool(Value);
}

public setcrimehud(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Value = GetNativeCell(2);
	CrimeHud[Client] = int2bool(Value);
}

public getmoneyhud(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	return MoneyHud[Client];
}

public getcrimehud(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	return CrimeHud[Client];
}

public setshowStats(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Value = GetNativeCell(2);
	ShowStats[Client] = Value;
}

public setshowStatsTime(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Time = GetNativeCell(2);
	rp_hud_stats_enabled(Client,1);
	CreateTimer(float(Time), StatsTicker, Client);
}

public Action:StatsTicker(Handle:Timer, any:Client)
{
	rp_hud_stats_enabled(Client,0);
}

public setshowLasers(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	
	if(Lasers[Client]) Lasers[Client] = false;
	else Lasers[Client] = true;
}

public getshowCrime(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);

	return CrimeTracer[Client];
}

public getshowPolice(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	
	return PoliceDetector[Client];
}

public getshowMetal(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	return MetalDetector[Client];
}

public getshowMetalTracer(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	
	return TracerDetector[Client];
}

public setshowCrime(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Value = GetNativeCell(2);
	CrimeTracer[Client] = int2bool(Value);

}

public setshowPolice(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Value = GetNativeCell(2);
	PoliceDetector[Client] = int2bool(Value);

}

public setshowMetal(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Value = GetNativeCell(2);
	MetalDetector[Client] = int2bool(Value);
}

public setshowMetalTracer(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Value = GetNativeCell(2);
	TracerDetector[Client] = int2bool(Value);
}

public showStats(Handle:plugin, numParams)
{
	
	new Client = GetNativeCell(1);
	if(ShowStats[Client] != 0)
	{
		SetHudTextParams(-1.0, 0.1, HUDTICK, 200, 150, 0, 255, 0, 6.0, 0.1, 0.2);
		ShowHudText(Client, -1, "Str: %d - Dex: %d - Spd: %d - Wgt: %d - Int: %d - Feeded:%d - Time2Train: %ds", rp_getStr(Client),rp_getDex(Client),rp_getSpd(Client),rp_getWgt(Client),rp_getInt(Client),rp_getFeed(Client),RoundToFloor(rp_getTrainTime(Client)));
	}
}

public setHudColor(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new R = GetNativeCell(2);
	new G = GetNativeCell(3);
	new B = GetNativeCell(4);
	
	if(R < 0 || R > 255) R = 255;
	if(G < 0 || G > 255) G = 255;
	if(B < 0 || B > 255) B = 255;
	
	HudColor[Client][0] = R;
	HudColor[Client][1] = G;
	HudColor[Client][2] = B;
}
// ---- HUD FUNCTIONS ----
public Action:DoTicker(Handle:Timer, any:Client)
{
	new String:tmr[10];
	
	new mkd = 10 - RoundToCeil((10.0 / Working[Client] * (Doing[Client])));
	
	for(new x = 0; x < mkd; x++)
	{
		tmr[x] = ' ';
	}
	for(new x = mkd; x < 9; x++)
	{
		if(x < 9 && x >= 0) tmr[x] = '-';
	}
	
	if((Doing[Client]) <= Working[Client])
	{
		SetHudTextParams(-1.0, -0.7, HUDTICK, 255, 0, 0, 150, 0, 6.0, 0.1, 0.2);
		ShowHudText(Client, -1, "%s\n(%s)",WorkInfo[Client],tmr);
		CreateTimer(0.95, DoTicker, Client);
		Doing[Client] = 1 + Doing[Client];
	}
}

public do_timer(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Time = GetNativeCell(2);
	
	Working[Client] = Time;
	Doing[Client] = 0;
	
	new len;
	GetNativeStringLength(3, len);
	
	new String:str[len+1];
	GetNativeString(3, str, len+1);

	Format(WorkInfo[Client],255,"%s",str);
	CreateTimer(0.01, DoTicker, Client);
}

public notice(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new len;
	GetNativeStringLength(2, len);
	
	if (len <= 0)
	{ return; }
	
	new String:str[len+1];
	GetNativeString(2, str, len+1);
	
	SetHudTextParams(-1.0, 0.015, 10.0, 255, 255, 255, 255, 1, 4.0, 0.1, 0.2); 
	ShowHudText(Client, -1, str);

}

public notice_all(Handle:plugin, numParams)	
{
	new len;
	GetNativeStringLength(1, len);
	
	if (len <= 0)
	{ return; }
	
	new String:str[len+1];
	GetNativeString(1, str, len+1);
	
	for(new Y = 1; Y <= MaxClients; Y++)
	{
		//Connected:
		if(IsClientInGame(Y))
		{ 
			SetHudTextParams(-1.0, 0.015, 10.0, 255, 255, 255, 255, 1, 4.0, 0.1, 0.2); 
			ShowHudText(Y, -1, str);
		}
	}
	
}

public notice_all_except_client(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new len;
	GetNativeStringLength(2, len);
	
	if (len <= 0)
	{ return; }
	
	new String:str[len+1];
	GetNativeString(2, str, len+1);
	
	for(new Y = 1; Y <= MaxClients; Y++)
	{
		//Connected:	
		if(IsClientConnected(Y) && IsClientInGame(Y) && Y != Client)
		{ 
			SetHudTextParams(-1.0, 0.015, 10.0, 255, 255, 255, 255, 1, 4.0, 0.1, 0.2); 
			ShowHudText(Y, -1, str);
		}
	}
	
}

public bankmod(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new len;
	GetNativeStringLength(2, len);
	
	if (len <= 0)
	{ return; }
	
	new String:str[len+1];
	GetNativeString(2, str, len+1);
	
	Format(BankBuffer[Client],50,"%s",str);
}

public moneymod(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new len;
	GetNativeStringLength(2, len);
	
	if (len <= 0)
	{ return; }
	
	new String:str[len+1];
	GetNativeString(2, str, len+1);
	Format(MoneyBuffer[Client],50,"%s",str);
}

// ---- SAVED NOTICES ----
public entNotice(Handle:plugin, numParams)
{
	new Ent = GetNativeCell(1);
	new len,len2,len3;
	GetNativeStringLength(2, len);
	GetNativeStringLength(3, len2);
	GetNativeStringLength(4, len3);
	
	if (len <= 0)
	{ return; }
	
	new String:str[len+1];
	new String:str2[len2+1];
	new String:str3[len3+1];
	GetNativeString(2, str, len+1);
	GetNativeString(3, str2, len2+1);
	GetNativeString(4, str3, len3+1);
	
	new String:sstring[255],String:sstring2[255],String:sstring3[255];
	
	Format(sstring,255,"%s",str);
	Format(sstring2,255,"%s",str2);
	Format(sstring3,255,"%s",str3);
	setNotice(Ent,sstring,sstring2,sstring3);
}

public entNpcNotice(Handle:plugin, numParams)
{
	new Ent = GetNativeCell(1);
	new len;
	GetNativeStringLength(2, len);

	if (len <= 0)
	{ return; }
	
	new String:str[len+1];
	GetNativeString(2, str, len+1);
	
	new String:sstring[255];
	
	Format(sstring,255,"%s",str);
	setNpcNotice(Ent,sstring);
}

public entsaveNpcNotice(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Ent = GetNativeCell(2);
	
	if(!StrEqual(NpcNotice[Ent], "", false))
	{
	 //Declare:
	decl Handle:Vault;
	new String:KeyBuffer[255];
	IntToString(calcSaveEnt(Ent), KeyBuffer, 255);
	    
	//Initialize:
	Vault = CreateKeyValues("Vault");

	FileToKeyValues(Vault, NamePath);
	
	KvJumpToKey(Vault, "note", false);
	KvDeleteKey(Vault, KeyBuffer); 
	KvRewind(Vault);

	
	//Jump:
	KvJumpToKey(Vault, "note", true);

	//Save:
	KvSetString(Vault, KeyBuffer, NpcNotice[Ent]);

	//Rewind:
	KvRewind(Vault);


	//Store:
	KeyValuesToFile(Vault, NamePath);

	if(Client > 0)
		PrintToChat(Client, "[RP] Notice has been saved on Entity #%d.", Ent);
		
	CloseHandle(Vault);
	} else if(Client > 0)
    	PrintToChat(Client, "[RP] Notice could not be saved on Entity #%d.", Ent);
}

public entsaveNotice(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Ent = GetNativeCell(2);
	
	if(!StrEqual(Notice[Ent], "", false))
	{
	 //Declare:
	decl Handle:Vault;
	new String:KeyBuffer[255];
	decl String:Buffers[3][255], String:Note[770];
	IntToString(calcSaveEnt(Ent), KeyBuffer, 255);
	    
	//Initialize:
	Vault = CreateKeyValues("Vault");

	FileToKeyValues(Vault, NamePath);
	
	KvJumpToKey(Vault, "note", false);
	KvDeleteKey(Vault, KeyBuffer); 
	KvRewind(Vault);
	
	Buffers[0] = Notice[Ent];
	Buffers[1] = SubNotice[Ent];
	Buffers[2] = ThirdNotice[Ent];
	ImplodeStrings(Buffers, 3, ";:", Note, 770);
	
	//Jump:
	KvJumpToKey(Vault, "note", true);

	//Save:
	KvSetString(Vault, KeyBuffer, Note);

	//Rewind:
	KvRewind(Vault);


	//Store:
	KeyValuesToFile(Vault, NamePath);

	if(Client > 0)
		PrintToChat(Client, "[RP] Notice has been saved on Entity #%d.", Ent);
		
	CloseHandle(Vault);
	} else if(Client > 0)
    	PrintToChat(Client, "[RP] Notice could not be saved on Entity #%d.", Ent);
}


public entremNotice(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Ent = GetNativeCell(2);
	
	//Declare:
	decl Handle:Vault;
	new String:KeyBuffer[255];
	IntToString(calcSaveEnt(Ent), KeyBuffer, 255);
	    
	//Initialize:
	Vault = CreateKeyValues("Vault");

	FileToKeyValues(Vault, NamePath);
	
	//Delete: (if exist)
	KvJumpToKey(Vault, "note", false);
	KvDeleteKey(Vault, KeyBuffer); 
	KvRewind(Vault);
	KeyValuesToFile(Vault, NamePath);
	CloseHandle(Vault);
	
	if(Client > 0)
		PrintToChat(Client, "[RP] Notice has been removed from Entity #%d.", Ent); 
}

stock setNpcNotice(Ent,String:Text[255])
{
	NpcNotice[Ent] = Text;
}


stock setNotice(Ent,String:Text[255],String:Text2[255],String:Text3[255])
{
	Notice[Ent] = Text;
	SubNotice[Ent] = Text2;
	ThirdNotice[Ent] = Text3;
}

//Load Notices:
stock Load()
{

	//Declare:
	decl Handle:Vault;
	
	Vault = CreateKeyValues("Vault");
	
	//Load:
	FileToKeyValues(Vault, NamePath);


	//Declare:
	decl String:Id[255];
	//Loop:
	for(new X = 0; X < MAXENT; X++)
	{
		//Convert:
		IntToString(X, Id, 255);
		
		decl String:Buffers[3][255];
		decl String:Note[770];

		//Jump:
		KvJumpToKey(Vault, "note", false);
	
		//Load:
		KvGetString(Vault, Id, Note, 770, "null");

		//Rewind:
		KvRewind(Vault);
	
		if(!StrEqual(Note, "null", false))	
		{
			ExplodeString(Note, ";:", Buffers, 3, 255);
			Notice[calcEnt(X)] = Buffers[0];
			SubNotice[calcEnt(X)] = Buffers[1];
			ThirdNotice[calcEnt(X)] = Buffers[2];
		}
	}

	//Close:
	CloseHandle(Vault);
}

// ---- CONNECT FUNCTIONS ----
public bool:OnClientConnect(Client, String:Reject[], Len)
{
	HudColor[Client] = {255, 200, 0};
	return true; 
}

//In-Game:
public OnClientPutInServer(Client)
{
	CreateTimer(0.1, HUDTicker, Client);
	Lasers[Client] = true;
}

public OnMapStart()
{
	decl String:Map[128], String:Path[64];
	GetCurrentMap(Map, 128);
	
	BuildPath(Path_SM, Path, 64, "data/roleplay/%s/", Map);
	CreateDirectory(Path,511);
	
	BuildPath(Path_SM, NamePath, 64, "data/roleplay/%s/notice.txt",Map);
	
	LaserCache = PrecacheModel("materials/sprites/laserbeam.vmt");
	Load();
}

public OnPluginStart()
{
	PrintToConsole(0, "[SM] Roleplay HUD %s by Krim loaded successfully!",VERSION);
	LoadTranslations("common.phrases");
	
	//Server Variable:
	CreateConVar("roleplay_hud", VERSION, "Roleplay HUD",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Plugin:myinfo =
{
	name = "Roleplay Revised HUD",
	author = "Krim",
	description = "Output and informations for the user",
	version = VERSION,
	url = "http://www.wmchris.de"
};

stock PoliceDetector2(Client) 
{
	if(PoliceDetector[Client]) 
	{
		decl Float:CriminalOrigin[3];
		decl Float:ClientOrigin[3];
		new BeamColor[4] = {0, 0, 255, 200}; //3300FF 
		GetClientAbsOrigin(Client, ClientOrigin);	
		for(new X = 1; X <= GetMaxClients(); X++)
		{
			if(X != Client && rp_iscop(X) && IsPlayerAlive(X))
			{
				//if(PoliceDetectorUpgrade[Client])
				//	BarroMeter(Client);
				GetClientAbsOrigin(X, CriminalOrigin);
				rp_setupbeampoint(ClientOrigin, CriminalOrigin, LaserCache, 0, 0, 66, 0.5, 3.0, 3.0, 0, 0.0, BeamColor, 0);
				rp_sendtoclient(Client);
			}
		}
	}
}

public ShowMetal(Client)
{
	if(MetalDetector[Client])
	{
		decl Float:ClientOrigin[3];
		GetClientAbsOrigin(Client, ClientOrigin);
		new Alt3BeamColor[4] = {255, 255, 255, 200};
		new Alt4BeamColor[4] = {255, 0, 0, 200};
		
		new bool:Found;
		decl Float:EntOrigin[3];
		new String:ModelName[64];
		new max = GetMaxEntities();
		
		SetHudTextParams(-1.0, 0.015, 10.0, 255, 255, 255, 255, 1, 4.0, 0.1, 0.2);
		for(new Z = GetMaxClients() + 1; Z < max; Z++)
		{
			if(IsValidEntity(Z) && GetEntPropString(Z, Prop_Data, "m_ModelName", ModelName, 32))
			{ 
				
				if(rp_getDroppedMoneyValue(Z) > 0 && !rp_hud_get_metal_tracer(Client))
				{
					Found = true;
					GetEntPropVector(Z, Prop_Send, "m_vecOrigin", EntOrigin);   
					rp_setupbeamringpoint(EntOrigin, 10.0, 150.0, LaserCache, 0, 0, 15, 0.5, 5.0, 0.0, Alt3BeamColor, 10, 0);
					rp_sendtoclient(Client); 
				}
				if(StrContains(ModelName, "models/Items/BoxMRounds.mdl", false) != -1 && rp_hud_get_calibrate(Client)  && !rp_hud_get_metal_tracer(Client))
				{
					Found = true;
					GetEntPropVector(Z, Prop_Send, "m_vecOrigin", EntOrigin);   
					rp_setupbeamringpoint(EntOrigin, 10.0, 150.0, LaserCache, 0, 0, 15, 0.5, 5.0, 0.0, Alt4BeamColor, 10, 0);
					rp_sendtoclient(Client);
				}
				
				if(rp_hud_get_metal_tracer(Client))
				{
					if(rp_getDroppedMoneyValue(Z) > 0)
					{
						Found = true;
						GetEntPropVector(Z, Prop_Send, "m_vecOrigin", EntOrigin);      
						rp_setupbeampoint(ClientOrigin, EntOrigin, LaserCache, 0, 0, 66, 0.5, 3.0, 3.0, 0, 0.0, Alt3BeamColor, 0);
						rp_sendtoclient(Client);
					}
				}
				if(rp_hud_get_calibrate(Client) && rp_hud_get_metal_tracer(Client)){
					if(StrContains(ModelName, "models/Items/BoxMRounds.mdl", false) != -1)
					{
						Found = true;
						GetEntPropVector(Z, Prop_Send, "m_vecOrigin", EntOrigin);
						rp_setupbeampoint(ClientOrigin, EntOrigin, LaserCache, 0, 0, 66, 0.5, 3.0, 3.0, 0, 0.0, Alt4BeamColor, 0);
						rp_sendtoclient(Client);      
					}
				}
			}
		}
		
		if(Found) rp_emitsound(Client, "npc/turret_floor/ping.wav");
	}
	return true;
}