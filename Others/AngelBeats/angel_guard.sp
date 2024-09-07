/*
 * @Author:             派蒙
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2022-03-24 17:00:57
 * @Last Modified time: 2023-07-14 23:12:16
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <menus>
#include <colors>
#include <sdktools>
#include <paiutils>
#include <sourcemod>
#include <keyvalues>
#include <left4dhooks>

#define MAXSIZE 33
#define VERSION "2022.07.18"
#define MENU_DISPLAY_TIME 15

int
    g_iKidneySold[MAXSIZE],
    g_iMealTickets[MAXSIZE],
    g_iRecordHapless[MAXSIZE];

enum Msgs
{
    Msg_Buy = 0,
    Msg_Lottery,
    Msg_NotEnough,
};//Message enums for message array(as an index)

char
    g_sInfoPath[PLATFORM_MAX_PATH],
    g_sMeleeName[][] = { "无近战","武士刀", "斧头", "小刀", "砍刀", "马格南", "物理学圣剑", },
    g_sMessages[][] =
    {
        "[{olive}Guard{default}] {blue}%N{default} 花费{olive}%d{default}饭票购买了%s",
        "[{olive}Guard{default}] {blue}%N {default}抽奖获得了{olive}%s",
        "[{olive}Guard{default}] 你没有饭票啦，快去学校抢一些吧",
    };

public Plugin myinfo =
{
    name = "AngelGuard",
    author = "我是派蒙啊",
    description = "AngelServer的商店插件",
    version = VERSION,
    url = "http://github.com/PaimonQwQ/L4D2-Plugins/AngelBeats"
};

//插件入口
public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDead);
    HookEvent("finale_win", Event_ResetTickets);
    //HookEvent("mission_lost", Event_ResetTickets);
    HookEvent("map_transition", Event_ResetTickets);

    BuildPath(Path_SM, g_sInfoPath, sizeof(g_sInfoPath), "data/AngelPlayer.txt");

    RegConsoleCmd("sm_buy", Cmd_GuardBuy, "Show guard menu");
    RegConsoleCmd("sm_rpg", Cmd_GuardBuy, "Show guard menu");
    RegAdminCmd("sm_miku", Cmd_MiKuMiKu, ADMFLAG_GENERIC, "Give ticket");
    RegAdminCmd("sm_ticket", Cmd_GiveTicket, ADMFLAG_GENERIC, "Give ticket");
}

//地图加载
public void OnMapStart()
{
    InitTickets();
}

//玩家正在连接
public void OnClientConnected(int client)
{
    g_iMealTickets[client] = 0;
}

//玩家断开连接
public void OnClientDisconnect(int client)
{
    g_iMealTickets[client] = 0;
}

//玩家离开安全屋给予近战
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
    for(int i = 1; i < MaxClients; i++)
        if (IsSurvivor(i) && IsPlayerAlive(i) && !IsFakeClient(i))
            GiveMelee(i);
    return Plugin_Continue;
}

//特感&生还死亡事件
public Action Event_PlayerDead(Event event, const char[] name, bool dont_broadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (IsInfected(client) && IsSurvivor(attacker) && !IsFakeClient(attacker) && IsPlayerAlive(attacker))
    {
        ZCLASSES zclass = view_as<ZCLASSES>(GetInfectedClass(client));
        if (zclass == ZC_Charger)
            g_iMealTickets[attacker] += 4;
        else if (zclass == ZC_Hunter)
            g_iMealTickets[attacker] += 3;
        else if (zclass == ZC_Jockey)
            g_iMealTickets[attacker] += 2;
        else if (zclass == ZC_Witch)
            g_iMealTickets[attacker] += 5;
        else if (zclass != ZC_Tank)
            g_iMealTickets[attacker] += 1;
    }
    return Plugin_Continue;
}

//重置饭票数量
public Action Event_ResetTickets(Event event, const char[] name, bool dont_broadcast)
{
    InitTickets();
}

//商店菜单命令
public Action Cmd_GuardBuy(int client, any args)
{
    if (!IsSurvivor(client))
        return Plugin_Handled;

    Event_CreateGuardMenu(client);
    return Plugin_Handled;
}

//MiKuMiKu~~
public Action Cmd_MiKuMiKu(int client, any args)
{
    ClientCommand(client, "sm_ticket 520");
    return Plugin_Handled;
}

//管理员作弊指令
public Action Cmd_GiveTicket(int client, any args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    char arg[16];
    int target = client;
    switch(args)
    {
        case 1:
        {
            GetCmdArg(1, arg, sizeof(arg));
            g_iMealTickets[target] = StringToInt(arg);
        }
        case 2:
        {
            GetCmdArg(1, arg, sizeof(arg));
            target = StringToInt(arg);
            GetCmdArg(2, arg, sizeof(arg));
            g_iMealTickets[target] = StringToInt(arg);
        }
    }

    return Plugin_Handled;
}

//创建GuardMenu
public Action Event_CreateGuardMenu(int client)
{
    if (!IsSurvivor(client)) return Plugin_Handled;
    Menu menu = new Menu(Handle_ExecGuardMenu);
    menu.SetTitle("Guard商店：%d 饭票", g_iMealTickets[client]);
    menu.AddItem("Weapon", "武器商店");
    menu.AddItem("Health", "补给商店");
    menu.AddItem("Melee",  "近战补给");
    menu.AddItem("Lottery",  "抽奖转盘");
    menu.Pagination = MENU_NO_PAGINATION;
    menu.ExitButton = true;
    menu.Display(client, MENU_DISPLAY_TIME);

    return Plugin_Handled;
}

//创建WeaponMenu
public Action Event_CreateWeaponMenu(int client)
{
    if (!IsSurvivor(client)) return Plugin_Handled;
    Menu menu = new Menu(Handle_ExecWeaponMenu);
    menu.SetTitle("Guard商店：%d 饭票", g_iMealTickets[client]);
    menu.AddItem("0", "子弹(0饭票)");
    menu.AddItem("20", "UZI(20饭票)");
    menu.AddItem("20", "SMG(20饭票)");
    menu.AddItem("30", "木喷(30饭票)");
    menu.AddItem("30", "铁喷(30饭票)");
    menu.AddItem("100", "AWP(100饭票)");
    menu.AddItem("150", "榴弹(150饭票)");
    menu.AddItem("200", "M60(200饭票)");
    menu.Pagination = MENU_NO_PAGINATION;
    menu.ExitButton = true;
    menu.Display(client, MENU_DISPLAY_TIME);

    return Plugin_Handled;
}

//创建HealthMenu
public Action Event_CreateHealthMenu(int client)
{
    if (!IsSurvivor(client)) return Plugin_Handled;
    Menu menu = new Menu(Handle_ExecHealthMenu);
    menu.SetTitle("Guard商店：%d 饭票", g_iMealTickets[client]);
    menu.AddItem("40", "止痛药(40饭票)");
    menu.AddItem("40", "肾上腺素(40饭票)");
    menu.AddItem("100", "急救包(100饭票)");
    menu.AddItem("100", "电击器(100饭票)");
    menu.AddItem("120", "红外升级(120饭票)");
    menu.AddItem("520", "麻婆豆腐(520饭票)");
    menu.Pagination = MENU_NO_PAGINATION;
    menu.ExitButton = true;
    menu.Display(client, MENU_DISPLAY_TIME);

    return Plugin_Handled;
}

//创建MeleePanel
public Action Event_CreateMeleePanel(int client)
{
    if (!IsSurvivor(client)) return Plugin_Handled;
    char str[256];
    Panel panel = new Panel();
    Format(str, 256, "Guard商店：%d 饭票", g_iMealTickets[client]);
    panel.SetTitle(str);

    GetClientAuthId(client, AuthId_Steam2, str, 32, true);
    strcopy(str, 256, g_sMeleeName[GetMeleeFromPlayerInfo(str)]);

    Format(str, 256, "当前近战：%s", str);
    panel.DrawText(str);
    panel.DrawItem("切换近战");

    panel.Send(client, Handle_ExecMeleePanel, MENU_DISPLAY_TIME);
    delete panel;

    return Plugin_Handled;
}

//创建ChoiceMenu
public Action Event_CreateChoiceMenu(int client)
{
    if (!IsSurvivor(client)) return Plugin_Handled;
    Menu menu = new Menu(Handle_ExecChoiceMenu);
    menu.SetTitle("Guard商店：%d 饭票", g_iMealTickets[client]);
    menu.AddItem("None", "无近战");
    menu.AddItem("Katana", "武士刀");
    menu.AddItem("Fireaxe", "斧头");
    menu.AddItem("Knife", "小刀");
    menu.AddItem("Machete", "砍刀");
    menu.AddItem("Magnum", "马格南");
    menu.AddItem("Crowbar", "物理学圣剑");
    menu.Pagination = MENU_NO_PAGINATION;
    menu.ExitButton = true;
    menu.Display(client, MENU_DISPLAY_TIME);

    return Plugin_Handled;
}

//创建LotteryMenu
public Action Event_CreateLotteryMenu(int client)
{
    if (!IsSurvivor(client)) return Plugin_Handled;
    Menu menu = new Menu(Handle_ExecLotteryMenu);
    menu.SetTitle("大大大大大转盘：%d 饭票", g_iMealTickets[client]);
    menu.AddItem("Start", "开始抽奖(12饭票)");
    menu.AddItem("Kill", "噶腰子(获取饭票)");
    menu.AddItem("Record", "吃保底(看看你有多非)");
    menu.Pagination = MENU_NO_PAGINATION;
    menu.ExitButton = true;
    menu.Display(client, MENU_DISPLAY_TIME);

    return Plugin_Handled;
}

//处理Guard列表事件
public int Handle_ExecGuardMenu(Menu menu, MenuAction action, int client, int item)
{
    if (!IsSurvivor(client)) return 0;
    if (action != MenuAction_Select) return 0;
    if (item == 0) Event_CreateWeaponMenu(client);
    if (item == 1) Event_CreateHealthMenu(client);
    if (item == 2) Event_CreateMeleePanel(client);
    if (item == 3) Event_CreateLotteryMenu(client);

    return 1;
}

//处理Weapon列表事件
public int Handle_ExecWeaponMenu(Menu menu, MenuAction action, int client, int item)
{
    if (!IsSurvivor(client)) return 0;
    if (action != MenuAction_Select) return 0;

    int ticket;
    char info[32];
    menu.GetItem(item, info, sizeof(info));
    ticket = StringToInt(info);

    switch(item)
    {
        case 0:
        {
            BypassAndExecuteCommand(client, "give", "ammo");
        }
        case 1:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                g_iMealTickets[client] -= ticket;
                BypassAndExecuteCommand(client, "give", "smg");
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "UZI");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
        case 2:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                g_iMealTickets[client] -= ticket;
                BypassAndExecuteCommand(client, "give", "smg_silenced");
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "SMG");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
        case 3:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                BypassAndExecuteCommand(client, "give", "pumpshotgun");
                g_iMealTickets[client] -= ticket;
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "木喷");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
        case 4:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                g_iMealTickets[client] -= ticket;
                BypassAndExecuteCommand(client, "give", "shotgun_chrome");
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "铁喷");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
        case 5:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                g_iMealTickets[client] -= ticket;
                BypassAndExecuteCommand(client, "give", "sniper_awp");
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "AWP");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
        case 6:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                g_iMealTickets[client] -= ticket;
                BypassAndExecuteCommand(client, "give", "grenade_launcher");
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "榴弹");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
        case 7:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                g_iMealTickets[client] -= ticket;
                BypassAndExecuteCommand(client, "give", "rifle_m60");
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "M60");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
    }

    return 1;
}

//处理Health列表事件
public int Handle_ExecHealthMenu(Menu menu, MenuAction action, int client, int item)
{
    if (!IsSurvivor(client)) return 0;
    if (action != MenuAction_Select) return 0;

    int ticket;
    char info[32];
    menu.GetItem(item, info, sizeof(info));
    ticket = StringToInt(info);

    switch(item)
    {
        case 0:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                g_iMealTickets[client] -= ticket;
                BypassAndExecuteCommand(client, "give", "pain_pills");
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "止痛药");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
        case 1:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                g_iMealTickets[client] -= ticket;
                BypassAndExecuteCommand(client, "give", "adrenaline");
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "肾上腺素");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
        case 2:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                BypassAndExecuteCommand(client, "give", "first_aid_kit");
                g_iMealTickets[client] -= ticket;
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "急救包");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
        case 3:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                g_iMealTickets[client] -= ticket;
                BypassAndExecuteCommand(client, "give", "defibrillator");
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "电击器");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
        case 4:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                g_iMealTickets[client] -= ticket;
                BypassAndExecuteCommand(client, "upgrade_add", "laser_sight");
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "红外");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
        case 5:
        {
            if (g_iMealTickets[client] >= ticket)
            {
                g_iMealTickets[client] -= ticket;
                SetPlayerHealth(client, 5200);
                L4D2_UseAdrenaline(client, 13140.0);
                CPrintToChatAll(g_sMessages[Msg_Buy], client, ticket, "麻婆豆腐");
            }
            else CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        }
    }

    return 1;
}

//处理Melee面板事件
public int Handle_ExecMeleePanel(Menu menu, MenuAction action, int client, int item)
{
    if (!IsSurvivor(client)) return 0;
    if (action != MenuAction_Select) return 0;
    if (item == 1) Event_CreateChoiceMenu(client);

    return 1;
}

//处理Choice列表事件
public int Handle_ExecChoiceMenu(Menu menu, MenuAction action, int client, int item)
{
    if (!IsSurvivor(client) || IsFakeClient(client)) return 0;
    if (action != MenuAction_Select) return 0;
    if (item > 5) return 0;

    char str[256];
    GetClientAuthId(client, AuthId_Steam2, str, 32, true);

    KeyValues PlayerInfo = new KeyValues("PlayerInfo");
    PlayerInfo.ImportFromFile(g_sInfoPath);
    PlayerInfo.JumpToKey(str, true);
    IntToString(item, str, sizeof(str));
    PlayerInfo.SetString("melee", str);
    GetClientName(client, str, 256);
    PlayerInfo.SetString("name", str);
    PlayerInfo.Rewind();
    PlayerInfo.ExportToFile(g_sInfoPath);
    delete PlayerInfo;

    return 1;
}

//处理Guard列表事件
public int Handle_ExecLotteryMenu(Menu menu, MenuAction action, int client, int item)
{
    if (!IsSurvivor(client)) return 0;
    if (action != MenuAction_Select) return 0;
    if (item == 0) StartLottery(client);
    if (item == 1 && L4D_HasAnySurvivorLeftSafeArea() && IsPlayerAlive(client) && !IsPlayerIncap(client))
    {
        g_iKidneySold[client]++;
        int ticket = GetRandomInt(10, 20);
        g_iMealTickets[client] += ticket;
        SDKHooks_TakeDamage(client, client, client, 20.0);
        CPrintToChatAll("[{olive}Guard{default}] {blue}%N {olive}噶掉了她的第%d个腰子，兑换了%d饭票", client, g_iKidneySold[client], ticket);
    }
    if (item == 2) CPrintToChat(client, "[{olive}Guard{default}] {default}你还需要{lime}%d{default}抽才能吃大保底", 40 - g_iRecordHapless[client]);
    Event_CreateLotteryMenu(client);

    return 1;
}

//初始化饭票
void InitTickets()
{
    for(int i = 1; i < MaxClients; i++)
        g_iMealTickets[i] = g_iRecordHapless[i] = g_iKidneySold[i] = 0;
}

//获取近战类型
int GetMeleeFromPlayerInfo(const char[] steamid)
{
    KeyValues PlayerInfo = new KeyValues("PlayerInfo");
    PlayerInfo.ImportFromFile(g_sInfoPath);

    if (!PlayerInfo.JumpToKey(steamid))
    {
        delete PlayerInfo;
        return 0;
    }

    char melee[256];
    PlayerInfo.GetString("melee", melee, 256);
    delete PlayerInfo;
 
    return StringToInt(melee);
}

void StartLottery(int client)
{
    if(g_iMealTickets[client] < 12)
    {
        CPrintToChat(client, g_sMessages[Msg_NotEnough]);
        return;
    }

    g_iMealTickets[client] -= 12;
    g_iRecordHapless[client]++;
    if (g_iRecordHapless[client] >= 40)
    {
        SetPlayerHealth(client, 5200);
        L4D2_UseAdrenaline(client, 13140.0);
        g_iRecordHapless[client] = 0;
        CPrintToChatAll("[{olive}Guard{default}] {blue}%N {olive}吃保底啦", client);
        return;
    }
    int random = GetRandomInt(1, 100);
    if (random <= 40)
    {
        random = GetRandomInt(1, 80);
        if (random <= 5)
        {
            SetPlayerHealth(client, 5200);
            L4D2_UseAdrenaline(client, 13140.0);
            g_iRecordHapless[client] = 0;
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "麻婆豆腐");
        }
        else if(random <= 20)
        {
            BypassAndExecuteCommand(client, "give", "sniper_awp");
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "AWP");
        }
        else if(random <= 35)
        {
            BypassAndExecuteCommand(client, "upgrade_add", "LASER_SIGHT");
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "激光升级");
        }
        else if(random <= 50)
        {
            BypassAndExecuteCommand(client, "upgrade_add", "INCENDIARY_AMMO");
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "燃烧弹升级");
        }
        else if(random <= 65)
        {
            BypassAndExecuteCommand(client, "upgrade_add", "EXPLOSIVE_AMMO");
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "爆炸弹升级");
        }
        else
        {
            g_iMealTickets[client] += 48;
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "48饭票");
        }
    }
    else
    {
        random = GetRandomInt(1, 100);
        if (random <= 30)
        {
            CPrintToChat(client, "[{olive}Guard{default}] 谢谢参与！");
            return;
        }
        else if (random <= 40)
        {
            BypassAndExecuteCommand(client, "give", "smg_silenced");
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "SMG");
        }
        else if (random <= 50)
        {
            BypassAndExecuteCommand(client, "give", "smg");
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "UZI");
        }
        else if (random <= 60)
        {
            BypassAndExecuteCommand(client, "give", "first_aid_kit");
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "急救包");
        }
        else if (random <= 70)
        {
            BypassAndExecuteCommand(client, "give", "defibrillator");
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "电击器");
        }
        else if (random <= 80)
        {
            BypassAndExecuteCommand(client, "give", "pain_pills");
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "止痛药");
        }
        else if (random <= 90)
        {
            BypassAndExecuteCommand(client, "give", "adrenaline");
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "肾上腺素");
        }
        else if (random <= 100)
        {
            BypassAndExecuteCommand(client, "give", "ammo");
            CPrintToChatAll(g_sMessages[Msg_Lottery], client, "弹药补充");
        }
    }
}

void GiveMelee(int client)
{
    if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client))
        return;

    char str[256];
    GetClientAuthId(client, AuthId_Steam2, str, 32, true);
    switch(GetMeleeFromPlayerInfo(str))
    {
        case 0:
        {
            return;
        }
        case 1:
        {
            BypassAndExecuteCommand(client, "give", "katana");
        }
        case 2:
        {
            BypassAndExecuteCommand(client, "give", "fireaxe");
        }
        case 3:
        {
            BypassAndExecuteCommand(client, "give", "knife");
        }
        case 4:
        {
            BypassAndExecuteCommand(client, "give", "machete");
        }
        case 5:
        {
            BypassAndExecuteCommand(client, "give", "pistol_magnum");
        }
        case 6:
        {
            BypassAndExecuteCommand(client, "give", "crowbar");
        }
        default:
        {
            return;
        }
    }

    KeyValues PlayerInfo = new KeyValues("PlayerInfo");
    PlayerInfo.ImportFromFile(g_sInfoPath);
    if (PlayerInfo.JumpToKey(str))
    {
        GetClientName(client, str, 256);
        PlayerInfo.SetString("name", str);
        PlayerInfo.Rewind();
        PlayerInfo.ExportToFile(g_sInfoPath);
    }
    delete PlayerInfo;
}