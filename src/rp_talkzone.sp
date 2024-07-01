//Roleplay v3.0 Talkzone
//Idea and first implementations by Joe 'Pinkfairie' Maley
//Programmed by Christian 'Krim' Uhl 
//Licence: Creative Commons BY-NC-SA
//http://creativecommons.org/licenses/by-nc-sa/3.0/


//Includes:
#include roleplay/COLORS
#include roleplay/rp_wrapper

//Definitions:
#define SAYDIST 600
#define YELLDIST 1000
#define WHISPDIST 150
#define MAXPLAYER 	33

//Variables:
static bool:DisableOOC = false;

//Calling:
static Connected[MAXPLAYER];
static bool:Answered[MAXPLAYER] = false;
static bool:NextText[MAXPLAYER];
static bool:Active[MAXPLAYER];
static bool:CallEnable[MAXPLAYER];

//Timers:
static TimeOut[MAXPLAYER];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{	
	CreateNative("GetPhoneEnabledNative", __GetPhoneEnabledNative);
	CreateNative("SetPhoneEnabledNative", __SetPhoneEnabledNative);
	return APLRes_Success;
}

public __GetPhoneEnabledNative(Handle:plugin, numParams)
{
	
	new Client = GetNativeCell(1);
	return CallEnable[Client];
}

public __SetPhoneEnabledNative(Handle:plugin, numParams)
{
	
	new Client = GetNativeCell(1);
	new bool:Buffer = GetNativeCell(2);
	CallEnable[Client] = Buffer;
	return;
}


//Calling:
stock Call(Client, Player)
{

	
	//World:
	if(Client != 0 && Player != 0)
	{	
		//Declare:
		decl String:PlayerName[32];
		
		//Initialize:
		GetClientName(Player, PlayerName, sizeof(PlayerName));
		if(CallEnable[Player])
		{

			
			//Not Connected:
			if(Connected[Player] == 0)
			{
				
				//Initialize:
				Connected[Client] = Player;
				Connected[Player] = Client;
				
				//Print:
				CPrintToChat(Client, "{red}[RP]\x01 You call \x04%s\x01", PlayerName);
				
				//Send:
				RecieveCall(Player, Client);
				TimeOut[Client] = 40;
				CreateTimer(1.0, TimeOutCall, Client);
				
			}
			else
			{
				//Print:
				CPrintToChat(Client, "{red}[RP] \x04%s\x01 is already on the phone", PlayerName);
			}
		}
		else
		{
			CPrintToChat(Client, "{red}[RP] \x04%s\x01 has disabled the Phone", PlayerName);
		}
	}
}

//Recieve:
stock RecieveCall(Client, Player)
{
	
	new String:ClientName[32];
	GetClientName(Player, ClientName, sizeof(ClientName));
	
	//Sound:
	rp_emitsoundring(Client);
	
	//Print:
	CPrintToChat(Client, "{red}[RP] \x04%s\x01 is calling you, Type \x04/answer\x01 to recieve the call", ClientName);
	
	//Send:
	TimeOut[Client] = 40;
	CreateTimer(1.0, TimeOutRecieve, Client);
}

//Answer:
stock Answer(Client)
{
	
	//Connected:
	if(!Answered[Client] && Connected[Client] != 0)
	{
		
		//Declare:
		decl Player;
		decl String:ClientName[32];
		
		//Initialize:
		Player = Connected[Client];
		GetClientName(Client, ClientName, sizeof(ClientName));
		
		//Print:
		CPrintToChat(Client, "{red}[RP]\x01 You answer your phone");
		CPrintToChat(Player, "{red}[RP]\x04 %s\x01 answered their phone", ClientName);
		
		//Send:
		Answered[Client] = true;
		Answered[Player] = true;
		
		//Sound:
		rp_stopsoundring(Client);
	}
	else
	{
		
		//Print:
		CPrintToChat(Client, "{red}[RP]\x01 You already answered the phone");
	}
}

//Hang Up:
stock HangUp(Client)
{
	
	//Connected:
	if(Connected[Client] != 0)
	{
		
		//Declare:
		decl Player;
		decl String:ClientName[32], String:PlayerName[32];
		
		//Initialize:
		Player = Connected[Client];
		GetClientName(Client, ClientName, sizeof(ClientName));
		GetClientName(Player, PlayerName, sizeof(PlayerName));
		
		//Print:
		CPrintToChat(Client, "{red}[RP]\x01 You hang up on \x04%s\x01", PlayerName);
		CPrintToChat(Player, "{red}[RP]\x04 %s\x01 hung up on you", ClientName);
		
		//Send:
		Connected[Client] = 0;
		Answered[Client] = false;
		Connected[Player] = 0;
		Answered[Player] = false;
		
		//Sound:
		rp_stopsoundring(Client);
	}
	else
	{
		
		//Print:
		CPrintToChat(Client, "{red}[RP]\x01 You are not on the phone");
	}
}

//Silent:
stock PrintSilentChat(Client, String:ClientName[32], Player, String:Message[32], String:Arg[255])
{
	
	//Print:
	if(GetClientTeam(Client) == 3)CPrintToChat(Client, "(%s) {red}%s : \x01%s", Message, ClientName, Arg);
	if(GetClientTeam(Client) == 3)CPrintToChat(Player, "(%s) {red}%s : \x01%s", Message, ClientName, Arg);
	if(GetClientTeam(Client) == 2)CPrintToChat(Client, "(%s) {blue}%s : \x01%s", Message, ClientName, Arg);
	if(GetClientTeam(Client) == 2)CPrintToChat(Player, "(%s) {blue}%s : \x01%s", Message, ClientName, Arg);
}

//Chat:
stock PrintRPChat(Client, String:ClientName[32], String:Message[32], String:Arg[255], ArgNumber, ChatDist, bool:RegChat = false)
{
	
	//Declare:
	decl Float:ClientOrigin[3];
	
	//Initialize:
	GetClientAbsOrigin(Client, ClientOrigin);
	
	//Players:
	for(new X = 1; X < MaxClients; X++)
	{
		
		//Loop:
		if(X != Client && IsClientConnected(X) && IsClientInGame(X))
		{
			
			//Declare:
			decl Float:Distance, Float:PlayerOrigin[3];
			
			//Initialize:
			GetClientAbsOrigin(X, PlayerOrigin);
			Distance = GetVectorDistance(ClientOrigin, PlayerOrigin);
			
			//Print:
			if(RegChat) if(Distance <= ChatDist) CPrintToChat(X, "%s: %s", ClientName, Arg[ArgNumber]);
			else if(Distance <= ChatDist) CPrintToChat(X, "(%s) %s: %s", Message, ClientName, Arg[ArgNumber]);
		}
	}
	
	//Close:
	if(RegChat) CPrintToChat(Client, "%s: %s", ClientName, Arg[ArgNumber]);
	else CPrintToChat(Client, "(%s) %s: %s", Message, ClientName, Arg[ArgNumber]);
}

//In-Game:
public OnClientPutInServer(Client)
{
	
	//Default:
	Connected[Client] = 0;
	Answered[Client] = false;
	TimeOut[Client] = 0;
}

//Disconnect:
public OnClientDisconnect(Client)
{
	
	//Connected:
	if(Connected[Client] != 0)
	{
		
		//Declare:
		decl Player;
		
		//Initialize:
		Player = Connected[Client];
		
		//Print:
		CPrintToChat(Player, "{red}[RP]\x01 You have lost service, phone conversation aborted");
		
		//Send:
		Connected[Client] = 0;
		Answered[Client] = false;
		Connected[Player] = 0;
		Answered[Player] = false;
	}
}

//Time Out (Calling):
public Action:TimeOutCall(Handle:Timer, any:Client)
{
	
	//Push:
	if(TimeOut[Client] > 0) TimeOut[Client] -= 1;
	
	//Broken Connection:
	if(Connected[Client] == 0)
	{
		
		//End:
		TimeOut[Client] = 0;
	}
	
	//Not Answered:
	if(!Answered[Client] && TimeOut[Client] == 1)
	{
		
		//Declare:
		decl Player;
		decl String:PlayerName[32];
		
		//Initialize:
		Player = Connected[Client];
		GetClientName(Player, PlayerName, sizeof(PlayerName));
		
		//Print:
		CPrintToChat(Client, "{red}[RP]\x04 %s\x01 failed to answer their phone!", PlayerName);
		
		//End Connection:
		Answered[Client] = false;
		Connected[Client] = 0;	
	}
	
	//Loop:
	if(TimeOut[Client] > 0)
	{
		
		//Send:
		CreateTimer(1.0, TimeOutCall, Client);
	}
}

//Time Out (Recieve):
public Action:TimeOutRecieve(Handle:Timer, any:Client)
{
	
	//Push:
	if(TimeOut[Client] > 0) TimeOut[Client] -= 1;
	
	//Broken Connection:
	if(Connected[Client] == 0)
	{
		
		//End:
		TimeOut[Client] = 0;
	}
	
	//Not Answered:
	if(!Answered[Client] && TimeOut[Client] == 1)
	{
		
		//Print:
		CPrintToChat(Client, "{red}[RP]\x01 Your phone has stopped ringing");
		
		//End Connection:
		Answered[Client] = false;
		Connected[Client] = 0;
	}
	
	//Loop:
	if(TimeOut[Client] > 0)
	{
		
		//Send:
		CreateTimer(1.0, TimeOutRecieve, Client);
	}
}

public LogChat(Client, const String:Message[])
{
	//Name:
	new String:ClientName[32], String:SteamId[64], String:Date[512], String:LogDate[PLATFORM_MAX_PATH], String:PlayerLog[PLATFORM_MAX_PATH];
	GetClientName(Client, ClientName, 32);
	GetClientAuthString(Client, SteamId, 64);	
	FormatTime(Date, sizeof(Date), "%d %B %Y", GetTime());
	
	BuildPath(Path_SM, LogDate, sizeof(LogDate), "logs/chatlogs/%s.log", Date);

	LogToFileEx(LogDate, "%s <%s> says: %s", ClientName,SteamId, Message);
	ReplaceString(SteamId, 255, ":", "-");
	
	BuildPath(Path_SM, PlayerLog, sizeof(PlayerLog), "logs/chatlogs/player/%s.log", SteamId);
	LogToFileEx(PlayerLog, "%s <%s> says: %s", ClientName,SteamId, Message);	
	
}

//Handle Chat:
public Action:CommandSay(Client, Arguments)
{
	
	//Declare:
	decl String:Arg[255];
	
	//Initialize:
	GetCmdArgString(Arg, sizeof(Arg));
	
	//Clean:
	StripQuotes(Arg);
	TrimString(Arg);
	
	//Name:
	new String:ClientName[32];
	GetClientName(Client, ClientName, 32);
	
	
	LogChat(Client, Arg);
	new IsAdmin = GetUserFlagBits(Client);	
	if(IsAdmin > 2 && Active[Client]){			
		if(Arg[0] == '/') return Plugin_Handled;
		CPrintToChatAll("(%s)\x04 %s :\x01 %s", "OOC", ClientName, Arg);
		return Plugin_Handled;
	}
	
	
	if(DisableOOC == false)
	{
		if(NextText[Client] == false)
		{
			//Print:
			if(Arg[0] == '/') return Plugin_Handled;
			if(GetClientTeam(Client) == 3)CPrintToChatAll("(%s) {red}%s : \x01%s", "OOC", ClientName, Arg);
			if(GetClientTeam(Client) == 2)CPrintToChatAll("(%s) {blue}%s : \x01%s", "OOC", ClientName, Arg);
			if(GetClientTeam(Client) == 1)CPrintToChatAll("(%s) {teamcolor}%s : \x01%s", "OOC", ClientName, Arg);
			NextText[Client] = true;
			CreateTimer(1.0, AllowChat, Client);
			return Plugin_Handled;
		}
		else
		{
			CPrintToChat(Client, "{red}[RP]\x01 You are flooding the chat");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Handled;
}
public Action:AllowChat(Handle:Timer, any:Client)
{
	NextText[Client] = false;
	return Plugin_Handled;	
}

public Action:Command_togglechat(Client,Args)
{
	if(Active[Client] == false){
		PrintToChat(Client, "Activated the green chat");
		Active[Client] = true;
	}
	else
	{
		Active[Client] = false;
		PrintToChat(Client, "Deactivated the green chat");
	}
	return Plugin_Handled;
	
}
//Handle Chat:
public Action:CommandSayTeam(Client, Arguments)
{
	
	//Declare:
	decl String:Arg[255];
	
	//Initialize:
	GetCmdArgString(Arg, sizeof(Arg));
	
	//Clean:
	StripQuotes(Arg);
	TrimString(Arg);
	
	//Name:
	new String:ClientName[32];
	GetClientName(Client, ClientName, 32);
	
	
	//Phone:
	if(Connected[Client] != 0)
	{
		
		//On the Phone:
		if(Answered[Client])
		{
			
			//Print:
			PrintSilentChat(Client, ClientName, Connected[Client], "Phone", Arg);
			
			//Return:
			return Plugin_Handled;
		}
	}
	
	//Yell:
	if(StrContains(Arg, "yell ", false) == 0)
	{
		
		//Print:
		PrintRPChat(Client, ClientName, "Yell", Arg, 5, YELLDIST);
		
		//Close:
		return Plugin_Handled;
	}
	
	//Whisper:
	if(StrContains(Arg, "whisper ", false) == 0)
	{
		
		//Print:
		PrintRPChat(Client, ClientName, "Whisper", Arg, 8, WHISPDIST);
		
		//Close:
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Command_Answer(Client, args)
{
	//Answer:
	Answer(Client);
	return Plugin_Handled;
	
}

public Action:Command_Hangup(Client, args)
{
	//Call:
	HangUp(Client);
	return Plugin_Handled;
	
}

public Action:Command_Call(Client, args)
{
	
	
	//Name:
	new String:ClientName[32], String:PlayerName[32], String:arg1[64];
	GetClientName(Client, ClientName, 32);
	GetCmdArg(1, arg1, 64);
	
	//Already Connected:
	if(Connected[Client] != 0) return Plugin_Handled;
	
	//Dead:
	if(!IsPlayerAlive(Client)) return Plugin_Handled;
	
	new Player = FindTarget(Client, arg1, false, false);
	GetClientName(Player, PlayerName, 32);
	//Invalid Name:
	if(Player == -1)
	{
		
		//Print:
		PrintToChat(Client, "{red}[RP]\x01 Could not find client \x04%s\x01", PlayerName);
		
		//Return:
		return Plugin_Handled;
	}
	
	//Yourself:
	if(Player == Client)
	{
		
		//Print:
		CPrintToChat(Client, "{red}[RP]\x01 You cannot call yourself");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Dead:
	if(!IsPlayerAlive(Player))
	{
		
		//Print:
		CPrintToChat(Client, "{red}[RP]\x01 Cannot call a dead player");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Call:
	Call(Client, Player);
	
	//Return:
	return Plugin_Handled; 
}


//Death:
public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	
	//Declare:
	decl Client;
	
	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	//Hangup:
	if(Connected[Client] != 0) 
	{
		HangUp(Client);
		CPrintToChat(Client, "{red}[RP]\x01 Your phone has been hanged up.");
	}
}

//OOC:
public Action:CommandOOC(Client, Args)
{
	
	//Check:
	if(Args < 1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_ooc <0|1>");
		
		//Print:
		return Plugin_Handled;
	}
	
	//Declare:
	decl iFlag;
	decl String:Flag[32];
	
	//Initialize:
	GetCmdArg(1, Flag, sizeof(Flag));
	StringToIntEx(Flag, iFlag);
	
	//Invalid Id:
	if(iFlag != 0 && iFlag != 1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Flag must be above 0 or 1");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Disable:
	if(iFlag == 0)
	{
		
		//Turn Off:
		DisableOOC = true;
		
		//Print:
		CPrintToChatAll("[RP] OOC Disabled");
	}
	
	//Enable:
	if(iFlag == 1)
	{
		
		//Turn On:
		DisableOOC = false;
		
		//Print:
		CPrintToChatAll("[RP] OOC Enabled");
	}
	
	//Return:
	return Plugin_Handled;
}

//Map Start:
public OnMapStart()
{
	decl String:Path[64];
	BuildPath(Path_SM, Path, 64, "logs/chatlogs/");
	CreateDirectory(Path,511);
	
	BuildPath(Path_SM, Path, 64, "logs/chatlogs/player/");
	CreateDirectory(Path,511);
	
	//Precache:
	PrecacheSound("roleplay/ring.wav", true);
}

//Information:
public Plugin:myinfo =
{
	
	//Initation:
	name = "Talkzone",
	author = "Krim & Benni",
	description = "Talkzone for RP",
	version = "2.3",
	url = "http://www.wmchris.de"
}

//Initation:
public OnPluginStart()
{
	
	//Commands:
	RegConsoleCmd("say_team", CommandSayTeam);
	RegConsoleCmd("say", CommandSay);
	
	RegConsoleCmd("sm_call", Command_Call);
	RegConsoleCmd("sm_answer", Command_Answer);
	RegConsoleCmd("sm_hangup", Command_Hangup);
	
	
	//Disable:
	RegAdminCmd("rp_ooc", CommandOOC, ADMFLAG_CUSTOM3, "<0|1> - Disabled/Enables OOC.");
	RegAdminCmd("rp_togglechat", Command_togglechat, ADMFLAG_SLAY, "- Toggle!");

	
	//Server Variable:
	CreateConVar("talkzone_version", "2.3", "Talkzone Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}