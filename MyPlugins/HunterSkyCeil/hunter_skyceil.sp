/*
 * @Author:             我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date:        2023-05-22 13:43:16
 * @Last Modified time: 2024-02-02 19:16:08
 * @Github:             https:// github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <paiutils>
#include <sdktools>
#include <sourcemod>

#define DEBUG		0
#define DEBUG_RAY	0
#define VERSION		"2023.07.25#12"

#define MAXSIZE		MAXPLAYERS + 1
#define TRACE_TICK	100
#define POUNCE_TICK 10

#if DEBUG_RAY
int g_iRayCallTimes = 0;
#endif

ConVar
	g_hHSCHuman,
	g_hHSCLimit,
	g_hHTEnhance,
	g_hHSCEnable,
	g_hHSCStopDis,
	g_hHSCMaxLeap,
	g_hHSCResetInv,

	g_hGravity,
	g_hLungePower;

int
	// 天花板ht数量
	g_iCeilHunterCount = 0,
	// 用于记录ht起飞次数，避免不停尝试
	g_iLeapTimes[MAXSIZE] = { 0, ... },
	// 用于记录上次射线的tick，用于设置间隔
	g_iLastRayTick[MAXSIZE] = { 0, ... },
	// 仅用于记录ht目标，便于查找
	g_iPounceTarget[MAXSIZE] = { 0, ... },
	// 用于记录生还被谁瞄准并设定目标
	g_iTargetWhoAimed[MAXSIZE] = { 0, ... },
	// 记录上次使用技能的tick，用于设置间隔
	g_iLastPounceTick[MAXSIZE] = { 0, ... };

bool
	// 标记ht是否在飞天花板
	g_bIsFlyingCeil[MAXSIZE] = { false, ... },
	// 用于标记是否允许使用天花板高扑
	g_bIsControllable[MAXSIZE] = { false, ... },
	// 用于标记ht是否准备从天花板突袭
	g_bIsAttemptPounce[MAXSIZE] = { false, ... },
	// 用于标记头顶是否是天花板
	g_bIsCeilAvaliable[MAXSIZE] = { false, ... };

float
	// 用于修正抛物线速度
	g_fPounceSpeed[MAXSIZE][2];

public Plugin myinfo =
{
	name = "Hunter flies sky ceil",
	author = "我是派蒙啊",
	description = "让 AI Hunter 飞天花板",
	version = VERSION,
	url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
};

// 注册ConVar
public void OnPluginStart()
{
	g_hHSCStopDis = CreateConVar("hsc_stop_dis", "600", "停止飞天花板距离", FCVAR_NONE, true, 0.0);
	g_hHSCMaxLeap = CreateConVar("hsc_max_leap", "3", "HT起飞的最大尝试次数", FCVAR_NONE, true, 0.0);
	g_hHSCEnable = CreateConVar("hsc_enable", "1", "允许HT弹天花板", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hHSCHuman = CreateConVar("hsc_human", "0", "允许玩家HT弹天花板", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hHSCResetInv = CreateConVar("hsc_reset_interval", "4.0", "重置起飞次数的时钟间隔", FCVAR_NONE, true, 0.0);
	g_hHSCLimit = CreateConVar("hsc_limit", "0", "允许HT弹天花板的数量，0=不限制", FCVAR_NONE, true, 0.0, true, 32.0);

	g_hLungePower = FindConVar("z_lunge_power");
	g_hLungePower.SetInt(600);

	g_hLungePower.AddChangeHook(ConVarChanged_LungePower);
	g_hHSCEnable.AddChangeHook(ConVarChanged_LungePower);
	g_hHSCHuman.AddChangeHook(ConVarChanged_LungePower);

	AutoExecConfig(true, "hunter_skyceil");
	HookEvent("player_spawn", Event_PlayerSpawn);
#if DEBUG_RAY
	CreateTimer(1.0, Timer_ShowRayCallTimes, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
#endif
}

#if DEBUG_RAY
Action Timer_ShowRayCallTimes(Handle timer)
{
	PrintToChatAll("times: %d", g_iRayCallTimes);
	g_iRayCallTimes = 0;

	return Plugin_Continue;
}
#endif

// 判断速度是否可以飞天花板
void ConVarChanged_LungePower(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_hLungePower.FloatValue > 930 && g_hHSCEnable.BoolValue)
		g_hHSCEnable.SetBool(false);
	if (g_hLungePower.FloatValue > 680 && g_hHSCHuman.BoolValue)
		g_hHSCHuman.SetBool(false);
}

// 设置是否接管ht
void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int hunter = GetClientOfUserId(event.GetInt("userid"));
	if (!IsInfected(hunter) || GetZombieClass(hunter) != ZC_Hunter || g_iCeilHunterCount >= GetAliveSurvivorCount())
		return;
	g_bIsControllable[hunter] = true;
}

// 获取ConVar
public void OnAllPluginsLoaded()
{
	g_hGravity = FindConVar("sv_gravity");
	g_hHTEnhance = FindConVar("ai_hunter_angle_mean");
	//取消插件的通知属性
	if (g_hHTEnhance != INVALID_HANDLE)
		g_hHTEnhance.Flags &= ~FCVAR_NOTIFY;
}

// 注册依赖
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("htskyceil");
	CreateNative("HSC_IsFlyingCeil", Native_IsFlyingCeil);
	CreateNative("HSC_IsControllable", Native_IsControllable);
	CreateNative("HSC_IsAttemptPounce", Native_IsAttemptPounce);

	return APLRes_Success;
}

// 地图加载时重置信息
public void OnMapStart()
{
	g_iCeilHunterCount = 0;
	for (int i = 0; i <= MaxClients; i++)
	{
		g_iLeapTimes[i] = g_iPounceTarget[i] =
			g_iLastRayTick[i] = g_iTargetWhoAimed[i] =
				g_iLastPounceTick[i] = 0;

		g_bIsFlyingCeil[i] = g_bIsControllable[i] =
			g_bIsCeilAvaliable[i] = g_bIsAttemptPounce[i] = false;

		g_fPounceSpeed[i][0] = g_fPounceSpeed[i][1] = 0.0;
	}
}

// 接管ht
public Action OnPlayerRunCmd(int hunter, int &buttons, int &impulse, float vel[3], float ang[3])
{
#if DEBUG
	if (GetEntityMoveType(hunter) == MOVETYPE_NOCLIP)
		return Plugin_Continue;
#endif

	// 插件关闭 或 达到最大起飞次数 或 数量超过设定上限，不接管ht
	if (!g_hHSCEnable.BoolValue || !g_bIsControllable[hunter] || g_iLeapTimes[hunter] >= g_hHSCMaxLeap.IntValue || (g_hHSCLimit.BoolValue && g_iCeilHunterCount >= g_hHSCLimit.IntValue))
		return Plugin_Continue;

	// ht死亡时 或 控制生还时
	if (!IsPlayerAlive(hunter) || IsPinningSurvivor(hunter))
	{
		if (IsPinningSurvivor(hunter))
		{
			// 修正控制的玩家(突袭可能被旁边的生还吸走XD)
			g_iTargetWhoAimed[GetPinningSurvivor(hunter)] = hunter;
			g_iPounceTarget[hunter] = GetPinningSurvivor(hunter);
		}
		else {
			// 死亡时释放目标
			g_iTargetWhoAimed[g_iPounceTarget[hunter]] = 0;
			g_iPounceTarget[hunter] = 0;
		}
		// 修正天花板ht的数量
		if (g_bIsControllable[hunter])
			g_iCeilHunterCount = g_iCeilHunterCount > 0 ? g_iCeilHunterCount - 1 : 0;
		// 重置起飞次数
		g_iLeapTimes[hunter] = 0;
		// 取消ht的天花板标记
		g_bIsControllable[hunter] = false;
		// 取消标记pounce
		g_bIsAttemptPounce[hunter] = false;
		// 标记天花板为可不用
		g_bIsCeilAvaliable[hunter] = false;
		// 修正技能tick
		g_iLastPounceTick[hunter] = GetGameTickCount();

		return Plugin_Continue;
	}

	// 是否在地面上
	bool isgrounded = GetEntPropEnt(hunter, Prop_Send, "m_hGroundEntity") != -1;

	// 当ht落地时，标记pounce为false
	// P.S.这个东西的目的是为了后面高扑完成也就是落地后不再接管ht
	if (isgrounded)
	{
		g_bIsFlyingCeil[hunter] = g_bIsAttemptPounce[hunter] = false;
		// 修正3方增强插件(音理提供)
		if (g_hHTEnhance != INVALID_HANDLE)
			g_hHTEnhance.SetInt(30);
	}

	// 玩家ht是否允许接管操作(速度高于680时玩家ht无法飞天花板)
	if (!IsFakeClient(hunter) && (!g_hHSCHuman.BoolValue || g_hLungePower.FloatValue > 680))
		return Plugin_Continue;

	float htpos[3];
	GetClientAbsOrigin(hunter, htpos);

	// 在地面上 且是 ai-ht 且 到达检测间隔时，检测头顶是否为天花板
	if (isgrounded && IsFakeClient(hunter) && GetGameTickCount() - g_iLastRayTick[hunter] >= TRACE_TICK)
	{
		g_iLastRayTick[hunter] = GetGameTickCount();
		Handle trace = TR_TraceRayFilterEx(htpos, { -90.0, 0.0, 0.0 },
										   MASK_SOLID, RayType_Infinite, SelfIgnore_TraceFilter);

#if DEBUG_RAY
		g_iRayCallTimes++;
#endif

		if (TR_DidHit(trace))
		{
			int flags = TR_GetSurfaceFlags(trace);
			delete trace;
			// 检测是否为天花板 并 标记
			g_bIsCeilAvaliable[hunter] = false;
			if (!(flags & SURF_SKY) && !(flags & SURF_SKY2D))
				return Plugin_Continue;
			g_bIsCeilAvaliable[hunter] = true;
		}
		delete trace;
	}

	// 天花板不可用 且是 ai-ht 时，取消接管
	if (!g_bIsCeilAvaliable[hunter] && IsFakeClient(hunter))
		return Plugin_Continue;

	// 让 ai-ht 瞄准生还
	if (IsFakeClient(hunter))
	{
		bool result = TryAimSurvivor(hunter);
		if (!result)
			return Plugin_Continue;

		// 修正 ai-ht 的btn指令
		buttons |= IN_ATTACK;
		buttons &= ~IN_ATTACK2;
	}

	// 玩家ht需要先使用一次技能
	bool canfly = IsFakeClient(hunter) || view_as<bool>(GetEntProp(GetEntPropEnt(hunter, Prop_Send, "m_customAbility"), Prop_Send, "m_hasBeenUsed"));

	int oldbtns = GetEntProp(hunter, Prop_Data, "m_nOldButtons");
	// 当ht在弹天花板 且 btn包含atk指令 且 pounce间隔达到pounce_tick，取消btn的atk指令
	if (!isgrounded && (buttons & IN_ATTACK) && (oldbtns & IN_ATTACK) && g_bIsFlyingCeil[hunter] && GetGameTickCount() - g_iLastPounceTick[hunter] >= POUNCE_TICK)
	{
		// 记录突袭时间
		g_iLastPounceTick[hunter] = GetGameTickCount();
		buttons &= ~IN_ATTACK;
	}

	float velocity[3];
	// 当btn包含atk指令 且 ht 在地面上
	if ((buttons & IN_ATTACK) && isgrounded && !g_bIsFlyingCeil[hunter] && canfly)
	{
		// 起飞次数+1
		if (IsFakeClient(hunter))
			g_iLeapTimes[hunter]++;
		// 达到最大尝试次数，启动重置时钟
		if (g_iLeapTimes[hunter] >= g_hHSCMaxLeap.IntValue)
			CreateTimer(g_hHSCResetInv.FloatValue,
						Timer_ResetLeapTimes, hunter, TIMER_FLAG_NO_MAPCHANGE);

		// 给予ht 6666的垂直速度使ht可以飞到天花板上XD
		velocity[0] = 0.0;
		velocity[1] = 0.0;
		velocity[2] = 6666.0;

		// 标记为未准备突袭
		g_bIsAttemptPounce[hunter] = false;
		// 发射ht（不是
		TeleportEntity(hunter, NULL_VECTOR, NULL_VECTOR, velocity);
	}

	// 修正玩家ht角度
	// P.S.这个角度不影响真实角度，故玩家可以随便转动视角
	//     但ai角度必须是真实角度，故需要使用tp函数
	ang[0] = 11.8;
	// 修正 ai-ht 真实角度为11.8
	if (IsFakeClient(hunter))
		TeleportEntity(hunter, NULL_VECTOR, ang, NULL_VECTOR);

	// 命令ht蹲下
	if (IsFakeClient(hunter))
		buttons |= IN_DUCK;
	SetEntProp(hunter, Prop_Send, "m_bDucked", 1);
	// 标记为在飞天花板
	g_bIsFlyingCeil[hunter] = true;
	// 修正3方增强插件(音理提供)
	if (g_hHTEnhance != INVALID_HANDLE)
		g_hHTEnhance.SetInt(0);

	return Plugin_Changed;
}

// 注册Native
int Native_IsFlyingCeil(Handle plugin, int numParams)
{
	return g_bIsFlyingCeil[GetNativeCell(1)];
}

// 注册Native
int Native_IsAttemptPounce(Handle plugin, int numParams)
{
	return g_bIsAttemptPounce[GetNativeCell(1)];
}

// 注册Native
int Native_IsControllable(Handle plugin, int numParams)
{
	return g_bIsControllable[GetNativeCell(1)];
}

// 忽略自身碰撞
bool SelfIgnore_TraceFilter(int entity, int mask, int self)
{
	if (entity == self || IsValidClient(entity))
		return false;

	return true;
}

// 瞄准生还并突袭
bool TryAimSurvivor(int hunter)
{
	int sur = g_iPounceTarget[hunter];
	float surpos[3], htpos[3], atkang[3], dis = -1.0;
	if (!IsSurvivor(sur) || !IsPlayerAlive(sur) || IsPlayerIncap(sur) || IsSurvivorPinned(sur))
	{
		// 选择最近的可用的生还目标
		for (int i = 1; i <= MaxClients; i++)
		{
			int inf = g_iTargetWhoAimed[i];
			if ((IsInfected(inf) && IsPlayerAlive(inf) && inf != hunter) || !IsSurvivor(i) || !IsPlayerAlive(i) || IsSurvivorPinned(i) || IsPlayerIncap(i))
				continue;
			GetClientAbsOrigin(i, surpos);
			float d = GetVectorDistance(surpos, htpos);
			if (d >= dis && dis != -1)
				continue;
			dis = d;
			sur = i;
		}

		// 目标不可用时，选择最近的生还
		if (!IsSurvivor(sur))
			sur = GetClosestClient(hunter, NULL_VECTOR, TEAM_SURVIVOR);
		// 最近的生还也不可用时，取消接管，让ai自行发挥ww
		if (!IsSurvivor(sur))
			return false;
		// 记录我们选择的目标
		g_iPounceTarget[hunter] = sur;
		g_iTargetWhoAimed[sur] = hunter;
		// 命令ai瞄准选择的目标
		CommandABot(hunter, sur, CMDBOT_ATTACK);
	}

	// 获取ht和生还位置
	GetClientAbsOrigin(sur, surpos);
	GetClientAbsOrigin(hunter, htpos);
	// 用函数获得距离
	dis = GetVector2Distance(htpos, surpos, false);

	// 距离小于预定值 且 不是在天花板上 且 未标记为准备突袭时，取消接管ht
	if (dis <= g_hHSCStopDis.IntValue && !g_bIsFlyingCeil[hunter] && !g_bIsAttemptPounce[hunter])
		return false;

	// 修正天花板ht数量
	if (!g_bIsControllable[hunter])
	{
		g_bIsControllable[hunter] = true;
		g_iCeilHunterCount++;
	}

	float velocity[3], height, delta = -1.0, multiple;
	// 计算高度差h
	height = FloatAbs(htpos[2] - surpos[2]);
	GetEntPropVector(hunter, Prop_Data, "m_vecVelocity", velocity);
	if (g_bIsFlyingCeil[hunter])
	{
		float gravity, time, speed;
		// 获取重力加速度g
		gravity = g_hGravity.FloatValue;
		// ht扑天花板可以近似看成平抛运动，故有
		// h = 1/2gt*t 易得 t = sqrt(2h/g)
		time = SquareRoot(2 * height / gravity);

		// 获取ht速度
		// 在天花板上时记录速度 并 修正天花板z轴速度为0
		velocity[2] = 0.0;
		g_fPounceSpeed[hunter][0] = velocity[0];
		g_fPounceSpeed[hunter][1] = velocity[1];
		SetEntPropVector(hunter, Prop_Data, "m_vecVelocity", velocity);

		// 解出xOy面移动速度
		speed = SquareRoot(Pow(velocity[0], 2.0) + Pow(velocity[1], 2.0));
		// 计算delta time
		delta = dis / speed - time;
		if (delta < 0)
			delta = 0.0;
		multiple = dis / time / speed;
	}

	// 当dt小于0.01，近似认为ht接近抛物线顶点，准备突袭
	if (0 <= delta <= 0.01 || g_bIsAttemptPounce[hunter])
	{
		if (multiple)
		{
			g_fPounceSpeed[hunter][0] *= multiple;
			g_fPounceSpeed[hunter][1] *= multiple;
		}

		float htvel[3], survel[3];
		// 记录两点间的方向向量
		MakeVectorFromPoints(htpos, surpos, atkang);

		// 将方向向量转换为角度
		GetVectorAngles(atkang, atkang);
		// 调整ai角度
		TeleportEntity(hunter, NULL_VECTOR, atkang, NULL_VECTOR);

		// 高度低于100，可能即将扑中，取消接管防止ht卡在生还头顶
		if (height < 100)
			return false;

		// 获取玩家移动速度，准备抵消生还在xOy面的移动
		GetEntPropVector(sur, Prop_Data, "m_vecVelocity", survel);

		// 修正ht速度
		htvel[2] = velocity[2];
		htvel[0] = g_fPounceSpeed[hunter][0];
		htvel[1] = g_fPounceSpeed[hunter][1];
		// 计算生还移动方向
		float dirx = htpos[0] - surpos[0];
		float diry = htpos[1] - surpos[1];
		// 向后移动，做加法
		if (dirx * survel[0] < 0)
			htvel[0] = (htvel[0] < 0 ? -1 : 1) * (FloatAbs(htvel[0]) + FloatAbs(survel[0]));
		else	// 向前移动，做减法
			htvel[0] = (htvel[0] < 0 ? -1 : 1) * (FloatAbs(htvel[0]) - FloatAbs(survel[0]));
		// 向左移动，做加法
		if (diry * survel[1] < 0)
			htvel[1] = (htvel[1] < 0 ? -1 : 1) * (FloatAbs(htvel[1]) + FloatAbs(survel[1]));
		else	// 向右移动，做减法
			htvel[1] = (htvel[1] < 0 ? -1 : 1) * (FloatAbs(htvel[1]) - FloatAbs(survel[1]));

		// 修正ht速度
		TeleportEntity(hunter, NULL_VECTOR, NULL_VECTOR, htvel);
		// 标记为准备突袭
		g_bIsAttemptPounce[hunter] = true;
		// 标记为离开天花板
		g_bIsFlyingCeil[hunter] = false;

		return false;
	}

	return true;
}

// 重置起飞次数
Action Timer_ResetLeapTimes(Handle timer, int hunter)
{
	g_iLeapTimes[hunter] = 0;

	return Plugin_Stop;
}