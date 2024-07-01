/** Double-include prevention */
#if defined _rp_hl2dm_included_
  #endinput
#endif
#define _rp_hl2dm_included_

#include "roleplay/rp_wrapper"

stock GetSecondaryAmmo(Client, entity)
{
	//Initialize:
	new Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
	new MaxGuns = 256;

	//Loop:
	for(new X = 0; X < MaxGuns; X = (X + 4))
	{
		
		//Initialize:
		new WeaponId = GetEntDataEnt2(Client, Offset + X);
		
		if(WeaponId == entity) 
		{
			return GetWeaponAmmo(Client, X);			
		}
	}	
}
//Usage //new Number = HasClientWeapon(Target, "weapon_ar2");
stock HasClientWeapon(Client, const String:WeaponName[])
{
	
	//Initialize:
	new Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
	
	new MaxGuns = 256;

	//Loop:
	for(new X = 0; X < MaxGuns; X = (X + 4))
	{
		
		//Initialize:
		new WeaponId = GetEntDataEnt2(Client, Offset + X);
		
		//Valid:
		if(WeaponId > 0)
		{
			new String:ClassName[32];
			GetEdictClassname(WeaponId, ClassName, sizeof(ClassName));
			if(StrEqual(ClassName, WeaponName))
			{
				
				return WeaponId;
			}
		}
	}	
	return -1;
}

stock GetPrimaryAmmo(client, weap) 
{   
    if(IsValidEntity(weap))
        return GetEntData(weap, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")); 
    return 0;
}

public SetPrimaryAmmo(entity, ammo)
{    
    if(IsValidEntity(entity))
        SetEntProp(entity, Prop_Send, "m_iClip1", ammo);
} 

stock GetWeaponAmmo(client, slot) 
{ 
    new ammoOffset = FindSendPropInfo("CHL2MP_Player", "m_iAmmo"); 
    return GetEntData(client, ammoOffset+(slot*4)); 
}  

stock SetEntityArmor(Client, Armor)
{
	SetEntProp(Client, Prop_Data, "m_ArmorValue", Armor, 4);	
}

stock SetEntitySpeed(Client, Float:fSpeed)
{
	SetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue", fSpeed);	
}

stock GiveWeapon(Client, const String:Stuff[])
{
	
	new String:Buffer[24][64];
	ExplodeString(Stuff, " ", Buffer, 24, 64);
	
	for(new X = 0; X < 23; X++)
	{
		if(!StrEqual(Buffer[X], ""))
		{
			rp_giveplayeritem(Client, Buffer[X])	
		}
	}
	
}
stock WeaponRemove(Client, MaxGuns)
{
	if(!IsClientInGame(Client)) return true;
	
	//Declare:
	decl Offset;
	decl WeaponId;
	
	//Initialize:
	Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
	
	
	//Loop:
	for(new X = 0; X < MaxGuns; X = (X + 4))
	{
		
		//Initialize:
		WeaponId = GetEntDataEnt2(Client, Offset + X);
		
		//Valid:
		if(WeaponId > 0)
		{
			
			//Weapon:
			RemovePlayerItem(Client, WeaponId);
			RemoveEdict(WeaponId);
		}
	}
	return true;
}

//Spawns a weapon
stock SpawnWeapon(client, String:weapon[32])
{

	new index = rp_createent(weapon);
	new Float:cllocation[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", cllocation);
	cllocation[2]+=20;
	rp_teleportent(index,cllocation, NULL_VECTOR, NULL_VECTOR);
	rp_dispatchspawn(index);

}

//Set Client Speed
stock SetSpeed(Client, Float:Speed)
{

	//Declare:
	decl SpeedOffset;
	
	//Initialize:
	SpeedOffset = FindSendPropOffs("CHL2MP_Player", "m_flMaxspeed");

	//Set Speed:
	if(SpeedOffset > 0) SetEntData(Client, SpeedOffset, Speed, 4, true);
}

//Gravity Gun:
public DefaultWeapon(Client)
{	
	//Give:
	rp_giveplayeritem(Client, "weapon_physcannon");
}