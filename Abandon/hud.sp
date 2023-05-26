/*
 * @Author:             派蒙
 * @Last Modified by:   派蒙
 * @Create Date:        2022-05-23 22:12:25
 * @Last Modified time: 2022-05-27 12:00:01
 * @Github:             http://github.com/PaimonQwQ
 */

public void OnPluginStart()
{
    RegConsoleCmd("sm_shud", Cmd_ShowSpecHud, "Show spectator hud");
}

public Action Cmd_ShowSpecHud(int client, any args)
{
    char arg[4];
    GetCmdArg(1, arg, sizeof(arg));//m_bNightVisionOn
    SetEntProp(client, Prop_Send, "m_iHideHUD", StringToInt(arg));
    return Plugin_Handled;
}
