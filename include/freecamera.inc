/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-03-22 19:08:40
 * @Last Modified time: 2023-05-26 16:59:45
 * @Github:             https://github.com/Paimon-Kawaii
 */

#if defined _freecamera_included_
#endinput
#endif
#define _freecamera_included_

/* Natives */

/**
 * Get client's free camera
 *
 * @param client    Client index
 * @return          Entity index of client's camera
 */
native int FC_GetClientCamera(int client);

/**
 * Set client's free camera
 *
 * @param client    Client index
 * @param camera    Camera's entity index
 * @return          True / False
 */
// native bool FC_SetClientCamera(int client, int camera);

/**
 * Is client camera available.
 *
 * @param client    Client index
 * @return          True / False
 */
native bool FC_IsClientCameraAvailable(int client);

/**
 * Is client camera activied.
 *
 * @param client    Client index
 * @return          True / False
 */
native bool FC_IsClientCameraActive(int client);

/**
 * When a client's free camera actived
 *
 * @param client    Client index
 * @return          Plugin_Handled or Plugin_Stop to block player from activing her free camera,
 *                  Plugin_Changed to change the player who will active the free camera, Plugin_Continue otherwise.
 */
forward Action FC_OnPlayerCameraActived(int &client);

/**
 * When a client's free camera actived
 *
 * @param client    Client index
 */
forward void FC_OnPlayerCameraActived_Post(int client);

/**
 * When a client's free camera deactived
 *
 * @param client    Client index
 * @return          Plugin_Handled or Plugin_Stop to block player from deactiving her free camera,
 *                  Plugin_Changed to change the player who will deactive the free camera, Plugin_Continue otherwise.
 */
forward Action FC_OnPlayerCameraDeactived(int &client);

/**
 * When a client's free camera deactived
 *
 * @param client    Client index
 */
forward void FC_OnPlayerCameraDeactived_Post(int client);

public SharedPlugin:__pl_freecamera =
{
    name = "freecamera",
    file = "free_camera.smx",
    #if defined REQUIRE_PLUGIN
    required = 1,
    #else
    required = 0,
    #endif
};

public void __pl_freecamera_SetNTVOptional()
{
    MarkNativeAsOptional("FC_GetClientCamera");
    // MarkNativeAsOptional("FC_SetClientCamera");
    MarkNativeAsOptional("FC_IsClientCameraAvailable");
    MarkNativeAsOptional("FC_IsClientCameraActive");
}