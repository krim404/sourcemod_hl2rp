//Roleplay v3.0 Wrapper
//Idea and first implementations by Joe 'Pinkfairie' Maley
//Programmed by Christian 'Krim' Uhl 
//Licence: GPLv2

#include <sdktools>
new Handle:hRemoveItems;
new Handle:hGameConf;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{	
	CreateNative("rp_emitsoundring", native_emitsoundring);
	CreateNative("rp_emitsound", native_emitsound);
	CreateNative("rp_stopsoundring", native_stopsound);
	CreateNative("rp_entclienttarget", native_cliententtarget);
	CreateNative("rp_entacceptinput", native_clientacceptinput);
	CreateNative("rp_teleportent", native_teleportent);
	CreateNative("rp_dispatchspawn", native_dispatchspawn);
	CreateNative("rp_equipplayerweapon", native_equipplayerweapon);
	CreateNative("rp_createent", native_createent);
	CreateNative("rp_dispatchkeyvalue", native_dispatchkeyvalue);
	CreateNative("rp_entmodel",native_entmodel);
	CreateNative("rp_forcesuicide",native_forcesuicide);
	CreateNative("rp_setupbeampoint",native_setupbeampoints);
	CreateNative("rp_setupbeamringpoint",native_setupbeamringpoints);
	CreateNative("rp_sendtoclient",native_sendtoclient);
	CreateNative("rp_giveplayeritem",native_giveplayeritem);
	CreateNative("rp_removeweapons", native_removeweapons);
	CreateNative("rp_geteyes", native_geteyes);
	CreateNative("rp_gettime", native_gettime);
	return APLRes_Success;
}

public native_gettime(Handle:plugin, numParams)
{
	return GetTime();
}
public native_emitsoundring(Handle:plugin, numParams)	
{
	EmitSoundToClient(GetNativeCell(1), "roleplay/ring.wav", SOUND_FROM_PLAYER, 5);
}

public native_stopsound(Handle:plugin, numParams)	
{
	StopSound(GetNativeCell(1), 5, "roleplay/ring.wav");
}

public native_forcesuicide(Handle:plugin, numParams)	
{
	ForcePlayerSuicide(GetNativeCell(1));
}

public native_cliententtarget(Handle:plugin, numParams)	
{
	return GetClientAimTarget(GetNativeCell(1), GetNativeCell(2));
}

public native_equipplayerweapon(Handle:plugin, numParams)	
{
	EquipPlayerWeapon(GetNativeCell(1), GetNativeCell(2));
}


public native_clientacceptinput(Handle:plugin, numParams)	
{
	new String:str[255];
	GetNativeString(2, str, sizeof(str));
	AcceptEntityInput(GetNativeCell(1), str, GetNativeCell(3)); 
}

public native_emitsound(Handle:plugin, numParams)	
{
	new String:str[255];
	GetNativeString(2, str, sizeof(str));
	EmitSoundToClient(GetNativeCell(1), str, SOUND_FROM_PLAYER, 5);
}

public native_createent(Handle:plugin, numParams)	
{
	new String:str[255];
	GetNativeString(1, str, sizeof(str));
	return CreateEntityByName(str); 
}

public native_entmodel(Handle:plugin, numParams)	
{
	new String:str[255];
	GetNativeString(2, str, sizeof(str));
	SetEntityModel(GetNativeCell(1),str); 
}

public native_giveplayeritem(Handle:plugin, numParams)	
{
	new String:str[255];
	GetNativeString(2, str, sizeof(str));
	GivePlayerItem(GetNativeCell(1),str); 
}

public native_teleportent(Handle:plugin, numParams)	
{
	new Float:origin[3],Float:angles[3],Float:velocity[3];
	GetNativeArray(2,origin,3);
	GetNativeArray(3,angles,3);
	GetNativeArray(4,velocity,3);
	TeleportEntity(GetNativeCell(1),origin,angles,velocity);
}

public native_dispatchspawn(Handle:plugin, numParams)	
{
	DispatchSpawn(GetNativeCell(1));
}

public native_sendtoclient(Handle:plugin, numParams)	
{
	TE_SendToClient(GetNativeCell(1));
}


public native_dispatchkeyvalue(Handle:plugin, numParams)	
{
	new String:str[255],String:str2[255];
	GetNativeString(2, str, sizeof(str));
	GetNativeString(3, str2, sizeof(str2));
	DispatchKeyValue(GetNativeCell(1),str,str2)
}

public native_removeweapons(Handle:plugin, numParams)
{
	SDKCall(hRemoveItems, GetNativeCell(1), false);
}

public native_setupbeampoints(Handle:plugin, numParams)	
{
	new Float:start[3], Float:end[3], Color[4];
	
	GetNativeArray(1,start,3);
	GetNativeArray(2,end,3);
	GetNativeArray(12,Color,4);
	
	TE_SetupBeamPoints(start,end,GetNativeCell(3),GetNativeCell(4),GetNativeCell(5),GetNativeCell(6),GetNativeCell(7),GetNativeCell(8),GetNativeCell(9),GetNativeCell(10),GetNativeCell(11),Color,GetNativeCell(13));
}

public native_setupbeamringpoints(Handle:plugin, numParams)	
{
	new Float:center[3], Color[4];
	
	GetNativeArray(1,center,3);
	GetNativeArray(12,Color,4);
	TE_SetupBeamRingPoint(center,GetNativeCell(2),GetNativeCell(3),GetNativeCell(4),GetNativeCell(5),GetNativeCell(6),GetNativeCell(7),GetNativeCell(8),GetNativeCell(9),GetNativeCell(10),Color,GetNativeCell(12),GetNativeCell(13));
}

public native_geteyes(Handle:plugin, numParams)	
{
	new Client = GetNativeCell(1);
	new Float:ang[3];
	
	GetClientEyeAngles(Client,ang);
	SetNativeArray(2,ang,3);
}

public OnPluginStart()
{
	hGameConf = LoadGameConfigFile("roleplay.gamedata");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RemoveAllItems");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hRemoveItems = EndPrepSDKCall();
}