/*
 * @Author: 我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date: 2024-02-02 19:02:53
 * @Last Modified time: 2024-02-02 19:09:45
 * @Github: https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <paiutils>
#include <sdktools>
#include <sourcemod>

#define VERSION "2024.02.02"

public Plugin myinfo =
{
	name = "LagRecall",
	author = "我是派蒙啊",
	description = "修正高延迟射击",
	version = VERSION,
	url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

#define DEBUG	0

#define MAXSIZE MAXPLAYERS + 1

public void OnPlayerRunCmdPost(int client, int buttons)
{
}