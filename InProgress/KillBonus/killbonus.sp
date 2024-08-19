/**
 * @Author: 我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date: 2024-08-17 20:15:07
 * @Last Modified time: 2024-08-19 16:43:18
 * @Github: https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#define DEBUG 0

#include <paiutils>

#define VERSION "2024.08.17#33"

public Plugin myinfo =
{
    name = "KillBonus",
    author = "我是派蒙啊",
    description = "",
    version = VERSION,
    url = "https://github.com/Paimon-Kawaii"
};

#define MAXSIZE MAXPLAYERS + 1

float
    BonusTime[MAXSIZE];

int
    BonusScore[MAXSIZE];

#define BONUS_TIME 3.0

public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart);
    HookEvent("player_death", Event_PlayerDeath);
}

void Event_RoundStart(Event event, const char[] name, bool dontBoardcast)
{
    for (int i = 0; i < MAXSIZE; i++)
        BonusScore[i] = 0;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBoardcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (!IsSurvivor(attacker) || !IsInfected(victim)) return;

    bool headshot = event.GetBool("headshot");
    if (BonusTime[attacker] < GetGameTime()) BonusScore[attacker] /= 2;
    BonusTime[attacker] = GetGameTime() + BONUS_TIME;
    BonusScore[attacker] += headshot ? 2 : 1;

    if (BonusScore[attacker] > 3)
        CreateBonusBar(attacker);
}

void CreateBonusBar(int client)
{
    DataPack dp = new DataPack();
    int clip = 2;
    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (HasEntProp(weapon, Prop_Send, "m_iClip1"))
        clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
    if (clip < 2) clip = 2;
    dp.WriteCell(client);
    dp.WriteFloat(BONUS_TIME);
    dp.WriteFloat(BONUS_TIME);
    dp.WriteFloat(GetGameTime());
    dp.WriteCell(clip);
    dp.Reset();

    RequestFrame(HandleBonusBar, dp);
    PrintHintText(client, "BONUS TIME !!");
}

void HandleBonusBar(DataPack data)
{
    int client = data.ReadCell();
    float bonus_time = data.ReadFloat();
    float duration = data.ReadFloat();
    float last_time = data.ReadFloat();
    int clip = data.ReadCell();
    data.Reset(true);
    if (duration <= 0.0)
    {
        SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
        SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
        BonusTime[client] = GetGameTime() + BONUS_TIME;
        BonusScore[client] = 0;
        delete data;
        return;
    }

    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime() - duration);
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", bonus_time);

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_upgradeBitVec"))
    {
        // m_upgradeBitVec
        // 燃烧：0b001
        // 高爆：0b010
        // 激光：0b100
        SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
        SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", view_as<int>(0b101));
        SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", clip);
    }
    duration -= GetGameTime() - last_time;
    data.WriteCell(client);
    data.WriteFloat(bonus_time);
    data.WriteFloat(duration);
    data.WriteFloat(GetGameTime());
    data.WriteCell(clip);
    data.Reset();

    RequestFrame(HandleBonusBar, data);
}