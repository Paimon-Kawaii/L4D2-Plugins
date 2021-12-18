#include <sourcemod>

public Plugin myinfo =
{
    name = "RPG MysqlHelper",
    author = "我是派蒙啊",
    description = "用于帮助RPG插件自动建表与初始化玩家数据",
    version = "0.1.1",
    url = ""
};

new String:createTable[512] = "create table if not exists `l4d2` (`steam_id` text, `steam_name` text, `LELVEL_DATA` int, `Str_DATA` int, `MELEE_DATA` int, `BLOOD_DATA` int,  `End_DATA` int, `MONEY_DATA` int, `Health_DATA` int, `Agi_DATA` int, `StatusPoint_DATA` int) engine = InnoDB default charset = utf8mb4 collate = utf8mb4_bin";

public void OnPluginStart()
{
	MYSQL_INIT();
	RegConsoleCmd("sm_pw", MoneyCmd, "", 0);
}

//玩家登录后初始化数据库
public void OnClientConnected(client)
{
	if (!IsFakeClient(client))
	{
		MYSQL_INSERT(client);
	}
}

public Action:MoneyCmd(client, args)
{
	ShowMoney();
}

//如果不存在l4d2，则自动建表
MYSQL_INIT()
{
	char error[256];
	new Handle:annedb = SQL_DefConnect(error, sizeof(error), false);
	new DBStatement:preCreate = SQL_PrepareQuery(annedb, createTable, error, 256);
	
	if (!preCreate)
	{
		PrintToServer("[Paimon] Warning - 准备出错：%s", error);
		return;
	}
	
	SQL_Query(annedb, createTable);
}

//插入初始玩家数据
MYSQL_INSERT(client)
{
	char error[256];
	char steamId[256];
	char steamName[256];
	new String:insertValues[512];
	GetClientName(client, steamName, 256);
	GetClientAuthId(client, AuthId_Steam2, steamId, 32, true);
	Format(insertValues, 512, "INSERT INTO `l4d2`(`steam_id`, `steam_name`, `LELVEL_DATA`, `Str_DATA`,`MELEE_DATA`,`BLOOD_DATA`,`End_DATA`, `MONEY_DATA`,`Health_DATA`,`Agi_DATA`,`StatusPoint_DATA`) VALUES ('%s',`%s`,'0','0','0','0','0','1000','0','0','0');", steamId, steamName);
	
	new Handle:annedb = SQL_DefConnect(error, sizeof(error), false);
	new DBStatement:preCreate = SQL_PrepareQuery(annedb, createTable, error, 256);
	
	if (!preCreate)
	{
		PrintToServer("[Paimon] Warning - 准备出错：%s", error);
		return;
	}
	
	SQL_Query(annedb, insertValues);
	CloseHandle(annedb);
}

void ShowMoney()
{
	char error[256];
	char steamId[256];
	char steamName[256];
	new String:selectMoney[512];
	
	new DBStatement:preSelect;
	new DBResultSet:dbResultSet;	
	new DBResult:dbResult = DBVal_Null;
	new Handle:annedb = SQL_DefConnect(error, sizeof(error), false);
	new DBStatement:preCreate = SQL_PrepareQuery(annedb, createTable, error, 256);
	
	if (!preCreate)
	{
		PrintToServer("[Paimon] Warning - 准备出错：%s", error);
		return;
	}
	
	PrintToChatAll("\x05┌────┬─────────┬──┬──────┐");
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsFakeClient(client))
		{
			GetClientName(client, steamName, 256);
			GetClientAuthId(client, AuthId_Steam2, steamId, 32, true);
			Format(selectMoney, 512, "SELECT `MONEY_DATA` FROM `l4d2` WHERE `steam_id` = '%s'", steamId);
			preSelect = SQL_PrepareQuery(annedb, selectMoney, error, 256);
			int test = SQL_Execute(preSelect);
			PrintToChatAll("Test1 %d", test);
			int money = SQL_FetchInt(preSelect, 0, dbResult);
			PrintToChatAll("Test2 %d", money);
			PrintToChatAll("\x05│玩家│\x04%-16s\x05│B数│\x04%-12d\x05│", steamName, money);
			PrintToChatAll("\x05├────┼─────────┼──┼──────┤");
		}
	}
	PrintToChatAll("\x05└────┴─────────┴──┴──────┘");
	CloseHandle(annedb);
}