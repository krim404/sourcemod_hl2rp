//Roleplay v3.0 Client Class
//Idea and first implementations by Joe 'Pinkfairie' Maley
//Programmed by Christian 'Krim' Uhl 
//Licence: Creative Commons BY-NC-SA
//http://creativecommons.org/licenses/by-nc-sa/3.0/


//Includes:
#include "roleplay/COLORS"
#include "roleplay/rp_include"
#include "roleplay/rp_main"
#include "roleplay/rp_hud"

//Initation:
public OnPluginStart()
{
	RegConsoleCmd("sm_stats", CommandStats);
	RegConsoleCmd("sm_tracers", CommandLasers);
}

public Action:CommandStats(Client, Args)
{
	rp_hud_show_stats(Client,30);
	return Plugin_Handled;
}

public Action:CommandLasers(Client, Args)
{
	CPrintToChat(Client, "{red}[RP]\x04 Tracers are toggled\x04");
	rp_hud_laser(Client);
	return Plugin_Handled;
}

