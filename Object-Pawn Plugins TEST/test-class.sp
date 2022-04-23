/*
 * @Author:             派蒙
 * @Last Modified by:   派蒙
 * @Create Date:        2022-04-21 08:18:59
 * @Last Modified time: 2022-04-23 16:19:00
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <dynamic>

methodmap TestClass < Dynamic
{
    public TestClass()
    {
        return view_as<TestClass>(Dynamic());
    }

    public int TestFunc(int a, int b)
    {
        return a > b ? a : b;
    }

    property int TestInt
    {
        public get()
        {
            return this.GetInt("TestInt");
        }
        public set(int value)
        {
            this.SetInt("TestInt", value);
        }
    }
}

TestClass
    g_cTest;

public void OnPluginStart()
{
    g_cTest = TestClass();
    g_cTest.TestInt = 1;

    RegConsoleCmd("sm_test", Cmd_TestInt, "TEST");
}

public Action Cmd_TestInt(int client, any args)
{
    char arg[16];
    switch(args)
    {
        case 1:
        {
            GetCmdArg(1, arg, sizeof(arg));
            int i = StringToInt(arg);
            g_cTest.TestInt = i;
        }
        case 2:
        {
            GetCmdArg(1, arg, sizeof(arg));
            int a = StringToInt(arg);
            GetCmdArg(2, arg, sizeof(arg));
            int b = StringToInt(arg);
            PrintToChat(client, "%d", g_cTest.TestFunc(a, b));
        }
        default:
        {
            PrintToChat(client, "%d", g_cTest.TestInt);
        }
    }

    return Plugin_Continue;
}
