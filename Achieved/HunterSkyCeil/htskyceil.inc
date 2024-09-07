/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-03-22 19:08:40
 * @Last Modified time: 2023-06-26 22:10:19
 * @Github:             https://github.com/Paimon-Kawaii
 */

#if defined _htskyceil_included_
#endinput
#endif
#define _htskyceil_included_

/**
 * Is hunter flying ceil.
 *
 * @param client    Client index
 * @return          True / False
 */
native bool HSC_IsFlyingCeil(int client);

/**
 * Is hunter try to pounce from ceil.
 *
 * @param client    Client index
 * @return          True / False
 */
native bool HSC_IsAttemptPounce(int client);

/**
 * Is hunter controllable.
 *
 * @param client    Client index
 * @return          True / False
 */
native bool HSC_IsControllable(int client);

public SharedPlugin:__pl_freecamera =
{
    name = "htskyceil",
    file = "hunter_skyceil.smx",
    #if defined REQUIRE_PLUGIN
    required = 1,
    #else
    required = 0,
    #endif
};

public void __pl_freecamera_SetNTVOptional()
{
    MarkNativeAsOptional("HSC_IsFlyingCeil");
}