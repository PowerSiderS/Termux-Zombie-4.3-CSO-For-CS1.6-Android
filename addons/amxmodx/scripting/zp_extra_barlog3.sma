#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>
#include <cstrike>
#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)

#define PDATA_SAFE 2

#define WEAPON_ANIM_IDLE 0
#define WEAPON_ANIM_SHOOT 3
#define WEAPON_ANIM_RELOAD 1
#define WEAPON_ANIM_DRAW 2
#define WEAPON_ANIM_SHOOT2 4
#define m_iFOV 363
// From model: Frames/FPS
#define WEAPON_ANIM_IDLE_TIME 2/16.0
#define WEAPON_ANIM_SHOOT_TIME 2.0/20.0
#define WEAPON_ANIM_RELOAD_TIME 2.5
#define WEAPON_ANIM_DRAW_TIME 1.0

#define WEAPON_SPECIAL_CODE 794831
#define WEAPON_REFERENCE "weapon_aug"

#define WEAPON_ITEM_NAME "Balrog-3"
#define WEAPON_ITEM_COST 25

#define WEAPON_MODEL_VIEW "models/v_balrog3.mdl"
#define WEAPON_MODEL_PLAYER "models/p_balrog3.mdl"
#define WEAPON_MODEL_WORLD "models/w_balrog3.mdl"
#define EXPLOSE_SPR "sprites/balrog5stack.spr"   
#define weapon_list_txt "weapon_balrog3"
#define WEAPON_BODY 0

#define WEAPON_MAX_CLIP 30
#define WEAPON_DEFAULT_AMMO 120

#define WEAPON_RATE 0.08
#define WEAPON_PUNCHANGLE 0.832
#define WEAPON_DAMAGE 1.1
#define WEAPON_DAMAGE2 1.3 * 1.5
// Linux extra offsets
#define linux_diff_weapon 4
#define linux_diff_player 5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

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
#define m_iWeaponState 74

// CBaseMonster
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376
#define OFFSET_AMMO_BALROG3 380
new const Sounds[][]=
{
	"weapons/balrig3-1.wav",
	"weapons/balrig3-2.wav"
}
new const weapon_list_sprites[][]=
{	
	"sprites/640hud86.spr",
	"sprites/640hud3.spr"
}

new g_iszAllocString_Entity,
	g_iszAllocString_ModelView, 
	g_iszAllocString_ModelPlayer, 
	g_iItemID,
	g_Shoot[33],
	g_Exp_SprId;

public plugin_init()
{
	register_plugin("[ZP] Weapon: BALROG3", "1.0", "PbI)I(Uu' / Batcoh & xUnicorn: Code base");

	g_iItemID = zp_register_extra_item(WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN);
	register_clcmd(weapon_list_txt,"weapon_list_balrog3");
	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);

	RegisterHam(Ham_Spawn,					"player",			"CPlayer__Spawn_Post", true);
	RegisterHam(Ham_Item_Holster,			WEAPON_REFERENCE,	"CWeapon__Holster_Post", true);
	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Post", true);	
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	WEAPON_REFERENCE,	"CWeapon__SecondaryAttack_Pre", false);
	RegisterHam(Ham_TraceAttack,"worldspawn","fw_TraceAttack",1);
	RegisterHam(Ham_TraceAttack,"func_breakable","fw_TraceAttack",1);
	RegisterHam(Ham_TraceAttack,"func_wall","fw_TraceAttack",1);
	RegisterHam(Ham_TraceAttack,"func_door","fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack,"func_door_rotating","fw_TraceAttack",1);
	RegisterHam(Ham_TraceAttack,"func_plat","fw_TraceAttack",1);
	RegisterHam(Ham_TraceAttack,"func_rotating","fw_TraceAttack",1);
	RegisterHam(Ham_TraceAttack,"player","fw_TraceAttack",1);
	RegisterHam(Ham_TakeDamage,"player","CEntity__TraceAttack_Pre",0)

}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);
	g_Exp_SprId=precache_model(EXPLOSE_SPR)
	new tmp[128]
	formatex(tmp, charsmax(tmp), "sprites/%s.txt", weapon_list_txt);
	precache_generic(tmp);
	for(new i; i<=charsmax(weapon_list_sprites); i++)
	{
		precache_generic(weapon_list_sprites[i]);
	}
	for(new i; i<=charsmax(Sounds); i++)
	{
		precache_sound(Sounds[i]);
	}
	UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW);
	// Other
	g_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	g_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	g_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);
}

// [ Amxx ]
#if AMXX_VERSION_NUM < 183
	public client_disconnect(iPlayer)
#else
	public client_disconnected(iPlayer)
#endif
{
	UTIL_SetRendering(iPlayer);
	set_pev(iPlayer, pev_iuser2, 0);
}

public weapon_list_balrog3(id) client_cmd(id,WEAPON_REFERENCE)
public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem == g_iItemID)
		Command_GiveWeapon(iPlayer);
}
public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(CustomItem(iItem))
	{
		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SHOOT_TIME* 0.67, linux_diff_weapon);
	}
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
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	ExecuteHamB(Ham_Item_AttachToPlayer, iEntity, iPlayer);
	set_pdata_int(iEntity, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	WeapList(iPlayer, weapon_list_txt)
	new iAmmoType = m_rgAmmo + get_pdata_int(iEntity, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, m_rgAmmo, linux_diff_player) < WEAPON_DEFAULT_AMMO)
		set_pdata_int(iPlayer, iAmmoType, WEAPON_DEFAULT_AMMO, linux_diff_player);
		
	g_Shoot[iPlayer] = 0
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

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	static item; item = get_pdata_cbase(iAttacker, 373)
	if(!CustomItem(item)) return
	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	if(iEnt)
	{
		if(zp_get_user_zombie(iEnt))
		{
			if(g_Shoot[iAttacker]>15)
			{
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
				write_byte(TE_SPRITE)
				engfunc(EngFunc_WriteCoord,flEnd[0]);
				engfunc(EngFunc_WriteCoord,flEnd[1]);
				engfunc(EngFunc_WriteCoord,flEnd[2]);
				write_short(g_Exp_SprId)
				write_byte(3)
				write_byte(255)
				message_end()
			}
		}
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_GUNSHOTDECAL);
		engfunc(EngFunc_WriteCoord,flEnd[0]);
		engfunc(EngFunc_WriteCoord,flEnd[1]);
		engfunc(EngFunc_WriteCoord,flEnd[2]);
		write_short(iEnt);
		write_byte(random_num(41,45));
		message_end();
	}
}

// [ HamSandwich ]
public CPlayer__Spawn_Post(iPlayer)
{
	if(!is_user_connected(iPlayer)) return;

	UTIL_SetRendering(iPlayer);
	set_pev(iPlayer, pev_iuser2, 0);
}

public CWeapon__Holster_Post(iItem)
{
	if(!CustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CWeapon__Deploy_Post(iItem)
{
	if(!CustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, g_iszAllocString_ModelView);
	set_pev_string(iPlayer, pev_weaponmodel2, g_iszAllocString_ModelPlayer);
	WeapList(iPlayer, weapon_list_txt)
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);
	g_Shoot[iPlayer] = 0
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

	if(get_pdata_int(iItem, m_fInReload, linux_diff_weapon) == 1)
	{
		static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
		
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
	g_Shoot[iPlayer]=0
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_RELOAD);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);
	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Post(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	if(g_Shoot[iPlayer]>15)
	{
		ExecuteHam(Ham_Weapon_Reload, iItem);
		g_Shoot[iPlayer]=0
		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);
	}
	else
	{
		g_Shoot[iPlayer]=0
	}
	if(get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) < 0.0)
	{
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);
	}
	return HAM_IGNORED;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED
	static clip; clip = get_pdata_int(iItem, m_iClip, linux_diff_weapon)
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(get_pdata_int(iItem, m_iClip, linux_diff_weapon) == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}


	g_Shoot[iPlayer]++
	static Float:vecPunchangle[3];
	pev(iPlayer, pev_punchangle, vecPunchangle);
	vecPunchangle[0] *= WEAPON_PUNCHANGLE ;
	vecPunchangle[1] *= WEAPON_PUNCHANGLE ;
	vecPunchangle[2] *= WEAPON_PUNCHANGLE ;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
	new bpammo = get_pdata_int(iPlayer,OFFSET_AMMO_BALROG3,linux_diff_player)
	if(bpammo == 0)
	{
		g_Shoot[iPlayer]=0
	}
	
		
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_SHOOT_TIME, linux_diff_player)
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon)
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon)
	emit_sound(iPlayer,CHAN_WEAPON,Sounds[0],VOL_NORM,ATTN_NORM,0,PITCH_NORM)
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);
		
	if(g_Shoot[iPlayer] > 15)
	{
		if(bpammo > 0)
		{
			set_pdata_int(iPlayer, OFFSET_AMMO_BALROG3, bpammo-1, linux_diff_player)
		}else{
			g_Shoot[iPlayer]=0
		}
		set_pdata_int(iItem, m_iClip, clip+1)  
		emit_sound(iPlayer,CHAN_WEAPON,Sounds[1],VOL_NORM,ATTN_NORM,0,PITCH_NORM)
		set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_SHOOT_TIME * 0.67, linux_diff_player)
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME * 0.67, linux_diff_weapon)
		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SHOOT_TIME * 0.67, linux_diff_weapon)
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT2); 
	}
	return HAM_IGNORED;
}

public CEntity__TraceAttack_Pre(victim, inflictor, attacker, Float:DAMAGE)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		static iItem; iItem = get_pdata_cbase(attacker, m_pActiveItem, linux_diff_player);
		if(iItem <= 0 || !CustomItem(iItem)) return;
	
		if(g_Shoot[attacker] > 15)
		{
			SetHamParamFloat(4,DAMAGE*WEAPON_DAMAGE2)
		}
		else
		{
			SetHamParamFloat(4,DAMAGE*WEAPON_DAMAGE)
		}	
	}
}
// [ Other ]

// [ Stocks ]
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
public WeapList(id, const weapon[])
{
	message_begin( MSG_ONE, get_user_msgid("WeaponList"), .player=id )
	write_string(weapon) 
	write_byte(4)
	write_byte(90)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(14)
	write_byte(CSW_AUG)
	write_byte(0)
	message_end()		
}
stock UTIL_SetRendering(iPlayer, iFx = 0, iRed = 255, iGreen = 255, iBlue = 255, iRender = 0, Float: flAmount = 16.0)
{
	static Float: flColor[3];
	
	flColor[0] = float(iRed);
	flColor[1] = float(iGreen);
	flColor[2] = float(iBlue);
	
	set_pev(iPlayer, pev_renderfx, iFx);
	set_pev(iPlayer, pev_rendercolor, flColor);
	set_pev(iPlayer, pev_rendermode, iRender);
	set_pev(iPlayer, pev_renderamt, flAmount);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
