/*
 * @Author:             我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date:        2023-03-22 19:08:40
 * @Last Modified time: 2024-02-07 16:29:04
 * @Github:             https://github.com/Paimon-Kawaii
 */

#if defined _freecamera_included_
    #endinput
#endif
#define _freecamera_included_

#define INVALID_BONE -1

enum Bone_Type
{
    Bone_Head,
    Bone_Neck,
    Bone_Chest,
    Bone_LeftHand,
    Bone_RightHand,
    Bone_Belly,
    Bone_LeftLeg,
    Bone_RightLeg,
    Bone_LeftFoot,
    Bone_RightFoot,
};

public SharedPlugin __pl_animbone = {
    name = "anim_bone",
    file = "anim_bone.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

public void __pl_animbone_SetNTVOptional()
{
    MarkNativeAsOptional("L4D_GetZombieBone");
    MarkNativeAsOptional("L4D_GetBoneByName");
    MarkNativeAsOptional("L4D_GetBonePosition");
}

/* Natives */

/**
 * Get zombie's bone of target type.
 *
 * @param client    Client index
 * @return          Zombie's bone
 */
native int L4D_GetZombieBone(int client, Bone_Type bone_type);

/**
 * Get zombie's bone of target type.
 *
 * @param client    Client index
 * @param bone_name    Bone name
 * @return          Zombie's bone
 */
native int L4D_GetBoneByName(int client, const char[] bone_name);

/**
 * Get bone's world position.
 *
 * @param client    Client index
 * @param bone    Bone index
 * @param origin    Bone origin to get
 * @param angle    Bone angle to get
 * @noreturn
 */
native int L4D_GetBonePosition(int client, int bone, float origin[3] = NULL_VECTOR, float angle[3] = NULL_VECTOR);