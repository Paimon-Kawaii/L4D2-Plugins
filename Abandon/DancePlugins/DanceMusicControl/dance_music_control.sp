/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-03-22 17:38:54
 * @Last Modified time: 2023-07-14 23:12:16
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <fnemotes>
#include <sdktools>
#include <paiutils>
#include <sourcemod>
// #include <dhooks>
// #include <freecamera>
// #include <clientprefs>

#define VERSION "2023.03.22"
#define MAXSIZE 33

// int
//     g_iMusicPlayNow = -1,
//     g_iSoundEnt[MAXSIZE] = { -1, ... };

char
    g_sSoundName[MAXSIZE][128];

public Plugin myinfo =
{
    name = "Dance Music Control",
    author = "我是派蒙啊",
    description = "跳舞音乐控制",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

public void OnPluginStart()
{
    AddNormalSoundHook(SoundHook);

    // RegConsoleCmd("sm_dmt", Cmd_Test);
}

// Action Cmd_Test(int client, any args)
// {
//     for(int i = 1; i<=MaxClients; i++)
//         if(IsValidClient(i) && IsFakeClient(i))
//         {
//             PrintToChatAll("%N Play sound", i);
//             ClientCommand(i, "spk kodua/fortnite_emotes/Hip_Hop_Good_Vibes_Mix_01_Loop.mp3");
//         }

//     //ServerCommand("play kodua/fortnite_emotes/Hip_Hop_Good_Vibes_Mix_01_Loop.mp3");
//     return Plugin_Handled;
// }

public void fnemotes_OnEmote_Pre(int client)
{
    SetListenOverride(client, client, Listen_Yes);
    for(int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i) && fnemotes_IsClientEmoting(i) && PrecacheSound(g_sSoundName[i]))
            SetListenOverride(client, i, Listen_No);
}

Action SoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],
      int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
      char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    if(!IsValidEntity(entity) || flags == SND_STOP)
        return Plugin_Continue;

    int dance = GetEntPropEnt(entity, Prop_Send, "moveparent");
    if(!IsValidEntity(dance))
        return Plugin_Continue;

    char name[64];
    GetEntityClassname(dance, name, sizeof(name));
    // May not be dance ent, skip fetching.
    if(strcmp(name, "prop_dynamic") != 0) return Plugin_Continue;

    // Set sound level to no attenuation
    // level = SNDLEVEL_NONE;

    int client = -1;
    // Try get who is dancing
    for(int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i) && dance == GetEntPropEnt(i, Prop_Send, "moveparent"))
        { client = i; break; }
    if(!IsValidClient(client))
        return Plugin_Continue;

    // Get our camera
    // int camera = FC_GetClientCamera(client);
    // if(!IsValidEntity(camera)) // Check is a camera ent
    //     return Plugin_Continue;
    // If client is dancing and camera doesnt belong to her,dont play music to her.
    // Make sure player only heard her bgm when dancing.

    // g_iSoundEnt[client] = entity;
    strcopy(g_sSoundName[client], sizeof(sample), sample);
    PrecacheSound(sample);
    PrintToChatAll("%N play %s", client, sample);
    ClientCommand(client, "spk %s", sample);
    return Plugin_Stop;

    // PrintToChatAll("%s", sample);
    // PrintToChatAll("%s", soundEntry);

    // int total = 0;
    // flags = SND_STOP;
    // int[] soundHeards = new int[MAXPLAYERS];

    // for(int i = 0; i < MAXPLAYERS; i++)
    //     if(IsValidClient(clients[i]) && IsClientInGame(clients[i]))
    //     {
    //         if(fnemotes_IsClientEmoting(clients[i]) && client != clients[i])
    //             continue;
    //         soundHeards[total++] = clients[i];
    //     }

    // for(int i = 0; i < MAXPLAYERS; i++)
    //     clients[i] = soundHeards[i];
    // numClients = total;

    // g_iMusicPlayNow = client;
    // CreateTimer(1.0, Timer_PlayerDanceShow, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

    // return Plugin_Changed;
}

// Action Timer_PlayerDanceShow(Handle timer)
// {
//     if(!IsValidClient(g_iMusicPlayNow) || !fnemotes_IsClientEmoting(g_iMusicPlayNow))
//         return Plugin_Stop;

//     for(int i = 1; i <= MaxClients; i++)
//         if(IsValidClient(i) && !fnemotes_IsClientEmoting(i) && i != g_iMusicPlayNow)
//             PrintCenterText(i, "[Dance] 正在播放 %N 的音乐", g_iMusicPlayNow);

//     return Plugin_Continue;
// }