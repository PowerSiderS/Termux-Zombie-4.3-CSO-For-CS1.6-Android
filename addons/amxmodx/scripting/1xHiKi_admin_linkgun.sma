#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define is_user_valid(%0) (0 < %0 <= 32)
#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)

#define Get_WeaponState(%0) (get_pdata_int(%0, m_iWeaponState, linux_diff_weapon))
#define Set_WeaponState(%0,%1) (set_pdata_int(%0, m_iWeaponState, %1, linux_diff_weapon))

enum _:eShootStates
{
	STATE_START = 0,
	STATE_LOOP
};

#define PDATA_SAFE 2

#define WEAPON_ANIM_IDLE 0
#define WEAPON_ANIM_SHOOT 3
#define WEAPON_ANIM_RELOAD 1
#define WEAPON_ANIM_DRAW 2
#define WEAPON_ANIM_SEC_START 4
#define WEAPON_ANIM_SEC_LOOP 5
#define WEAPON_ANIM_SEC_END 6

// From model: Frames/FPS
#define WEAPON_ANIM_IDLE_TIME 80/15.0
#define WEAPON_ANIM_SHOOT_TIME 5/15.0
#define WEAPON_ANIM_RELOAD_TIME 1.53
#define WEAPON_ANIM_DRAW_TIME 11/20.0
#define WEAPON_ANIM_SEC_TIME 12/30.0

//#define WEAPON_LIST_ENABLED // Weapon List enabled [ Comment this if u not needed use Weapon List ]
#define WEAPON_MUZZLEFLASH_ENABLED // MuzzleFlash enabled [ Comment this if u not needed use MuzzleFlash ]
#define WEAPON_SPECIAL_CODE 532534
#define WEAPON_REFERENCE "weapon_m249"
#define WEAPON_NEW_NAME "weapon_m249" // Name of Weapon List

#define WEAPON_MODEL_VIEW "models/x/v_linkgun.mdl"
#define WEAPON_MODEL_PLAYER "models/x/p_linkgun.mdl"
#define WEAPON_MODEL_WORLD "models/x/w_linkgun.mdl"
#define WEAPON_BODY 0

#define WEAPON_SOUND_SHOOT "weapons/linkgun_shoot.wav"

new const WEAPON_SOUND_SEC_SOUNDS[][] =
{
	"weapons/linkgun_lightstart.wav", // 0 - Shoot start
	"weapons/linkgun_lightshoot.wav", // 1 - Shoot loop (shooting)
	"weapons/linkgun_lightend.wav" // 2 - Shoot end
};

#define WEAPON_MAX_CLIP 100 // Max clip
#define WEAPON_DEFAULT_AMMO 200 // Default ammo
#define WEAPON_RATE 0.12 // Shoot speed (prim mode)
#define WEAPON_SEC_RATE 0.09 // Shoot speed (sec mode)
#define WEAPON_SEC_ACCURACY 0.0 // Accuracy (sec mode) 0.0 - 0.9
#define WEAPON_SEC_PUNCHANGLE 0.1 // Recoil (sec mode)
#define WEAPON_SEC_DAMAGE 1.64 // Damage (sec mode)
#define WEAPON_SEC_HIT_SPRITE "sprites/x/linkgun_bomb.spr" // Hit sprite (all modes)

#define ENTITY_PLASMA_CLASSNAME "ent_linkgun_ball"
#define ENTITY_PLASMA_SPRITE "sprites/x/linkgun_ball.spr"
#define ENTITY_PLASMA_SOUND "weapons/linkgun_shothit.wav"
#define ENTITY_PLASMA_SPEED 1500.0
#define ENTITY_PLASMA_DAMAGE random_float(10.0, 40.0)
#define ENTITY_PLASMA_RADIUS 60.0
#define ENTITY_PLASMA_DMGTYPE DMG_NEVERGIB|DMG_CLUB // Damage type of Entity

#define ENTITY_MUZZLE_CLASSNAME "ent_linkgun_mf"
#define ENTITY_MUZZLE_SPRITE "sprites/x/linkgun_light.spr"
#define ENTITY_MUZZLE_INTOLERANCE 100

#if defined WEAPON_LIST_ENABLED
	new const iWeaponList[] = 
	{
		3, 200,-1, -1, 0, 4, 20, 0 // weapon_m249
	};
#endif

// Linux extra offsets
#define linux_diff_weapon 4
#define linux_diff_player 5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CSprite
#define m_maxFrame 35

// CBaseAnimating
#define m_flLastEventCheck 38

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
#define m_flAccuracy 62
#define m_iWeaponState 74
#define m_flNextReload 75

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

new g_iszAllocString_Entity,
	g_iszAllocString_ModelView, 
	g_iszAllocString_ModelPlayer,

	g_iszAllocString_InfoTarget,
	g_iszAllocString_PlasmaClass,

	HamHook: g_HamHook_TraceAttack[4],

	g_iszModelIndex_Laserbeam,
	g_iszModelIndex_Lightning,
	g_iszModelIndex_Explosion

#if defined WEAPON_LIST_ENABLED
	new g_iMsgID_Weaponlist;
#endif

#if defined WEAPON_MUZZLEFLASH_ENABLED
	#define CustomMuzzle(%0) (pev(%0, pev_impulse) == g_iszAllocString_MuzzleFlash)
	new g_iszAllocString_MuzzleFlash;
#endif

public plugin_init()
{
	// Idea: Unreal Tournament 3 & Dias (Weapon for CS 1.6)
	register_plugin("[ZP] Weapon: UT3 Link Gun", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);

	RegisterHam(Ham_Item_Holster,			WEAPON_REFERENCE,	"CWeapon__Holster_Post", true);
	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	#if defined WEAPON_LIST_ENABLED
		RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
		g_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	#endif
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	WEAPON_REFERENCE,	"CWeapon__SecondaryAttack_Pre", false);
	
	g_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,		"func_breakable",	"CEntity__TraceAttack_Pre", false);
	g_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,		"info_target",		"CEntity__TraceAttack_Pre", false);
	g_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,		"player",			"CEntity__TraceAttack_Pre", false);
	g_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,		"hostage_entity",	"CEntity__TraceAttack_Pre", false);

	RegisterHam(Ham_Touch,					"info_target",		"CEntity__Touch_Pre", false);
	#if defined WEAPON_MUZZLEFLASH_ENABLED
		RegisterHam(Ham_Think,					"env_sprite",		"CMuzzleFlash__Think_Pre", false);
	#endif
	
	fm_ham_hook(false);
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_NEW_NAME, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);
	engfunc(EngFunc_PrecacheModel, ENTITY_PLASMA_SPRITE);

	#if defined WEAPON_LIST_ENABLED
		// Precache generic
		UTIL_PrecacheSpritesFromTxt(WEAPON_NEW_NAME);
	#endif

	// Precache sounds
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_SHOOT);
	engfunc(EngFunc_PrecacheSound, ENTITY_PLASMA_SOUND);
	engfunc(EngFunc_PrecacheSound, "common/null.wav");

	for(new i = 0; i < sizeof WEAPON_SOUND_SEC_SOUNDS; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_SEC_SOUNDS[i]);

	UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW);

	#if defined WEAPON_MUZZLEFLASH_ENABLED
		// Muzzle Flash
		engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITE);

		g_iszAllocString_MuzzleFlash = engfunc(EngFunc_AllocString, ENTITY_MUZZLE_CLASSNAME);
	#endif

	// Other
	g_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	g_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	g_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);

	g_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");
	g_iszAllocString_PlasmaClass = engfunc(EngFunc_AllocString, ENTITY_PLASMA_CLASSNAME);

	// Model Index
	g_iszModelIndex_Laserbeam = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr");
	g_iszModelIndex_Lightning = engfunc(EngFunc_PrecacheModel, "sprites/lgtning.spr");
	g_iszModelIndex_Explosion = engfunc(EngFunc_PrecacheModel, WEAPON_SEC_HIT_SPRITE);
}

// [ Native ]
public plugin_natives()
{
	register_native("give_linkgun", "Command_GiveWeapon", 1);
}

public Command_HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

public Command_GiveWeapon(iPlayer)
{
	static iEntity; iEntity = engfunc(EngFunc_CreateNamedEntity, g_iszAllocString_Entity);
	if(iEntity <= 0) return 0;

	set_pev(iEntity, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, iEntity);
	UTIL_DropWeapon(iPlayer, 1);

	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iEntity))
	{
		set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
		return 0;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, iEntity, iPlayer);
	set_pdata_int(iEntity, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);

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
	if(pev_valid(iItem) != PDATA_SAFE || !CustomItem(iItem)) return;

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

		if(iItem > 0 && CustomItem(iItem))
		{
			engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
			set_pev(iEntity, pev_body, WEAPON_BODY);
			
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;

public FM_Hook_TraceLine_Post(Float: flOrigin1[3], Float: flOrigin2[3], iFrag, iAttacker, iTrace)
{
	if(iFrag & IGNORE_MONSTERS) return FMRES_IGNORED;

	static pHit; pHit = get_tr2(iTrace, TR_pHit);
	static Float: flvecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, flvecEndPos);

	if(is_user_valid(pHit))
	{
		engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, flvecEndPos, 0);
		write_byte(TE_EXPLOSION);
		engfunc(EngFunc_WriteCoord, flvecEndPos[0]);
		engfunc(EngFunc_WriteCoord, flvecEndPos[1]);
		engfunc(EngFunc_WriteCoord, flvecEndPos[2] - 10.0);
		write_short(g_iszModelIndex_Explosion);
		write_byte(2); // Scale
		write_byte(60); // Framerate
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // Flags
		message_end();
	}
	
	return FMRES_IGNORED;
}

// [ HamSandwich ]
public CWeapon__Holster_Post(iItem)
{
	if(!CustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	emit_sound(iPlayer, CHAN_WEAPON, "common/null.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextReload, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CWeapon__Deploy_Post(iItem)
{
	if(!CustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, g_iszAllocString_ModelView);
	set_pev_string(iPlayer, pev_weaponmodel2, g_iszAllocString_ModelPlayer);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

	Set_WeaponState(iItem, STATE_START);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextReload, 0.0, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	static iButton; iButton = pev(iPlayer, pev_button);

	// reload
	if(get_pdata_int(iItem, m_fInReload, linux_diff_weapon) == 1)
	{
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
		static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
		static j; j = min(WEAPON_MAX_CLIP - iClip, iAmmo);

		set_pdata_int(iItem, m_iClip, iClip + j, linux_diff_weapon);
		set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
		set_pdata_int(iItem, m_fInReload, 0, linux_diff_weapon);

		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	}

	// reset secondary attack
	if(Get_WeaponState(iItem) == STATE_LOOP)
	{
		if(!iClip || !(iButton & IN_ATTACK2))
		{
			Set_WeaponState(iItem, STATE_START);

			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SEC_END);
			emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_SEC_SOUNDS[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SEC_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_SEC_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SEC_TIME, linux_diff_weapon);
		}
	}

	// secondary attack
	if(iButton & IN_ATTACK2 && get_pdata_float(iItem, m_flNextSecondaryAttack, linux_diff_weapon) < 0.0)
	{
		ExecuteHamB(Ham_Weapon_SecondaryAttack, iItem);

		iButton &= ~IN_ATTACK2;
		set_pev(iPlayer, pev_button, iButton);
	}

	return HAM_IGNORED;
}

#if defined WEAPON_LIST_ENABLED
	public CWeapon__AddToPlayer_Post(iItem, iPlayer)
	{
		switch(pev(iItem, pev_impulse))
		{
			case WEAPON_SPECIAL_CODE: UTIL_WeaponList(iPlayer, true);
			case 0: UTIL_WeaponList(iPlayer, false);
		}
	}
#endif

public CWeapon__Reload_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

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
	if(!CustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	new Float: flPunchangle[3];
	flPunchangle[0] = random_float(-1.5, -1.0);
	flPunchangle[1] = 0.0;
	flPunchangle[2] = 0.0;
	set_pev(iPlayer, pev_punchangle, flPunchangle);

	Create_PlasmaBall(iPlayer);
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_SHOOT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	#if defined WEAPON_MUZZLEFLASH_ENABLED
		Weapon_MuzzleFlash(iPlayer, ENTITY_MUZZLE_SPRITE, 0.15, 200.0, 1, 0.19);
	#endif

	set_pdata_int(iItem, m_iClip, iClip - 1, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextSecondaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	switch(Get_WeaponState(iItem))
	{
		case STATE_START:
		{
			Set_WeaponState(iItem, STATE_LOOP);

			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SEC_START);
			emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_SEC_SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SEC_TIME - 0.1, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_SEC_TIME - 0.1, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SEC_TIME - 0.1, linux_diff_weapon);
		}
		case STATE_LOOP:
		{
			set_pdata_float(iItem, m_flAccuracy, WEAPON_SEC_ACCURACY, linux_diff_weapon);

			static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
			static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
			fm_ham_hook(true);

			ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);

			unregister_forward(FM_TraceLine, fw_TraceLine, true);
			unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
			fm_ham_hook(false);

			static Float:vecPunchangle[3];
			pev(iPlayer, pev_punchangle, vecPunchangle);
			vecPunchangle[0] *= WEAPON_SEC_PUNCHANGLE;
			vecPunchangle[1] *= WEAPON_SEC_PUNCHANGLE;
			vecPunchangle[2] *= WEAPON_SEC_PUNCHANGLE;
			set_pev(iPlayer, pev_punchangle, vecPunchangle);

			static Float: flNextAnim; pev(iItem, pev_fuser4, flNextAnim);
			static Float: flGameTime; flGameTime = get_gametime();

			if(flNextAnim <= flGameTime)
			{
				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SEC_LOOP);
				set_pev(iItem, pev_fuser4, flGameTime + 7/30.0);
			}

			if(get_pdata_float(iItem, m_flNextReload, linux_diff_weapon) <= flGameTime)
			{
				emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_SEC_SOUNDS[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				set_pdata_float(iItem, m_flNextReload, flGameTime + 1.0, linux_diff_weapon);
			}

			#if defined WEAPON_MUZZLEFLASH_ENABLED
				Weapon_MuzzleFlash(iPlayer, ENTITY_MUZZLE_SPRITE, 0.15, 255.0, 1, 0.25);
			#endif

			set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_SEC_RATE, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_SEC_RATE, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SEC_TIME, linux_diff_weapon);

			static Float: vecEndPos[3]; fm_get_aim_origin(iPlayer, vecEndPos);

			// index, attachment, endpos, modelindex, width, red, green, blue
			UTIL_CreateBeamEntPoint(iPlayer, 0x1000, vecEndPos, g_iszModelIndex_Lightning, 4, 255, 255, 255);
			UTIL_CreateBeamEntPoint(iPlayer, 0x1000, vecEndPos, g_iszModelIndex_Lightning, 8, 0, 127, 255);
			UTIL_CreateBeamEntPoint(iPlayer, 0x1000, vecEndPos, g_iszModelIndex_Lightning, 12, 255,	255, 255);
			UTIL_CreateBeamEntPoint(iPlayer, 0x1000, vecEndPos, g_iszModelIndex_Lightning, 20, 0, 127, 255);
		}
	}

	return HAM_SUPERCEDE;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float:flDamage)
{
	if(!is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(iItem <= 0 || !CustomItem(iItem)) return;

	SetHamParamFloat(3, flDamage * WEAPON_SEC_DAMAGE);
}

public CEntity__Touch_Pre(iEntity, iVictim)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == g_iszAllocString_PlasmaClass)
	{
		new iOwner = pev(iEntity, pev_owner);
		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);

		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		if(iVictim == iOwner) return HAM_SUPERCEDE;

		engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
		write_byte(TE_EXPLOSION);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2] - 10.0);
		write_short(g_iszModelIndex_Explosion);
		write_byte(5); // Scale
		write_byte(36); // Framerate
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // Flags
		message_end();

		iVictim = FM_NULLENT;

		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_PLASMA_RADIUS)) > 0)
		{
			if(pev_valid(iVictim) != PDATA_SAFE) continue;

			if(pev(iVictim, pev_takedamage) == DAMAGE_NO) 
				continue;

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

			set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);
			ExecuteHamB(Ham_TakeDamage, iVictim, iOwner, iOwner, ENTITY_PLASMA_DAMAGE, ENTITY_PLASMA_DMGTYPE);
		}

		emit_sound(iEntity, CHAN_ITEM, ENTITY_PLASMA_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_pev(iEntity, pev_flags, FL_KILLME);
	}

	return HAM_IGNORED;
}

#if defined WEAPON_MUZZLEFLASH_ENABLED
	public CMuzzleFlash__Think_Pre(iSprite)
	{
		static Float: flFrame;
		
		if(pev_valid(iSprite) != PDATA_SAFE || !CustomMuzzle(iSprite)) return HAM_IGNORED;

		static Float: flNextThink; pev(iSprite, pev_fuser3, flNextThink);
		if(pev(iSprite, pev_frame, flFrame) && ++flFrame - 1.0 < get_pdata_float(iSprite, m_maxFrame, linux_diff_weapon))
		{
			set_pev(iSprite, pev_frame, flFrame);
			set_pev(iSprite, pev_nextthink, get_gametime() + flNextThink);
			
			return HAM_SUPERCEDE;
		}

		set_pev(iSprite, pev_flags, FL_KILLME);
		return HAM_SUPERCEDE;
	}
#endif

// [ Other ]
public Create_PlasmaBall(iOwner)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, g_iszAllocString_InfoTarget);
	if(!pev_valid(iEntity)) return 0;

	new Float: vecOrigin[3]; pev(iOwner, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iOwner, pev_v_angle, vecAngles);
	new Float: vecVelocity[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecVelocity);
	new Float: vecViewOfs[3]; pev(iOwner, pev_view_ofs, vecViewOfs);

	vecOrigin[0] += vecViewOfs[0] + vecVelocity[0] * 20.0;
	vecOrigin[1] += vecViewOfs[1] + vecVelocity[1] * 20.0;
	vecOrigin[2] += vecViewOfs[2] + vecVelocity[2] * 20.0;

	vecVelocity[0] *= ENTITY_PLASMA_SPEED;
	vecVelocity[1] *= ENTITY_PLASMA_SPEED;
	vecVelocity[2] *= ENTITY_PLASMA_SPEED;

	set_pev_string(iEntity, pev_classname, g_iszAllocString_PlasmaClass);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_owner, iOwner);

	set_pev(iEntity, pev_velocity, vecVelocity);

	set_pev(iEntity, pev_rendermode, kRenderTransAdd);
	set_pev(iEntity, pev_renderamt, 200.0);
	set_pev(iEntity, pev_renderfx, kRenderFxNone);

	set_pev(iEntity, pev_scale, 0.1);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_PLASMA_SPRITE);
	engfunc(EngFunc_SetSize, iEntity, Float: { -1.0, -1.0, -1.0 }, Float: { 1.0, 1.0, 1.0 });
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	message_begin(MSG_PVS, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(g_iszModelIndex_Laserbeam);
	write_byte(1); // Life
	write_byte(3); // Width
	write_byte(0); // Red
	write_byte(255); // Green
	write_byte(255); // Blue
	write_byte(200); // Alpha
	message_end();

	return iEntity;
}

public fm_ham_hook(bool: bEnabled)
{
	if(bEnabled)
	{
		EnableHamForward(g_HamHook_TraceAttack[0]);
		EnableHamForward(g_HamHook_TraceAttack[1]);
		EnableHamForward(g_HamHook_TraceAttack[2]);
		EnableHamForward(g_HamHook_TraceAttack[3]);
	}
	else 
	{
		DisableHamForward(g_HamHook_TraceAttack[0]);
		DisableHamForward(g_HamHook_TraceAttack[1]);
		DisableHamForward(g_HamHook_TraceAttack[2]);
		DisableHamForward(g_HamHook_TraceAttack[3]);
	}
}

// [ Stocks ]
stock is_wall_between_points(iPlayer, iEntity)
{
	// vector
	#define Vector_Equal(%0,%1) ((%1[0] == %0[0]) && (%1[1] == %0[1]) && (%1[2] == %0[2]))

	if(!is_user_alive(iEntity))
		return 0;

	new iTrace = create_tr2();
	new Float: flStart[3], Float: flEnd[3], Float: flEndPos[3];

	pev(iPlayer, pev_origin, flStart);
	pev(iEntity, pev_origin, flEnd);

	engfunc(EngFunc_TraceLine, flStart, flEnd, IGNORE_MONSTERS, iPlayer, iTrace);
	get_tr2(iTrace, TR_vecEndPos, flEndPos);

	free_tr2(iTrace);

	return Vector_Equal(flEnd, flEndPos);
}

#if defined WEAPON_MUZZLEFLASH_ENABLED
	stock Sprite_SetTransparency(iSprite, iRendermode, Float: flAmt, iFx = kRenderFxNone)
	{
		set_pev(iSprite, pev_rendermode, iRendermode);
		set_pev(iSprite, pev_renderamt, flAmt);
		set_pev(iSprite, pev_renderfx, iFx);
	}

	stock Weapon_MuzzleFlash(iPlayer, szMuzzleSprite[], Float: flScale, Float: flBrightness, iAttachment, Float: flNextThink)
	{
		if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < ENTITY_MUZZLE_INTOLERANCE) return FM_NULLENT;
		
		static iSprite, iszAllocStringCached;
		if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
			iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
		
		if(pev_valid(iSprite) != PDATA_SAFE) return FM_NULLENT;
		
		set_pev(iSprite, pev_model, szMuzzleSprite);
		set_pev(iSprite, pev_spawnflags, SF_SPRITE_ONCE);
		
		set_pev(iSprite, pev_classname, ENTITY_MUZZLE_CLASSNAME);
		set_pev(iSprite, pev_impulse, g_iszAllocString_MuzzleFlash);
		set_pev(iSprite, pev_owner, iPlayer);
		set_pev(iSprite, pev_fuser3, flNextThink);
		
		set_pev(iSprite, pev_aiment, iPlayer);
		set_pev(iSprite, pev_body, iAttachment);
		
		Sprite_SetTransparency(iSprite, kRenderTransAdd, flBrightness);
		set_pev(iSprite, pev_scale, flScale);
		
		dllfunc(DLLFunc_Spawn, iSprite)

		return iSprite;
	}
#endif

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

stock UTIL_CreateBeamEntPoint(iPlayer, iAttachment, Float: flOrigin[3], iszModelIndex, iWidth, iRed, iGreen, iBlue)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(iPlayer | iAttachment);
	engfunc(EngFunc_WriteCoord, flOrigin[0]);
	engfunc(EngFunc_WriteCoord, flOrigin[1]);
	engfunc(EngFunc_WriteCoord, flOrigin[2]);
	write_short(iszModelIndex) // Model index
	write_byte(0); // Framestart
	write_byte(0); // Framerate
	write_byte(1); // Life
	write_byte(iWidth * 4); // Width
	write_byte(5); // Noise
	write_byte(iRed); // Red
	write_byte(iGreen); // Green
	write_byte(iBlue); // Blue
	write_byte(255); // Alpha
	write_byte(100); // Speed 
	message_end();
}

stock UTIL_PrecacheSoundsFromModel(szModelPath[])
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

#if defined WEAPON_LIST_ENABLED
	stock UTIL_PrecacheSpritesFromTxt(szWeaponList[])
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

	stock UTIL_WeaponList(iPlayer, bool: bEnabled)
	{
		message_begin(MSG_ONE, g_iMsgID_Weaponlist, _, iPlayer);
		write_string(bEnabled ? WEAPON_NEW_NAME : WEAPON_REFERENCE);
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
#endif