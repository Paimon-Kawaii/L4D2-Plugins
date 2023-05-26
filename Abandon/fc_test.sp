/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-03-25 23:53:33
 * @Last Modified time: 2023-03-25 23:59:52
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <l4d2tools>
#include <sourcemod>
#include <freecamera>

#define VERSION "2023.03.25"
#define MAXSIZE 33

public Plugin myinfo =
{
    name = "Free Camera Native Test",
    author = "我是派蒙啊",
    description = "freecamera测试Native",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

public Action FC_OnPlayerCameraActived(int &client)
{
    PrintToChatAll("%N 激活自由相机", client);
    for(int i = 1; i <= MaxClients; i++)
        if(IsSurvivor(i) && IsFakeClient(i))
            { client = i; break; }

    if(!IsFakeClient(client)) return Plugin_Handled;

    return Plugin_Changed;
}

public void FC_OnPlayerCameraActived_Post(int client)
{
    PrintToChatAll("%N 激活了自由相机", client);
}

public Action FC_OnPlayerCameraDeactived(int &client)
{
    PrintToChatAll("%N 退出自由相机", client);
    for(int i = 1; i <= MaxClients; i++)
        if(IsSurvivor(i) && IsFakeClient(i))
            { client = i; break; }

    if(!IsFakeClient(client)) return Plugin_Handled;

    return Plugin_Changed;
}

public void FC_OnPlayerCameraDeactived_Post(int client)
{
    PrintToChatAll("%N 退出了自由相机", client);
}