/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-11-20 13:24:45
 * @Last Modified time: 2023-11-22 10:14:02
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <paiutils>
#include <sdktools>
#include <sourcemod>

#define VERSION "2023.11.19"

Handle
    g_hCTerrorPlayer_TakeOverBot,
    g_hCTerrorPlayer_SetCharacter,
    g_hSurvivorBot_SetHumanSpectator,
    g_hNextBotCreatePlayerBot_SurvivorBot;

char
    g_sSurvivorModels[][] =
    {
        "models/survivors/survivor_gambler.mdl",    //Nick
        "models/survivors/survivor_producer.mdl",   //Rochelle
        "models/survivors/survivor_coach.mdl",      //Coach
        "models/survivors/survivor_mechanic.mdl",   //Ellis
        "models/survivors/survivor_namvet.mdl",     //Bill
        "models/survivors/survivor_teenangst.mdl",  //Zoey
        "models/survivors/survivor_biker.mdl",      //Francis
        "models/survivors/survivor_manager.mdl",    //Louis
    };

public Plugin myinfo =
{
    name = "SurvivorManager",
    author = "我是派蒙啊",
    description = "",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

//插件入口
public void OnPluginStart()
{
    CheckModel();
    InitGameData();
    AddCommandListener(SayClass_Callback, "say");
    AddCommandListener(SayClass_Callback, "say_team");
}

void InitGameData()
{
    GameData gamedata = new GameData("test_survivor");
    if (gamedata == null)
        SetFailState("Gamedata not found: \"test_survivor.txt\".");

    StartPrepSDKCall(SDKCall_Static);
    if(!PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "NextBotCreatePlayerBot<SurvivorBot>"))
    {
        LogError("Failed to find signature: \"NextBotCreatePlayerBot<SurvivorBot>\"");
    }
    else
    {
        PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
        PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Plain);
        g_hNextBotCreatePlayerBot_SurvivorBot = EndPrepSDKCall();
        if(g_hNextBotCreatePlayerBot_SurvivorBot == null)
            LogError("Failed to create SDKCall: \"CDirector::AddSurvivorBot\"");
    }

    StartPrepSDKCall(SDKCall_Player);
    if(!PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTerrorPlayer::TakeOverBot"))
    {
        LogError("Failed to find signature: \"CTerrorPlayer::TakeOverBot\"");
    }
    else
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
        g_hCTerrorPlayer_TakeOverBot = EndPrepSDKCall();
        if(g_hCTerrorPlayer_TakeOverBot == null)
            LogError("Failed to create SDKCall: \"CTerrorPlayer::TakeOverBot\"");
    }

    StartPrepSDKCall(SDKCall_Player);
    if(!PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "SurvivorBot::SetHumanSpectator"))
    {
        LogError("Failed to find signature: \"SurvivorBot::SetHumanSpectator\"");
    } else {
        PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
        PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
        g_hSurvivorBot_SetHumanSpectator = EndPrepSDKCall();
        if(g_hSurvivorBot_SetHumanSpectator == null)
            LogError("Failed to create SDKCall: \"SurvivorBot::SetHumanSpectator\"");
    }

    StartPrepSDKCall(SDKCall_Player);
    if(!PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTerrorPlayer::SetCharacter"))
    {
        LogError("Failed to find signature: \"CTerrorPlayer::SetCharacter\"");
    }
    else
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        g_hCTerrorPlayer_SetCharacter = EndPrepSDKCall();
        if(g_hCTerrorPlayer_SetCharacter == null)
            LogError("Failed to create SDKCall: \"CTerrorPlayer::SetCharacter\"");
    }

    delete gamedata;
}

int SDKCall_NextBotCreatePlayerBot_SurvivorBot(const char[] name)
{
    return SDKCall(g_hNextBotCreatePlayerBot_SurvivorBot, name);
}

bool SDKCall_CTerrorPlayer_TakeOverBot(int client, bool joinSurvivor = true)
{
    return SDKCall(g_hCTerrorPlayer_TakeOverBot, client, joinSurvivor);
}

void SDKCall_CTerrorPlayer_SetCharacter(int client, int character)
{
    SDKCall(g_hCTerrorPlayer_SetCharacter, client, character);
}

void SDKCall_SurvivorBot_SetHumanSpectator(int bot, int client)
{
    SDKCall(g_hSurvivorBot_SetHumanSpectator, bot, client);
}

//预加载模型
void CheckModel()
{
    for(int i = 0; i < 8; i++)
    {
        if(!IsModelPrecached(g_sSurvivorModels[i]))
            PrecacheModel(g_sSurvivorModels[i]);
    }
}

//拦截Say
Action SayClass_Callback(int client, char[] command, int args)
{
    char say[MAX_NAME_LENGTH];
    GetCmdArg(1, say, sizeof(say));
    
    if((say[0] != '!' && say[0] != '/') || strlen(say) > 2)
        return Plugin_Continue;

    int index = -1;
    char name = CharToLower(say[1]);

    switch(name)
    {
        case 'n':
            index = 0;
        case 'r':
            index = 1;
        case 'c':
            index = 2;
        case 'e':
            index = 3;
        case 'b':
            index = 4;
        case 'z':
            index = 5;
        case 'f':
            index = 6;
        case 'l':
            index = 7;
    }

    if(index == -1)
        return Plugin_Continue;

    SDKCall_CTerrorPlayer_SetCharacter(client, index);
    SetEntityModel(client, g_sSurvivorModels[index]);

    return Plugin_Continue;
}

bool JoinSurvivor(int client)
{
    if(!IsSpectator(client)) return false;

    int bot = SDKCall_NextBotCreatePlayerBot_SurvivorBot("Bot");
    ChangeClientTeam(bot, TEAM_SURVIVOR);
    SetEntProp(bot, Prop_Send, "m_lifeState", 1);
    SetEntProp(bot, Prop_Send, "deadflag", 0);
    DispatchSpawn(bot);
    SDKCall_SurvivorBot_SetHumanSpectator(bot, client);
    SDKCall_CTerrorPlayer_TakeOverBot(client);

    return IsSurvivor(client);
}