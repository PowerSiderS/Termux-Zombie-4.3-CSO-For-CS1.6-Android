#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>

#define IsCustomItem(%0) 			(pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define setWeaponState(%0)			(set_pdata_int(iItem, m_iWeaponState, %0, linux_diff_weapon))
#define getWeaponState				(get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon))
#define setHitCount(%0)				(set_pdata_int(iItem, m_iGlock18ShotsFired, %0, linux_diff_weapon))
#define getHitCount					(get_pdata_int(iItem, m_iGlock18ShotsFired, linux_diff_weapon))

enum
{
	WPNSTATE_IDLE = 0,
	WPNSTATE_SHOOT_SECONDARY
};

#define PDATA_SAFE 					2

#define pev_missile_type			pev_iuser3
#define pev_rotate					pev_iuser4

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 		61/30.0 // 2nd - 91/30.0
#define WEAPON_ANIM_SHOOT_TIME 		31/30.0
#define WEAPON_ANIM_SHOOT_EX_TIME	61/30.0
#define WEAPON_ANIM_RELOAD_TIME 	121/30.0
#define WEAPON_ANIM_DRAW_TIME 		31/30.0

#define WEAPON_ANIM_IDLE 			0
#define WEAPON_ANIM_RELOAD 			2
#define WEAPON_ANIM_DRAW 			3
#define WEAPON_ANIM_SHOOT 			random_num(4,5)
#define WEAPON_ANIM_SHOOT_EX		6

/* ~ [ Weapon Settings ] ~ */

// This macros enable animated sprite of heart in first mode
// At the enabled macro, Sprite will turn
#define ENABLE_ANIMATED_SPRITE		true // [ true = Enable / false = Disable ]

new const WEAPON_REFERENCE[] = 		"weapon_m249";
new const WEAPON_WEAPONLIST[] = 	"x/weapon_magicmg";
new const WEAPON_NATIVE[] = 		"give_magicmg";
new const WEAPON_MODEL_VIEW[] = 	"models/x/v_magicmg.mdl";
new const WEAPON_MODEL_PLAYER[] = 	"models/x/p_magicmg.mdl";
new const WEAPON_MODEL_WORLD[] = 	"models/x/w_magicmg.mdl";
new const WEAPON_SOUND_FIRE[][] = 
{
	"weapons/magicmg-1.wav",
	"weapons/magicmg-2.wav"
};
new const WEAPON_SOUND_READY[] = 	"weapons/magicmg_alarm.wav";

const WEAPON_SPECIAL_CODE = 		14082019;
const WEAPON_BODY = 				0;

const WEAPON_HIT_COUNT = 			40; // Count of hit for active 2nd mode
const WEAPON_MAX_CLIP = 			100;
const WEAPON_DEFAULT_AMMO = 		200;
const Float: WEAPON_RATE = 			0.2;
const Float: WEAPON_PUNCHANGLE = 	0.834;

new const iWeaponList[] = 			{ 3, 200,-1, -1, 0, 4, 20, 0 };

/* ~ [ Entity: Missile ] ~ */
new const ENTITY_MISSILE_CLASSNAME[] = "ent_magicmg_missile";
new const ENTITY_MISSILE_SPRITE[][] =
{
	"sprites/x/ef_magicmgmissile1.spr",
	"sprites/x/ef_magicmgmissile2.spr"
};
new const ENTITY_MISSILE_EXP_SPRITE[][] =
{
	"sprites/x/ef_magicmgexplo.spr",
	"sprites/x/ef_magicmgexplo2.spr"
};
new const ENTITY_MISSILE_EXP_SOUND[][] =
{
	"weapons/magicmg_1exp.wav",
	"weapons/magicmg_2exp.wav"
};
const Float: ENTITY_MISSILE_SPEED = 650.0;
const Float: ENTITY_MISSILE_RADIUS = 75.0;
const Float: ENTITY_MISSILE_RADIUS_EX = 125.0;
const ENTITY_MISSILE_DMGTYPE = 		DMG_BULLET|DMG_NEVERGIB;
#define ENTITY_MISSILE_DAMAGE		random_float(50.0, 100.0)
#define ENTITY_MISSILE_DAMAGE_EX	random_float(1500.0, 2000.0)

/* ~ [ Offsets ] ~ */
// Linux extra offsets
#define linux_diff_weapon 4
#define linux_diff_player 5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CBasePlayerItem
#define m_pPlayer 41
#define m_pNext 42
#define m_iId 43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flTimeWeaponIdle 48
#define m_iPrimaryAmmoType 49
#define m_iClip 51
#define m_fInReload 54
#define m_iGlock18ShotsFired 70
#define m_iWeaponState 74

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

/* ~ [ Params ] ~ */
new gl_iszAllocString_Entity,
	gl_iszAllocString_ModelView,
	gl_iszAllocString_ModelPlayer,
	gl_iszAllocString_EnvSprite,
	gl_iszAllocString_Misille,

	gl_iszModelIndex_MissileExp[2],
	gl_iszModelIndex_BloodSpray,
	gl_iszModelIndex_BloodDrop,

	gl_iMsgID_Weaponlist,
	gl_iMsgID_StatusIcon,
	gl_iMsgID_ScreenFade

public plugin_init()
{
	// https://cso.fandom.com/wiki/Shining_Heart_Rod
	register_plugin("[ZP] Weapon: Shining Heart Rod", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);

	// Hook Weapon
	RegisterHam(Ham_Item_Holster,			WEAPON_REFERENCE,	"CWeapon__Holster_Post", true);
	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	WEAPON_REFERENCE,	"CWeapon__SecondaryAttack_Pre", false);

	// Hook Entities
	RegisterHam(Ham_Touch,					"env_sprite",		"CSprite__Touch_Post", true);

	#if ENABLE_ANIMATED_SPRITE == true

	RegisterHam(Ham_Think,					"env_sprite",		"CSprite__Think_Post", true);

	#endif

	// Messages
	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	gl_iMsgID_StatusIcon = get_user_msgid("StatusIcon");
	gl_iMsgID_ScreenFade = get_user_msgid("ScreenFade");
}

public plugin_precache()
{
	new i;

	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

	for(i = 0; i < sizeof ENTITY_MISSILE_SPRITE; i++)
		engfunc(EngFunc_PrecacheModel, ENTITY_MISSILE_SPRITE[i]);

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	
	// Precache sounds
	for(i = 0; i < sizeof WEAPON_SOUND_FIRE; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_FIRE[i]);

	for(i = 0; i < sizeof ENTITY_MISSILE_EXP_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, ENTITY_MISSILE_EXP_SOUND[i]);

	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_READY);
	UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW);

	// Other
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);
	gl_iszAllocString_EnvSprite = engfunc(EngFunc_AllocString, "env_sprite");
	gl_iszAllocString_Misille = engfunc(EngFunc_AllocString, ENTITY_MISSILE_CLASSNAME);

	// Model Index
	for(i = 0; i < sizeof ENTITY_MISSILE_EXP_SPRITE; i++)
		gl_iszModelIndex_MissileExp[i] = engfunc(EngFunc_PrecacheModel, ENTITY_MISSILE_EXP_SPRITE[i]);

	gl_iszModelIndex_BloodSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
	gl_iszModelIndex_BloodDrop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");
}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

public zp_user_infected_post(iPlayer) UTIL_StatusIcon(iPlayer, 0);

public Command_HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

public Command_GiveWeapon(iPlayer)
{
	static iEntity; iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
	if(iEntity <= 0) return 0;

	set_pev(iEntity, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, iEntity);
	set_pdata_int(iEntity, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	UTIL_DropWeapon(iPlayer, 1);

	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iEntity))
	{
		set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
		return 0;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, iEntity, iPlayer);

	new iAmmoType = m_rgAmmo + get_pdata_int(iEntity, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, m_rgAmmo, linux_diff_player) < WEAPON_DEFAULT_AMMO)
		set_pdata_int(iPlayer, iAmmoType, WEAPON_DEFAULT_AMMO, linux_diff_player);

	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return 1;
}

// [ Fakemeta ]
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(!is_user_alive(iPlayer)) return;

	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
	static i, szClassName[32], iItem;
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

	for(i = 0; i < 6; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, linux_diff_weapon);

		if(iItem > 0 && IsCustomItem(iItem))
		{
			engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
			set_pev(iEntity, pev_body, WEAPON_BODY);
			
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

// [ HamSandwich ]
public CWeapon__Holster_Post(iItem)
{
	if(!IsCustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	
	UTIL_StatusIcon(iPlayer, 0);
	setWeaponState(WPNSTATE_IDLE);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CWeapon__Deploy_Post(iItem)
{
	if(!IsCustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
	set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);
	UTIL_StatusIcon(iPlayer, getHitCount >= WEAPON_HIT_COUNT ? 1 : 0);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iButton; iButton = pev(iPlayer, pev_button);

	// Reload
	if(get_pdata_int(iItem, m_fInReload, linux_diff_weapon) == 1)
	{
		static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
		static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
		static j; j = min(WEAPON_MAX_CLIP - iClip, iAmmo);

		set_pdata_int(iItem, m_iClip, iClip + j, linux_diff_weapon);
		set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
		set_pdata_int(iItem, m_fInReload, 0, linux_diff_weapon);
	}

	// Shoot from SecondaryAttack
	if(getWeaponState == WPNSTATE_SHOOT_SECONDARY)
	{
		CWeapon__CreateMissile(iPlayer, 1);
		setWeaponState(WPNSTATE_IDLE);
	}

	// Hook SecondaryAttack
	if(iButton & IN_ATTACK2 && get_pdata_float(iItem, m_flNextSecondaryAttack, linux_diff_weapon) < 0.0)
	{
		ExecuteHamB(Ham_Weapon_SecondaryAttack, iItem);

		iButton &= ~IN_ATTACK2;
		set_pev(iPlayer, pev_button, iButton);
	}

	return HAM_IGNORED;
}

public CWeapon__AddToPlayer_Post(iItem, iPlayer)
{
	if(IsCustomItem(iItem)) UTIL_WeaponList(iPlayer, true);
	else if(pev(iItem, pev_impulse) == 0) UTIL_WeaponList(iPlayer, false);
}

public CWeapon__Reload_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInReload, 1, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_RELOAD);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!IsCustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iIdleAnim;
	if(random_num(0, 10) <= 1) // Chance for second idle anim 10%
		iIdleAnim = 1;
	else iIdleAnim = 0;

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE + iIdleAnim);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME + (iIdleAnim ? 1.0 : 0.0), linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(!iClip)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	static Float: vecPunchangle[3];
	vecPunchangle[0] = -WEAPON_PUNCHANGLE * 2.0;
	vecPunchangle[1] = random_float(-WEAPON_PUNCHANGLE * 2.0, WEAPON_PUNCHANGLE * 2.0);
	vecPunchangle[2] = 0.0;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	CWeapon__CreateMissile(iPlayer);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	if(getWeaponState != WPNSTATE_IDLE) setWeaponState(WPNSTATE_IDLE);
	set_pdata_int(iItem, m_iClip, iClip - 1, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;
	if(getHitCount < WEAPON_HIT_COUNT) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_StatusIcon(iPlayer, 0);
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT_EX);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	setHitCount(0);
	setWeaponState(WPNSTATE_SHOOT_SECONDARY);
	set_pdata_float(iPlayer, m_flNextAttack, 31/30.0, linux_diff_player);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SHOOT_EX_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_SHOOT_EX_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_EX_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CSprite__Touch_Post(iEntity, iTouch)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Misille)
	{
		new iOwner = pev(iEntity, pev_owner);
		if(iTouch == iOwner) return HAM_SUPERCEDE;

		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		new iMissileType = pev(iEntity, pev_missile_type);

		emit_sound(iEntity, CHAN_ITEM, ENTITY_MISSILE_EXP_SOUND[iMissileType], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
		write_byte(TE_EXPLOSION); // TE
		engfunc(EngFunc_WriteCoord, vecOrigin[0]); // Position X
		engfunc(EngFunc_WriteCoord, vecOrigin[1]); // Position Y
		engfunc(EngFunc_WriteCoord, vecOrigin[2] + 20.0); // Position Z
		write_short(gl_iszModelIndex_MissileExp[iMissileType]); // Model Index
		write_byte(iMissileType ? 16 : 8); // Scale
		write_byte(32); // Framerate
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // Flags
		message_end();

		new iVictim = FM_NULLENT;
		new Float: flRadius = iMissileType ? ENTITY_MISSILE_RADIUS_EX : ENTITY_MISSILE_RADIUS;
		new Float: flDamage = iMissileType ? ENTITY_MISSILE_DAMAGE_EX : ENTITY_MISSILE_DAMAGE;

		// It's only blood
		if(is_user_alive(iTouch) && zp_get_user_zombie(iTouch))
			UTIL_BloodDrips(vecOrigin, iTouch, floatround(flDamage));

		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, flRadius)) > 0)
		{
			if(pev(iVictim, pev_takedamage) == DAMAGE_NO) continue;
			if(is_user_alive(iVictim))
			{
				if(iVictim == iOwner || !zp_get_user_zombie(iVictim) || !is_wall_between_points(iOwner, iVictim))
					continue;
			}
			else if(pev(iVictim, pev_solid) == SOLID_BSP)
			{
				if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
					continue;
			}

			if(is_user_alive(iVictim))
			{
				set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);

				if(!iMissileType) CWeapon__CheckHitCount(iOwner);
			}

			ExecuteHamB(Ham_TakeDamage, iVictim, iOwner, iOwner, flDamage, ENTITY_MISSILE_DMGTYPE);
		}

		set_pev(iEntity, pev_flags, FL_KILLME);
	}

	return HAM_IGNORED;
}

#if ENABLE_ANIMATED_SPRITE == true

public CSprite__Think_Post(iEntity)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Misille)
	{
		if(pev(iEntity, pev_missile_type) == 1) return HAM_IGNORED;

		new Float: flGameTime = get_gametime();
		new iRotate = pev(iEntity, pev_rotate);
		new Float: vecAngles[3]; pev(iEntity, pev_angles, vecAngles);

		vecAngles[1] += iRotate ? 15.0 : -15.0;
		vecAngles[2] += iRotate ? 15.0 : -15.0;

		set_pev(iEntity, pev_angles, vecAngles);
		set_pev(iEntity, pev_nextthink, flGameTime + 0.05);
	}

	return HAM_IGNORED;
}

#endif

// [ Other ]
CWeapon__CheckHitCount(iPlayer)
{
	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_weapon);

	if(!iItem || pev_valid(iItem) != PDATA_SAFE) return;
	if(!IsCustomItem(iItem)) return;
	if(getHitCount > WEAPON_HIT_COUNT) return;

	if(getHitCount == WEAPON_HIT_COUNT)
	{
		UTIL_StatusIcon(iPlayer, 1);
		UTIL_ScreenFade(iPlayer, (1<<10) * 2, (1<<10) * 2, 0x0000, 219, 48, 130, 70);

		emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUND_READY, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}

	setHitCount(getHitCount + 1);
}

CWeapon__CreateMissile(iPlayer, iMissileType = 0)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_EnvSprite);
	if(!iEntity) return 0;

	new Float: flGameTime = get_gametime();
	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
	new Float: vecRight[3]; angle_vector(vecAngles, ANGLEVECTOR_RIGHT, vecRight);
	new Float: vecUp[3]; angle_vector(vecAngles, ANGLEVECTOR_UP, vecUp);
	new Float: vecVelocity[3]; xs_vec_copy(vecForward, vecVelocity);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);

	// Create start position
	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);
	xs_vec_mul_scalar(vecForward, 25.0, vecForward);
	xs_vec_mul_scalar(vecRight, random_float(-10.0, 10.0), vecRight);
	xs_vec_mul_scalar(vecUp, random_float(-10.0, 10.0), vecUp);
	xs_vec_add(vecOrigin, vecForward, vecOrigin);
	xs_vec_add(vecOrigin, vecRight, vecOrigin);
	xs_vec_add(vecOrigin, vecUp, vecOrigin);

	// Speed for missile
	xs_vec_mul_scalar(vecVelocity, ENTITY_MISSILE_SPEED, vecVelocity);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_MISSILE_SPRITE[iMissileType]);
	
	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Misille);
	set_pev(iEntity, pev_spawnflags, SF_SPRITE_STARTON);
	set_pev(iEntity, pev_animtime, flGameTime);
	set_pev(iEntity, pev_framerate, 32.0);
	set_pev(iEntity, pev_frame, 1.0);
	set_pev(iEntity, pev_rendermode, kRenderTransAdd);
	set_pev(iEntity, pev_renderamt, 200.0);
	set_pev(iEntity, pev_scale, iMissileType ? 0.5 : random_float(0.1, 0.4));

	dllfunc(DLLFunc_Spawn, iEntity);

	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_rotate, random_num(0, 1));
	set_pev(iEntity, pev_missile_type, iMissileType);
	set_pev(iEntity, pev_velocity, vecVelocity);
	set_pev(iEntity, pev_nextthink, flGameTime);

	engfunc(EngFunc_SetSize, iEntity, Float: {-1.0, -1.0, -1.0}, Float: {1.0, 1.0, 1.0});
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	return iEntity;
}

// [ Stocks ]
stock is_wall_between_points(iPlayer, iEntity)
{
	if(!is_user_alive(iEntity))
		return 0;

	new iTrace = create_tr2();
	new Float: flStart[3], Float: flEnd[3], Float: flEndPos[3];

	pev(iPlayer, pev_origin, flStart);
	pev(iEntity, pev_origin, flEnd);

	engfunc(EngFunc_TraceLine, flStart, flEnd, IGNORE_MONSTERS, iPlayer, iTrace);
	get_tr2(iTrace, TR_vecEndPos, flEndPos);

	free_tr2(iTrace);

	return xs_vec_equal(flEnd, flEndPos);
}

stock UTIL_SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_DropWeapon(iPlayer, iSlot)
{
	static iEntity, iNext, szWeaponName[32];
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

	if(iEntity > 0)
	{
		do
		{
			iNext = get_pdata_cbase(iEntity, m_pNext, linux_diff_weapon);

			if(get_weaponname(get_pdata_int(iEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
				engclient_cmd(iPlayer, "drop", szWeaponName);
		}
		
		while((iEntity = iNext) > 0);
	}
}

stock UTIL_PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;
	
	if((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for(new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);
			
			for(k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if(iEvent != 5004)
					continue;
				
				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if(strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					engfunc(EngFunc_PrecacheSound, szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}

stock UTIL_PrecacheSpritesFromTxt(const szWeaponList[])
{
	new szTxtDir[64], szSprDir[64]; 
	new szFileData[128], szSprName[48], temp[1];

	format(szTxtDir, charsmax(szTxtDir), "sprites/%s.txt", szWeaponList);
	engfunc(EngFunc_PrecacheGeneric, szTxtDir);

	new iFile = fopen(szTxtDir, "rb");
	while(iFile && !feof(iFile)) 
	{
		fgets(iFile, szFileData, charsmax(szFileData));
		trim(szFileData);

		if(!strlen(szFileData)) 
			continue;

		new pos = containi(szFileData, "640");	
			
		if(pos == -1)
			continue;
			
		format(szFileData, charsmax(szFileData), "%s", szFileData[pos+3]);		
		trim(szFileData);

		strtok(szFileData, szSprName, charsmax(szSprName), temp, charsmax(temp), ' ', 1);
		trim(szSprName);
		
		format(szSprDir, charsmax(szSprDir), "sprites/%s.spr", szSprName);
		engfunc(EngFunc_PrecacheGeneric, szSprDir);
	}

	if(iFile) fclose(iFile);
}

public UTIL_BloodDrips(Float: vecOrigin[3], iVictim, iAmount)
{
	if(iAmount > 255) iAmount = 255;
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(gl_iszModelIndex_BloodSpray);
	write_short(gl_iszModelIndex_BloodDrop);
	write_byte(ExecuteHamB(Ham_BloodColor, iVictim));
	write_byte(min(max(3, iAmount / 10), 16));
	message_end();
}

stock UTIL_WeaponList(iPlayer, bool: bEnabled)
{
	message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, iPlayer);
	write_string(bEnabled ? WEAPON_WEAPONLIST : WEAPON_REFERENCE);
	write_byte(iWeaponList[0]);
	write_byte(bEnabled ? WEAPON_DEFAULT_AMMO : iWeaponList[1]);
	write_byte(iWeaponList[2]);
	write_byte(iWeaponList[3]);
	write_byte(iWeaponList[4]);
	write_byte(iWeaponList[5]);
	write_byte(iWeaponList[6]);
	write_byte(iWeaponList[7]);
	message_end();
}

stock UTIL_StatusIcon(iPlayer, iUpdateMode)
{
	message_begin(MSG_ONE, gl_iMsgID_StatusIcon, { 0, 0, 0 }, iPlayer);
	write_byte(iUpdateMode ? 1 : 0);
	write_string("number_1"); 
	write_byte(219);
	write_byte(48); 
	write_byte(130);
	message_end();
}

stock UTIL_ScreenFade(iPlayer, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{
	if(!iPlayer)
		message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, gl_iMsgID_ScreenFade);
	else message_begin(iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, gl_iMsgID_ScreenFade, _, iPlayer);

	write_short(iDuration);
	write_short(iHoldTime);
	write_short(iFlags);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}
