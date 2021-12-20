#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <topmenus>
#include <adminmenu>
#include <sdktools>
#include <sourcemod>

#define VERSION "0.3.3"
#define MENU_DISPLAY_TIME 15

Handle
	AdminMenu = INVALID_HANDLE;

TopMenuObject
	SpecMenu = INVALID_TOPMENUOBJECT,
	PlayerCMDMenu = INVALID_TOPMENUOBJECT;

public Plugin myinfo =
{
    name = "ForceSpec",
    author = "我是派蒙啊",
    description = "为AdminMenu添加强迫玩家旁观操作",
    version = VERSION,
    url = "http://anne.paimeng.ltd/l4d2_plugins/l4d_forcespec.sp"
};

public void OnPluginStart()
{
	if (LibraryExists("adminmenu") && (GetAdminTopMenu() != INVALID_HANDLE))
		OnAdminMenuReady(GetAdminTopMenu());
}
				/*	########################################
							SourceModHookEvent:START==>
				########################################	*/

//AdminMenuReadyEvent
public void OnAdminMenuReady(Handle topmenu)
{
	if(AdminMenu == topmenu)
		return;
	AdminMenu = topmenu;
	PlayerCMDMenu = FindTopMenuCategory(AdminMenu, "PlayerCommands");
	if(PlayerCMDMenu == INVALID_TOPMENUOBJECT) return;
	SpecMenu = AddToTopMenu(AdminMenu, "spec_menu", TopMenuObject_Item, SpecMenuItemHandler, PlayerCMDMenu);
}

//创建SpecMenu
public Action CreateSpecMenu(int client)
{
	Handle menu = CreateMenu(SpecMenuHandle);
	SetMenuTitle(menu, "ForceSpec player:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	AddTargetsToMenu(menu, 0);
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}

				/*	########################################
							HandleFunctions:START==>
				########################################	*/

//创建菜单内容
public void SpecMenuItemHandler(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int client, char[] buffer, int maxlength)
{
	if(action == TopMenuAction_DisplayOption)
		if (topobj_id == SpecMenu)
			Format(buffer, maxlength, "ForceSpec player");
	if (action == TopMenuAction_SelectOption)
		if (topobj_id == SpecMenu)
			CreateSpecMenu(client);
}

//处理列表事件
public int SpecMenuHandle(Menu menu, MenuAction action, int client, int item)
{
	char useridStr[255];
	int target = -1, userid;
	if(!IsValidClient(client)) return 0;
	if(action != MenuAction_Select) return 0;
	GetMenuItem(menu, item, useridStr, 255);
	userid = StringToInt(useridStr, userid);
	target = GetClientOfUserId(userid);
	if(!IsValidClient(target) || IsFakeClient(target) || GetClientTeam(target) == 1) return 0;
	CPrintToChatAll("{olive}[Paimon] {orange}笨比 %N {lightgreen}被管理强制旁观啦！", target);
	ChangeClientTeam(target, 1);

	return 1;
}

				/*	########################################
							<==HandleFunctions:END
				########################################	*/


				/*	########################################
							OtherFunctions:START==>
				########################################	*/

//Client是否正确
bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

				/*	########################################
							<==OtherFunctions:END
				########################################	*/