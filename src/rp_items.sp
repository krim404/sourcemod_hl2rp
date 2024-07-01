//Roleplay v3.0 HUD
//Idea and first implementations by Joe 'Pinkfairie' Maley
//Programmed by Christian 'Krim' Uhl 
//Licence: Creative Commons BY-NC-SA
//http://creativecommons.org/licenses/by-nc-sa/3.0/

//Includes:
#include "roleplay/rp_wrapper"
#include "roleplay/rp_include"
#include "roleplay/rp_hl2dm"
#include "roleplay/rp_main"
#include "roleplay/rp_hud"
#include "roleplay/rp_items"
#include "roleplay/COLORS"
#include "roleplay/rp_doors"
#include "roleplay/rp_placeholder"

#define TICKER		1.2
#define VERSION 	"2.0"
#define MAXPLAYER 	33
#define MAXITEMS 	667

public String:ItemPath[128];
public String:LockPath[128];

//Player Infos
static ItemOwn[MAXPLAYER][MAXITEMS];
static Float:LastSpawn[MAXPLAYER];

//Item Infos
static ItemCost[MAXITEMS];
public String:ItemName[MAXITEMS][255];
public ItemAction[MAXITEMS];
public String:ItemVar[MAXITEMS][255];
public IsGiving[MAXPLAYER];

//Menus:
static MenuTarget[MAXPLAYER];
static NextKey[MAXPLAYER];
static SelectedBuffer[7][MAXPLAYER];
static SelectedItem[MAXPLAYER];

public bool:DoorLocked[2000]; 

public Float:LockTime[MAXPLAYER];
public Float:HackTime[MAXPLAYER];
public Float:SawTime[MAXPLAYER];
public Float:RobTime[MAXPLAYER];
public Float:CrimeTime[MAXPLAYER];
public Float:lastspawn[MAXPLAYER]; 
public IsPVP[MAXPLAYER];
public GPS[MAXPLAYER][MAXPLAYER];


public RaffleWin[MAXPLAYER];

//Update:
static ItemAmount[2000][MAXITEMS];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("rp_setItem", setItem);
	CreateNative("rp_addItem", addItem);
	CreateNative("rp_remItem", remItem);
	CreateNative("rp_setItemMenuTarget", setItemMenuTarget);
	CreateNative("rp_CommandPickUpItem", CommandPickUpItem);

	CreateNative("rp_checkItem", checkItem);
	
	CreateNative("rp_itemAction", getItemAction);
	CreateNative("rp_itemVar", getItemVar);
	CreateNative("rp_itemCost", getItemCost);
	CreateNative("rp_itemName", getItemName);
	CreateNative("rp_SetIsGiving", SetIsGiving);
	CreateNative("rp_ShowInvetory", showinventory);
	
	CreateNative("rp_getPvP", getPvP);
	CreateNative("rp_setPvP", setPvP);


	return APLRes_Success;
}

public OnClientPutInServer(Client)
{
	for(new X = 1; X < MAXITEMS; X++)
	{
		ItemOwn[Client][X] = 0;
	}
}

public getPvP(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);	
	return IsPVP[Client];
}

public setPvP(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);	
	new Amount = GetNativeCell(2);
	IsPVP[Client] = Amount;
}

//selectedbuffer
public showinventory(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);	
	new start = GetNativeCell(2);
	Inventory(Client, start);
}

//selectedbuffer
public SetIsGiving(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);	
	new bool:give = GetNativeCell(2);
	IsGiving[Client] = give;
}

//selectedbuffer
public setItemMenuTarget(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);	
	new Player = GetNativeCell(2);
	MenuTarget[Client] = Player;
}

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
	for(new X = 0; X < 7; X++)
	{
		SelectedBuffer[X][Client] = 0;
		if(strlen(Buffers[X]) > 0)
		{
	
			//Add:
			DrawPanelItem(Panel, Buffers[X]);
	
			//Var:
			SelectedBuffer[X][Client] = Variables[X];
		}
	}
 
	//Draw:
	SendPanelToClient(Panel, Client, MenuHandle, 30);

	//Close:
	CloseHandle(Panel);
}


//Map Start:
public OnMapStart()
{	
	decl String:Map[128], String:Path[64];
	GetCurrentMap(Map, 128);

	BuildPath(Path_SM, Path, 64, "data/roleplay/%s/", Map);
	CreateDirectory(Path,511);
	
	//Config DB:
	BuildPath(Path_SM, ItemPath, 64, "data/roleplay/items.txt");
	BuildPath(Path_SM, LockPath, 64, "data/roleplay/%s/lock.txt",Map);
	
	new Handle:Vault;	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, LockPath);
	
	decl String:ReferenceString[255], String:ItemId[255];
	
	//Loop:
	for(new X = 0; X < 2000; X++)
	{
		//Convert:
		IntToString(X, ItemId, sizeof(ItemId));
		
		//Load:
		LoadString(Vault, "1", ItemId, "Null", ReferenceString);
		
		//Check:
		if(!StrEqual(ReferenceString, "Null"))
		{
			DoorLocked[X] = true;
		}
	}
	
	CloseHandle(Vault);
	
	LoadItems();
	
}


public OnMapEnd()
{
	cleanUpTimer();
}

//Cleans all Timers = fixing the wrong timer bugs
public cleanUpTimer()
{
	for(new i = 0;i < MAXPLAYER; i++)
	{
		LastSpawn[i] = 0.0;
		LockTime[i] = 0.0;
		HackTime[i] = 0.0;
		SawTime[i] = 0.0;
		CrimeTime[i] = 0.0;
		//InterruptTime[i] = 0.0;
	}
}

public OnPluginStart() 
{
	LoadTranslations("common.phrases");
	RegAdminCmd("rp_createitem", CommandCreateItem, ADMFLAG_ROOT, "<Id> <Name> <Type> <Variable> <cost> - Creates an Item");
	RegAdminCmd("rp_removeitem", CommandRemoveItem, ADMFLAG_ROOT, "<Id> - Removes an Item");
	RegAdminCmd("rp_itemlist", CommandListItems, ADMFLAG_ROOT, "- Lists items from the database");
	
	RegAdminCmd("rp_lockdoor", CommandLockDoor, ADMFLAG_ROOT, "- Lists items from the database");
	RegAdminCmd("rp_unlockdoor", CommandUnlockDoor, ADMFLAG_ROOT, "- Lists items from the database");
	RegConsoleCmd("rp_items", Command_items);
	RegConsoleCmd("sm_items", Command_items);
}

public CommandPickUpItem(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);	
	new Ent = GetNativeCell(2);
	
	//Loop:
	for(new X = 0; X < MAXITEMS; X++)
	{
		
		//Items:
		if(ItemAmount[Ent][X] > 0)
		{
			
			//Declare:
			decl Float:Dist;
			decl Float:ClientOrigin[3], Float:EntOrigin[3];
			
			//Initialize:
			GetClientAbsOrigin(Client, ClientOrigin);
			GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", EntOrigin);
			Dist = GetVectorDistance(ClientOrigin, EntOrigin);
			
			//Range:
			if(Dist <= 100)
			{
				
				//Remove Ent:				
				rp_entacceptinput(Ent, "Kill");
				
				if(X == 666)
				{
					CPrintToChat(Client, "{red}[RP]\x04 You picked up a trap!!!\x04");
					decl ClientID;
					
					//Initialize:
					ClientID = GetClientUserId(Client);
					rp_setLooseMoney(Client, true);
					
					//Send:
					ServerCommand("sm_timebomb #%d 1", ClientID);
				} 
				else
				{
					//Exchange:
					ItemOwn[Client][X] += ItemAmount[Ent][X];
					new String:ClientName[32], String:SteamId[32];
					GetClientName(Client, ClientName, 32);				
					GetClientAuthString(Client, SteamId, 32);	
					CPrintToChat(Client, "{teamcolor}[RP]\x01 You pick up \x04%d\x01 x \x04%s\x04\x01!", ItemAmount[Ent][X], ItemName[X]);
					rp_saveItem(Client, X, ItemOwn[Client][X]);
				}
				//Save:
				ItemAmount[Ent][X] = 0;
				
				//Return:
				return true;
			}
		}
	}	
	return true;
}


//Item Handle:
public HandleItems(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{
	
	//Select:
	if(HandleAction == MenuAction_Select)
	{
		
		//"Give"
		if(IsGiving[Client])
		{
			
			
			//"Next":
			if(Parameter == NextKey[Client])
			{
				
				//Draw:
				Inventory(Client, SelectedBuffer[NextKey[Client] - 1][Client]);
			}
			else
			{
				
				//Initialize:
				new String:Buffers[7][64] = {"1", "5", "10", "20", "50", "100", "All"};
				new Variables[7] = {1, 5, 10, 20, 50, 100, 69};
				
				//Save:
				SelectedItem[Client] = SelectedBuffer[Parameter - 1][Client];
				
				//Draw:
				DrawMenu(Client, Buffers, HandleGive, Variables);
			}	
		}
		else
		{
			
			
			//"Next":
			if(Parameter == NextKey[Client])
			{
				
				//Draw:
				Inventory(Client, SelectedBuffer[NextKey[Client] - 1][Client]);
			}
			else
			{
				
				//Initialize:
				new String:Buffers2[7][64];
				Buffers2[0] = "Use";
				Buffers2[1] = "Drop";
				
				//Save:
				SelectedItem[Client] = SelectedBuffer[Parameter - 1][Client];
				
				
				//Draw:
				DrawMenu(Client, Buffers2, HandlePrompt);

			}
		}
	}
}
//Handle Prompting:
public HandlePrompt(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Select:
	if(HandleAction == MenuAction_Select)
	{
		//Declare:
		decl ItemId;

		//Initialize:
		ItemId = SelectedItem[Client];
		if(Parameter == 1)
		{
		
			//Draw:
			use(Client, ItemId);
		}
		//Drop:
		if(Parameter == 2)
		{

			//Initialize:
			new String:Buffers[7][64] = {"1", "5", "25", "100", "500", "1000", "All"};
			new Variables[7] = {1, 5, 25, 100, 500, 1000, 69};

			//Draw:
			DrawMenu(Client, Buffers, HandleDropItem, Variables);
		}
	
	}
	
	
}

stock bool:IsPvPOn(Client, ItemId)
{
	if(IsPVP[Client] >= 1)
	{	
		CPrintToChat(Client, "{teamcolor}[RP]\x01 You cannot use \x04%s\x01 while you have PvP \x04(Player vs. Player)\x01.", ItemName[ItemId]);
		return true;
	}
	else
	{		
		return false;
	}
}


//Job Menu Handle:
public HandleGive(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Select:
	if(HandleAction == MenuAction_Select)
	{

		//Valid:
		if(IsClientInGame(MenuTarget[Client]))
		{

			//Declare:
			decl ItemId, Amount;

			//Initialize:
			ItemId = SelectedItem[Client];
			Amount = SelectedBuffer[Parameter - 1][Client];
			if(SelectedBuffer[Parameter - 1][Client] == 69) Amount = ItemOwn[Client][ItemId];

			//Has:
			if(ItemOwn[Client][ItemId] - Amount >= 0)
			{

				//Declare:
				decl String:ClientName[32], String:PlayerName[32];

				//Initialize:
				GetClientName(Client, ClientName, 32);
				GetClientName(MenuTarget[Client], PlayerName, 32);

				//Action:
				ItemOwn[Client][ItemId] -= Amount;


				ItemOwn[MenuTarget[Client]][ItemId] += Amount;
				//Print:
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You give \x04%s %d\x01 x \x04%s\x01!", PlayerName, Amount, ItemName[ItemId]);
				CPrintToChat(MenuTarget[Client], "{teamcolor}[RP]\x01 You recieve \x04%d\x01 x \x04%s\x01 from \x04%s\x01!", Amount, ItemName[ItemId], ClientName);

				//Save:
				IsGiving[Client] = true;
	
				//Send:
				Inventory(Client, 0);

				//Save:
				rp_saveItem(MenuTarget[Client], ItemId, ItemOwn[MenuTarget[Client]][ItemId]);
				rp_saveItem(Client, ItemId, ItemOwn[Client][ItemId]);
			}
			else
			{

				//Print:
				CPrintToChat(Client, "{teamcolor}[RP]\x04 You don't have \x04%d\x01 x \x04%s\x01!", Amount, ItemName[ItemId]);
			}
		}
	}
}

//Drop Menu Handle:
public HandleDropItem(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Select:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl ItemId, Amount;
		decl Ent, Collision;
		decl Float:Position[3];
		new Float:Angles[3] = {0.0, 0.0, 0.0};

		//Initialize:
		ItemId = SelectedItem[Client];
		Ent = rp_createent("prop_physics");

		//Check:
		Amount = SelectedBuffer[Parameter - 1][Client];
		if(SelectedBuffer[Parameter - 1][Client] == 69) Amount = ItemOwn[Client][ItemId];

		//Has:
		if(ItemOwn[Client][ItemId] - Amount >= 0 && Amount > 0)
		{
			if(ItemAction[ItemId] == 17 || ItemAction[ItemId] == 19)
			{
				if(rp_hud_get_police(Client))
				{
					rp_hud_set_police(Client, false);
					rp_hud_set_policeupgrade(Client, false);
					CPrintToChat(Client, "{teamcolor}[RP]\x04 Your Police Detector has been disabled!");
				}
			}
			
			
			if(ItemAction[ItemId] == 20)
			{
				if(rp_hud_get_metal(Client))
				{
					rp_hud_set_metal(Client, false);
					rp_hud_set_metal_tracer(Client, false);
					rp_hud_set_calibrate(Client, false);
					CPrintToChat(Client, "{teamcolor}[RP]\x04 Your metal detector has been disabled!");
				}
			}

			//Values:
			rp_dispatchkeyvalue(Ent, "model", "models/Items/BoxMRounds.mdl");

			//Spawn:
			rp_dispatchspawn(Ent);

			//Angles:
			Angles[1] = GetRandomFloat(0.0, 360.0);

			//Position:
			GetClientAbsOrigin(Client, Position);
			Position[2] += 10.0;

			//Debris:
			Collision = GetEntSendPropOffs(Ent, "m_CollisionGroup");
			if(IsValidEntity(Ent)) SetEntData(Ent, Collision, 1, 1, true);
	
			//Send:
			rp_teleportent(Ent, Position, Angles, NULL_VECTOR);

			//Check:
			if(SelectedBuffer[Parameter - 1][Client] == 69) Amount = ItemOwn[Client][ItemId];

			
			//Update:
			ItemAmount[Ent][ItemId] = Amount;
			
			//Send:
			PrintToChat(Client, "[RP] You drop %d x %s", Amount, ItemName[ItemId]);
			ItemOwn[Client][ItemId] -= Amount;
			rp_saveItem(Client, ItemId, ItemOwn[Client][ItemId]);
					
			//Initialize:
			new String:Buffers[7][64] = {"1", "5", "25", "100", "500", "1000", "All"};
			new Variables[7] = {1, 5, 25, 100, 500, 1000, 69};
			
			//Draw:
			DrawMenu(Client, Buffers, HandleDropItem, Variables);
		}
		else
		{
			
			//Print:
			PrintToChat(Client, "[RP] You don't have %d x %s!", Amount, ItemName[ItemId]);
		}
	}
}

//Items:
public Action:Inventory(Client, Start)
{

	//Declare:
	decl Next;
	decl Buffer;
	decl bool:MenuDisplay;
	new bool:Available = false;

	//Initalize:
	Buffer = 1;
	MenuDisplay = false;
	new Variables[7];
	new String:Buffers[7][64];

	//Items:
	for(new X = Start; X < MAXITEMS; X++)
	{

		//Owns:
		if(ItemOwn[Client][X] > 0)
		{

			//Max:
			if(Buffer < 7)
			{

				//Initialize:
				Format(Buffers[Buffer - 1], 32, "%d x %s", ItemOwn[Client][X], ItemName[X]);

				//Display:
				MenuDisplay = true;

				//Send:
				Variables[Buffer-1] = X;
				Buffer += 1;
				Next = X + 1;
			}
		}	
	}

	//Check:
	for(new Y = Next; Y < MAXITEMS; Y++)
	{

		//Available:
		if(ItemOwn[Client][Y] > 0)
		{

			Available = true;
		}
	}
	
	//Check:
	if(Buffer != 7) Next = 0;
	if(!Available) Next = 0;

	//Draw:
	Format(Buffers[Buffer - 1], 32, "Next");
	Variables[Buffer-1] = Next;
	NextKey[Client] = Buffer;
 
	//Draw:
	if(MenuDisplay)
	{

		//Draw:
		DrawMenu(Client, Buffers, HandleItems, Variables);
	} 
	else
	{
		
		//Print:
		PrintToChat(Client, "[RP] You don't have any items!");

		//Return:
		return Plugin_Handled;
	}

	//Return:
	return Plugin_Handled;
}

public Action:CommandLockDoor(Client,Args)
{
	decl Ent;
	Ent = rp_entclienttarget(Client, false);
	if(Ent != -1)
	{
		if(!DoorLocked[Ent])
		{
			decl Handle:Vault;
			decl String:NPCId[255];
			
			Vault = CreateKeyValues("Vault");
			IntToString(Ent,NPCId,32);
			FileToKeyValues(Vault, LockPath); 
			SaveString(Vault, "1", NPCId, "1");
			KeyValuesToFile(Vault, LockPath);
			CloseHandle(Vault);  
			
			DoorLocked[Ent] = true;
			CPrintToChat(Client, "{red}[RP]\x01 Door \x04#%d\x01 locked",Ent); 
		}
		else
		{
			CPrintToChat(Client, "{red}[RP]\x01 Door \x04#%d\x01 already locked",Ent);  
		}  
	}
	return Plugin_Handled; 
}

public Action:CommandUnlockDoor(Client,Args)
{
	decl Ent;
	Ent = rp_entclienttarget(Client, false);
	if(Ent != -1)
	{
		if(!DoorLocked[Ent])
		{
			decl Handle:Vault;
			decl String:NPCId[255];
			
			Vault = CreateKeyValues("Vault");
			IntToString(Ent,NPCId,32);
			FileToKeyValues(Vault, LockPath); 
			SaveString(Vault, "1", NPCId, "1");
			KeyValuesToFile(Vault, LockPath);
			CloseHandle(Vault);  
			
			DoorLocked[Ent] = true;
			CPrintToChat(Client, "{red}[RP]\x01 Door \x04#%d\x01 locked",Ent); 
		}
		else
		{
			CPrintToChat(Client, "{red}[RP]\x01 Door \x04#%d\x01 already locked",Ent);  
		}  
	}
	return Plugin_Handled;
}

public Action:Command_items(Client,Args)
{
	
	//Cuffed:
	if(!rp_iscuff(Client))
	{
		
		//Inventory:
		Inventory(Client, 0);
		IsGiving[Client] = false;
		
		//Return:
		return Plugin_Handled;
	}
	CPrintToChat(Client, "{red}[RP]\x04 You can't use any item while you are cuffed!");
	return Plugin_Handled;
}

public getItemName(Handle:plugin, numParams)	
{
	new id = GetNativeCell(1);
	new String:str[255];
	GetNativeString(2, str, sizeof(str));

	Format(str,sizeof(str),"%s",ItemName[id]);
	SetNativeString(2, str, sizeof(str), false);
}

public getItemVar(Handle:plugin, numParams)	
{
	new id = GetNativeCell(1);
	new String:str[255];
	GetNativeString(2, str, sizeof(str));

	Format(str,sizeof(str),"%s",ItemVar[id]);
	SetNativeString(2, str, sizeof(str), false);
}

public getItemCost(Handle:plugin, numParams)	
{
	new Item = GetNativeCell(1);
	return ItemCost[Item];
}

public getItemAction(Handle:plugin, numParams)	
{
	new Item = GetNativeCell(1);
	return ItemAction[Item];
}

public setItem(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Item = GetNativeCell(2);
	new Amount = GetNativeCell(3);
	
	ItemOwn[Client][Item] = Amount;
	rp_saveItem(Client, Item, ItemOwn[Client][Item]);
}

public addItem(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Item = GetNativeCell(2);
	new Amount = GetNativeCell(3);
	
	ItemOwn[Client][Item] += Amount;
	rp_saveItem(Client, Item, ItemOwn[Client][Item]);
}

public remItem(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Item = GetNativeCell(2);
	new Amount = GetNativeCell(3);
	
	ItemOwn[Client][Item] -= Amount;
	rp_saveItem(Client, Item, ItemOwn[Client][Item]);

	
}

public checkItem(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Item = GetNativeCell(2);
	
	return (Item < 0) ? 0 : ItemOwn[Client][Item];
}


public useItem(Handle:plugin, numParams)
{
	new Client = GetNativeCell(1);
	new Item = GetNativeCell(2);
	
	if(ItemOwn[Client][Item] > 0 && LastSpawn[Client] <= (GetGameTime() - 5))
	{
		LastSpawn[Client] = GetGameTime();
		ItemOwn[Client][Item]--;
		use(Client,Item);
	}
}

public Action:PhysGunTimer(Handle:Timer, any:Client)
{
		//Give:
	rp_giveplayeritem(Client, "weapon_physcannon");
	return Plugin_Handled;	
}



public Action:backspeed(Handle:Timer, any:Client) {
	SetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	return Plugin_Handled;	
}

public Action:ToggleNexus(Handle:Timer, any:Ent)
{
	rp_entacceptinput(Ent, "Close", Ent);
	return Plugin_Handled;
}



stock use(Client,ItemId)
{
		if(rp_iscuff(Client))
		{
			CPrintToChat(Client, "{teamcolor}[RP] \x04\x01You cannot use item while cuffed");
			return true;
		}

		if(lastspawn[Client] > (GetGameTime() - 3))
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x01 Wait some seconds and try it again.");
			return true;
		}
		
		lastspawn[Client] = GetGameTime();
		
		
		
		
		//HL2 Item:
		if(ItemAction[ItemId] == 1) 
		{
			if(IsPvPOn(Client, ItemId))return true;
			if(StrEqual(ItemVar[ItemId], "weapon_frag"))
			{
				SpawnWeapon(Client, "weapon_frag");
			}
			else
			{
				if(HasClientWeapon(Client, ItemVar[ItemId]) != -1)
				{
					CPrintToChat(Client, "{teamcolor}[RP]\x01 You already own a \x04%s\x01.", ItemVar[ItemId]);
					return true;
				}
			}
			
			//Give:
			rp_giveplayeritem(Client, ItemVar[ItemId]);
			
			
			CPrintToChat(Client, "{teamcolor}[RP]\x01 You use \x04%s\x01.", ItemName[ItemId]);
			//Save:
			ItemOwn[Client][ItemId] -= 1;
		}
		
		//Alchohal (Alcohol):
		if(ItemAction[ItemId] == 2) 
		{
			rp_alcohol(Client,StringToInt(ItemVar[ItemId]));
		}
		
		// Drugs
		if(ItemAction[ItemId] == 3) 
		{
			rp_drugs(Client,StringToInt(ItemVar[ItemId]));
		}
		
		//Food:
		if(ItemAction[ItemId] == 4)
		{
			//Declare:
			decl Var;
			
			//Initialize:
			Var = StringToInt(ItemVar[ItemId]);
			
			//Max Feeded:
			if(rp_getFeed(Client) < 100)
			{
				rp_setFeed(Client,rp_getFeed(Client)+Var);
				//Print:
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You eat %s and you're feeded by +%d!\x04", ItemName[ItemId], Var);
				ItemOwn[Client][ItemId] -= 1;
			}
			else
			{
				//Print:
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You cannot eat right now, you're full\x04");
			}
		}
		
		//Lockpick:
		if(ItemAction[ItemId] == 5)
		{
			//Declare:
			decl Var;
			
			//Initialize:
			Var = StringToInt(ItemVar[ItemId]);
			if(IsPvPOn(Client, ItemId))return true;
			
			
			//Buffer:
			if(LockTime[Client] <= (GetGameTime() - (60 * Var)))
			{
				
				//Declare:
				decl DoorEnt;
				decl String:ClassName[255];
				
				//Initialize:
				DoorEnt = rp_entclienttarget(Client,false);
				
				//ClassName:
				GetEdictClassname(DoorEnt, ClassName, 255);
				
				//Action:
				if(DoorEnt > 1)
				{
					
					if(DoorLocked[DoorEnt])
					{
						CPrintToChat(Client, "{teamcolor}[RP]\x04 Door is not unlockable\x04");
					}
					else
					{
						//Doors:
						if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
						{
							if(rp_getLock(DoorEnt) <= 1)
							{
								//Unlock:
								rp_entacceptinput(DoorEnt, "Unlock", Client);
								rp_SetDoorStatus(DoorEnt, 0);
								//Print:
								CPrintToChat(Client, "{teamcolor}[RP]\x01 Door has been unlocked\x04");
								
								//Save:
								LockTime[Client] = GetGameTime();
								
								rp_crime(Client,100); 
							} else
							{
								CPrintToChat(Client, "{teamcolor}[RP]\x01 This door has some additional locks!\x04");
							}   
						}
					}
					
					//Metal:
					if(StrEqual(ClassName, "func_door"))
					{
						//Print:
						CPrintToChat(Client, "{teamcolor}[RP]\x01 Lockpick cannot be used on this door\x04");
					}
				}
			}
			else
			{
				
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You can only use this once every \x04%d\x01 minutes\x04", Var);		
			}
		}
		
		//DoorHack:
		if(ItemAction[ItemId] == 6)
		{
			
			//Declare:
			decl Var;
			
			//Initialize:
			Var = StringToInt(ItemVar[ItemId]);
			if(IsPvPOn(Client, ItemId))return true;
			
			
			//Buffer:
			if(HackTime[Client] <= (GetGameTime() - (60 * Var)))
			{
				
				//Declare:
				decl DoorEnt;
				decl String:ClassName[255];
				
				//Initialize:
				DoorEnt = rp_entclienttarget(Client,false);
				
				//ClassName:
				GetEdictClassname(DoorEnt, ClassName, 255);
				
				//Action:
				if(DoorEnt > 1)
				{
					if(DoorLocked[DoorEnt])
					{
						CPrintToChat(Client, "{teamcolor}[RP]\x04 Door is not unlockable\x04");
					}
					else
					{
						//Metal:
						if(StrEqual(ClassName, "func_door"))
						{
							if(rp_getLock(DoorEnt) <= 1)
							{
								//Unlock:
								rp_entacceptinput(DoorEnt, "Unlock", Client);
								rp_entacceptinput(DoorEnt, "Toggle", Client);
								rp_SetDoorStatus(DoorEnt, 0);
								//Print:
								CPrintToChat(Client, "{teamcolor}[RP]\x01 Door has been opened.");
								CreateTimer(4.0, ToggleNexus, DoorEnt);
								//Save:
								HackTime[Client] = GetGameTime();
								rp_crime(Client,150); 
							}
							else
							{
								CPrintToChat(Client, "{teamcolor}[RP]\x01 This door has some additional locks!");
							}
						}
					}
					//Doors:
					if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
					{
						//Print:
						CPrintToChat(Client, "{teamcolor}[RP]\x01 Cannot be used on this door\x04");
					}
				}
			}
			else
			{
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You can only use this once every \x04%d\x01 minutes.", Var);
			}
		}
		
		//Furniture:
		if(ItemAction[ItemId] == 7)
		{
			
			//Declare:
			decl Ent;
			decl Float:EyeAngles[3];
			decl Float:ClientOrigin[3], Float:FurnitureOrigin[3];
			
			//Initialize:
			GetClientAbsOrigin(Client, ClientOrigin);
			rp_geteyes(Client, EyeAngles);
			
			//Math:
			FurnitureOrigin[0] = (ClientOrigin[0] + (50 * Cosine(DegToRad(EyeAngles[1]))));
			FurnitureOrigin[1] = (ClientOrigin[1] + (50 * Sine(DegToRad(EyeAngles[1]))));
			FurnitureOrigin[2] = (ClientOrigin[2] + 100);
			
			//Print:
			CPrintToChat(Client, "{teamcolor}[RP]\x01 You spawn a \x04%s\x04\x01!", ItemName[ItemId]);
			
			//Create:
			Ent = rp_createent("prop_physics_override");
			SetEntProp(Ent, Prop_Data, "m_takedamage", 2, 1);
			//Key Values:
			rp_dispatchkeyvalue(Ent, "solid", "6");
			
			//Model:
			rp_dispatchkeyvalue(Ent, "model", ItemVar[ItemId]);
			
			//Spawn & Send:
			rp_dispatchspawn(Ent);
			rp_teleportent(Ent, FurnitureOrigin, NULL_VECTOR, NULL_VECTOR);
			
			//Remove:
			ItemOwn[Client][ItemId] -= 1;
		}
		
		//Med Kits:
		if(ItemAction[ItemId] == 8)
		{
			//Declare:
			decl Var;
			decl Player;
			decl PlayerHP;
			decl String:ClientName[32], String:PlayerName[32];
			
			//Initialize:
			Var = StringToInt(ItemVar[ItemId]);
			Player = rp_entclienttarget(Client, true);
			PlayerHP = GetClientHealth(Player);
			GetClientName(Client, ClientName, 32);
			GetClientName(Player, PlayerName, 32);
			
			//Legit:
			if(Player > 0)
			{
				//Connected:
				if(IsClientInGame(Player))
				{
					if(PlayerHP >= 100)
					{
						CPrintToChat(Client, "{teamcolor}[RP]\x01 The player \x04%s\x01 already has full HP!", PlayerName);
					}
					else
					{
						//Work:
						if((PlayerHP + Var) > 100) SetEntityHealth(Player, 100);
						else SetEntityHealth(Player, (PlayerHP + Var));
						
						//Print:
						CPrintToChat(Client, "{teamcolor}[RP]\x01 You heal \x04%s\x01 for +\x04%d\x01HP!", PlayerName, Var);
						CPrintToChat(Player, "{teamcolor}[RP]\x01 You have been healed by \x04%s\x01 for +\x04%d\x01HP!", ClientName, Var);
						ItemOwn[Client][ItemId] -= 1;
					}
				}
			}
			else
			{
				//Print:
				CPrintToChat(Client, "{teamcolor}[RP]\x04 Invalid Player\x04");
			}
		}
		
		//CuffSaw:
		if(ItemAction[ItemId] == 9)
		{
			//Declare:
			decl Var;
			
			//Initialize:
			Var = StringToInt(ItemVar[ItemId]);
			if(IsPvPOn(Client, ItemId))return true;
			if(rp_iscop(Client))
			{
				CPrintToChatAll("{teamcolor}[RP]\x01 You can't use \x04%s\x01 as a cop!", ItemName[ItemId]);
				return true;
			}
			
			//Buffer:
			if(SawTime[Client] <= (GetGameTime() - (60 * Var)))
			{
				
				//Not Cuffed:
				if(!rp_iscuff(Client))
				{
					
					//Declare:
					decl Player;
					
					//Initialize:
					Player = rp_entclienttarget(Client, true);
					
					//Legit:
					if(Player > 0)
					{
						
						//Connected:
						if(IsClientInGame(Player))
						{
							
							//Declare:
							decl String:ClientName[32], String:PlayerName[32];
							
							//Initialize:
							GetClientName(Client, ClientName, 32);
							GetClientName(Player, PlayerName, 32);
							
							//Cuffed:
							if(rp_iscuff(Player))
							{
								//Print:
								CPrintToChat(Client, "{teamcolor}[RP]\x01 You saw the handcuffs off of %s!\x04", PlayerName);
								CPrintToChat(Player, "{teamcolor}[RP]\x04 %s\x01 sawed off your handcuffs!\x04", ClientName);
								
								//Action:
								rp_uncuff(Player);
								//Crime[Player] = 0
								rp_crime(Client, 50);
								//Save:
								SawTime[Client] = GetGameTime();
							}
							else
							{
								//Print:
								CPrintToChat(Client, "{teamcolor}[RP]\x04 %s\x01 is not cuffed", PlayerName);
							}
						}
					}
					else
					{
						//Print:
						CPrintToChat(Client, "{teamcolor}[RP]\x01 Invalid Player");
					}
				}
				else
				{
					//Print:
					CPrintToChat(Client, "{teamcolor}[RP]\x01 You cannot do this while cuffed\x04");
				}
			}
			else
			{
				//Print:
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You can only use this once every \x04%d\x01 minutes.", Var);
			}
		}
		//Bomb and commands:
		if(ItemAction[ItemId] == 10)
		{
			//Not Cuffed:
			if(!rp_iscuff(Client))
			{
				//Send:
				ServerCommand("%s #%d", ItemVar[ItemId], Client);
				
				//Save:
				ItemOwn[Client][ItemId] -= 1;
			}
		}
		
		//Potions
		if(ItemAction[ItemId] == 11)
		{
			
			//Declare:
			decl Var;
			decl ClientHP;
			
			//Initialize:
			
			ClientHP = GetClientHealth(Client);
			
			//Max HP:
			if(ClientHP < 500)
			{
				
				//Work:
				if((ClientHP + Var) > 500) SetEntityHealth(Client, 500);
				else SetEntityHealth(Client, (ClientHP + Var)); 
				//Print:
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You drink \x04%s\x01 for +\x04%d\x01hp!", ItemName[ItemId], Var);
				ItemOwn[Client][ItemId] -= 1;
			}
			else
			{					
				//Print:
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You cannot drink right now, your health is full.");
			}
		} 
		
		//Raffle Tickets:
		if(ItemAction[ItemId] == 12)
		{
			//Declare:
			decl Var,Winamount;
			
			//Initialize:
			Var = StringToInt(ItemVar[ItemId]);
			
			new random = GetRandomInt(1,200);
			if(random < 80)
			{
				Winamount = 25*Var;
			} else if(random < 60)
			{
				Winamount = 50*Var;
			} else if(random == 98)
			{
				Winamount = 200*Var;
			} else if(random == 99 && RaffleWin[Client] < 0)
			{
				Winamount = 300*Var;
			} else if(random == 100 && RaffleWin[Client] < 0)
			{
				Winamount = 500*Var;
			} else if(random > 180)
			{
				Winamount = 20*Var;
			} else if(random > 170)
			{
				Winamount = 50*Var;
			} 
			
			if(Winamount > 0)
				CPrintToChat(Client, "{teamcolor}[RP-Lottery]\x01 You won \x04%d\x01$.",Winamount);
			else
				CPrintToChat(Client, "{teamcolor}[RP-Lottery]\x01 You draw a blank.");
			
			
			RaffleWin[Client] += Winamount - 10*Var;
			rp_addMoney(Client, Winamount);
			ItemOwn[Client][ItemId] -= 1;
			
			if(Winamount >= 200*Var)
			{
				decl String:ClientName[255];
				GetClientName(Client, ClientName, sizeof(ClientName));
				
				for(new X = 1; X <= MaxClients; X++)
				{
					//Connected:
					if(IsClientInGame(X) && X != Client)
					{
						CPrintToChat(X, "{teamcolor}[RP-Lottery]\x01 The Player \x04\"%s\"\x01 hit the jackpot and won $\x04%d\x01 with a $\x01%d\x04 ticket",ClientName,Winamount,10*Var);        
					}
				}
			}
		}
		
		//AddLock
		if(ItemAction[ItemId] == 13)
		{
			//Declare:
			decl DoorEnt;
			decl String:ClassName[255];
			
			//Initialize:
			DoorEnt = rp_entclienttarget(Client,false);
			
			//ClassName:
			GetEdictClassname(DoorEnt, ClassName, 255);
			
			//Action:
			if(DoorEnt > 1)
			{
				if(StrEqual(ClassName, "func_door") || StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
				{
					if(rp_getLock(DoorEnt) >= 10)
					{
						CPrintToChat(Client, "{teamcolor}[RP]\x01 You only can put \x0410 Locks\x01 on each Door.");
						return true;
					}
					ItemOwn[Client][ItemId] -= 1;
					
					rp_addLock(Client, DoorEnt);
					CPrintToChat(Client, "{teamcolor}[RP]\x01 Added a lock on the door\x04");  
				}
				else
				{
					CPrintToChat(Client, "{teamcolor}[RP]\x01 You cannot add a Doorlock to this.\x04");
				}
			}
		}
		
		//Destroylock
		if(ItemAction[ItemId] == 14)
		{
			//Declare:
			decl DoorEnt;
			decl String:ClassName[255];
			
			//Initialize:
			DoorEnt = rp_entclienttarget(Client,false);
			
			//ClassName:
			GetEdictClassname(DoorEnt, ClassName, 255);
			
			//Action:
			if(DoorEnt > 1)
			{
				if(StrEqual(ClassName, "func_door") || StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
				{
					if(rp_getLock(DoorEnt) > 0)
					{
						ItemOwn[Client][ItemId] -= 1;
						rp_breakLock(Client, DoorEnt);
						CPrintToChat(Client, "{teamcolor}[RP]\x01 You broke a lock on this door\x04"); 
					}else
					{
						CPrintToChat(Client, "{teamcolor}[RP]\x01 There are no locks on the door\x04"); 

					}
					
				}
				else
				{
					CPrintToChat(Client, "{teamcolor}[RP]\x01 You cannot remove a Doorlock from this.\x04");
				}
			}
		}
		
		//GPS Bug - NOT YET CORRECTED
		if(ItemAction[ItemId] == 15)
		{
			decl Player;
			//Initialize:
			Player = rp_entclienttarget(Client, true);
			
			//Legit:
			if(Player > 0)
			{
				GPS[Client][Player] = true;
				decl String:PlayerName[32];
				GetClientName(Player, PlayerName, 32);
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You hide a GPS Bug on %s.\x04",PlayerName);
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You can trigger the tracers by saying \x04/tracers\x01");
				ItemOwn[Client][ItemId] -= 1; 
			}
		}
		
		//GPS Scanner - NOT YET CORRECTED
		if(ItemAction[ItemId] == 16)
		{
			CPrintToChat(Client, "{teamcolor}[RP]\x01 Scanning for GPS Bugs...");
			
			for(new X = 0; X < 32; X++)
			{
				if(GPS[X][Client] == 1)
				{
					decl String:PlayerName[32];
					GetClientName(X, PlayerName, 32);
					CPrintToChat(Client, "{teamcolor}[RP]\x01 Found a GPS Bug from \x04%s\x01.",PlayerName);
					
					GPS[X][Client] = 0;
					ItemOwn[Client][ItemId] -= 1; 
				} 	
			}
		}
		
		//Police scanner
		if(ItemAction[ItemId] == 17)
		{
			if(!rp_hud_get_police(Client))
			{
			
				//Declare:
				decl Var;
				
				//Initialize:
				Var = StringToInt(ItemVar[ItemId]);
				CPrintToChat(Client, "{teamcolor}[RP]\x04 Initializing Police Detector\x04",Var);
				rp_hud_set_police(Client,true);
			}
		}
		
		//Police Jammer - NOT YET CORRECTED
		if(ItemAction[ItemId] == 18)
		{
			//Declare:
			decl Var;
			
			//Initialize:
			Var = StringToInt(ItemVar[ItemId]);
			CPrintToChat(Client, "{teamcolor}[RP]\x04 Initializing Police Jammer for %d minutes\x04",Var);
			//InterruptTime[Client] = GetGameTime() + (60*Var);
			ItemOwn[Client][ItemId] -= 1; 
		}
		//Police Scanner Addon
		if(ItemAction[ItemId] == 19)
		{
			if(rp_hud_get_policeupgrade(Client))
			{	
				CPrintToChat(Client, "{teamcolor}[RP]\x04 Deactivated your \x04Police Detector Upgrade\x01.");
				rp_hud_set_policeupgrade(Client, false);
				return true;
			}
			if(!rp_hud_get_police(Client))
			{		
				//Print:
				CPrintToChat(Client, "{teamcolor}[RP]\x04 First Activate your \x04Police Detector Upgrade\x01.");
			}	
			else
			{
				CPrintToChat(Client, "{teamcolor}[RP]\x04 Activated your \x04Police Detector Upgrade\x01.");
				rp_hud_set_policeupgrade(Client, true);
			}	
		}
		
		//Metal Detector
		if(ItemAction[ItemId] == 20)
		{
			decl Var;
			Var = StringToInt(ItemVar[ItemId]);
			
			if(Var == 1)
			{
				if(!rp_hud_get_metal(Client))
				{		
					//Print:
					CPrintToChat(Client, "{teamcolor}[RP]\x01 Activated your \x04Metal Detector\x01.");
					rp_hud_set_metal(Client, true);					
				}	
				else
				{
					CPrintToChat(Client, "{teamcolor}[RP]\x01 Deactivated your \x04Metal Detector\x01.");
					rp_hud_set_calibrate(Client, false);
					rp_hud_set_metal(Client, false);
					rp_hud_set_metal_tracer(Client, false);
				}
			} else if(Var == 2)
			{
				if(rp_hud_get_calibrate(Client))
				{
					CPrintToChat(Client, "{teamcolor}[RP]\x01 Deactivated your \x04Calibrate Tool\x01.");
					rp_hud_set_calibrate(Client, false);
					return true;
				}
				if(!rp_hud_get_metal(Client))
				{		
					CPrintToChat(Client, "{teamcolor}[RP]\x01 First Activate your \x04Metal Detector\x01.");
				}	
				else
				{
					CPrintToChat(Client, "{teamcolor}[RP]\x01 Activated your \x04Calibrate Tool\x01.");
					rp_hud_set_calibrate(Client, true);
				}
			} else if(Var == 3)
			{
				if(rp_hud_get_metal_tracer(Client))
				{	
					CPrintToChat(Client, "{teamcolor}[RP]\x04 Deactivated your \x04Tracer Detector\x01.");
					rp_hud_set_metal_tracer(Client, false);
					return true;
				}
				if(!rp_hud_get_metal(Client))
				{
					//Print:
					CPrintToChat(Client, "{teamcolor}[RP]\x04 First Activate your \x04Metal Detector\x01.");
				}	
				else
				{
					CPrintToChat(Client, "{teamcolor}[RP]\x04 Activated your \x04Tracer Detector\x01.");
					rp_hud_set_metal_tracer(Client, true);
				}	
			}
		}
		
		//Push:
		if(ItemAction[ItemId] == 21)
		{			
		
			decl Ent;
			decl Var;
			
			//Initialize:
			Var = StringToInt(ItemVar[ItemId]);
			Ent = rp_entclienttarget(Client,false);
			
			if(Ent < MAXPLAYER && Ent > 0 && !rp_iscuff(Client))
			{
				decl Float:ClientOrigin[3], Float:EntOrigin[3], Float:Dist;
				
				//Initialize:
				GetClientAbsOrigin(Client, ClientOrigin);
				GetClientAbsOrigin(Ent, EntOrigin);
				Dist = GetVectorDistance(ClientOrigin, EntOrigin);
				
				if(Dist <= 100)
				{
					decl Float:Push[3];
					decl Float:EyeAngles[3];
					rp_geteyes(Client, EyeAngles);
					Push[0] = (Var * 800.0 * Cosine(DegToRad(EyeAngles[1])));
					Push[1] = (Var * 800.0 * Sine(DegToRad(EyeAngles[1])));
					Push[2] = (Var * -100.0 * Sine(DegToRad(EyeAngles[0])));
					rp_teleportent(Ent, NULL_VECTOR, NULL_VECTOR, Push);
					if(rp_iscop(Ent) && !rp_iscop(Client))
					{
						CPrintToChat(Client, "{teamcolor}[RP]\x01 You just jostled a cop!\x04");
					}	
				}
			}	
			
		}
		
		//Security PVP
		if(ItemAction[ItemId] == 22)
		{
			new String:sname[80];
			GetClientName(Client, sname, 80);
			
			if(rp_getCrime(Client) != 0) {
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You cannot use \x04Security PvP\x01 \x04(Player vs. Player)\x01 while you have crime.");					
				return true;
				
			}
			IsPVP[Client] = 600;
			CPrintToChat(Client, "{teamcolor}[RP]\x01 You activated \x04Security PvP (Player vs. Player)\x01.");
			
			CreateTimer(1.0, PhysGunTimer, Client);
			
			ItemOwn[Client][ItemId] -= 1;
		}
		
		//Battery:
		if(ItemAction[ItemId] == 23)
		{
			decl Var;
			Var = StringToInt(ItemVar[ItemId]);
			
			if(GetClientArmor(Client) + Var < 100) SetEntityArmor(Client, GetClientArmor(Client) + Var); 
				else
			SetEntityArmor(Client, 100);
			CPrintToChat(Client, "{teamcolor}[RP]\x01 You used a \x04Battery Pack\x01");
			ItemOwn[Client][ItemId] -= 1;
			
		}
		
		//Crime Remover
		if(ItemAction[ItemId] == 24)
		{
			//Declare:
			decl Var;
			
			//Initialize:
			Var = StringToInt(ItemVar[ItemId]);
			
			//Buffer:
			if(CrimeTime[Client] <= (GetGameTime() - (60 * Var)))
			{
				
				rp_crime(Client,(-10*Var)); 
				
				CrimeTime[Client] = GetGameTime();
				//Print:
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You lose \x04%d\x01 crime!\x04",10*Var);
				ItemOwn[Client][ItemId] -= 1;
			}
			else
			{
				CPrintToChat(Client, "{teamcolor}[RP]\x01 You can only use this once every \x04%d\x01 minutes\x04", Var);
			}
		}

		rp_saveItem(Client, ItemId, ItemOwn[Client][ItemId]);
		return true;
}

// ---- ADMIN COMMANDS ----
//Create Item:
public Action:CommandCreateItem(Client, Args)
{
	
	//Error:
	if(Args < 5)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: rp_createitem <id> <name> <type> <variables> <cost>");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	decl Handle:Vault;
	decl String:Buffers[4][128];
	decl String:SaveBuffer[255], String:ItemId[255];
	
	//Initialize:
	GetCmdArg(1, ItemId, sizeof(ItemId));
	GetCmdArg(2, Buffers[0], 128);
	GetCmdArg(3, Buffers[1], 128);
	GetCmdArg(4, Buffers[2], 128);
	GetCmdArg(5, Buffers[3], 128);
	
	//Implode:
	ImplodeStrings(Buffers, 4, "^", SaveBuffer, 255);
	
	//Vault:
	Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, ItemPath);
	
	//Save:
	SaveString(Vault, "Items", ItemId, SaveBuffer);
	
	//Store:
	KeyValuesToFile(Vault, ItemPath);
	
	//Print:
	CPrintToChat(Client, "{red}[RP]\x01 Added Item \x04%s\x01 - \x04%s\x01, Type: \x04%s\x01 - \x04%s\x01.", ItemId, Buffers[0], Buffers[1], Buffers[2]);
	
	//Close:
	CloseHandle(Vault);
	
	//Return:
	return Plugin_Handled;
}

//Remove Item:
public Action:CommandRemoveItem(Client, Args)
{
	if(Client == 0)return Plugin_Handled;	
	//Error:
	if(Args < 1)
	{
		
		//Print:
		CPrintToChat(Client, "{red}[RP]\x01 Usage: rp_removeitem <id>");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:	
	decl bool:Deleted;
	decl String:ItemId[255];
	
	//Initialize:
	GetCmdArg(1, ItemId, sizeof(ItemId));
	
	//Vault:
	new Handle:Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, ItemPath);
	
	//Delete:
	KvJumpToKey(Vault, "Items", false);
	Deleted = KvDeleteKey(Vault, ItemId); 
	KvRewind(Vault);
	
	//Store:
	KeyValuesToFile(Vault, ItemPath);
	
	//Print:
	if(!Deleted) CPrintToChat(Client, "{red}[RP]\x01 Failed to remove Item \x04%s\x01 from the database", ItemId);
	else CPrintToChat(Client, "{red}[RP]\x01 Removed Item \x04%s\x01 from the database", ItemId);
	
	//Close:
	CloseHandle(Vault);
	
	//Return:
	return Plugin_Handled;
}


//List Items:
public Action:CommandListItems(Client, Args)
{
	
	if(Args < 1)	
	{	
		CPrintToChat(Client, "{red}[RP]\x01 Usage: rp_itemlist <page>");
		return Plugin_Handled;
	}
	
	decl String:Page[2],PageInt;
	GetCmdArg(1, Page, sizeof(Page));
	PageInt = StringToInt(Page);
	
	//Declare:	
	decl String:ReferenceString[255], String:ItemId[255];
	
	//Vault:
	new Handle:Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, ItemPath);
	
	//Header:
	PrintToConsole(Client, "Items:");
	
	PrintToConsole(Client, "Printing Itemlist Page %d", PageInt);
	PageInt = PageInt * 90;
	//Loop:
	for(new X = PageInt - 90; X < PageInt; X++)
	{
		
		//Convert:
		IntToString(X, ItemId, sizeof(ItemId));
		
		//Load:
		LoadString(Vault, "Items", ItemId, "Null", ReferenceString);
		
		//Check:
		if(!StrEqual(ReferenceString, "Null"))
		{
			
			//Format:
			ReplaceString(ReferenceString, 255, "^", " "); 
			
			//Print:
			PrintToConsole(Client, "%d - %s", X, ReferenceString);
		}		
	}
	
	//Close:
	CloseHandle(Vault);
	
	//Return:
	return Plugin_Handled;
}




//Load Items:
stock LoadItems()
{
	
	//Declare:
	decl ActionId, Cost;
	decl Handle:Vault;
	decl String:Buffer[4][255];
	decl String:ReferenceString[255], String:ItemId[255];
	
	//Initialize:
	Vault = CreateKeyValues("Vault");
	
	//Retrieve:
	FileToKeyValues(Vault, ItemPath);
	
	//Loop:
	for(new X = 0; X < MAXITEMS; X++)
	{
		
		//Convert:
		IntToString(X, ItemId, sizeof(ItemId));
		
		//Load:
		LoadString(Vault, "Items", ItemId, "Null", ReferenceString);
		
		//Check:
		if(!StrEqual(ReferenceString, "Null"))
		{
			
			//Explode:
			ExplodeString(ReferenceString, "^", Buffer, 4, 255);
			
			//Convert:
			ActionId = StringToInt(Buffer[1]);
			Cost = StringToInt(Buffer[3]);
			
			//Save:
			ItemName[X] = Buffer[0];
			ItemAction[X] = ActionId;
			ItemVar[X] = Buffer[2];
			ItemCost[X] = Cost;
			
			//Furniture:
			if(ItemAction[X] == 7)
			{
				PrecacheModel(ItemVar[X]);
			}
		}
	}
	
	//Save:
	KeyValuesToFile(Vault, ItemPath);
	
	//Close:
	CloseHandle(Vault);
}