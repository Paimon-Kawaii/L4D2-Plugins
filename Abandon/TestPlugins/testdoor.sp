/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-12-08 22:55:03
 * @Last Modified time: 2023-12-09 09:34:54
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <paiutils>
#include <left4dhooks>

#define UNLOCK 0
#define LOCK 1

public Plugin myinfo =
{
    name = "Test",
    author = "我是派蒙啊",
    description = "",
    version = "",
    url = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_td", Cmd_TD);
    RegConsoleCmd("sm_td2", Cmd_TD2);
}

// public void OnMapStart()
// {
//     int door = L4D_GetCheckpointFirst();
//     ControlDoor(door, LOCK);
//     door = L4D_GetCheckpointLast();
//     ControlDoor(door, LOCK);
// }

Action Cmd_TD(int client, int args)
{
    int door = L4D_GetCheckpointFirst();
    SetVariantFloat(0.0);
    AcceptEntityInput(door, "SetSpeed");
    // AcceptEntityInput(door, "Disable");

    // PrintToChatAll("door1:%d", GetEntProp(door, Prop_Send, "m_eDoorState"));
    // ControlDoor(door, UNLOCK);
    // PrintToChatAll("door1:%d", GetEntProp(door, Prop_Send, "m_eDoorState"));
    // door = L4D_GetCheckpointLast();
    // ControlDoor(door, UNLOCK);
}

Action Cmd_TD2(int client, int args)
{
    int door = L4D_GetCheckpointFirst();
    SetVariantFloat(200.0);
    AcceptEntityInput(door, "SetSpeed");
    // AcceptEntityInput(door, "Enable");

    // PrintToChatAll("door2:%d", GetEntProp(door, Prop_Send, "m_eDoorState"));
    // ControlDoor(door, LOCK);
    // PrintToChatAll("door2:%d", GetEntProp(door, Prop_Send, "m_eDoorState"));
    // door = L4D_GetCheckpointLast();
    // ControlDoor(door, LOCK);
}

void ControlDoor(int entity, int iOperation)
{
    switch (iOperation)
    {
        case LOCK:
        {
            AcceptEntityInput(entity, "Close");
            AcceptEntityInput(entity, "Lock");
            AcceptEntityInput(entity, "ForceClosed");
            
            if (HasEntProp(entity, Prop_Data, "m_hasUnlockSequence"))
            { 
                SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", LOCK);
            } 
        }
        case UNLOCK:
        {
            if (HasEntProp(entity, Prop_Data, "m_hasUnlockSequence"))
            { 
                SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", UNLOCK); 
            } 

            AcceptEntityInput(entity, "Unlock"); 
            AcceptEntityInput(entity, "ForceClosed"); 
            AcceptEntityInput(entity, "Open"); 
        }
    }
}