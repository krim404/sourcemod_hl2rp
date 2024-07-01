//Roleplay v3.0 LOGGER
//Programmed by Samantha
//Info http://www.hl2rp.de/forum/showthread.php?t=126
//Licence: GPLv2


#include <sourcemod>
#include "roleplay/rp_logger"
#include "roleplay/rp_items"

#define PLUGIN_VERSION "1.0"

new Handle:CV_ENLOG = INVALID_HANDLE;
new Handle:db = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Roleplay Logger",
	author = "Samantha",
	description = "Logs Roleplay info to a MySQL database",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	// Plugin version public Cvar
	CreateConVar("rp_logger", PLUGIN_VERSION, "Advanced Roleplay Logger Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	CV_ENLOG = CreateConVar("rp_enable_logging","0","Enables Logging for the RP Mod - by Samantha");
	
	
	new String:error[512];
	new Handle:kv = INVALID_HANDLE;
	
	kv = CreateKeyValues(""); 
	KvSetString(kv, "driver", "sqlite"); 
	KvSetString(kv, "database", "RoleplayDB");
	CloseHandle(kv);
	
	db = SQL_ConnectCustom(kv, error, sizeof(error), true);  

	if(db==INVALID_HANDLE)
	{
		LogError("FATAL: Could not connect.");
		SetFailState("Could not connect.");
	}
	
	
}

public OnMapStart()
{
	if(GetConVarInt(CV_ENLOG) == 1)
	{
		CreateTables();
	}
}

stock CreateTables()
{
	// Make the table
	decl String:Table[400];
	
	//Bank Logs
	Format(Table, sizeof(Table), "CREATE TABLE IF NOT EXISTS `rp_logs_bank` (`ID` int(11) NOT NULL auto_increment, `Time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP, `SteamId` varchar(255) NOT NULL,`Name` varchar(255) NOT NULL,`Type` varchar(15) NOT NULL, `Amount` int(10) NOT NULL, PRIMARY KEY  (`ID`));");
	
	if (!SQL_FastQuery(db, Table)) 
	{
		LogError("FATAL: Could not create table");
		SetFailState("Could not create table");
	}
	//Cuffs Table
	Format(Table, sizeof(Table), "CREATE TABLE IF NOT EXISTS `rp_logs_cuffs` (`ID` int(11) NOT NULL auto_increment, `Time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP, `SteamId` varchar(255) NOT NULL,`Name` varchar(255) NOT NULL, `Cuffer` varchar(255) NOT NULL, `Crime` int(10) NOT NULL, PRIMARY KEY (`ID`));");
	
	if (!SQL_FastQuery(db, Table)) 
	{
		LogError("FATAL: Could not create table");
		SetFailState("Could not create table");
	}
	
	//Purchase Menu
	Format(Table, sizeof(Table), "CREATE TABLE IF NOT EXISTS `rp_logs_purchases` (`ID` int(11) NOT NULL auto_increment, `Time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP, `SteamId` varchar(255) NOT NULL,`Name` varchar(255) NOT NULL, `ItemId` int(10) NOT NULL, `ItemName` varchar(255) NOT NULL, `Amount` int(10) NOT NULL, PRIMARY KEY (`ID`));");

	if (!SQL_FastQuery(db, Table)) 
	{
		LogError("FATAL: Could not create table");
		SetFailState("Could not create table");
	}	
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("rp_log_cuff", Log_Cuff);
	CreateNative("rp_log_deposit", Log_Deposit);
	CreateNative("rp_log_withdraw", Log_Withdraw);
	CreateNative("rp_log_purchase", Log_Purchase);
	
	return APLRes_Success;
}

stock GetName( Client, String:Name[64] )
{
	GetClientName(Client, Name, sizeof(Name));
		
	ReplaceString(Name, sizeof(Name), "'", "");
	ReplaceString(Name, sizeof(Name), ";", "");
	ReplaceString(Name, sizeof(Name), "*", "");
	ReplaceString(Name, sizeof(Name), "#", "");
	ReplaceString(Name, sizeof(Name), "<?", "");
	ReplaceString(Name, sizeof(Name), "?>", "");
}

/*
* rp_log_cuff( Client, attacker, Crime[Client] )
*/
public Log_Cuff(Handle:plugin, numParams)
{
	if(GetConVarInt(CV_ENLOG) == 1)
	{
		new Cuffed = GetNativeCell(1);
		new Attacker = GetNativeCell(2);
		new Crime = GetNativeCell(3);
		
		decl String:Query[128], String:SteamId[64], String:Name[64], String:CufferName[64];
		
		GetName( Cuffed, Name );
		GetName( Attacker, CufferName );
		GetClientAuthString( Cuffed, SteamId, sizeof(SteamId) );
		
		Format( Query, sizeof(Query), "INSERT INTO `rp_logs_cuffs` (`SteamId`, `Name`, `Cuffer`, `Crime`) VAULES ('%s', '%s', '%s', '%d');", SteamId, Name, CufferName, Crime );
		SQL_TQuery(db, SQL_ErrorCallback, Query);
	}
}

/*
* rp_log_deposit( Client, Amount );
*/
public Log_Deposit(Handle:plugin, numParams)
{
	if(GetConVarInt(CV_ENLOG) == 1)
	{
		new Client = GetNativeCell(1);
		new Amount = GetNativeCell(2);
		
		decl String:Query[128], String:SteamId[64], String:Name[64];
		
		GetName( Client, Name );
		GetClientAuthString( Client, SteamId, sizeof(SteamId) );
		
		Format( Query, sizeof(Query), "INSERT INTO `rp_logs_bank` (`SteamId`, `Name`, `Type`, `Amount`) VALUES ( '%s', '%s', 'Deposit', '%d' );", SteamId, Name, Amount );
		
		SQL_TQuery(db, SQL_ErrorCallback, Query);
	}
}

/*
* rp_log_withdraw( Client, Amount );
*/
public Log_Withdraw(Handle:plugin, numParams)
{
	if(GetConVarInt(CV_ENLOG) == 1)
	{
		new Client = GetNativeCell(1);
		new Amount = GetNativeCell(2);
		
		decl String:Query[128], String:SteamId[64], String:Name[64];
		
		GetName( Client, Name );
		GetClientAuthString( Client, SteamId, sizeof(SteamId) );
		
		Format( Query, sizeof(Query), "INSERT INTO `rp_logs_bank` (`SteamId`, `Name`, `Type`, `Amount`) VALUES ( '%s', '%s', 'Withdraw', '%d' );", SteamId, Name, Amount );
		
		SQL_TQuery(db, SQL_ErrorCallback, Query);
	}
}

/*
* rp_log_purchase( Client, SelectedItem[Client], Amount);
*/
public Log_Purchase(Handle:plugin, numParams)
{
	if(GetConVarInt(CV_ENLOG) == 1)
	{
		new Client = GetNativeCell(1);
		new ItemId = GetNativeCell(2);
		new Amount = GetNativeCell(3);
		
		decl String:Query[128], String:SteamId[64], String:Name[64], String:ItemName[64];
		
		GetName( Client, Name );
		GetClientAuthString( Client, SteamId, sizeof(SteamId) );
		rp_itemName( ItemId, ItemName );
		
		Format( Query, sizeof(Query), "INSERT INTO `rp_logs_purchases` (`SteamId`, `Name`, `ItemId`, `ItemName`, `Amount`) VALUES ('%s', '%s', '%d', '%s', '%s' );", SteamId, Name, ItemId, ItemName, Amount);
		
		SQL_TQuery(db, SQL_ErrorCallback, Query);
	}
}



public SQL_ErrorCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
	}
}

/*
	new Handle:QueryHandle = SQL_Query(db,"SELECT * FROM rp_skill_logs;");
	decl Id;
	
	if(QueryHandle != INVALID_HANDLE)
	{
		Id = SQL_GetRowCount(QueryHandle) + 1;
	}
	
*/
