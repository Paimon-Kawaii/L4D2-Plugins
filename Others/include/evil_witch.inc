#if defined _evil_witch_included
 #endinput
#endif
#define _evil_witch_included

/**
 * Receive dropped weapon when player died.
 *
 * @param iOldWitch		Old witch index
 * @param iNewWitch		New witch index
 * @param iNewTarget	New target of witch (you should verify index)
 */
forward void EW_OnWitchChanged(int iOldWitch, int iNewWitch, int iNewTarget);

/**
 * Makes witch to walk.
 *
 * @param iWitch		Witch index
 * @param bDoWalk		1 - to walk, 0 - to stop
 *
 * @noreturn
 */
native int EW_WitchWalk(int iWitch, int iDoWalk);