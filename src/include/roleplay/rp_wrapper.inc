/** Double-include prevention */
#if defined _rp_wrapper_included_
  #endinput
#endif
#define _rp_wrapper_included_

native rp_gettime();
native rp_emitsoundring(Client);
native rp_stopsoundring(Client);
native rp_emitsound(Client,String:str[]);
native rp_entclienttarget(Client,bool:bo);
native rp_entacceptinput(Ent,String:str[],Ent2=-1);
native rp_teleportent(entity, const Float:origin[3], const Float:angles[3], const Float:velocity[3]);
native rp_dispatchspawn(Ent);
native rp_createent(String:str[]);
native rp_dispatchkeyvalue(Ent, String:str[],String:str2[]);
native rp_entmodel(Ent,String:str[]);
native rp_forcesuicide(Client);
native rp_removeweapons(Client);
native rp_geteyes(Client,Float:ang[3]);
native rp_sendtoclient(Client);
native rp_giveplayeritem(Client,String:str[]);
native rp_equipplayerweapon(Client,Ent);
native rp_setupbeamringpoint(Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:Amplitude,Color[4], Speed, Flags);
native rp_setupbeampoint(Float:start[3], Float:end[3], ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, Color[4], Speed);