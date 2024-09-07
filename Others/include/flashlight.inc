/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-03-22 19:08:40
 * @Last Modified time: 2024-01-04 23:14:22
 * @Github:             https://github.com/Paimon-Kawaii
 */

#if defined _flashlight_included_
#endinput
#endif
#define _flashlight_included_

/* Natives */

/**
 * Is flash light on.
 *
 * @param client    Client index
 * @return          True / False
 */
native bool FL_IsLightOn(int client);

/**
 * When a client's light on
 *
 * @param client    Client index
 */
forward void OnPlayerLightOn(int client);

/**
 * When a client's light off
 *
 * @param client    Client index
 */
forward void OnPlayerLightOff(int client);

public SharedPlugin:__pl_freecamera =
{
    name = "flashlight",
    file = "l4d_flashlight.smx",
    #if defined REQUIRE_PLUGIN
    required = 1,
    #else
    required = 0,
    #endif
};

public void __pl_flashlight_SetNTVOptional()
{
    MarkNativeAsOptional("FL_IsLightOn");
}