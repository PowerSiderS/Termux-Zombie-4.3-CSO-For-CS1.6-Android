#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <beam>

new const WEAPON_ITEM_NAME[] = "CrossBow Ex";
const WEAPON_ITEM_COST = 45;
new const WEAPON_REFERENCE[] = "weapon_ak47";
new const WEAPON_NATIVE[] = "zp_give_user_crossbowex";

new const WEAPON_MODELS[][] =
{
	"models/zpt/v_crossbowex21.mdl",
	"models/zpt/p_crossbowex21.mdl",
	"models/zpt/w_crossbowex21.mdl",
	"sprites/zpt/muzzleflash172.spr",
	"sprites/zpt/muzzleflash173.spr",
	"models/zpt/v_crossbowex21_2s.mdl",
	"sprites/zpt/ishot.spr"
}
new const WEAPON_SOUNDS[][] =
{
	"zpt/crossbowex21-1.wav",
	"zpt/crossbowex21-2.wav",
	"zpt/crossbowex21_zoom.wav",
	"zpt/crossbowex21_beep.wav"
}
const WEAPON_SPECIAL_CODE = 60020210603;

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 121/30.0
#define WEAPON_ANIM_RELOAD_TIME 111/30.0
#define WEAPON_ANIM_DRAW_TIME 31/30.0
#define WEAPON_ANIM_SHOOT_TIME 21/30.0
#define ANIM_CHANGE_TO_DEF_TIME	31/30.0
#define ANIM_CHANGE_TO_EX_TIME 	21/30.0

#define WEAPON_ANIM_IDLE 0
#define WEAPON_ANIM_SHOOT1_A 1
#define WEAPON_ANIM_SHOOT2_A 2
#define WEAPON_ANIM_RELOAD_A 3
#define WEAPON_ANIM_DRAW_A 4
#define WEAPON_ANIM_IDLE_B 5
#define WEAPON_ANIM_SHOOT1_B 6
#define WEAPON_ANIM_SHOOT2_B 7
#define WEAPON_ANIM_RELOAD_B 8
#define WEAPON_ANIM_DRAW_B 9
#define WEAPON_ANIM_ZOOM_IN 10	
#define WEAPON_ANIM_ZOOM_IDLE 11
#define WEAPON_ANIM_ZOOM_SHOOT 12
#define WEAPON_ANIM_ZOOM_OUT_A 13
#define WEAPON_ANIM_ZOOM_OUT_B 14	

#define WEAPONSTATE_MODE	(1<<7)
#define WEAPONSTATE_SKIN	(1<<6)
#define WEAPONSTATE_SCOPE	(1<<5)

const Float: MUZZLE_TIME_SHOOT = 0.03;// Время обновления спрайта при выстреле

//settings
#define WEAPON_MAX_ENERGY 10				//максимум накопленной энергии
#define ZP_WEAPON_ENERGY_NEW 1.0			//время обновления траты/накопления заряда у 2 режима
#define WEAPON_MAX_CLIP 50				//патроны в магазине
#define WEAPON_DEFAULT_AMMO 200				//патроны в запасе
#define WEAPON_RATE 0.15				//скорострельность
#define WEAPON_PUNCHANGLE 0.65				//отдача	
#define DMG_BULLET_1_MOD 0.95				//дамаг 1 режим
#define DMG_BULLET_2_MOD random_float(300.0,500.0)	//дамаг 2 режим

/* ~ [ Params ] ~ */
new gl_iszAllocString_Entity,
	gl_iszAllocString_ModelView,
	gl_iszAllocString_ModelView_2s,
	gl_iszAllocString_ModelPlayer,
	gl_iMsgID_Weaponlist,
	gl_iItemID,
	g_SmokePuff_Id_blue,
	g_SmokePuff_Id_red,
	gl_iszModelIndex_BloodSpray,
	gl_iszModelIndex_BloodDrop,
	g_iszMuzzleKeyShoot,
	HamHook: gl_HamHook_TraceAttack[4],
	g_iszBeamKey2,
	Enable_beep[33],
	Enable_zoom,
	Enable_item[33],
	g_sprite,
	Enable_reload[33];
	
/* ~ [ Macroses ] ~ */

#define IsValidEntity(%0) (pev_valid(%0) == PDATA_SAFE)
#define IsCustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define CustomMuzzleShoot(%0) (pev(%0, pev_impulse) == g_iszMuzzleKeyShoot)
#define Sprite_SetScale(%0,%1) set_pev(%0, pev_scale, %1)
#define MUZZLE_CLASSNAME4 "ent_crossbowmuzle1" // класс спрайта выстрела
#define PDATA_SAFE 2
#define MUZZLE_INTOLERANCE 100

#define WEAPON_SPRITE_LINE3	"sprites/laserbeam.spr"
#define BEAM_CLASSNAME2			"szBeamCrossBow21"
#define BEAM_COLOR 			{246.0, 56.0, 148.0}
#define BEAM_SCROLLRATE			20.0
#define BEAM_NOISE			0
#define BEAM_WEIGHT			20.0		
#define BEAM_FRAMECHANGETIME		0.005
#define IsCustomBeam2(%0) (pev(%0, pev_impulse) == g_iszBeamKey2)
new const iWeaponList[] = 			{ 2,  90, -1, -1, 0, 1, CSW_AK47, 0 };
new const WEAPON_WEAPONLIST[] = 	"zpt/weapon_crossbowex21";
/* ~ [ Offsets ] ~ */
// Linux extra offsets
#define linux_diff_animating 4
#define linux_diff_weapon 4
#define linux_diff_player 5

// CWeaponBox
#define m_fInSuperBullets 30
#define m_rgpPlayerItems_CWeaponBox 34
#define m_maxFrame 35
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
#define m_flAccuracy 62

// CBaseMonster
#define m_iScope 70
#define m_iSkin 72
#define m_Activity 73
#define m_iWeaponState 74
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376
#define m_szAnimExtention 492

public plugin_init()
{
	register_plugin("[ZP] Weapon: CrossbowEx", "1.0", "PeTRoX | t3rke/Batcoh: Code base");
	register_forward(FM_UpdateClientData,					"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_PlaybackEvent, 					"fw_PlaybackEvent");
	register_forward(FM_SetModel, 						"FM_Hook_SetModel_Pre", false);
	RegisterHam(Ham_Item_Holster,			WEAPON_REFERENCE,	"CWeapon__Holster_Post", true);
	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,		WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,		WEAPON_REFERENCE,	"CWeapon__SecondaryAttack_Pre", false);
	RegisterHam(Ham_Think, 				"env_sprite", 		"CWeapon__Think_Pre", false);
	RegisterHam(Ham_Think, 				"beam", 		"CWeapon__Think_Beam", true);
	
	gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,	"func_breakable",	"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",		"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",		"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",	"CEntity__TraceAttack_Pre", false);
	
	fm_ham_hook(false);
	
	// Register on Extra-Items
	gl_iItemID = zp_register_extra_item(WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN);

	// Messages
	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	
	// Alloc String

	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODELS[0]);
	gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODELS[1]);	
	gl_iszAllocString_ModelView_2s = engfunc(EngFunc_AllocString, WEAPON_MODELS[5]);	

}

public plugin_precache()
{
	new i;

	g_SmokePuff_Id_blue = engfunc(EngFunc_PrecacheModel, WEAPON_MODELS[3]);
	g_SmokePuff_Id_red = engfunc(EngFunc_PrecacheModel, WEAPON_MODELS[4]);
	
	for(i = 0; i < sizeof WEAPON_MODELS; i++)
		engfunc(EngFunc_PrecacheModel, WEAPON_MODELS[i]);
	
	// Precache sounds
	for(i = 0; i < sizeof WEAPON_SOUNDS; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUNDS[i]);
	g_sprite = engfunc(EngFunc_PrecacheModel, WEAPON_MODELS[6]);
	g_iszMuzzleKeyShoot = engfunc(EngFunc_AllocString, MUZZLE_CLASSNAME4);
	UTIL_PrecacheSoundsFromModel(WEAPON_MODELS[0]);
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	gl_iszModelIndex_BloodSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
	gl_iszModelIndex_BloodDrop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

public Command_HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}
#if AMXX_VERSION_NUM < 183
	public client_disconnect(iPlayer)
#else
	public client_disconnected(iPlayer)
#endif
{
	Enable_reload[iPlayer]=0
	Enable_item[iPlayer]=0
}
public zp_user_infected_pre(iPlayer)
{
	
	if(is_user_connected(iPlayer))
	{
		Enable_reload[iPlayer]=0
		Enable_item[iPlayer]=0
	}
}
public FM_Hook_TraceLine_Post(const Float: vecStart[3], const Float: vecEnd[3], iFlags, iAttacker, iTrace)
{
	if(iFlags & IGNORE_MONSTERS) return FMRES_IGNORED;
	if(!is_user_alive(iAttacker)) return FMRES_IGNORED;

	static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	static pHit; pHit = get_tr2(iTrace, TR_pHit);
	if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;
	if(zp_get_user_zombie(iAttacker))
	{
		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecEndPos, 0)
		write_byte(TE_EXPLOSION); // TE
		engfunc(EngFunc_WriteCoord, vecEndPos[0]); // Position X
		engfunc(EngFunc_WriteCoord, vecEndPos[1]); // Position Y
		engfunc(EngFunc_WriteCoord, vecEndPos[2]-10.0); // Position Z
		write_short(g_SmokePuff_Id_blue); // Model Index
		write_byte(2); // Scale
		write_byte(30); // Framerate
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // Flags
		message_end();	
		return FMRES_IGNORED;
	}
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecEndPos, 0)
	write_byte(TE_EXPLOSION); // TE
	engfunc(EngFunc_WriteCoord, vecEndPos[0]); // Position X
	engfunc(EngFunc_WriteCoord, vecEndPos[1]); // Position Y
	engfunc(EngFunc_WriteCoord, vecEndPos[2]-10.0); // Position Z
	write_short(g_SmokePuff_Id_blue); // Model Index
	write_byte(2); // Scale
	write_byte(30); // Framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // Flags
	message_end();
	static Float: VecPlayer[3];
	get_weapon_position(iAttacker, VecPlayer, 18.0, 5.0, -5.0)
	static Float: vecVelocity[3];
	vecVelocity[0] = vecEndPos[0] - VecPlayer[0];
	vecVelocity[1] = vecEndPos[1] - VecPlayer[1];
	vecVelocity[2] = vecEndPos[2] - VecPlayer[2];
	xs_vec_normalize(vecVelocity, vecVelocity);
	xs_vec_mul_scalar(vecVelocity, 4096.0, vecVelocity);
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte(TE_USERTRACER);
	engfunc(EngFunc_WriteCoord, VecPlayer[0]);
	engfunc(EngFunc_WriteCoord, VecPlayer[1]);
	engfunc(EngFunc_WriteCoord, VecPlayer[2]);
	engfunc(EngFunc_WriteCoord, vecVelocity[0]);
	engfunc(EngFunc_WriteCoord, vecVelocity[1]);
	engfunc(EngFunc_WriteCoord, vecVelocity[2]);
	write_byte(50); // Life
	write_byte(7); // Color
	write_byte(5); // Lenght
	message_end();

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
	write_byte(TE_GUNSHOTDECAL);
	engfunc(EngFunc_WriteCoord, vecEndPos[0]);
	engfunc(EngFunc_WriteCoord, vecEndPos[1]);
	engfunc(EngFunc_WriteCoord, vecEndPos[2]);
	write_short(pHit > 0 ? pHit : 0);
	write_byte(random_num(41,45));
	message_end();
	
	new Float:vecPlaneNormal[3]; get_tr2(iTrace, TR_vecPlaneNormal, vecPlaneNormal);

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEndPos, 0);
	write_byte(TE_STREAK_SPLASH);
	engfunc(EngFunc_WriteCoord, vecEndPos[0]);
	engfunc(EngFunc_WriteCoord, vecEndPos[1]);
	engfunc(EngFunc_WriteCoord, vecEndPos[2]);
	engfunc(EngFunc_WriteCoord, vecPlaneNormal[0] * random_float(25.0, 30.0));
	engfunc(EngFunc_WriteCoord, vecPlaneNormal[1] * random_float(25.0, 30.0));
	engfunc(EngFunc_WriteCoord, vecPlaneNormal[2] * random_float(25.0, 30.0));
	write_byte(7); // Color
	write_short(random_num(15, 17)); // Count
	write_short(1); // Speed
	write_short(100); // Speed noice
	message_end();
	
	return FMRES_IGNORED;
}
public Command_GiveWeapon(iPlayer)
{
	static iWeapon; iWeapon = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
	if(iWeapon <= 0) return 0;
	set_pev(iWeapon, pev_skin, random_num(0,1))
	set_pev(iWeapon, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, iWeapon);
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	UTIL_DropWeapon(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));
	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iWeapon))
	{
		set_pev(iWeapon, pev_flags, pev(iWeapon, pev_flags) | FL_KILLME)
		return 0;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, iWeapon, iPlayer);
	
	new iAmmoType = m_rgAmmo + get_pdata_int(iWeapon, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, m_rgAmmo, linux_diff_player) < WEAPON_DEFAULT_AMMO)
		set_pdata_int(iPlayer, iAmmoType, WEAPON_DEFAULT_AMMO, linux_diff_player);

	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	set_pdata_int(iWeapon, m_fInSuperBullets, 0, 4);
	SetExtraAmmo(iPlayer, 0);
	SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iWeapon), WEAPON_DEFAULT_AMMO);
	Enable_item[iPlayer]=1
	return 1;
}

public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem == gl_iItemID)
		Command_GiveWeapon(iPlayer);
}

public CWeapon__Holster_Post(iItem)
{
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(is_user_connected(iPlayer)&&IsCustomItem(iItem))
	{
		Enable_item[iPlayer]=0
		Enable_reload[iPlayer]=0
		static bitsWeaponState; bitsWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);
		if (bitsWeaponState & WEAPONSTATE_MODE) 
		{
			set_screen_empty(iPlayer);
			bitsWeaponState &= ~WEAPONSTATE_MODE;
			set_pdata_int(iItem, m_iWeaponState, bitsWeaponState, linux_diff_weapon);
		}
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
		set_pev(iItem, pev_iuser1, 0);
		set_task(ZP_WEAPON_ENERGY_NEW,"plusa",iItem,_,_,"b");	
	}
}

public CWeapon__Deploy_Post(iItem)
{
	if(!IsCustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(get_pdata_int(iItem, m_iSkin, linux_diff_weapon) & WEAPONSTATE_SKIN)
	{
		set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView_2s);
	}
	else
	{
		set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
	}
	set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);
	set_pdata_string(iPlayer, m_szAnimExtention * 4, "ak47", -1, linux_diff_player * linux_diff_animating);
	
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
	static iShoots; iShoots = get_pdata_int(iItem, m_fInSuperBullets, 4)
	UTIL_WeaponList(iPlayer,1,true)
	SetExtraAmmo(iPlayer, iShoots);
	static bitsWeaponState; bitsWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);
	if (bitsWeaponState & WEAPONSTATE_MODE) 
	{
		bitsWeaponState &= ~WEAPONSTATE_MODE;
		set_pdata_int(iItem, m_iWeaponState, bitsWeaponState, linux_diff_weapon);
	}
	UTIL_SendWeaponAnim(iPlayer, iShoots>9?WEAPON_ANIM_DRAW_B:WEAPON_ANIM_DRAW_A);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
	remove_task(iItem)
	static Float:fTime;
	pev(iItem,pev_fuser1,fTime);
	set_pev(iItem, pev_fuser1, fTime)
	Enable_item[iPlayer]=1
	static bitsWeaponScope; bitsWeaponScope = get_pdata_int(iItem, m_iScope, linux_diff_weapon);
	if (bitsWeaponScope & WEAPONSTATE_SCOPE) 
	{	
		bitsWeaponState &= ~WEAPONSTATE_SCOPE;
		set_pdata_int(iItem, m_iScope, bitsWeaponScope, linux_diff_weapon);
	}	
}

public client_PreThink(iPlayer)
{
	if(Enable_beep[iPlayer])
	{
		emit_sound(iPlayer, CHAN_STATIC, WEAPON_SOUNDS[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		Enable_beep[iPlayer]=0
	}
	if(Enable_reload[iPlayer])
	{
		static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
		if(IsCustomItem(iItem))
		{
			static bitsWeaponState; bitsWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);
			if (bitsWeaponState != WEAPONSTATE_MODE)
			{
				static Float:fTimeNewEn
				pev(iItem, pev_fuser1, fTimeNewEn)
				if(get_gametime() >= fTimeNewEn)
				{	

					if(get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon) < WEAPON_MAX_ENERGY)
					{
						static iShoots; iShoots = get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon);
						set_pdata_int(iItem, m_fInSuperBullets,iShoots+1, linux_diff_weapon);
						SetExtraAmmo(iPlayer, iShoots+1);
						if(get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon) == WEAPON_MAX_ENERGY)
						{
							Enable_beep[iPlayer]=1;
							//set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
						}
						set_pev(iItem, pev_fuser1, get_gametime()+ZP_WEAPON_ENERGY_NEW);
						
					}			
				}
				//client_print(iPlayer,print_center,"enable_reload %d",random_num(0,100))
			}

		}
		
	}
	
	if(Enable_item[iPlayer])
	{
		static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
		if(IsValidEntity(iItem)&&IsCustomItem(iItem)&&get_pdata_int(iItem, m_iScope, linux_diff_weapon) & WEAPONSTATE_SCOPE)
		{
			static Float: fTime;
			pev(iItem,pev_fuser2,fTime);	
			static iVictim;iVictim = FM_NULLENT;			
			static Float:vecOrigin[3];
			pev(iPlayer,pev_origin,vecOrigin);
			//client_print(iPlayer,print_chat,"Enable_item %d",random_num(0,100))
			while((iVictim = find_ent_in_sphere(iVictim, vecOrigin, 99999.9)) > 0)
			{
				if(is_user_connected(iVictim))
				{
					if(is_user_alive(iVictim))
					{
						
						if(iVictim == iPlayer || !zp_get_user_zombie(iVictim) )
							continue;
					}

					static Float:vecEnd[3];
					pev(iVictim, pev_origin, vecEnd);
					static b; b = 1;
					
					if(is_user_alive(iVictim))
					{
						if(fm_is_in_viewcone(iPlayer, vecEnd)&&!IsWallBetweenPoints(vecOrigin, vecEnd, iPlayer)) 
						{
							message_begin(MSG_ONE, SVC_TEMPENTITY, _, iPlayer)
							write_byte(TE_PLAYERATTACHMENT)
							write_byte(iVictim)
							write_coord(0)
							write_short(g_sprite)
							write_short(b)
							message_end()
						}
						else
						{
							message_begin(MSG_ONE, SVC_TEMPENTITY, _, iPlayer)
							write_byte(TE_KILLPLAYERATTACHMENTS)
							write_byte(iVictim)
							message_end()
						}
					}
					else
					{
						message_begin(MSG_ONE, SVC_TEMPENTITY, _, iPlayer)
						write_byte(TE_KILLPLAYERATTACHMENTS)
						write_byte(iVictim)
						message_end()
						continue
					}
				}
			}
		}
	}
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!is_user_connected(iPlayer)) return HAM_IGNORED;
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	static iShoots; iShoots = get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon);

	static bitsWeaponState; bitsWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);

	if(get_pdata_int(iItem, m_fInReload, linux_diff_weapon) == 1)
	{
		static iPrimaryAmmoIndex;iPrimaryAmmoIndex = PrimaryAmmoIndex(iItem);
		static iAmmoPrimary;iAmmoPrimary = GetAmmoInventory(iPlayer, iPrimaryAmmoIndex);
		static iAmount;iAmount= min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary);
		set_pdata_int(iItem, m_iClip, iClip + iAmount, linux_diff_weapon);
		set_pdata_int(iItem, m_fInReload, 0, linux_diff_weapon);
		SetAmmoInventory(iPlayer, iPrimaryAmmoIndex, iAmmoPrimary - iAmount);
		Enable_reload[iPlayer]=0
	}
	static Float:fTimeNewEn
	pev(iItem, pev_fuser1, fTimeNewEn)
	if(get_gametime() >= fTimeNewEn)
	{	
		if(get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon) < WEAPON_MAX_ENERGY)
		{
			if (bitsWeaponState != WEAPONSTATE_MODE) 
			{
				static iShoots; iShoots = get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon);
				set_pdata_int(iItem, m_fInSuperBullets,iShoots+1, linux_diff_weapon);
				SetExtraAmmo(iPlayer, iShoots+1);
				if(get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon) == WEAPON_MAX_ENERGY&&get_pdata_int(iItem, m_fInReload, linux_diff_weapon) == 0)
				{
					Enable_beep[iPlayer]=1;
					set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
				}
				set_pev(iItem, pev_fuser1, get_gametime()+ZP_WEAPON_ENERGY_NEW);		
			}
		}
	}
	static iButton; iButton = pev(iPlayer, pev_button);
	if(iButton & IN_ATTACK2 && get_pdata_float(iItem, m_flNextPrimaryAttack, linux_diff_weapon) < 0.0 && get_pdata_float(iItem, m_flNextSecondaryAttack, linux_diff_weapon) !=ANIM_CHANGE_TO_DEF_TIME)
	{
		ExecuteHamB(Ham_Weapon_SecondaryAttack, iItem);
		iButton &= ~IN_ATTACK2;
		set_pev(iPlayer, pev_button, iButton);
	}	
	if (bitsWeaponState & WEAPONSTATE_MODE) 
	{
		if(iShoots<1)
		{
			static bitsWeaponSkin; bitsWeaponSkin = get_pdata_int(iItem, m_iSkin, linux_diff_weapon);
			set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
			bitsWeaponSkin &= ~WEAPONSTATE_SKIN
			set_pdata_int(iItem, m_iSkin, bitsWeaponSkin, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_CHANGE_TO_DEF_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_CHANGE_TO_DEF_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_CHANGE_TO_DEF_TIME, linux_diff_weapon);
			set_pdata_float(iPlayer, m_flNextAttack, ANIM_CHANGE_TO_DEF_TIME, linux_diff_player);
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_ZOOM_OUT_A);
			set_screen_empty(iPlayer)
			bitsWeaponState &= ~WEAPONSTATE_MODE;
			set_pdata_int(iItem, m_iWeaponState, bitsWeaponState, linux_diff_weapon);
			emit_sound(iPlayer, CHAN_WEAPON, "weapons/crossbowex21_zoom_out.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		
	}
	static Float:fTimeScope
	pev(iItem, pev_fuser4, fTimeScope)
	if(get_gametime() >= fTimeScope&&bitsWeaponState & WEAPONSTATE_MODE&&Enable_zoom)
	{	
		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, iPlayer)
		write_short(1<<10)
		write_short(1<<10)
		write_short(0x0004)
		write_byte(246)
		write_byte(56)
		write_byte(148)
		write_byte(15)
		message_end()
		static bitsWeaponScope; bitsWeaponScope = get_pdata_int(iItem, m_iScope, linux_diff_weapon);	
		bitsWeaponScope |= WEAPONSTATE_SCOPE;
		set_pdata_int(iItem, m_iScope, bitsWeaponScope, linux_diff_weapon);
		set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView_2s);
		static bitsWeaponSkin; bitsWeaponSkin = get_pdata_int(iItem, m_iSkin, linux_diff_weapon);
		bitsWeaponSkin |= WEAPONSTATE_SKIN
		set_pdata_int(iItem, m_iSkin, bitsWeaponSkin, linux_diff_weapon);
		emit_sound(iPlayer, CHAN_STATIC, WEAPON_SOUNDS[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		Enable_zoom=0
		
	}	

	
	return HAM_IGNORED;
}

public CWeapon__AddToPlayer_Post(iItem, iPlayer)
{
	if(IsCustomItem(iItem))
	{
		UTIL_WeaponList(iPlayer, 1, true);
		SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem), pev(iItem, pev_iuser2));
		Enable_item[iPlayer]=1
	}
	else if(pev(iItem, pev_impulse) == 0) UTIL_WeaponList(iPlayer, -1, false);
}

public CWeapon__Reload_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;
	static iShoots; iShoots = get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon);
	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	Enable_reload[iPlayer]=1
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInReload, 1, linux_diff_weapon);
	UTIL_SendWeaponAnim(iPlayer, iShoots>9?WEAPON_ANIM_RELOAD_B:WEAPON_ANIM_RELOAD_A);
	static bitsWeaponState; bitsWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);
	if (bitsWeaponState & WEAPONSTATE_MODE)
	{
		set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
		static bitsWeaponSkin; bitsWeaponSkin = get_pdata_int(iItem, m_iSkin, linux_diff_weapon);
		bitsWeaponSkin &= ~ WEAPONSTATE_SKIN
		set_pdata_int(iItem, m_iSkin, bitsWeaponSkin, linux_diff_weapon);
		set_screen_empty(iPlayer)
		bitsWeaponState &= ~WEAPONSTATE_MODE;
		set_pdata_int(iItem, m_iWeaponState, bitsWeaponState, linux_diff_weapon);
	}
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);
	
	return HAM_SUPERCEDE;
	
}
	
public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;
	if(get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);
	static iShoots; iShoots = get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon);
	static bitsWeaponState; bitsWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);
	if (bitsWeaponState & WEAPONSTATE_MODE) 
	{
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_ZOOM_IDLE);
		
	}
	else
	{
		UTIL_SendWeaponAnim(iPlayer, iShoots>9?WEAPON_ANIM_IDLE_B:WEAPON_ANIM_IDLE);
	}
	return HAM_SUPERCEDE;
}
public CWeapon__SecondaryAttack_Pre(iItem)
{
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iShoots; iShoots = get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon);
	static bitsWeaponState; bitsWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);
	if (bitsWeaponState != WEAPONSTATE_MODE&&iShoots>9) 
	{	
		set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_CHANGE_TO_EX_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_CHANGE_TO_EX_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_CHANGE_TO_EX_TIME, linux_diff_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, ANIM_CHANGE_TO_EX_TIME, linux_diff_player);
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_ZOOM_IN);
		bitsWeaponState |= WEAPONSTATE_MODE
		set_pev(iItem, pev_fuser1,get_gametime()+ANIM_CHANGE_TO_EX_TIME+ZP_WEAPON_ENERGY_NEW)
		Enable_zoom=1
		emit_sound(iPlayer, CHAN_WEAPON, "weapons/crossbowex21_zoom_in.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		
	}
	else if(bitsWeaponState & WEAPONSTATE_MODE) 
	{
		set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_CHANGE_TO_DEF_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_CHANGE_TO_DEF_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_CHANGE_TO_DEF_TIME, linux_diff_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, ANIM_CHANGE_TO_DEF_TIME, linux_diff_player);
		UTIL_SendWeaponAnim(iPlayer, iShoots>9?WEAPON_ANIM_ZOOM_OUT_B:WEAPON_ANIM_ZOOM_OUT_A);
		bitsWeaponState &= ~WEAPONSTATE_MODE;
		set_screen_empty(iPlayer)
		set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
		static bitsWeaponSkin; bitsWeaponSkin = get_pdata_int(iItem, m_iSkin, linux_diff_weapon);
		bitsWeaponSkin &= ~ WEAPONSTATE_SKIN
		set_pdata_int(iItem, m_iSkin, bitsWeaponSkin, linux_diff_weapon);
		set_pev(iItem, pev_fuser1,get_gametime()+ANIM_CHANGE_TO_EX_TIME+ZP_WEAPON_ENERGY_NEW)
		emit_sound(iPlayer, CHAN_WEAPON, "weapons/crossbowex21_zoom_out.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
	}
	set_pdata_int(iItem, m_iWeaponState, bitsWeaponState, linux_diff_weapon);
	return HAM_IGNORED;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;
	if(get_pdata_float(iItem, m_flNextPrimaryAttack, linux_diff_weapon) > 0.0) return HAM_SUPERCEDE;
	static iShoots; iShoots = get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	//static bitsWeaponState; bitsWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!iClip)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	

	if (get_pdata_int(iItem, m_iWeaponState, 4) & WEAPONSTATE_MODE) 
	{
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_ZOOM_SHOOT);
		Weapon_MuzzleFlash(iPlayer, WEAPON_MODELS[4], 0.15, 255.0, 1, 1);
		set_pdata_int(iItem, m_fInSuperBullets, iShoots-1, linux_diff_weapon);
		SetExtraAmmo(iPlayer, iShoots-1);	
		set_pdata_float(iItem, m_flNextSecondaryAttack, 1.0, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 1.0, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, 1.0, linux_diff_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, 0.5, linux_diff_player);
		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		create_beam_shoot(iItem,iPlayer);
		new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
        
		if((iAnimDesired = lookup_sequence(iPlayer, "crouch_shoot_ak47", flFrameRate, bLoops, flGroundSpeed)) == -1)
		{
			iAnimDesired = 0;
		}
		    
		new Float: flGameTime = get_gametime();
		
		set_pev(iPlayer, pev_frame, 0.0);
		set_pev(iPlayer, pev_framerate, 1.0);
		set_pev(iPlayer, pev_animtime, flGameTime);
		set_pev(iPlayer, pev_sequence, iAnimDesired);
		    
		set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, linux_diff_animating);
		set_pdata_int(iPlayer, m_fSequenceFinished, 0, linux_diff_animating);
		    
		set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, linux_diff_animating);
		set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, linux_diff_animating);
		set_pdata_float(iPlayer, m_flLastEventCheck, flGameTime , linux_diff_animating);
		    
		set_pdata_int(iPlayer, m_Activity, 28, linux_diff_player);
		set_pdata_int(iPlayer, 74, 28, linux_diff_player);
		set_pdata_float(iPlayer, 220, flGameTime , linux_diff_player);
	}
	else
	{
		static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
		fm_ham_hook(true);
		state FireBullets: Enabled;
		ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
		state FireBullets: Disabled;
		unregister_forward(FM_TraceLine, fw_TraceLine, true);
		fm_ham_hook(false);	
		set_pdata_float(iItem, m_flAccuracy, 0.001, linux_diff_weapon);
		static Float: vecPunchangle[3];
		vecPunchangle[0] = -WEAPON_PUNCHANGLE * 2.0;
		vecPunchangle[1] = random_float(-WEAPON_PUNCHANGLE * 2.0, WEAPON_PUNCHANGLE * 2.0);
		vecPunchangle[2] = 0.0;
		set_pev(iPlayer, pev_punchangle, vecPunchangle);
		Weapon_MuzzleFlash(iPlayer, WEAPON_MODELS[3], 0.1, 255.0, 1, 1);
		UTIL_SendWeaponAnim(iPlayer, iShoots>9?WEAPON_ANIM_SHOOT1_B:WEAPON_ANIM_SHOOT1_A);
		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_RATE, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_RATE+0.68, linux_diff_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, WEAPON_RATE, linux_diff_player);
	}
	return HAM_SUPERCEDE;
}

public create_beam_shoot(iItem,iPlayer)
{
	static Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);		
	get_weapon_position(iPlayer, vecOrigin, 18.0, 0.0, -5.0)
	
	static nobody
	new pPlayer = Players_GetRandomIndex(iPlayer, nobody)
	if(Players_GetRandomIndex(iPlayer, nobody)==nobody)
	{
		static Float:vecLook[3];
		fm_get_aim_origin(iPlayer, vecLook)
		Weapon_DrawBeam2(iPlayer, vecLook)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION); // TE
		engfunc(EngFunc_WriteCoord, vecLook[0]); // Position X
		engfunc(EngFunc_WriteCoord, vecLook[1]); // Position Y
		engfunc(EngFunc_WriteCoord, vecLook[2]-10.0); // Position Z
		write_short(g_SmokePuff_Id_red); // Model Index
		write_byte(7); // Scale
		write_byte(25); // Framerate
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // Flags
		message_end();
		static iVictim;iVictim = FM_NULLENT;			
	
		while((iVictim = find_ent_in_sphere(iVictim, vecLook, 100.0)) > 0)
		{
			if(pev(iVictim, pev_takedamage) == DAMAGE_NO) continue;
			static classnameptd[32]; pev(iVictim, pev_classname, classnameptd, 31);
			if (equali(classnameptd, "func_breakable")) 
			{
				ExecuteHamB(Ham_TakeDamage, iVictim, 0, 0, 250.0, DMG_GENERIC);
			}
			if(is_user_connected(iVictim) && is_user_alive(iVictim))
			{
				if(iVictim == iPlayer || !zp_get_user_zombie(iVictim) ) continue;
				static Float:OrigVictim[3];
				pev(iVictim, pev_origin, OrigVictim)
				UTIL_BloodDrips(OrigVictim, iVictim, floatround(DMG_BULLET_2_MOD*0.5));
				set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);
				ExecuteHamB(Ham_TakeDamage, iVictim, iPlayer, iPlayer, DMG_BULLET_2_MOD*0.5, DMG_GENERIC);
			}
		}
		
	}
	else
	{
		static Float:vec[3];
		pev(pPlayer, pev_origin, vec)
		Weapon_DrawBeam2(iPlayer, vec)
		if(is_user_alive(pPlayer))
		{
			UTIL_BloodDrips(vec, pPlayer, floatround(DMG_BULLET_2_MOD));
			set_pdata_int(pPlayer, m_LastHitGroup, HIT_GENERIC, linux_diff_player);
			ExecuteHamB(Ham_TakeDamage, pPlayer, iPlayer, iPlayer, DMG_BULLET_2_MOD, DMG_GENERIC);
		}
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION); // TE
		engfunc(EngFunc_WriteCoord, vec[0]); // Position X
		engfunc(EngFunc_WriteCoord, vec[1]); // Position Y
		engfunc(EngFunc_WriteCoord, vec[2]-10.0); // Position Z
		write_short(g_SmokePuff_Id_red); // Model Index
		write_byte(7); // Scale
		write_byte(25); // Framerate
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // Flags
		message_end();
	}
}
Players_GetRandomIndex(iPlayer,nobody)
{
	new iIndex, szIndex[33],Float:vecOrigin[3];
	
	pev(iPlayer,pev_origin,vecOrigin);
	static Float:vecId[3];
	for(new pId = 1; pId <= get_maxplayers(); pId++)
	{
		
		if(!is_user_connected(pId) || !is_user_alive(pId) || iPlayer == pId || !zp_get_user_zombie(pId)) continue;
		
		pev(pId,pev_origin,vecId);
		if(fm_is_in_viewcone(iPlayer, vecId)&&!IsWallBetweenPoints(vecOrigin, vecId, iPlayer)) 
		{
			szIndex[++iIndex] = pId;
		}
		else
		{
			szIndex[32] = nobody
		}
	}
	return szIndex[random_num(1, iIndex)];
}

public fw_PlaybackEvent() <FireBullets: Enabled> { return FMRES_SUPERCEDE; }
public fw_PlaybackEvent() <FireBullets: Disabled> { return FMRES_IGNORED; }
public fw_PlaybackEvent() <> { return FMRES_IGNORED; }
public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
	if(!is_user_connected(iAttacker)) return HAM_IGNORED;
	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;
	SetHamParamFloat(3, flDamage * DMG_BULLET_1_MOD);
	return HAM_IGNORED;
}
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(!is_user_alive(iPlayer)) return;
	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;
	set_cd(CD_Handle, CD_flNextAttack, get_gametime()+0.001);	
}

public FM_Hook_SetModel_Pre(iEntity)
{
	static i, szClassName[32], iItem;
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

	for(i = 0; i < 6; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, linux_diff_weapon);

		if(IsValidEntity(iItem) && IsCustomItem(iItem))
		{
			engfunc(EngFunc_SetModel, iEntity, WEAPON_MODELS[2]);
			set_pev(iEntity, pev_body, 0);
			set_task(ZP_WEAPON_ENERGY_NEW,"plusa",iItem,_,_,"b")
			
			set_pev(iItem, pev_iuser2, GetAmmoInventory(pev(iEntity,pev_owner), PrimaryAmmoIndex(iItem)))
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}
public plusa(iItem) //функция для таска накопления одного заряда
{
	if(!IsValidEntity(iItem)) return HAM_IGNORED;
	static Float:fTimeNewEn
	pev(iItem, pev_fuser1, fTimeNewEn)

	if(get_gametime() >= fTimeNewEn)
	{		
		if(get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon) < WEAPON_MAX_ENERGY)
		{
			static iShoots; iShoots = get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon);
			set_pdata_int(iItem, m_fInSuperBullets,iShoots+1, linux_diff_weapon)
			set_pev(iItem, pev_fuser1, get_gametime()+ZP_WEAPON_ENERGY_NEW)
		}
		else
		{
			remove_task(iItem)
		}	
	}
	return HAM_IGNORED;
}


public UTIL_BloodDrips(Float: vecOrigin[3], iVictim, iAmount)
{
	if(iAmount > 255) iAmount = 255;
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
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

stock UTIL_DropWeapon(iPlayer, iSlot)
{
	static iEntity, iNext, szWeaponName[32];
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

	if(IsValidEntity(iEntity))
	{
		Enable_item[iPlayer]=0
		Enable_reload[iPlayer]=0
		do
		{
			iNext = get_pdata_cbase(iEntity, m_pNext, linux_diff_weapon);

			if(get_weaponname(get_pdata_int(iEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
			{
				
				engclient_cmd(iPlayer, "drop", szWeaponName);
			}
		}
		
		while((iEntity = iNext) > 0);
	}
}
	
public CWeapon__Think_Pre(iSprite)
{
	if(!IsValidEntity(iSprite)) return HAM_IGNORED;
	if(CustomMuzzleShoot(iSprite))
	{
		static Float: flFrame;
		if (pev(iSprite, pev_frame, flFrame) && ++flFrame - 1.0 < get_pdata_float(iSprite, m_maxFrame, 4))
		{
			set_pev(iSprite, pev_frame, flFrame);
			set_pev(iSprite, pev_nextthink, get_gametime() + MUZZLE_TIME_SHOOT);
			return HAM_SUPERCEDE;
		}
		set_pev(iSprite, pev_flags, pev(iSprite, pev_flags)|FL_KILLME);
	}	
	return HAM_IGNORED;
}

public CWeapon__Think_Beam(iSprite)
{
	if (!IsValidEntity(iSprite) || !IsCustomBeam2(iSprite))
	{
		return HAM_IGNORED;
	}
	static Float:amt; pev(iSprite, pev_renderamt, amt)
	amt -= 5.0
	set_pev(iSprite, pev_renderamt, amt)
	set_pev(iSprite, pev_nextthink, get_gametime() + BEAM_FRAMECHANGETIME);
	if(amt <= 0.0) 
	{
		set_pev(iSprite, pev_flags, pev(iSprite,pev_flags) | FL_KILLME)
	}
	return HAM_SUPERCEDE;
}
public fm_ham_hook(bool: bEnabled)
{
	if(bEnabled)
	{
		EnableHamForward(gl_HamHook_TraceAttack[0]);
		EnableHamForward(gl_HamHook_TraceAttack[1]);
		EnableHamForward(gl_HamHook_TraceAttack[2]);
		EnableHamForward(gl_HamHook_TraceAttack[3]);
	}
	else 
	{
		DisableHamForward(gl_HamHook_TraceAttack[0]);
		DisableHamForward(gl_HamHook_TraceAttack[1]);
		DisableHamForward(gl_HamHook_TraceAttack[2]);
		DisableHamForward(gl_HamHook_TraceAttack[3]);
	}
}
stock Weapon_DrawBeam2(iPlayer, Float: vecEnd[3])
{
	static iBeamEntity, iszAllocStringCached; 
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "beam"))) 
	{ 
		iBeamEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached); 
	} 
	if(!IsValidEntity(iBeamEntity)) return FM_NULLENT;
	set_pev(iBeamEntity, pev_flags, pev(iBeamEntity, pev_flags) | FL_CUSTOMENTITY); 
	set_pev(iBeamEntity, pev_rendercolor, Float: {255.0, 255.0, 255.0}) 
	set_pev(iBeamEntity, pev_renderamt, 255.0) 
	set_pev(iBeamEntity, pev_body, 0) 
	set_pev(iBeamEntity, pev_frame, 0.0) 
	set_pev(iBeamEntity, pev_animtime, 0.0) 
	set_pev(iBeamEntity, pev_scale, BEAM_WEIGHT) 
	     
	engfunc(EngFunc_SetModel, iBeamEntity, WEAPON_SPRITE_LINE3); 
	     
	set_pev(iBeamEntity, pev_skin, 0); 
	set_pev(iBeamEntity, pev_sequence, 0); 
	set_pev(iBeamEntity, pev_rendermode, 0); 	

	static Float:Origp[3];
	get_weapon_position(iPlayer, Origp, 17.0, 0.0, -5.0)

	set_pev(iBeamEntity, pev_rendermode, (pev(iBeamEntity, pev_rendermode) & 0xF0) | BEAM_POINTS & 0x0F) 
	set_pev(iBeamEntity, pev_origin, vecEnd)  
	set_pev(iBeamEntity, pev_angles, Origp) 
	set_pev(iBeamEntity, pev_sequence, (pev(iBeamEntity, pev_sequence) & 0x0FFF) | ((0 & 0xF) << 12)) 
	set_pev(iBeamEntity, pev_skin, (pev(iBeamEntity, pev_skin) & 0x0FFF) | ((0 & 0xF) << 12)) 
	Beam_RelinkBeam(iBeamEntity); 	
	
	set_pev(iBeamEntity, pev_skin, (pev(iBeamEntity, pev_skin) & 0x0FFF) | ((0 & 0xF) << 12)) 
	set_pev(iBeamEntity, pev_sequence, (pev(iBeamEntity, pev_sequence) & 0x0FFF) | ((0 & 0xF) << 12))
	set_pev(iBeamEntity, pev_renderamt, 255.0) 
	set_pev(iBeamEntity, pev_animtime, BEAM_SCROLLRATE) 
	set_pev(iBeamEntity, pev_rendercolor, BEAM_COLOR) 
	set_pev(iBeamEntity, pev_body, BEAM_NOISE) 
	
	set_pev(iBeamEntity, pev_nextthink, get_gametime() + 0.3);
	set_pev(iBeamEntity, pev_classname, BEAM_CLASSNAME2);
	set_pev(iBeamEntity, pev_impulse, g_iszBeamKey2);
	set_pev(iBeamEntity, pev_owner, iPlayer);
	return iBeamEntity;
}
stock Weapon_MuzzleFlash(iPlayer, szMuzzleSprite[], Float: flScale, Float: flBrightness, iAttachment,iMode)
{
	if (global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < MUZZLE_INTOLERANCE)
	{
		return FM_NULLENT;
	}
	static iSprite, iszAllocStringCached;
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
	{
		iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	if(!pev_valid(iSprite)) return FM_NULLENT;
	set_pev(iSprite, pev_model, szMuzzleSprite);
	set_pev(iSprite, pev_owner, iPlayer);
	set_pev(iSprite, pev_aiment, iPlayer);
	set_pev(iSprite, pev_body, iAttachment);
	if(iMode==1)
	{
		set_pev(iSprite, pev_classname, MUZZLE_CLASSNAME4);
		set_pev(iSprite, pev_impulse, g_iszMuzzleKeyShoot);
		set_pev(iSprite, pev_spawnflags, SF_SPRITE_ONCE);

	}	
	Sprite_SetTransparency(iSprite, kRenderTransAdd, flBrightness);
	Sprite_SetScale(iSprite, flScale);
	
	dllfunc(DLLFunc_Spawn, iSprite)

	return iSprite;
}

PrimaryAmmoIndex(iItem)
{
	return get_pdata_int(iItem, m_iPrimaryAmmoType, 4);
}

GetAmmoInventory(iPlayer, iAmmoIndex)
{
	if (iAmmoIndex == -1)
	{
		return -1;
	}

	return get_pdata_int(iPlayer, m_rgAmmo + iAmmoIndex, 5);
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
stock set_screen_empty(iPlayer)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, iPlayer)
	write_short(1<<10)
	write_short(1<<10)
	write_short(0x0001)
	write_byte(0)
	write_byte(0)
	write_byte(0)
	write_byte(0)
	message_end()
	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	
	static bitsWeaponScope; bitsWeaponScope = get_pdata_int(iItem, m_iScope, linux_diff_weapon);
	Enable_zoom=0
	if(bitsWeaponScope & WEAPONSTATE_SCOPE)
	{
		bitsWeaponScope &= ~ WEAPONSTATE_SCOPE;
		
		set_pdata_int(iItem, m_iScope, bitsWeaponScope, linux_diff_weapon);
		
	}
}
stock IsWallBetweenPoints(Float: vecStart[3], Float: vecEnd[3], PlayerEnt)
{
	static iTrace;iTrace = create_tr2();
	static Float: vecEndPos[3];
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, PlayerEnt, iTrace);
	get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	free_tr2(iTrace);
	return floatround(get_distance_f(vecEnd, vecEndPos));
} 
SetAmmoInventory(iPlayer, iAmmoIndex, iAmount)
{
	if (iAmmoIndex == -1)
	{
		return 0;
	}

	set_pdata_int(iPlayer, m_rgAmmo + iAmmoIndex, iAmount, 5);
	return 1;
}
stock SetExtraAmmo(iPlayer, iClip)
{
	message_begin(MSG_ONE, get_user_msgid("AmmoX"), { 0, 0, 0 }, iPlayer);
	write_byte(1);
	write_byte(iClip);
	message_end();
}
stock get_weapon_position(id, Float:fOrigin[], Float:add_forward = 0.0, Float:add_right = 0.0, Float:add_up = 0.0)
{
	static Float:Angles[3],Float:ViewOfs[3], Float:vAngles[3]
	static Float:Forward[3], Float:Right[3], Float:Up[3]
	
	pev(id, pev_v_angle, vAngles)
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, ViewOfs)
	xs_vec_add(fOrigin, ViewOfs, fOrigin)
	
	pev(id, pev_angles, Angles)
	
	Angles[0] = vAngles[0]
	
	engfunc(EngFunc_MakeVectors, Angles)
	
	global_get(glb_v_forward, Forward)
	global_get(glb_v_right, Right)
	global_get(glb_v_up, Up)
	
	xs_vec_mul_scalar(Forward, add_forward, Forward)
	xs_vec_mul_scalar(Right, add_right, Right)
	xs_vec_mul_scalar(Up, add_up, Up)
	
	fOrigin[0] = fOrigin[0] + Forward[0] + Right[0] + Up[0]
	fOrigin[1] = fOrigin[1] + Forward[1] + Right[1] + Up[1]
	fOrigin[2] = fOrigin[2] + Forward[2] + Right[2] + Up[2]
}
stock UTIL_SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_WeaponList(iPlayer, iByte, bool: bEnabled)
{
	message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, iPlayer);
	write_string(bEnabled ? WEAPON_WEAPONLIST : WEAPON_REFERENCE);
	write_byte(iWeaponList[0]);
	write_byte(bEnabled ? WEAPON_DEFAULT_AMMO : iWeaponList[1]);
	write_byte(iByte);
	write_byte(WEAPON_MAX_ENERGY);
	write_byte(iWeaponList[4]);
	write_byte(iWeaponList[5]);
	write_byte(iWeaponList[6]);
	write_byte(iWeaponList[7]);
	message_end();
}
stock Sprite_SetTransparency(iSprite, iRendermode, Float: flAmt, iFx = kRenderFxNone)
{
	set_pev(iSprite, pev_rendermode, iRendermode);
	set_pev(iSprite, pev_renderamt, flAmt);
	set_pev(iSprite, pev_renderfx, iFx);
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
