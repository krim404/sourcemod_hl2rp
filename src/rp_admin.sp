//Roleplay v3.0 Admin
//Idea and first implementations by Joe 'Pinkfairie' Maley
//Programmed by Christian 'Krim' Uhl 
//CommandFix by Samantha
//Licence: Creative Commons BY-NC-SA
//http://creativecommons.org/licenses/by-nc-sa/3.0/

//Includes:
#include "roleplay/rp_wrapper"
#include "roleplay/rp_include"
#include "roleplay/rp_main"
#include "roleplay/rp_items"
#include "roleplay/rp_hud"

#define	MAXJOBS		1000 

public String:JobPath[128];
public String:NPCPath[128];

//Initation:
public OnPluginStart()
{
	RegAdminCmd("rp_name", CommandName, ADMFLAG_CUSTOM2, "<Name> <New Name> - Sets name of the user");
	RegAdminCmd("rp_setbank", Command_setMoneyBank, ADMFLAG_CUSTOM1, "- <Name> <Amount> - Sets the Bank of the Client");
	RegAdminCmd("rp_setmoney", Command_setMoney, ADMFLAG_CUSTOM1, "- <Name> <Amount> - Sets the money of the Client");
	RegAdminCmd("rp_setincome", Command_setIncome,ADMFLAG_CUSTOM1, "- <Name> <Amount> - Sets the income of the Client");
	RegAdminCmd("rp_crime", CommandCrime,ADMFLAG_CUSTOM1, "- <Name> <Amount> - Sets the crime of the Client");
	RegAdminCmd("rp_cuff", Command_cuff, ADMFLAG_CUSTOM1, "- <Name> Cuffs the Player");
	RegAdminCmd("rp_uncuff", Command_uncuff, ADMFLAG_CUSTOM1, "- <Name> Uncuffs the Player");
	RegAdminCmd("rp_status", CommandStatus, ADMFLAG_CUSTOM1, "- Lists status of all players");
	RegAdminCmd("rp_setcop", CommandSetcop, ADMFLAG_CUSTOM1, "- Sets the Coplevel of the player");
	
	RegAdminCmd("rp_setfeed", CommandSetFeed, ADMFLAG_CUSTOM1, "- Modifies the feeding of a player");
	RegAdminCmd("rp_setsta", CommandSetSta, ADMFLAG_CUSTOM1, "- Modifies the stamina of a player");
	RegAdminCmd("rp_setint", CommandSetInt, ADMFLAG_CUSTOM1, "- Modifies the intelligence of a player");
	RegAdminCmd("rp_setstr", CommandSetStr, ADMFLAG_CUSTOM1, "- Modifies the strenght of a player");
	RegAdminCmd("rp_setdex", CommandSetDex, ADMFLAG_CUSTOM1, "- Modifies the dex of a player");
	RegAdminCmd("rp_setspd", CommandSetSpd, ADMFLAG_CUSTOM1, "- Modifies the speed of a player");
	RegAdminCmd("rp_setwgt", CommandSetWgt, ADMFLAG_CUSTOM1, "- Modifies the weight of a player");
	RegAdminCmd("rp_sethate", CommandSetHate, ADMFLAG_CUSTOM1, "- Modifies the weight of a player");
	RegAdminCmd("rp_setTrainTimer", CommandSetTimer, ADMFLAG_CUSTOM1, "- Modifies the TrainTimer of a player");
	
	
	RegAdminCmd("rp_createjob", CommandCreateJob, ADMFLAG_ROOT, "<Id> <Job> <0|1> - Creates a job (public|admin)");
	RegAdminCmd("rp_removejob", CommandRemoveJob, ADMFLAG_ROOT, "<Id> <0|1> - Removes a job from the database (public|admin)");
	RegAdminCmd("rp_joblist", CommandListJobs, ADMFLAG_ROOT, "- Lists jobs from the database");
	RegAdminCmd("rp_addvendoritem", Command_AddVendorItem, ADMFLAG_ROOT, "<Vendor Id> <Item Id> - Add's Item to a vendor");
	RegAdminCmd("rp_removevendoritem", Command_RemoveVendorItem, ADMFLAG_ROOT, "<Vendor Id> <Item Id> - Remove's Item from a vendor");
	
	RegAdminCmd("rp_additem", Command_AddItem, ADMFLAG_ROOT, "- Add Item to a player");
	RegAdminCmd("rp_remitem", Command_RemoveItem, ADMFLAG_ROOT, "- Remove Item from a player");
	RegAdminCmd("rp_setitem", Command_SetItem, ADMFLAG_ROOT, "- Set Item amount from a player");

	
	//Notes
	RegAdminCmd("rp_note", CommandSetNotice, ADMFLAG_CUSTOM3, "<Ent> <1|0 Save> <String> <Substring> <Thirdstring>");
	RegAdminCmd("rp_rmnote", CommandRemNotice, ADMFLAG_CUSTOM3, "<Ent>");
	
	//JOB DB:
	BuildPath(Path_SM, JobPath, 64, "data/roleplay/jobs.txt");
	
	HookEvent("player_spawn", EventSpawn);
	CreateTimer(5.0, Ticker, 0);
}

public OnMapStart()
{		
	decl String:Map[128], String:Path[64];
	GetCurrentMap(Map, 128);

	BuildPath(Path_SM, Path, 64, "data/roleplay/%s/", Map);
	CreateDirectory(Path,511);
	
	//NPC DB:
	BuildPath(Path_SM, NPCPath, 64, "data/roleplay/%s/npcs.txt",Map);
}

public Action:Command_AddItem(Client, Args)
{
	if(Args == 3)
	{
		decl String:Target[32];
		decl String:Item[32];
		decl String:Amount[32];
		
		GetCmdArg(1, Target, 32);
		GetCmdArg(2, Item, 32);
		GetCmdArg(3, Amount, 32);
		
		new Player = FindTarget(Client, Target);
		
		rp_addItem(Player, StringToInt(Item), StringToInt(Amount));
		
		ReplyToCommand(Client, "[RP] You gave %N %s x %s.", Player, Amount, Item);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(Client, "[RP] Usage: rp_additem <Target> <Item> <Amount>.");
		return Plugin_Handled;
	}
}

public Action:Command_SetItem(Client, Args)
{
	if(Args == 3)
	{
		decl String:Target[32];
		decl String:Item[32];
		decl String:Amount[32];
		
		GetCmdArg(1, Target, 32);
		GetCmdArg(2, Item, 32);
		GetCmdArg(3, Amount, 32);
		
		new Player = FindTarget(Client, Target);
		
		rp_setItem(Player, StringToInt(Item), StringToInt(Amount));
		
		ReplyToCommand(Client, "[RP] Set %N %s to %s.", Player, Amount, Item);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(Client, "[RP] Usage: rp_setitem <Target> <Item> <Amount>.");
		return Plugin_Handled;
	}
}

public Action:Command_RemoveItem(Client, Args)
{
	if(Args == 3)
	{
		decl String:Target[32];
		decl String:Item[32];
		decl String:Amount[32];
		
		GetCmdArg(1, Target, 32);
		GetCmdArg(2, Item, 32);
		GetCmdArg(3, Amount, 32);
		
		new Player = FindTarget(Client, Target);
		
		rp_remItem(Player, StringToInt(Item), StringToInt(Amount));
		
		ReplyToCommand(Client, "[RP] Removed %s X %s from %N", Amount, Item, Player);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(Client, "[RP] Usage: rp_remitem <Target> <Item> <Amount>.");
		return Plugin_Handled;
	}
	
}

//Add Vendor Item:
public Action:Command_AddVendorItem(Client, Args)
{

	if(Args < 2)
	{
		ReplyToCommand(Client, "[RP] Usage: sm_addvendoritem <Vendor Id> <ItemId>.");
	
		return Plugin_Handled;
	}
	
	decl String:Buffer[255];
	decl String:VendorId[255], String:ItemId[255];
	
	GetCmdArg(1, VendorId, sizeof(VendorId));
	GetCmdArg(2, ItemId, sizeof(ItemId));
	
	new Handle:Vault = CreateKeyValues("Vault");
	
	FileToKeyValues(Vault, NPCPath);
	
	LoadString(Vault, "VItems", VendorId, "Null", Buffer);
	
	if(StrContains(Buffer, "Null", false) == -1)
	{
	
		decl String:AddString[2][255];
		decl String:OutputString[255];
		
		AddString[0] = Buffer;
		AddString[1] = ItemId;
		
		ImplodeStrings(AddString, 2, " ", OutputString, 255);
		
		SaveString(Vault, "VItems", VendorId, OutputString);
	}
	else
	{
		
		SaveString(Vault, "VItems", VendorId, ItemId);
	}
	
	KeyValuesToFile(Vault, NPCPath);
	

	ReplyToCommand(Client, "[RP] Added item %s to vendor #%s", ItemId, VendorId);
	
	CloseHandle(Vault);
	
	return Plugin_Handled;
}

//Remove Vendor Item:
public Action:Command_RemoveVendorItem(Client, Args)
{

	if(Args < 2)
	{
		ReplyToCommand(Client, "[RP]\x01 Usage: sm_removevendoritem <npc id> <item id>");
		
		return Plugin_Handled;
	}
	
	decl String:Formated[32];
	decl bool:Deleted;
	decl String:Buffer[255];
	decl String:VendorId[255], String:ItemId[255];
	
	
	GetCmdArg(1, VendorId, sizeof(VendorId));
	GetCmdArg(2, ItemId, sizeof(ItemId));
	
	new Handle:Vault = CreateKeyValues("Vault");
	
	FileToKeyValues(Vault, NPCPath);
	
	LoadString(Vault, "VItems", VendorId, "Null", Buffer);
	
	if(StrContains(Buffer, "Null", false) == -1)
	{
		
		if(StrContains(Buffer, " ", false) == -1)
		{
			
			KvJumpToKey(Vault, "VItems", false);
			KvDeleteKey(Vault, VendorId);
			KvRewind(Vault);
			
			Deleted = true;
		}
		
		Format(Formated, 32, "%s ", ItemId);
		if(StrContains(Buffer, Formated, false) == 0)
		{
			
			ReplaceString(Buffer, 255, Formated, " ");
			ReplaceString(Buffer, 255, "  ", " ");
			ReplaceString(Buffer, 255, "  ", " ");
			TrimString(Buffer);
			
			SaveString(Vault, "VItems", VendorId, Buffer);
			Deleted = true;
		}
		
		Format(Formated, 32, " %s", ItemId);
		if(StrContains(Buffer, Formated, false) != -1)
		{
			
			if(strlen(Buffer[StrContains(Buffer, Formated, false) + strlen(Formated)]) < 1)
			{
				
				ReplaceString(Buffer, 255, Formated, " ");
				ReplaceString(Buffer, 255, "  ", " ");
				ReplaceString(Buffer, 255, "  ", " ");
				TrimString(Buffer);
				
				SaveString(Vault, "VItems", VendorId, Buffer);
				Deleted = true;
			}
		}
		
		if(!Deleted)
		{
			
			Format(Formated, 32, " %s ", ItemId);
			

			ReplaceString(Buffer, 255, Formated, " ");
			ReplaceString(Buffer, 255, "  ", " ");
			ReplaceString(Buffer, 255, "  ", " ");
			TrimString(Buffer);
			
			SaveString(Vault, "VItems", VendorId, Buffer);
			Deleted = true;
		}
	}
	else
	{

		Deleted = false;
	}
	
	KeyValuesToFile(Vault, NPCPath);
	
	if(!Deleted) ReplyToCommand(Client, "[RP] Failed to remove item %s from vendor #%s.", ItemId, VendorId);
	else ReplyToCommand(Client, "[RP] Removed item %s from vendor #%s", ItemId, VendorId);
	
	CloseHandle(Vault);

	return Plugin_Handled;
}

/*
* Prints job info
* @param Client Player to print to
* @param Vault Keyvalue handle to use
* @param Header Header to use
* @param Key Subkey to find inside the vault
* @param MaxNPCs Maximum number of Jobs
*/
stock PrintJob(Client, Handle:Vault, const String:Header[255], const String:Key[32], MaxJobs)
{
	
	//Declare:
	decl String:JobId[255], String:JobTitle[255];
	
	//Print:
	PrintToConsole(Client, Header);
	for(new X = 0; X < MaxJobs; X++)
	{
		
		//Convert:
		IntToString(X, JobId, 255);
		
		//Load:
		LoadString(Vault, Key, JobId, "Null", JobTitle);
		
		//Found in DB:
		if(StrContains(JobTitle, "Null", false) == -1) PrintToConsole(Client, "--%s: %s", JobId, JobTitle);	
	}
}

//List Jobs:
public Action:CommandListJobs(Client, Args)
{
	
	new Handle:Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, JobPath);
	
	//Header:
	PrintToConsole(Client, "Jobs:");
	
	//Public:
	PrintJob(Client, Vault, "-0: (Public)", "0", MAXJOBS);
	
	//Private:
	PrintJob(Client, Vault, "-1: (Admin)", "1", MAXJOBS);
	
	//Store:
	KeyValuesToFile(Vault, JobPath);
	
	//Close:
	CloseHandle(Vault);
	
	//Return:
	return Plugin_Handled;
}

//Create Job:
public Action:CommandCreateJob(Client, Args)
{
	
	if(Args < 3)
	{
		
		ReplyToCommand(Client, "[RP] Usage: sm_createjob <Id> <Job> <0|1>");
		
		return Plugin_Handled;
	}
	
	decl Flag, iJobId;
	decl String:JobId[255], String:JobName[255], String:sFlag[32];
	
	GetCmdArg(1, JobId, sizeof(JobId));
	GetCmdArg(2, JobName, sizeof(JobName));
	GetCmdArg(3, sFlag, sizeof(sFlag));
	StringToIntEx(sFlag, Flag);
	StringToIntEx(JobId, iJobId);
	
	if(iJobId < 1)
	{
		ReplyToCommand(Client, "{[RP][RP] Id must be above 0.");
		return Plugin_Handled;
	}
	
	if(Flag != 1 && Flag != 0)
	{
		ReplyToCommand(Client, "{[RP] Flag must be 0 or 1.");
		return Plugin_Handled;
	}
	
	//Vault:
	new Handle:Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, JobPath);
	
	//Save:
	SaveString(Vault, sFlag, JobId, JobName);
	
	//Store:
	KeyValuesToFile(Vault, JobPath);
	
	//Print:
	ReplyToCommand(Client, "[RP] Added job %s - %s (%s) into the database.", JobId, JobName, sFlag);
	
	//Close:
	CloseHandle(Vault);
	
	//Return:
	return Plugin_Handled;
}

//Remove Job:
public Action:CommandRemoveJob(Client, Args)
{
	
	if(Args < 2)
	{
		ReplyToCommand(Client, "[RP] Usage: sm_removejob <Id> <0|1>.");
		return Plugin_Handled;
	}
	
	decl Flag;
	decl bool:Deleted;
	decl String:JobId[255], String:sFlag[32];
	
	GetCmdArg(1, JobId, sizeof(JobId));
	GetCmdArg(2, sFlag, sizeof(sFlag));
	StringToIntEx(sFlag, Flag);
	
	if(Flag != 1 && Flag != 0)
	{
		ReplyToCommand(Client, "[RP] Flag must be 0 or 1.");
		return Plugin_Handled;
	}
	
	//Vault:
	new Handle:Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, JobPath);
	
	//Delete:
	KvJumpToKey(Vault, sFlag, false);
	Deleted = KvDeleteKey(Vault, JobId); 
	KvRewind(Vault);
	
	//Store:
	KeyValuesToFile(Vault, JobPath);

	if(!Deleted) ReplyToCommand(Client, "[RP] Failed to remove job %s (%s) from the database.", JobId, sFlag);
	else ReplyToCommand(Client, "[RP] Removed job %s (%s) from the database.", JobId, sFlag);

	CloseHandle(Vault);

	return Plugin_Handled;
}

public Action:Ticker(Handle:Timer, any:Client)
{	
	for(new X = 1; X <= MaxClients; X ++)
	{
		if(IsClientInGame(X) && IsPlayerAlive(X))
		{
			ModelCheck(X);
		}
	}
	
	CreateTimer(2.0, Ticker, 0);
}

stock ModelCheck(Client)
{
	decl String:Buffer[64];
	GetClientModel(Client, Buffer, 64);
	
	//Kein Cop aber Combine / Police Skin
	if((StrContains(Buffer, "combine", false) != -1 || StrContains(Buffer, "police", false) != -1) && rp_iscop(Client) == 0)
	{	
		if(!StrEqual(Buffer, "models/humans/group03/male_06.mdl", false)) 
			rp_entmodel(Client, "models/humans/group03/male_06.mdl");
	} else if(rp_iscop(Client)) 
	{
		if(rp_iscop(Client) < 2)
		{
			if(!StrEqual(Buffer, "models/police.mdl", false)) 
				rp_entmodel(Client, "models/police.mdl");
		}
		else if(rp_iscop(Client) < 5)
		{
			if(!StrEqual(Buffer, "models/combine_soldier_prisonguard.mdl", false)) 
				rp_entmodel(Client, "models/combine_soldier_prisonguard.mdl");
		}
		else if(rp_iscop(Client) < 8)
		{
			if(!StrEqual(Buffer, "models/combine_super_soldier.mdl", false)) 
				rp_entmodel(Client, "models/combine_super_soldier.mdl");
		}
		else if(rp_iscop(Client) > 8)
		{
			if(!StrEqual(Buffer, "models/combine_super_soldier.mdl", false)) 
				rp_entmodel(Client, "models/combine_super_soldier.mdl");
		}
	}
	
}

public EventSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
	//Initialize:
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	CreateTimer(1.0, CopWeapons, Client);
	ModelCheck(Client);
}

stock giveWeapon(Client,String:Name[])
{
	new Ent = rp_createent(Name); 
	rp_dispatchspawn(Ent);
	rp_equipplayerweapon(Client, Ent);
}

public Action:CopWeapons(Handle:Timer, any:Client)
{	
	if(rp_iscop(Client) > 0)
	{
		rp_setDefault(Client);
		giveWeapon(Client,"weapon_stunstick");
	}
	
	if(rp_iscop(Client) > 1)
	{
		giveWeapon(Client,"weapon_pistol");
		rp_giveplayeritem(Client, "item_ammo_pistol_large");
	}
	
	if(rp_iscop(Client) > 2)
	{
		giveWeapon(Client, "weapon_shotgun");
		rp_giveplayeritem(Client, "item_box_buckshot");
		if(rp_getTmpStr(Client) < 12)
			rp_setTmpStr(Client,12);
	}
	
	if(rp_iscop(Client) > 3)
	{
		giveWeapon(Client, "weapon_slam");
		giveWeapon(Client, "weapon_crowbar"); //Admin Utils
		
		if(rp_getTmpSpd(Client) < 12)
			rp_setTmpSpd(Client,12);
	}
	
	if(rp_iscop(Client) > 4)
	{
		giveWeapon(Client, "weapon_crossbow");
	}
	
	if(rp_iscop(Client) > 5)
	{
		giveWeapon(Client, "weapon_smg1");
		rp_giveplayeritem(Client, "item_ammo_crossbow");
		if(rp_getTmpStr(Client) < 15)
			rp_setTmpStr(Client,15);
	}
	
	if(rp_iscop(Client) > 6)
	{	
		rp_giveplayeritem(Client, "item_ammo_smg1_large");
	}
	
	if(rp_iscop(Client) > 7)
	{
		giveWeapon(Client, "weapon_ar2");
		rp_giveplayeritem(Client, "item_ammo_ar2_large");
		if(rp_getTmpSpd(Client) < 15)
			rp_setTmpSpd(Client,15);
	}
	
	if(rp_iscop(Client) > 8)
	{
		if(rp_getTmpStr(Client) < 20)
			rp_setTmpStr(Client,20);
		
		giveWeapon(Client, "weapon_rpg");
		rp_giveplayeritem(Client, "item_ammo_smg1_grenade");
		rp_giveplayeritem(Client, "item_ammo_smg1_grenade");
		rp_giveplayeritem(Client, "item_ammo_smg1_grenade");
				
	}
	
	if(rp_iscop(Client) > 9)
	{
		rp_giveplayeritem(Client, "item_ammo_ar2_altfire");
		rp_giveplayeritem(Client, "item_ammo_ar2_altfire");
		rp_giveplayeritem(Client, "item_ammo_ar2_altfire");
		if(rp_getTmpSpd(Client) < 20)
			rp_setTmpSpd(Client,20);
	}
}

public Action:CommandName(Client, Args)
{
	//Error:
	if(Args < 2)
	{
		ReplyToCommand(Client, "[RP] Usage: rp_name <Name> <New Name>");
		return Plugin_Handled;
	}

	//Declare:
	decl Player;
	decl String:PlayerName[32];
	decl String:TargetName[32];

	//Initialize:
	Player = -1;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));
	GetCmdArg(2, TargetName, sizeof(TargetName));
	
	//Find:
	Player = FindPlayer(Client,PlayerName);
	
	if(Player == 0)
	{
		ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
		return Plugin_Handled;
	}

	ClientCommand(Player, "name \"%s\"", TargetName);

	ReplyToCommand(Client, "[RP] Set %N's name to %s.", Player, TargetName);
	PrintToChat(Player, "[RP] %N set your name to %s.", Client, TargetName);

	return Plugin_Handled;
}

public Action:CommandCrime(Client, Args)
{
	//Error:
	if(Args < 2)
	{
		ReplyToCommand(Client, "[RP] Usage: rp_crime <Name> <Crime #>");
		return Plugin_Handled;
	}

	//Declare:
	decl Player;
	decl String:PlayerName[32];
	decl String:Amount[32];
	decl iAmount;

	//Initialize:
	GetCmdArg(1, PlayerName, sizeof(PlayerName));
	GetCmdArg(2, Amount, sizeof(Amount));
	iAmount = StringToInt(Amount);
	
	Player = FindPlayer(Client,PlayerName);
	
	//Invalid Name:
	if(Player == 0)
	{
		ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
		return Plugin_Handled;
	}

	decl Crime;
	Crime = rp_getCrime(Player);
	rp_uncrime(Player,Crime);
	
	rp_crime(Player,iAmount);

	ReplyToCommand(Client, "[RP] Set %N's crime to %s.", Player, Amount);
	PrintToChat(Player, "[RP] %N set your crime to %s.", Client, Amount);

	return Plugin_Handled;
}

public Action:Command_setIncome(Client,Args)
{
    decl Player; 
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Wrong Parameter. Usage: rp_setincome <USER> <MONEY>");
        return Plugin_Handled;      
    }
    
    if(Args == 2)
    {
        decl String:PlayerName[32];
        decl String:Name[32];
        new Munny = 0; 
        decl String:Muny[32];
        
        GetCmdArg(1, PlayerName, sizeof(PlayerName));
        GetCmdArg(2, Muny, sizeof(Muny));
        Munny = StringToInt(Muny);  
       	Player = FindPlayer(Client,PlayerName);   
		
        //Invalid Name:
        if(Player == 0)
        {
            PrintToConsole(Client, "[RP] Could not find client %s.", PlayerName);
            return Plugin_Handled;
        }
        
        GetClientName(Client, Name, sizeof(Name));
        GetClientName(Player, PlayerName, sizeof(PlayerName));
        
        rp_setWage(Player,Munny); 
		
        ReplyToCommand(Client, "[RP] Set the wage for %s to $%d.", PlayerName,Munny);
        PrintToChat(Player, "[RP] Your wage has been set to $%d by %s.",Munny,Name); 
    }
    return Plugin_Handled; 
}

public Action:Command_setMoneyBank(Client,Args)
{
    decl Player; 
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Wrong Parameter. Usage: rp_setbank <USER> <MONEY>");
        return Plugin_Handled;      
    }
    
    if(Args == 2)
    {
        decl String:PlayerName[32];
        decl String:Name[32];
        new Munny = 0; 
        decl String:Muny[32];
        
        GetCmdArg(1, PlayerName, sizeof(PlayerName));
        GetCmdArg(2, Muny, sizeof(Muny));
        Munny = StringToInt(Muny);  
       	Player = FindPlayer(Client,PlayerName);       
        //Invalid Name:
        if(Player == 0)
        {
            ReplyToCommand(Client, "[RP] Could not find client %s.", PlayerName);
            return Plugin_Handled;
        }
        
        GetClientName(Client, Name, sizeof(Name));
        GetClientName(Player, PlayerName, sizeof(PlayerName));
        
        rp_setBank(Player,Munny); 
		
        ReplyToCommand(Client, "[RP] Set the bank for %s to $%d", PlayerName,Munny);
        PrintToChat(Player, "[RP] Your bank has been set to $%d by %s",Munny,Name); 
    }
    return Plugin_Handled; 
}

public Action:Command_setMoney(Client,Args)
{
    decl Player; 
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Wrong Parameter. Usage: rp_setmoney <USER> <MONEY>");
        return Plugin_Handled;      
    }
    
    if(Args == 2)
    {
        decl String:PlayerName[32];
        decl String:Name[32];
        new Munny = 0; 
        decl String:Muny[32];
        
        GetCmdArg(1, PlayerName, sizeof(PlayerName));
        GetCmdArg(2, Muny, sizeof(Muny));
        Munny = StringToInt(Muny);  
       	Player = FindPlayer(Client,PlayerName);       
        //Invalid Name:
        if(Player == 0)
        {
            ReplyToCommand(Client, "[RP] Could not find client %s.", PlayerName);
            return Plugin_Handled;
        }
        
        GetClientName(Client, Name, sizeof(Name));
        GetClientName(Player, PlayerName, sizeof(PlayerName));
        
        rp_setMoney(Player,Munny); 
		
        ReplyToCommand(Client, "[RP] Set the money for %s to $%d.", PlayerName,Munny);
        PrintToChat(Player, "[RP] Your money has been set to $%d by %s.",Munny,Name); 
    }
    return Plugin_Handled; 
}

public Action:Command_uncuff(Client, Args)
{
	
        
    //Error:
    if(Args < 1)
    {
        PrintToConsole(Client, "[RP] Usage: rp_uncuff <name>");
        return Plugin_Handled;
    }

    //Declare:
    decl Player;
    decl String:PlayerName[32], String:ClientName[32];

    //Initialize:
    Player = 0;
    GetCmdArg(1, PlayerName, sizeof(PlayerName));
    Player = FindPlayer(Client,PlayerName); 
    
    //Invalid Name:
    if(Player == 0)
    {
        PrintToConsole(Client, "[RP] Could not find client %s", PlayerName);
        return Plugin_Handled;
    }
    
    rp_uncuff(Player);
  
    GetClientName(Client, ClientName, sizeof(ClientName));
    GetClientName(Player, PlayerName, sizeof(PlayerName));
    
    //Print:
    ReplyToCommand(Client, "[RP] You uncuff %s.",PlayerName);
    PrintToChat(Player, "[RP] You are uncuffed by %s.",ClientName);
    return Plugin_Handled; 
}

public Action:CommandSetcop(Client, Args)
{
    //Error:
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Usage: rp_setcop <name> <level>");
        return Plugin_Handled;
    }

    //Declare:
    decl Player;
    decl String:PlayerName[32], String:ClientName[32],String:Level[10];

    //Initialize:
    Player = 0;
    GetCmdArg(1, PlayerName, sizeof(PlayerName));
    GetCmdArg(2, Level, sizeof(Level));
    Player = FindPlayer(Client,PlayerName); 
    
    //Invalid Name:
    if(Player == 0)
    {
        ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
        return Plugin_Handled;
    }
    
    rp_setCrime(Player, 0);
    rp_setCop(Player,StringToInt(Level));
    rp_save(Player);
    
    GetClientName(Client, ClientName, sizeof(ClientName));
    GetClientName(Player, PlayerName, sizeof(PlayerName));
    
    //Print:
    if(StringToInt(Level) > 0)
    {
	    ReplyToCommand(Client, "[RP] You promoted %s to cop Level %s",PlayerName,Level);
	    PrintToChat(Player, "[RP] You are promoted to a cop by %s Level %s",ClientName,Level);
    }
	else
    {
    	ReplyToCommand(Client, "[RP] You revoked %s's coprights",PlayerName);
    	PrintToChat(Player, "[RP] %s took your cop status",ClientName);
    }
	
    rp_forcesuicide(Player);
    return Plugin_Handled; 
}

public Action:CommandSetFeed(Client, Args)
{
    //Error:
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Usage: rp_setfeed <name> <level>");
        return Plugin_Handled;
    }

    //Declare:
    decl Player;
    decl String:PlayerName[32], String:ClientName[32],String:Level[10];

    //Initialize:
    Player = 0;
    GetCmdArg(1, PlayerName, sizeof(PlayerName));
    GetCmdArg(2, Level, sizeof(Level));
    Player = FindPlayer(Client,PlayerName); 
    
    //Invalid Name:
    if(Player == 0)
    {
        ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
        return Plugin_Handled;
    }
    
    rp_setFeed(Player,StringToInt(Level));
    
    GetClientName(Client, ClientName, sizeof(ClientName));
    GetClientName(Player, PlayerName, sizeof(PlayerName));
    
    //Print:
    ReplyToCommand(Client, "[RP] You fed %s to %s",PlayerName,Level);
    PrintToChat(Player, "[RP] You are fed by %s to %s",ClientName,Level);
	
    rp_save(Player);
    return Plugin_Handled; 
}

public Action:CommandSetSta(Client, Args)
{
    //Error:
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Usage: rp_setsta <name> <level>");
        return Plugin_Handled;
    }

    //Declare:
    decl Player;
    decl String:PlayerName[32], String:ClientName[32],String:Level[10];

    //Initialize:
    Player = 0;
    GetCmdArg(1, PlayerName, sizeof(PlayerName));
    GetCmdArg(2, Level, sizeof(Level));
    Player = FindPlayer(Client,PlayerName); 
    
    //Invalid Name:
    if(Player == 0)
    {
        ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
        return Plugin_Handled;
    }
    
    rp_setSta(Player,StringToInt(Level));
    
    GetClientName(Client, ClientName, sizeof(ClientName));
    GetClientName(Player, PlayerName, sizeof(PlayerName));
    
    //Print:
    ReplyToCommand(Client, "[RP] The stamina has been set for %s to %s",PlayerName,Level);
    PrintToChat(Player, "[RP] Your stamina has been set by %s to %s",ClientName,Level);
    rp_save(Player);
    return Plugin_Handled; 
}

public Action:CommandSetStr(Client, Args)
{
    //Error:
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Usage: rp_setstr <name> <level>");
        return Plugin_Handled;
    }

    //Declare:
    decl Player;
    decl String:PlayerName[32], String:ClientName[32],String:Level[10];

    //Initialize:
    Player = 0;
    GetCmdArg(1, PlayerName, sizeof(PlayerName));
    GetCmdArg(2, Level, sizeof(Level));
    Player = FindPlayer(Client,PlayerName); 
    
    //Invalid Name:
    if(Player == 0)
    {
        ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
        return Plugin_Handled;
    }
    
    rp_setStr(Player,StringToInt(Level));
    
    GetClientName(Client, ClientName, sizeof(ClientName));
    GetClientName(Player, PlayerName, sizeof(PlayerName));
    
    //Print:
    ReplyToCommand(Client, "[RP] The strenght has been set for %s to %s",PlayerName,Level);
    PrintToChat(Player, "[RP] Your strenght has been set by %s to %s",ClientName,Level);
    rp_save(Player);
    return Plugin_Handled; 
}

public Action:CommandSetDex(Client, Args)
{
    //Error:
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Usage: rp_setdex <name> <level>");
        return Plugin_Handled;
    }

    //Declare:
    decl Player;
    decl String:PlayerName[32], String:ClientName[32],String:Level[10];

    //Initialize:
    Player = 0;
    GetCmdArg(1, PlayerName, sizeof(PlayerName));
    GetCmdArg(2, Level, sizeof(Level));
    Player = FindPlayer(Client,PlayerName); 
    
    //Invalid Name:
    if(Player == 0)
    {
        ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
        return Plugin_Handled;
    }
    
    rp_setDex(Player,StringToInt(Level));
    
    GetClientName(Client, ClientName, sizeof(ClientName));
    GetClientName(Player, PlayerName, sizeof(PlayerName));
    
    //Print:
    ReplyToCommand(Client, "[RP] The dex has been set for %s to %s",PlayerName,Level);
    PrintToChat(Player, "[RP] Your dex has been set by %s to %s",ClientName,Level);
	
    rp_save(Player);
    return Plugin_Handled; 
}

public Action:CommandSetInt(Client, Args)
{
    //Error:
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Usage: rp_setint <name> <level>");
        return Plugin_Handled;
    }

    //Declare:
    decl Player;
    decl String:PlayerName[32], String:ClientName[32],String:Level[10];

    //Initialize:
    Player = 0;
    GetCmdArg(1, PlayerName, sizeof(PlayerName));
    GetCmdArg(2, Level, sizeof(Level));
    Player = FindPlayer(Client,PlayerName); 
    
    //Invalid Name:
    if(Player == 0)
    {
        ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
        return Plugin_Handled;
    }
    
    rp_setInt(Player,StringToInt(Level));
    
    GetClientName(Client, ClientName, sizeof(ClientName));
    GetClientName(Player, PlayerName, sizeof(PlayerName));
    
    //Print:
    ReplyToCommand(Client, "[RP] The Int has been set for %s to %s",PlayerName,Level);
    PrintToChat(Player, "[RP] Your intelligence has been set by %s to %s",ClientName,Level);
    rp_save(Player);
    return Plugin_Handled; 
}

public Action:CommandSetSpd(Client, Args)
{
    //Error:
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Usage: rp_setspd <name> <level>");
        return Plugin_Handled;
    }

    //Declare:
    decl Player;
    decl String:PlayerName[32], String:ClientName[32],String:Level[10];

    //Initialize:
    Player = 0;
    GetCmdArg(1, PlayerName, sizeof(PlayerName));
    GetCmdArg(2, Level, sizeof(Level));
    Player = FindPlayer(Client,PlayerName); 
    
    //Invalid Name:
    if(Player == 0)
    {
        ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
        return Plugin_Handled;
    }
    
    rp_setSpd(Player,StringToInt(Level));
    
    GetClientName(Client, ClientName, sizeof(ClientName));
    GetClientName(Player, PlayerName, sizeof(PlayerName));
    
    //Print:
    ReplyToCommand(Client, "[RP] The speed has been set for %s to %s",PlayerName,Level);
    PrintToChat(Player, "[RP] Your speed has been set by %s to %s",ClientName,Level);	
	
    rp_save(Player);
    return Plugin_Handled; 
}

public Action:CommandSetHate(Client, Args)
{
    //Error:
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Usage: rp_sethate <name> <level>");
        return Plugin_Handled;
    }

    //Declare:
    decl Player;
    decl String:PlayerName[32], String:ClientName[32],String:Level[10];

    //Initialize:
    Player = 0;
    GetCmdArg(1, PlayerName, sizeof(PlayerName));
    GetCmdArg(2, Level, sizeof(Level));
    Player = FindPlayer(Client,PlayerName); 
    
    //Invalid Name:
    if(Player == 0)
    {
        ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
        return Plugin_Handled;
    }
    
    rp_setHate(Player,StringToInt(Level));
    
    GetClientName(Client, ClientName, sizeof(ClientName));
    GetClientName(Player, PlayerName, sizeof(PlayerName));
    
    //Print:
    ReplyToCommand(Client, "[RP] The hate has been set for %s to %s",PlayerName,Level);
    PrintToChat(Player, "[RP] Your hatelevel has been set by %s to %s",ClientName,Level);
    rp_save(Player);
    return Plugin_Handled; 
}

public Action:CommandSetWgt(Client, Args)
{
    //Error:
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Usage: rp_setwgt <name> <level>");
        return Plugin_Handled;
    }

    //Declare:
    decl Player;
    decl String:PlayerName[32], String:ClientName[32],String:Level[10];

    //Initialize:
    Player = 0;
    GetCmdArg(1, PlayerName, sizeof(PlayerName));
    GetCmdArg(2, Level, sizeof(Level));
    Player = FindPlayer(Client,PlayerName); 
    
    //Invalid Name:
    if(Player == 0)
    {
        ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
        return Plugin_Handled;
    }
    
    rp_setWgt(Player,StringToInt(Level));
    
    GetClientName(Client, ClientName, sizeof(ClientName));
    GetClientName(Player, PlayerName, sizeof(PlayerName));
    
    //Print:
    ReplyToCommand(Client, "[RP] The weight has been set for %s to %s",PlayerName,Level);
    PrintToChat(Player, "[RP] Your weight has been set by %s to %s",ClientName,Level);
    rp_save(Player);
    return Plugin_Handled; 
}

public Action:CommandSetTimer(Client, Args)
{
    //Error:
    if(Args < 2)
    {
        ReplyToCommand(Client, "[RP] Usage: rp_settimer <name> <time>");
        return Plugin_Handled;
    }

    //Declare:
    decl Player;
    decl String:PlayerName[32], String:ClientName[32],String:Level[10];

    //Initialize:
    Player = 0;
    GetCmdArg(1, PlayerName, sizeof(PlayerName));
    GetCmdArg(2, Level, sizeof(Level));
    Player = FindPlayer(Client,PlayerName); 
    
    //Invalid Name:
    if(Player == 0)
    {
        ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
        return Plugin_Handled;
    }
    
    rp_setTrainTime(Player,StringToFloat(Level));
    
    GetClientName(Client, ClientName, sizeof(ClientName));
    GetClientName(Player, PlayerName, sizeof(PlayerName));
    
    //Print:
    ReplyToCommand(Client, "[RP] The traintimer has been set for %s to %s",PlayerName,Level);
    PrintToChat(Player, "[RP] Your traintimer has been set by %s to %s",ClientName,Level);
	
    rp_save(Player);
    return Plugin_Handled; 
}


public Action:Command_cuff(Client, Args)
{
    //Error:
    if(Args < 1)
    {
        ReplyToCommand(Client, "[RP] Usage: rp_cuff <name>");
        return Plugin_Handled;
    }

    //Declare:
    decl Player;
    decl String:PlayerName[32], String:ClientName[32];

    //Initialize:
    Player = 0;
    GetCmdArg(1, PlayerName, sizeof(PlayerName));
    
    //Find:
    Player = FindPlayer(Client,PlayerName);
    
    //Invalid Name:
    if(Player == 0)
    {
        ReplyToCommand(Client, "[RP] Could not find client %s", PlayerName);
        return Plugin_Handled;
    }
    
    rp_cuff(Player);

    GetClientName(Client, ClientName, sizeof(ClientName));
    GetClientName(Player, PlayerName, sizeof(PlayerName));
    //Print:
    ReplyToCommand(Client, "[RP] Got him by cheating you pathetic admin.. %s is now cuffed",PlayerName);
    PrintToChat(Player, "[RP] You are cuffed by %s",ClientName);
    
    return Plugin_Handled; 
}

public Action:CommandStatus(Client, Args)
{
	//Declare:
	decl String:Job[50];

	//Print:
	PrintToConsole(Client, "Status:");

	//Loop:
	for(new X = 1; X <= MaxClients; X++)
	{
		//In-Game:
		if(IsClientInGame(X))
		{
			rp_getJob(X,Job);
			
			//Print:
			ReplyToCommand(Client, "%N: Money: $%d. Bank: $%d. Job: %s. Wages: %d.", X, rp_getMoney(X), rp_getBank(X), Job, rp_getWage(X));
		}
	}
	//Return:
	return Plugin_Handled;
}

public Action:CommandRemNotice(Client, Arguments)
{
    decl Ent;
    //Arguments:
    if(Arguments < 1)
    {
		//Print:
		ReplyToCommand(Client, "[RP] Usage: rp_rmnote <Ent>");

		//Return:
		return Plugin_Handled;
    }
    
    decl String:EntName[32];
    GetCmdArg(1, EntName, sizeof(EntName));
    Ent = StringToInt(EntName);
    rp_remNotice(Client,Ent);
	
    ReplyToCommand( Client, "[RP] Notice is removed." );
    return Plugin_Handled;
}

//setOwner:
public Action:CommandSetNotice(Client, Arguments)
{
    decl Ent;
    //Arguments:
    if(Arguments < 2)
    {

		//Print:
		ReplyToCommand(Client, "[RP] Usage: rp_note <Ent> <1|0 Save> <String> <Substring> <Thirdstring>");

		//Return:
		return Plugin_Handled;
    }

    //Declare:
    decl String:Text[255],String:Text2[255],String:Text3[255],String:EntName[32],String:Saven[2],SavenBuffer;

    //Initialize:
    GetCmdArg(1, EntName, sizeof(EntName));
    GetCmdArg(2, Saven, sizeof(Saven));     
    GetCmdArg(3, Text, sizeof(Text));
    GetCmdArg(4, Text2, sizeof(Text2));
    GetCmdArg(5, Text3, sizeof(Text3));
    SavenBuffer = StringToInt(Saven);
    Ent = StringToInt(EntName);
    
    
    rp_setNotice(Ent,Text,Text2,Text3);
    
    if(SavenBuffer == 1)
    	rp_saveNotice(Client,Ent);
		
    ReplyToCommand( Client, "[RP] Set notes on entity" );
    		
    return Plugin_Handled;
}
