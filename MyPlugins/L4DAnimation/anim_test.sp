/*
 * @Author: 我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date: 2024-02-07 16:56:36
 * @Last Modified time: 2024-02-08 16:58:37
 * @Github: https://github.com/Paimon-Kawaii
 */
#include <paiutils>
#include <sdktools>
#include <sourcemod>
#include <l4d_anim>

#include <debug_draw>

public Plugin myinfo =
{
    name = "AnimationBoneTest",
    author = "我是派蒙啊",
    description = "",
    version = "",
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_a", TESTA_CMD);
}

int g_iAttachIndex = 0;
Action TESTA_CMD(int client, int args)
{
    if (!args) g_iAttachIndex++;
    else g_iAttachIndex = GetCmdArgInt(1);

    PrintToChatAll("at: %d", g_iAttachIndex);

    return Plugin_Handled;
}

/*
Common generic attachments: eyes, mouth, chest, forward, anim_attachment_RH, anim_attachment_LH.
常见的通用附件：眼睛、嘴巴、胸部、前倾、anim_attachment_RH、anim_attachment_LH。
The head attachment for ragdolls and players is "eyes".
布娃娃和玩家的头部附件是“眼睛”。
The muzzle attachment for weapons is "muzzle".
*/
public void OnPlayerRunCmdPost(int client, int buttons)
{
    if (!IsInfected(client)) return;
    float pos1[3], pos2[3];
    // 1-Chest, 2-LFoot, 3-RFoot, 4-LHand, 5-RHand, 6-Eyes HUNTER
    // 1-LFoot, 2-RFoot, 3-Mouth, 4-Eyes SMOKER
    // 1-Mouth, 2-Eyes,  3-LFoot, 4-RFoot BOOMER
    // 1-LFoot, 2-RFoot, 3-RHand?, 4-RHand?, 5-Mouth, 6-Eyes SPITTER
    // 1-Eyes, 2-LFoot, 3-RFoot,  4-RHand, 5-RHand? JOCKEY
    // 1-LFoot, 2-RFoot, 3-RHand, 4-RHand?, 5-Body, 6-Eyes CHARGER
    GetEntityAttachment(client, L4D_GetZombieAttachment(client, Attach_Eyes), pos1, pos2);
    L4D_GetBonePosition(client, L4D_GetZombieBone(client, Bone_Head), pos2);
    DebugDrawLine(pos1, pos2);

    PrintToChatAll("%.2f", GetVectorDistance(pos1, pos2));
    // DebugDrawCross(pos1);
}
// public void OnPlayerRunCmdPost(int client, int buttons)
// {
//     if (!IsInfected(client)) return;
//     int bone;
//     float pos1[3], pos2[3];

//     bone = L4D_GetZombieBone(client, Bone_Head);
//     L4D_GetBonePosition(client, bone, pos1);

//     bone = L4D_GetZombieBone(client, Bone_Neck);
//     L4D_GetBonePosition(client, bone, pos2);
//     DebugDrawLine(pos1, pos2);

//     bone = L4D_GetZombieBone(client, Bone_RightHand);
//     L4D_GetBonePosition(client, bone, pos1);
//     DebugDrawLine(pos1, pos2);

//     bone = L4D_GetZombieBone(client, Bone_LeftHand);
//     L4D_GetBonePosition(client, bone, pos1);
//     DebugDrawLine(pos1, pos2);

//     bone = L4D_GetZombieBone(client, Bone_Chest);
//     L4D_GetBonePosition(client, bone, pos1);
//     DebugDrawLine(pos1, pos2);

//     bone = L4D_GetZombieBone(client, Bone_LeftKnee);
//     L4D_GetBonePosition(client, bone, pos2);
//     DebugDrawLine(pos1, pos2);

//     bone = L4D_GetZombieBone(client, Bone_RightKnee);
//     L4D_GetBonePosition(client, bone, pos2);
//     DebugDrawLine(pos1, pos2);

//     bone = L4D_GetZombieBone(client, Bone_RightFoot);
//     L4D_GetBonePosition(client, bone, pos1);
//     DebugDrawLine(pos1, pos2);

//     bone = L4D_GetZombieBone(client, Bone_LeftLeg);
//     L4D_GetBonePosition(client, bone, pos1);

//     bone = L4D_GetZombieBone(client, Bone_LeftFoot);
//     L4D_GetBonePosition(client, bone, pos2);
//     DebugDrawLine(pos1, pos2);
// }