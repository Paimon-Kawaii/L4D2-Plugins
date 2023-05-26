/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-05-22 13:43:16
 * @Last Modified time: 2023-05-25 22:20:12
 * @Github:             https:// github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <l4d2tools>
#include <sourcemod>

public Plugin myinfo =
{
    name = "test laser",
    author = "我是派蒙啊",
    description = "",
    version = "",
    url = ""
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float ang[3])
{
    if (!IsValidClient(client)) return Plugin_Continue;

    if(buttons & IN_USE)
    {
        float pos[3];
        GetClientAbsOrigin(client, pos);

        Handle trace = TR_TraceRayFilterEx(pos, {-90.0, 0.0, 0.0}, MASK_SOLID, RayType_Infinite, SelfIgnore_TraceFilter);
        if(TR_DidHit(trace))
        {
            int flags = TR_GetSurfaceFlags(trace);
            // 不是天花板，取消接管
            if(!(flags & SURF_SKY) && !(flags & SURF_SKY2D))
            {
                PrintToChatAll("不是天花板");
                return Plugin_Continue;
            }
            PrintToChatAll("是天花板");
        }
    }
    return Plugin_Continue;
}

// 忽略自身碰撞
bool SelfIgnore_TraceFilter(int entity, int mask, int self)
{
    if(entity == self || IsValidClient(entity))
        return false;

    return true;
}