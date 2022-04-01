#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <l4d2tools>
#include <sourcemod>
#include <left4dhooks>

#define VERSION "1.1.1"

public Plugin myinfo =
{
	name = "BafflingTanker",
	author = "我是派蒙啊",
	description = "诶哈哈哈哈，消耗克来喽",
	version = VERSION,
	url = "http://github.com/PaimonQwQ/L4D2-Plugins/bafflingtanker.sp",
};

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], 
	float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!IsTank(client) || !IsFakeClient(client)) return Plugin_Continue;
	if (IsTankHasView(client) && (buttons & IN_FORWARD))
	{
		buttons |= IN_ATTACK2;
		buttons &= ~IN_FORWARD;
		//return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action L4D2_OnSelectTankAttack(int client, int &sequence)
{
	if(!IsTank(client)) return Plugin_Continue;

	sequence = view_as<int>(TH_OverHead);
	return Plugin_Handled;
}