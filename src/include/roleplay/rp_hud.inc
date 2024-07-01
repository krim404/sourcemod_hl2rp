/** Double-include prevention */
#if defined _rp_hud_included_
  #endinput
#endif
#define _rp_hud_included_

native rp_notice(Client,String:Text[]);
native rp_notice_all(String:Text[]);
native rp_notice_all_except_client(Client,String:Text[]);

native rp_hud_money(Client,String:Text[]);
native rp_hud_bank(Client,String:Text[]);
native rp_hud_stats(Client);
native rp_hud_show_stats(Client,time);
native rp_hud_timer(Client,Time,String:Text[]);

native rp_hud_laser(Client);
native rp_hud_stats_enabled(Client,On);

native rp_setNotice(Ent,String:Text[],String:Subtext[],String:Thirdtext[]);
native rp_setNpcNotice(Ent,String:Text[]);
native rp_remNotice(Client,Ent);
native rp_saveNotice(Client,Ent);
native rp_saveNpcNotice(Client,Ent);


native rp_hud_get_police(stat);
native rp_hud_get_metal(stat);
native rp_hud_get_metal_tracer(stat);
native rp_hud_get_policeupgrade(stat);
native rp_hud_get_crime(stat);
native rp_hud_get_moneyhud(stat);
native rp_hud_get_crimehud(stat);
native rp_hud_get_calibrate(stat);

native rp_hud_set_calibrate(Client, bool:value);
native rp_hud_set_police(Client, bool:value);
native rp_hud_set_metal(Client, bool:value);
native rp_hud_set_metal_tracer(Client, bool:value);
native rp_hud_set_policeupgrade(Client, bool:value);
native rp_hud_set_crime(Client, bool:value);
native rp_hud_set_moneyhud(Client, bool:value);
native rp_hud_set_crimehud(Client, bool:value);
native rp_hud_set_color(Client,R,G,B);

native GetPhoneEnabledNative(Client);
native SetPhoneEnabledNative(Client, bool:Buffer);
	
native rp_setfirst(Ent,String:Text[]);
native rp_setsub(Ent,String:Text[]);
native rp_setthird(Ent,String:Text[]);

native rp_notify(Client, String:Text[], any:... );
