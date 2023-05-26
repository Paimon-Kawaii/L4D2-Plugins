/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-05-26 14:49:07
 * @Last Modified time: 2023-05-26 15:42:33
 * @Github:             https://github.com/Paimon-Kawaii
 */
#pragma semicolon 1
#pragma newdecls required

#include <l4d2tools>
#include <sdktools>
#include <sourcemod>

public void OnPluginStart()
{
    CreateConVar("cv_test_str", "default");
    RegConsoleCmd("sm_tst", Cmd_Test, "");
}

Action Cmd_Test(int client, any args)
{
    char result[64];
    ExecuteVscript("<r>Convars.GetStr(\"cv_test_str\")</r>", result, sizeof(result));
    PrintToChatAll("result: ", result);

    return Plugin_Handled;
}