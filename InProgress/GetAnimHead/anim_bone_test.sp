#include <paiutils>
#include <sdktools>
#include <sourcemod>
#include <anim_bone>

#include <debug_draw>

public Plugin myinfo =
{
    name = "AnimationBoneTest",
    author = "我是派蒙啊",
    description = "",
    version = "",
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
};

public void OnPlayerRunCmdPost(int client, int buttons)
{
    if (!IsInfected(client)) return;
    int bone;
    float pos1[3], pos2[3];

    bone = L4D_GetZombieBone(client, Bone_Head);
    L4D_GetBonePosition(client, bone, pos1);

    bone = L4D_GetZombieBone(client, Bone_Neck);
    L4D_GetBonePosition(client, bone, pos2);
    DebugDrawLine(pos1, pos2);

    bone = L4D_GetZombieBone(client, Bone_RightHand);
    L4D_GetBonePosition(client, bone, pos1);
    DebugDrawLine(pos1, pos2);

    bone = L4D_GetZombieBone(client, Bone_LeftHand);
    L4D_GetBonePosition(client, bone, pos1);
    DebugDrawLine(pos1, pos2);

    bone = L4D_GetZombieBone(client, Bone_Chest);
    L4D_GetBonePosition(client, bone, pos1);
    DebugDrawLine(pos1, pos2);

    bone = L4D_GetZombieBone(client, Bone_LeftLeg);
    L4D_GetBonePosition(client, bone, pos2);
    DebugDrawLine(pos1, pos2);

    bone = L4D_GetZombieBone(client, Bone_RightLeg);
    L4D_GetBonePosition(client, bone, pos2);
    DebugDrawLine(pos1, pos2);

    bone = L4D_GetZombieBone(client, Bone_RightFoot);
    L4D_GetBonePosition(client, bone, pos1);
    DebugDrawLine(pos1, pos2);

    bone = L4D_GetZombieBone(client, Bone_LeftLeg);
    L4D_GetBonePosition(client, bone, pos1);

    bone = L4D_GetZombieBone(client, Bone_LeftFoot);
    L4D_GetBonePosition(client, bone, pos2);
    DebugDrawLine(pos1, pos2);
}