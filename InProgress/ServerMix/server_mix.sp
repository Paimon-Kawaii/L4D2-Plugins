/*
 * @Author: 我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date: 2024-09-06 22:30:02
 * @Last Modified time: 2024-09-07 00:01:35
 * @Github: https://github.com/Paimon-Kawaii
 */

#define DEBUG      0

#define PL_NAME    "Server Mix"
#define PL_AUTHOR  "我是派蒙啊"
#define PL_DESC    " "
#define PL_VERSION "0.0.1.1"
#define PL_URL     "https://github.com/Paimon-Kawaii"

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = PL_NAME,
    author = PL_AUTHOR,
    description = PL_DESC,
    version = PL_VERSION,
    url = PL_URL
};

#include <paiutils>
#define MAXSIZE MAXPLAYERS + 1

public void OnPluginStart()
{
}