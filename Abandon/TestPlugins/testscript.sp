/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-05-26 14:49:07
 * @Last Modified time: 2023-06-02 18:49:20
 * @Github:             https://github.com/Paimon-Kawaii
 */
#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
// #include <l4d2tools>

public void OnPluginStart()
{
    CreateConVar("cv_test_str", "");
    RegConsoleCmd("sm_tst", Cmd_Test, "");
}

Action Cmd_Test(int client, any args)
{
    char result[64], code[1024];
    Format(code, sizeof(code), "<r>Convars.GetStr(\"cv_test_str\")</r>");
    // ExecuteVscript("<r>Convars.GetStr(\"cv_test_str\")</r>", result, sizeof(result));
    ExecuteVscript(code, result, sizeof(result));
    PrintToChatAll("result: %s", result);

    return Plugin_Handled;
}

bool ExecuteVscript(const char[] code, char[] result, int maxlength)
{
    int script = CreateEntityByName("logic_script");
    if(!IsValidEdict(script)) return false;
    DispatchSpawn(script);

    if((StrContains(code, "<r>") | StrContains(code, "</r>")) < 0) return false;

    char buffer[2048], put[1024];
    strcopy(buffer, sizeof(buffer), code);
    Format(put, sizeof(put), "NetProps.SetPropString(%d, \"m_iName\", ",
        EntIndexToEntRef(script), code);
    ReplaceString(buffer, sizeof(buffer), "<r>", put);
    ReplaceString(buffer, sizeof(buffer), "</r>", ");");
    SetVariantString(buffer);
    PrintToChatAll("%s", buffer);

    AcceptEntityInput(script, "RunScriptCode");
    GetEntPropString(script, Prop_Data, "m_iName", result, maxlength);

    AcceptEntityInput(script, "Kill");
    RemoveEdict(script);

    return true;
}

// bool ExecuteVscript(char[] code, char[] result, int maxlength)
// {
//     int script = CreateEntityByName("logic_script");
//     int button = CreateEntityByName("func_button_timed");
//     if(!IsValidEdict(script)) return false;
//     DispatchSpawn(script);

//     if((StrContains(code, "<r>") | StrContains(code, "</r>")) < 0) return false;

//     char buffer[1024], put[] = "Convars.SetValue(\"cv_test_str\", ";
//     Format(put, sizeof(put), put, button);
//     strcopy(buffer, sizeof(buffer), code);
//     ReplaceString(buffer, sizeof(buffer), "<r>", put);
//     ReplaceString(buffer, sizeof(buffer), "</r>", ");");
//     SetVariantString(buffer);

//     AcceptEntityInput(script, "RunScriptCode");
//     // GetEntPropString(button, Prop_Send, "m_sUseString", result, maxlength);
//     FindConVar("cv_test_str").GetString(result, maxlength);

//     GetEntPropString(1, Prop_Send, "m_playerName", result, maxlength);

//     PrintToChatAll("%s", buffer);

//     AcceptEntityInput(button, "Kill");
//     RemoveEdict(button);
//     AcceptEntityInput(script, "Kill");
//     RemoveEdict(script);

//     return true;
// }