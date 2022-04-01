/*
 * @Author:             派蒙
 * @Last Modified by:   派蒙
 * @Create Date:        2022-03-25 17:19:27
 * @Last Modified time: 2022-03-25 17:21:50
 * @Github:             
 */

public void OnPluginStart()
{
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	ServerCommand("sm_startspawn");
    return Plugin_Continue;
}
