/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-03-22 19:08:40
 * @Last Modified time: 2023-05-26 16:59:03
 * @Github:             https://github.com/Paimon-Kawaii
 */

#if defined _hunterfloor_included_
#endinput
#endif
#define _hunterfloor_included_

/**
 * Is hunter flying floor.
 *
 * @param client    Client index
 * @return          True / False
 */
native bool HF_IsFlyingFloor(int client);

public SharedPlugin:__pl_freecamera =
{
    name = "hunterfloor",
    file = "hunter_floor.smx",
    #if defined REQUIRE_PLUGIN
    required = 1,
    #else
    required = 0,
    #endif
};

public void __pl_freecamera_SetNTVOptional()
{
    MarkNativeAsOptional("HF_IsFlyingFloor");
}