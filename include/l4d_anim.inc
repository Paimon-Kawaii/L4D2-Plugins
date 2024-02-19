/*
 * @Author:             我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date:        2023-03-22 19:08:40
 * @Last Modified time: 2024-02-17 20:52:40
 * @Github:             https://github.com/Paimon-Kawaii
 */

#if defined _l4danim_included_
    #endinput
#endif
#define _l4danim_included_

#define INVALID_BONE       -1
#define INVALID_ATTACHMENT 0

enum Attachment_Type
{
    Attach_Eyes,
    Attach_Mouth,
    Attach_Chest,
    Attach_LeftHand,
    Attach_RightHand,
    Attach_Body,
    Attach_LeftFoot,
    Attach_RightFoot
};

enum Bone_Type
{
    Bone_Head,
    Bone_Neck,
    Bone_Chest,
    Bone_LeftHand,
    Bone_RightHand,
    Bone_Belly,
    Bone_LeftKnee,
    Bone_RightKnee,
    Bone_LeftFoot,
    Bone_RightFoot,
};

public SharedPlugin __pl_l4danim = {
    name = "l4d_anim",
    file = "l4d_anim.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

public void __pl_l4danim_SetNTVOptional()
{
    MarkNativeAsOptional("L4D_GetZombieBone");
    MarkNativeAsOptional("L4D_GetBoneByName");
    MarkNativeAsOptional("L4D_GetBonePosition");
    MarkNativeAsOptional("L4D_GetZombieAttachment");
}

/* Natives */

/**
 * Get zombie's bone of target type.
 *
 * @param client    Client index
 * @return          Zombie's bone, -1 for invalid bone
 */
native int L4D_GetZombieBone(int client, Bone_Type bone_type);

/**
 * Get zombie's attachment of target type.
 *
 * @param client    Client index
 * @return          Zombie's attachment, 0 for invalid attachment
 */
native int L4D_GetZombieAttachment(int client, Attachment_Type attach_type);

/**
 * Get zombie's bone of target name.
 *
 * @param entity    Entity index
 * @param bone_name    Bone name
 * @return          Entity's bone, -1 for invalid bone
 */
native int L4D_GetBoneByName(int entity, const char[] bone_name);

/**
 * Get bone's world position.
 *
 * @param client    Client index
 * @param bone    Bone index
 * @param origin    Bone origin to get
 * @param angle    Bone angle to get
 * @noreturn
 */
native void L4D_GetBonePosition(int client, int bone, float origin[3] = NULL_VECTOR, float angle[3] = NULL_VECTOR);