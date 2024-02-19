/*
 * @Author: 我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date: 2024-02-06 15:17:44
 * @Last Modified time: 2024-02-17 11:44:33
 * @Github: https://github.com/Paimon-Kawaii
 */
#if defined _debugdraw_included
    #endinput
#endif
#define _debugdraw_included

stock void DebugDrawCross(const float origin[3])
{
    static const char command[] = "drawcross";
    int flag = GetCommandFlags(command);
    if (flag & FCVAR_CHEAT)
        SetCommandFlags(command, flag & (~FCVAR_CHEAT));

    ServerCommand("%s %f %f %f", command, origin[0], origin[1], origin[2]);
}

stock void DebugDrawLine(const float from[3], const float to[3])
{
    static const char command[] = "drawline";
    int flag = GetCommandFlags(command);
    if (flag & FCVAR_CHEAT)
        SetCommandFlags(command, flag & (~FCVAR_CHEAT));

    ServerCommand("%s %f %f %f %f %f %f", command, from[0], from[1], from[2], to[0], to[1], to[2]);
}

stock void DebugDrawVOXBox(const float from[3], const float to[3])
{
    static const char command[] = "voxeltree_box";
    int flag = GetCommandFlags(command);
    if (flag & FCVAR_CHEAT)
        SetCommandFlags(command, flag & (~FCVAR_CHEAT));

    ServerCommand("%s %f %f %f %f %f %f", command, from[0], from[1], from[2], to[0], to[1], to[2]);
}

stock void DebugDrawBox(const float from[3], const float to[3])
{
    static const char command[] = "box";
    int flag = GetCommandFlags(command);
    if (flag & FCVAR_CHEAT)
        SetCommandFlags(command, flag & (~FCVAR_CHEAT));

    ServerCommand("%s %f %f %f %f %f %f", command, from[0], from[1], from[2], to[0], to[1], to[2]);
}

stock void DebugDrawRay(int client)
{
    static const char command[] = "cast_ray";
    int flag = GetCommandFlags(command);
    if (flag & FCVAR_CHEAT)
        SetCommandFlags(command, flag & (~FCVAR_CHEAT));

    ClientCommand(clinet, "%s", command);
}

stock void DebugDrawHull(int client)
{
    static const char command[] = "cast_hull";
    int flag = GetCommandFlags(command);
    if (flag & FCVAR_CHEAT)
        SetCommandFlags(command, flag & (~FCVAR_CHEAT));

    ClientCommand(clinet, "%s", command);
}