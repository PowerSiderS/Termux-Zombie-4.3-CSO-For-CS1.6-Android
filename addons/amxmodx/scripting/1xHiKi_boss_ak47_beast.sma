#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)

#define DONT_BLEED -1
#define PDATA_SAFE 2
#define ACT_RANGE_ATTACK1 28

#define WEAPON_ANIM_IDLE 0
#define WEAPON_ANIM_SHOOT random_num(3, 5)
#define WEAPON_ANIM_RELOAD 1
#define WEAPON_ANIM_DRAW 2
#define WEAPON_ANIM_STAB_KNIFE 6

// From model: Frames/FPS
#define WEAPON_ANIM_IDLE_TIME 41/4.0
#define WEAPON_ANIM_SHOOT_TIME 13/60.0
#define WEAPON_ANIM_RELOAD_TIME 101/48.0
#define WEAPON_ANIM_DRAW_TIME 24/40.0
#define WEAPON_ANIM_STAB_KNIFE_TIME 61/45.0

#define WEAPON_SPECIAL_CODE 2071
#define WEAPON_REFERENCE "weapon_ak47"
#define WEAPON_NEW_NAME "x/weapon_ak47beast"
#define WEAPON_HUD "sprites/x/640hudx2.spr"
#define WEAPON_HUD_AMMO "sprites/640hud7.spr"

#define WEAPON_ANIM_EXTENSION_STAB_KNIFE "knife"

#define WEAPON_MODEL_VIEW "models/x/v_ak47_beast.mdl"
#define WEAPON_MODEL_PLAYER "models/x/p_ak47_beast.mdl"
#define WEAPON_MODEL_WORLD "models/x/w_ak47_beast.mdl"
#define WEAPON_SOUND_SHOOT "weapons/AK47-Beast_Shoot_1.wav"
#define WEAPON_SOUND_STAB_KNIFE "weapons/AK47-Beast_Knife-Attack.wav"
#define WEAPON_BODY 0

#define WEAPON_STAB_KNIFE_DISTANCE 125.0
#define WEAPON_STAB_KNIFE_DAMAGE random_float(200.0, 400.0)
#define WEAPON_STAB_KNIFE_KNOCKBACK 250.0

#define WEAPON_MAX_CLIP 30
#define WEAPON_DEFAULT_AMMO 180
#define WEAPON_RATE 0.1
#define WEAPON_PUNCHAGNLE 0.75
#define WEAPON_DAMAGE 1.45

new const iWeaponList[] = 
{
	2, 90, -1, -1, 0, 1, 28, 0 // weapon_ak47
};

// Linux extra offsets
#define linux_diff_weapon 4
#define linux_diff_player 5
#define linux_diff_animation 4

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CBaseAnimating
#define m_flFrameRate 36
#define m_flGroundSpeed 37
#define m_flLastEventCheck 38
#define m_fSequenceFinished 39
#define m_fSequenceLoops 40

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
#define m_iWeaponState 74

// CBaseMonster
#define m_Activity 73
#define m_IdealActivity 74
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_flPainShock 108
#define m_iPlayerTeam 114
#define m_flLastAttackTime 220
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

new g_iszAllocString_Entity,
	g_iszAllocString_ModelView, 
	g_iszAllocString_ModelPlayer, 

	g_iszModelIndexBloodSpray,
	g_iszModelIndexBloodDrop,

	HamHook: g_HamHook_TraceAttack[4],

	g_iMsgID_Weaponlist

public plugin_init()
{
	register_plugin("[ZP] Weapon: AK47 Beast", "1.0 | 2018", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);

	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);
	
	g_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,		"func_breakable",	"CEntity__TraceAttack_Pre", false);
	g_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,		"info_target",		"CEntity__TraceAttack_Pre", false);
	g_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,		"player",			"CEntity__TraceAttack_Pre", false);
	g_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,		"hostage_entity",	"CEntity__TraceAttack_Pre", false);
	
	fm_ham_hook(false);

	g_iMsgID_Weaponlist = get_user_msgid("WeaponList");
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_NEW_NAME, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

	// Precache generic
	new szBuffer[64]; formatex(szBuffer, charsmax(szBuffer), "sprites/%s.txt", WEAPON_NEW_NAME);

	engfunc(EngFunc_PrecacheGeneric, szBuffer);
	engfunc(EngFunc_PrecacheGeneric, WEAPON_HUD);
	engfunc(EngFunc_PrecacheGeneric, WEAPON_HUD_AMMO);
	
	// Precache sounds
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_SHOOT);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_STAB_KNIFE);

	UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW);

	// Other
	g_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	g_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	g_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);

	g_iszModelIndexBloodSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
	g_iszModelIndexBloodDrop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");
}

public plugin_natives() register_native("give_ak47beast", "Command_GiveWeapon", 1);

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

public FM_Hook_TraceLine_Post(const Float:flOrigin1[3], const Float:flOrigin2[3], iFrag, iAttacker, iTrace)
{
	if(iFrag & IGNORE_MONSTERS) return FMRES_IGNORED;

	static pHit; pHit = get_tr2(iTrace, TR_pHit);
	static Float:flvecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, flvecEndPos);

	if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, flvecEndPos, 0);
	write_byte(TE_GUNSHOTDECAL);
	engfunc(EngFunc_WriteCoord, flvecEndPos[0]);
	engfunc(EngFunc_WriteCoord, flvecEndPos[1]);
	engfunc(EngFunc_WriteCoord, flvecEndPos[2]);
	write_short(pHit > 0 ? pHit : 0);
	write_byte(random_num(41, 45));
	message_end();

	return FMRES_IGNORED;
}

// [ HamSandwich ]
public CWeapon__Deploy_Post(iItem)
{
	if(!CustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, g_iszAllocString_ModelView);
	set_pev_string(iPlayer, pev_weaponmodel2, g_iszAllocString_ModelPlayer);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

	set_pdata_int(iItem, m_iWeaponState, 0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	if(get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon) == 0)
	{
		static iButton; iButton = pev(iPlayer, pev_button);
		
		if(iButton & IN_ATTACK2 && !get_pdata_int(iItem, m_fInReload, linux_diff_weapon) && get_pdata_float(iItem, m_flNextSecondaryAttack, linux_diff_weapon) <= 0.0)
		{
			new szAnimation[64];

			formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIM_EXTENSION_STAB_KNIFE);
			UTIL_PlayerAnimation(iPlayer, szAnimation);

			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_STAB_KNIFE);
			emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_STAB_KNIFE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			set_pdata_int(iItem, m_iWeaponState, 1, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_STAB_KNIFE_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_STAB_KNIFE_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_STAB_KNIFE_TIME, linux_diff_weapon);
			set_pdata_float(iPlayer, m_flNextAttack, 22/45.0, linux_diff_player);

			iButton &= ~IN_ATTACK2;
			set_pev(iPlayer, pev_button, iButton);
		}
	}
	else
	{
		new Float: flOrigin[3], Float: flAngle[3], Float: flEnd[3], Float: flViewOfs[3];
		new Float: flForw[3], Float: flUp[3], Float: flRight[3];

		pev(iPlayer, pev_origin, flOrigin);
		pev(iPlayer, pev_view_ofs, flViewOfs);

		flOrigin[0] += flViewOfs[0];
		flOrigin[1] += flViewOfs[1];
		flOrigin[2] += flViewOfs[2];
			
		pev(iPlayer, pev_v_angle, flAngle);
		engfunc(EngFunc_AngleVectors, flAngle, flForw, flRight, flUp);
			
		new iTrace = create_tr2();

		new Float: flSendAngles[] = { 0.0, -10.0, 10.0, -5.0, 5.0, -5.0, 5.0, 0.0, 0.0 }
		new Float: flSendAnglesUp[] = { 0.0, 0.0, 0.0, 7.5, 7.5, -7.5, -7.5, -15.0, 15.0 }
		new Float: flTan;
		new Float: flMul;

		new Float: flFraction;
		new pHit, pHitEntity = -1;

		for(new i; i < sizeof flSendAngles; i++)
		{
			flTan = floattan(flSendAngles[i], degrees);

			flEnd[0] = (flForw[0] * WEAPON_STAB_KNIFE_DISTANCE) + (flRight[0] * flTan * WEAPON_STAB_KNIFE_DISTANCE) + flUp[0] * flSendAnglesUp[i];
			flEnd[1] = (flForw[1] * WEAPON_STAB_KNIFE_DISTANCE) + (flRight[1] * flTan * WEAPON_STAB_KNIFE_DISTANCE) + flUp[1] * flSendAnglesUp[i];
			flEnd[2] = (flForw[2] * WEAPON_STAB_KNIFE_DISTANCE) + (flRight[2] * flTan * WEAPON_STAB_KNIFE_DISTANCE) + flUp[2] * flSendAnglesUp[i];
				
			flMul = (WEAPON_STAB_KNIFE_DISTANCE/vector_length(flEnd));
			flEnd[0] *= flMul;
			flEnd[1] *= flMul;
			flEnd[2] *= flMul;

			flEnd[0] = flEnd[0] + flOrigin[0];
			flEnd[1] = flEnd[1] + flOrigin[1];
			flEnd[2] = flEnd[2] + flOrigin[2];

			engfunc(EngFunc_TraceLine, flOrigin, flEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
			get_tr2(iTrace, TR_flFraction, flFraction);

			if(flFraction == 1.0)
			{
				engfunc(EngFunc_TraceHull, flOrigin, flEnd, HULL_HEAD, iPlayer, iTrace);
				get_tr2(iTrace, TR_flFraction, flFraction);
			
				engfunc(EngFunc_TraceLine, flOrigin, flEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
				pHit = get_tr2(iTrace, TR_pHit);
			}
			else
			{
				pHit = get_tr2(iTrace, TR_pHit);
			}
				
			if(pHit > 0 && pHitEntity != pHit)
			{
				if(pev(pHit, pev_solid) == SOLID_BSP && !(pev(pHit, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
				{
					ExecuteHamB(Ham_TakeDamage, pHit, iPlayer, iPlayer, WEAPON_STAB_KNIFE_DAMAGE, DMG_NEVERGIB | DMG_CLUB);
				}
				else
				{
					FakeTraceAttack(pHit, iPlayer, WEAPON_STAB_KNIFE_DAMAGE, flForw, iTrace, DMG_NEVERGIB | DMG_CLUB);
					FakeKnockBack(pHit, flForw, WEAPON_STAB_KNIFE_KNOCKBACK);
				}

				pHitEntity = pHit;
			}
		}

		free_tr2(iTrace);

		set_pdata_int(iItem, m_iWeaponState, 0, linux_diff_weapon);
	}

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

	return HAM_IGNORED;
}

public CWeapon__AddToPlayer_Post(iItem, iPlayer)
{
	switch(pev(iItem, pev_impulse))
	{
		case WEAPON_SPECIAL_CODE: UTIL_WeaponList(iPlayer, true);
		case 0: UTIL_WeaponList(iPlayer, false);
	}
}

public CWeapon__Reload_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE

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
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	if(get_pdata_int(iItem, m_iClip, linux_diff_weapon) == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
	static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
	fm_ham_hook(true);

	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);

	unregister_forward(FM_TraceLine, fw_TraceLine, true);
	unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
	fm_ham_hook(false);

	static Float:vecPunchangle[3];
	pev(iPlayer, pev_punchangle, vecPunchangle);
	vecPunchangle[0] *= WEAPON_PUNCHAGNLE;
	vecPunchangle[1] *= WEAPON_PUNCHAGNLE;
	vecPunchangle[2] *= WEAPON_PUNCHAGNLE;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_SHOOT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float:flDamage)
{
	if(!is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(iItem <= 0 || !CustomItem(iItem)) return;

	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

// [ Other ]
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

public FakeTraceAttack(iVictim, iAttacker, Float: flDamage, Float: vecDirection[3], iTrace, ibitsDamageBits)
{
	static Float: flTakeDamage; pev(iVictim, pev_takedamage, flTakeDamage);

	if(flTakeDamage == DAMAGE_NO) return 0; 
	if(!(is_user_alive(iVictim) && zp_get_user_zombie(iVictim))) return 0;

	if(is_user_connected(iVictim)) 
	{
		if(get_pdata_int(iVictim, m_iPlayerTeam, linux_diff_player) == get_pdata_int(iAttacker, m_iPlayerTeam, linux_diff_player)) 
			return 0;
	}

	static iHitgroup; iHitgroup = get_tr2(iTrace, TR_iHitgroup);
	static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	static iBloodColor; iBloodColor = ExecuteHamB(Ham_BloodColor, iVictim);
	
	set_pdata_int(iVictim, m_LastHitGroup, iHitgroup, linux_diff_player);

	switch(iHitgroup) 
	{
		case HIT_HEAD:                  flDamage *= 3.0;
		case HIT_LEFTARM, HIT_RIGHTARM: flDamage *= 0.75;
		case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 0.75;
		case HIT_STOMACH:               flDamage *= 1.5;
	}
	
	ExecuteHamB(Ham_TakeDamage, iVictim, iAttacker, iAttacker, flDamage, ibitsDamageBits);
	
	if(zp_get_user_zombie(iVictim)) 
	{
		if(iBloodColor != DONT_BLEED) 
		{
			ExecuteHamB(Ham_TraceBleed, iVictim, flDamage, vecDirection, iTrace, ibitsDamageBits);
			UTIL_BloodDrips(vecEndPos, iBloodColor, floatround(flDamage));
		}
	}

	return 1;
}

public FakeKnockBack(iVictim, Float: vecDirection[3], Float: flKnockBack) 
{
	if(!(is_user_alive(iVictim) && zp_get_user_zombie(iVictim))) return 0;

	set_pdata_float(iVictim, m_flPainShock, 1.0, linux_diff_player);

	static Float:vecVelocity[3]; pev(iVictim, pev_velocity, vecVelocity);

	if(pev(iVictim, pev_flags) & FL_DUCKING) 
		flKnockBack *= 0.7;

	vecVelocity[0] = vecDirection[0] * flKnockBack;
	vecVelocity[1] = vecDirection[1] * flKnockBack;
	vecVelocity[2] = 200.0;

	set_pev(iVictim, pev_velocity, vecVelocity);
	
	return 1;
}

// [ Stocks ]
public UTIL_BloodDrips(Float:vecOrigin[3], iColor, iAmount) {
	if(iAmount > 255) iAmount = 255;
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(g_iszModelIndexBloodSpray);
	write_short(g_iszModelIndexBloodDrop);
	write_byte(iColor);
	write_byte(min(max(3,iAmount/10),16));
	message_end();
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

stock UTIL_PlayerAnimation(const iPlayer, const szAnim[]) 
{
	new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
		
	if ((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1) 
	{
		iAnimDesired = 0;
	}
	
	new Float: flGametime = get_gametime();

	set_pev(iPlayer, pev_frame, 0.0);
	set_pev(iPlayer, pev_framerate, 1.0);
	set_pev(iPlayer, pev_animtime, flGametime);
	set_pev(iPlayer, pev_sequence, iAnimDesired);
	
	set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, linux_diff_animation);
	set_pdata_int(iPlayer, m_fSequenceFinished, 0, linux_diff_animation);
	
	set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, linux_diff_animation);
	set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, linux_diff_animation);
	set_pdata_float(iPlayer, m_flLastEventCheck, flGametime , linux_diff_animation);
	
	set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_float(iPlayer, m_flLastAttackTime, flGametime , linux_diff_player);
}