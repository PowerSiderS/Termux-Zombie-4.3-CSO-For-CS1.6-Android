#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

// Mofiying Plugin Info Will Violate CopyRight///
#define PLUGIN "Dual Beretta GunsLinger"   /////
#define VERSION "1.0"					  /////
#define AUTHOR "ZinoZack47"				 /////
/////////////////////////////////////////////

#define GK_WEAPONKEY					854647

const USE_STOPPED  				=		0
const OFFSET_ACTIVE_ITEM 		= 		373
const OFFSET_WEAPONOWNER 		=		41
const OFFSET_LINUX 				= 		5
const OFFSET_LINUX_WEAPONS 		= 		4

#define WEAP_LINUX_XTRA_OFF				4
#define m_pPlayer             			41
#define m_iId 	                		43
#define m_fKnown						44
#define m_flNextPrimaryAttack 			46
#define m_flNextSecondaryAttack 		47
#define m_flTimeWeaponIdle				48
#define m_iClip							51
#define m_fInReload						54
#define m_iShotsFired 					64
#define PLAYER_LINUX_XTRA_OFF			5
#define m_flNextAttack					83
#define m_pActiveItem 					373

#define GK_DRAW_TIME     				1.0
#define GK_RELOAD_TIME					2.0

#define CSW_GK 							CSW_DEAGLE
#define weapon_gk						"weapon_deagle"

#define GK_EXP_CLASSNAME				"GK_EXP"
#define GK_SHADOW_CLASSNAME				"GK_SENPAI"
#define GK_FASTEFFECT_CLASSNAME			"GK_STALKER"
#define GK_HANDS_CLASSNAME				"GK_HANDS"

enum (+= 47)
{
	GK_TASK_FIX = 85969147,
	GK_TASK_RESET,
	GK_TASK_LAST
}

enum
{
	MODE_RIGHT = 0,
	MODE_LEFT,
	MODE_SKILL1,
	MODE_SKILL2,
	MODE_SKILL3,
	MODE_SKILL4,
	MODE_SKILL5,
	MODE_SKILL_LAST
}

enum
{
	GK_IDLE = 0,
	GK_IDLE2,
	GK_SHOOT,
	GK_SHOOT_LAST,
	GK_SHOOT2,
	GK_SHOOT2_LAST,
	GK_RELOAD,
	GK_RELOAD2,
	GK_DRAW,
	GK_DRAW2,
	GK_SKILL1,
	GK_SKILL2,
	GK_SKILL3,
	GK_SKILL4,
	GK_SKILL5,
	GK_SKILL_LAST
}

new GK_V_MODEL[64] = "models/z47_gunkata/v_gunkata.mdl"
new GK_P_MODEL[64] = "models/z47_gunkata/p_gunkata.mdl"
new GK_P_MODEL2[64] = "models/z47_gunkata/p_gunkata2.mdl"
new GK_W_MODEL[64] = "models/z47_gunkata/w_gunkata.mdl"

new const GK_Sounds[][] = 
{
	"weapons/z47_gunkata/gunkata_idle.wav",
	"weapons/z47_gunkata/gunkata-1.wav",
	"weapons/z47_gunkata/gunkata_draw.wav",
	"weapons/z47_gunkata/gunkata_draw2.wav",
	"weapons/z47_gunkata/gunkata_reload.wav",
	"weapons/z47_gunkata/gunkata_reload2.wav",
	"weapons/z47_gunkata/gunkata_reload2.wav",
	"weapons/z47_gunkata/gunkata_skill_01.wav",
	"weapons/z47_gunkata/gunkata_skill_02.wav",
	"weapons/z47_gunkata/gunkata_skill_03.wav",
	"weapons/z47_gunkata/gunkata_skill_04.wav",
	"weapons/z47_gunkata/gunkata_skill_05.wav",
	"weapons/z47_gunkata/gunkata_skill_last.wav",
	"weapons/z47_gunkata/gunkata_skill_last_exp.wav"
}

new const GK_Effects[][] = 
{
	"models/z47_gunkata/ef_gunkata.mdl",
	"models/z47_gunkata/ef_hole.mdl",
	"models/z47_gunkata/ef_gunkata_man.mdl"
}

new const GK_Sprites[][] = 
{
	"sprites/weapon_gunkata.txt",
	"sprites/640hud18.spr",
	"sprites/640hud176.spr"
}

new const GK_MUZZLEFLASH[64] = "sprites/muzzleflash77.spr"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

const pev_life = pev_fuser1

new cvar_dmg_gk, cvar_recoil_gk, cvar_clip_gk, cvar_gk_ammo, cvar_one_round, cvar_cooldown_gk, cvar_radius_gk
new g_maxplayers, g_orig_event_gk, g_IsInPrimaryAttack, g_iClip, g_clip_counter[33]
new Float:cl_pushangle[33][3], m_iBlood[2], g_HitGroup[33]
new g_has_gk[33], g_clip_ammo[33], g_gk_TmpClip[33], g_current_mode[33]
new g_MsgWeaponList, g_MsgCurWeapon, g_nCurWeapon[33][2]
new g_Muzzleflash[33], g_Muzzleflash_Ent[2], Float:g_Delay[33]

const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")

	RegisterHam(Ham_Item_Deploy, weapon_gk, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_gk, "fw_GunKata_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_gk, "fw_GunKata_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_gk, "fw_GunKata_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, weapon_gk, "fw_GunKata_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_gk, "fw_GunKata_Reload_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_gk, "fw_GunKata_AddToPlayer")
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_gk, "fw_GunKata_WeaponIdle_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_Think, "fw_Think")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_post", 1)
	register_forward(FM_CheckVisibility, "fw_CheckVisibility")

	cvar_clip_gk = register_cvar("zp_dualberetta_clip", "36")
	cvar_gk_ammo = register_cvar("zp_dualberetta_ammo", "180")
	cvar_dmg_gk = register_cvar("zp_dualberetta_dmg", "200")
	cvar_recoil_gk = register_cvar("zp_dualberettak_recoil", "0.06")
	cvar_one_round = register_cvar("zp_dualberetta_one_round", "0")
	cvar_radius_gk = register_cvar("zp_dualberetta_radius", "300")
	cvar_cooldown_gk = register_cvar("zp_dualberetta_mode_cooldown", "45.0")

	g_MsgWeaponList = get_user_msgid("WeaponList")
	g_MsgCurWeapon = get_user_msgid("CurWeapon")

	register_clcmd("weapon_gunkata", "select_gunkata")
	g_maxplayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(GK_V_MODEL)
	precache_model(GK_P_MODEL)
	precache_model(GK_P_MODEL2)
	precache_model(GK_W_MODEL)

	for(new i = 0; i < sizeof(GK_Sounds); i++)
		precache_sound(GK_Sounds[i])	
	
	for(new i = 0; i < sizeof(GK_Sprites); i++)
		precache_generic(GK_Sprites[i])

	for(new i = 0; i < sizeof(GK_Effects); i++)
		precache_model(GK_Effects[i])

	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	
	precache_model(GK_MUZZLEFLASH)

	g_Muzzleflash_Ent[MODE_RIGHT] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	engfunc(EngFunc_SetModel, g_Muzzleflash_Ent[MODE_RIGHT], GK_MUZZLEFLASH)
	set_pev(g_Muzzleflash_Ent[MODE_RIGHT], pev_scale, 0.1)
	set_pev(g_Muzzleflash_Ent[MODE_RIGHT], pev_rendermode, kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent[MODE_RIGHT], pev_renderamt, 0.0)

	g_Muzzleflash_Ent[MODE_LEFT] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	engfunc(EngFunc_SetModel, g_Muzzleflash_Ent[MODE_LEFT], GK_MUZZLEFLASH)
	set_pev(g_Muzzleflash_Ent[MODE_LEFT], pev_scale, 0.1)
	set_pev(g_Muzzleflash_Ent[MODE_LEFT], pev_rendermode, kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent[MODE_LEFT], pev_renderamt, 0.0)

	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)

}

public plugin_natives ()
{
	register_native("give_gk", "native_give_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_gunkata(id)
}

public select_gunkata(id)
{
    engclient_cmd(id, weapon_gk)
    return PLUGIN_HANDLED
}

public fw_PrecacheEvent_Post(type, const name[])
{
	new weapon[32], event_gk[64]
	
	copy(weapon, charsmax(weapon), weapon_gk)
	replace(weapon, charsmax(weapon), "weapon_", "")

	formatex(event_gk, charsmax(event_gk), "events/%s.sc", weapon)

	if (equal(event_gk, name))
	{
		g_orig_event_gk = get_orig_retval()
		return FMRES_HANDLED
	}

	return FMRES_IGNORED
}

public Event_NewRound()
{
	for(new id = 0; id <= g_maxplayers; id++)
	{
		if(!g_has_gk[id])

		if(get_pcvar_num(cvar_one_round))
			remove_gunkata(id)
	}
}

public zp_user_humanized_post(id)
	remove_gunkata(id)


public client_disconnected(id)
	remove_gunkata(id)

public zp_user_infected_post(id)
	remove_gunkata(id)


public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED

	static classname[33], weapon[32], old_gk[64]
	pev(entity, pev_classname, classname, charsmax(classname))

	if(!equal(classname, "weaponbox"))
		return FMRES_IGNORED

	copy(weapon, charsmax(weapon), weapon_gk)
	replace(weapon, charsmax(weapon), "weapon_", "")

	formatex(old_gk, charsmax(old_gk), "models/w_%s.mdl", weapon)

	static owner
	owner = pev(entity, pev_owner)

	if(equal(model, old_gk))
	{
		static StoredWepID
		
		StoredWepID = fm_find_ent_by_owner(-1, weapon_gk, entity)
	
		if(!pev_valid(StoredWepID))
			return FMRES_IGNORED
	
		if(g_has_gk[owner])
		{
			set_pev(StoredWepID, pev_impulse, GK_WEAPONKEY)

			remove_gunkata(owner)

			engfunc(EngFunc_SetModel, entity, GK_W_MODEL)
						
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_gunkata(id)
{
	drop_weapons(id, 2)

	g_has_gk[id] = true
	g_current_mode[id] = MODE_RIGHT

	fm_give_item(id, weapon_gk)
	
	static weapon; weapon = fm_get_user_weapon_entity(id, CSW_GK)

	if(!pev_valid(weapon))
		return

	cs_set_weapon_ammo(weapon, get_pcvar_num(cvar_clip_gk))	

	message_begin(MSG_ONE_UNRELIABLE, g_MsgWeaponList, .player = id)
	write_string("weapon_gunkata")
	write_byte(8)
	write_byte(35)
	write_byte(-1)
	write_byte(-1)
	write_byte(1) 
	write_byte(1)
	write_byte(CSW_GK)
	write_byte(0)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgCurWeapon, {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_GK)
	write_byte(get_pcvar_num(cvar_clip_gk))
	message_end()

	cs_set_user_bpammo (id, CSW_GK, get_pcvar_num(cvar_gk_ammo))
}

public remove_gunkata(id)
{
	remove_task(id+GK_TASK_RESET)
	remove_task(id+GK_TASK_FIX)
	remove_task(id+GK_TASK_RESET)
	g_has_gk[id] = false
	g_current_mode[id] = MODE_RIGHT
	g_clip_counter[id] = 0
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return HAM_IGNORED

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_GK || !g_has_gk[iAttacker])
		return HAM_IGNORED

	if(is_user_alive(iEnt))
	{
		g_HitGroup[iAttacker] = get_tr2(ptr, TR_iHitgroup)
		return HAM_IGNORED
	}

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)

	if(iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		engfunc(EngFunc_WriteCoord, flEnd[0])
		engfunc(EngFunc_WriteCoord, flEnd[1])
		engfunc(EngFunc_WriteCoord, flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, flEnd[0])
		engfunc(EngFunc_WriteCoord, flEnd[1])
		engfunc(EngFunc_WriteCoord, flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	engfunc(EngFunc_WriteCoord, flEnd[0])
	engfunc(EngFunc_WriteCoord, flEnd[1])
	engfunc(EngFunc_WriteCoord, flEnd[2])
	write_short(iAttacker)
	write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
	message_end()

	return HAM_IGNORED
}

public fw_GunKata_AddToPlayer(item, id)
{
	if(!pev_valid(item))
		return HAM_IGNORED

	switch(pev(item, pev_impulse))
	{
		case 0:
		{
			message_begin(MSG_ONE, g_MsgWeaponList, .player = id)
			write_string(weapon_gk)
			write_byte(8)
			write_byte(35)
			write_byte(-1)
			write_byte(-1)
			write_byte(1)
			write_byte(1)
			write_byte(CSW_GK)
			write_byte(0)
			message_end()
			
			return HAM_IGNORED
		}
		case GK_WEAPONKEY:
		{
			g_has_gk[id] = true
			
			message_begin(MSG_ONE, g_MsgWeaponList, .player = id)
			write_string("weapon_gunkata")
			write_byte(8)
			write_byte(35)
			write_byte(-1)
			write_byte(-1)
			write_byte(1)
			write_byte(1)
			write_byte(CSW_GK)
			write_byte(0)
			message_end()
			set_pev(item, pev_impulse, 0)
			
			return HAM_HANDLED
		}
	}

	return HAM_IGNORED
}

public fw_Item_Deploy_Post(weapon_ent)
{
	if(pev_valid(weapon_ent) != 2)
		return

	static id
	id = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	if(get_pdata_cbase(id, m_pActiveItem) != weapon_ent)
		return

	if(!g_has_gk[id])
		return

	set_pev(id, pev_viewmodel2, GK_V_MODEL)
	set_pev(id, pev_weaponmodel2, GK_P_MODEL)

	switch(g_current_mode[id])
	{
		case MODE_RIGHT:fm_play_weapon_animation(id, GK_DRAW)
		case MODE_LEFT:fm_play_weapon_animation(id, GK_DRAW2)
	}

	fm_set_weapon_idle_time(id, weapon_gk, GK_DRAW_TIME)
	set_pdata_string(id, (492) * 4, "dualpistols", -1 , 20)
}

public fw_GunKata_WeaponIdle_Post(gk)
{
	if(pev_valid(gk) != 2)
		return HAM_IGNORED

	new id = fm_cs_get_weapon_ent_owner(gk)
	
	if(get_pdata_cbase(id, m_pActiveItem) != gk)
		return HAM_IGNORED

	if (!g_has_gk[id])
		return HAM_IGNORED;

	if(get_pdata_float(gk, m_flTimeWeaponIdle, WEAP_LINUX_XTRA_OFF) < 0.1)
	{
		switch(g_current_mode[id])
		{
			case MODE_RIGHT: fm_play_weapon_animation(id, GK_IDLE)
			case MODE_LEFT: fm_play_weapon_animation(id, GK_IDLE2)
		}

		set_pdata_float(gk, m_flTimeWeaponIdle, 20.0, WEAP_LINUX_XTRA_OFF)
		set_pdata_string(id, (492) * 4, "dualpistols", -1 , 20)
	}

	return HAM_IGNORED
}

public CurrentWeapon(id)
{
	new weapon = read_data(2)
	new ammo = read_data(3) 

	if(weapon != CSW_GK || !g_has_gk[id])
	{
		if(task_exists(id+GK_TASK_RESET))
		{
			remove_task(id+GK_TASK_RESET)
			g_current_mode[id] = MODE_RIGHT
			g_clip_counter[id] = 0
		}
		return
	}

	if(g_current_mode[id] >= MODE_SKILL1)
		return

	static Float:iSpeed, Ent
	Ent = fm_find_ent_by_owner(-1, weapon_gk, id)

	if(g_clip_counter[id] == 2 || g_clip_counter[id] == 5)
		iSpeed = 0.5
	else
		iSpeed = 0.1

	if(Ent)
	{
		set_pdata_float(Ent, m_flNextPrimaryAttack, iSpeed, WEAP_LINUX_XTRA_OFF)
		set_pdata_float(Ent, m_flNextSecondaryAttack, iSpeed, WEAP_LINUX_XTRA_OFF)
	}

	Check_Counter(id, weapon, ammo)
}

public fw_UpdateClientData_Post(id, SendWeapons, CD_Handle)
{
	if(!is_user_alive(id) || get_user_weapon(id) != CSW_GK || !g_has_gk[id])
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001)
	return FMRES_HANDLED
}

public fw_GunKata_PrimaryAttack(Weapon)
{
	new id = get_pdata_cbase(Weapon, m_pPlayer, WEAP_LINUX_XTRA_OFF)
	
	if (!g_has_gk[id])
		return HAM_IGNORED

	g_IsInPrimaryAttack = 1
	pev(id,pev_punchangle, cl_pushangle[id])

	set_pdata_int(Weapon, m_iShotsFired, -1)

	g_clip_ammo[id] = cs_get_weapon_ammo(Weapon)
	g_iClip = cs_get_weapon_ammo(Weapon)

	return HAM_IGNORED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (eventid != g_orig_event_gk || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	
	if (!(1 <= invoker <= g_maxplayers))
    	return FMRES_IGNORED

	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_GunKata_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new id = get_pdata_cbase(Weapon, m_pPlayer, WEAP_LINUX_XTRA_OFF)
	
	if(!is_user_alive(id))
		return HAM_IGNORED

	new szClip, szAmmo
	get_user_weapon(id, szClip, szAmmo)

	if(g_iClip <= cs_get_weapon_ammo(Weapon))
		return HAM_IGNORED

	if(g_current_mode[id] <= MODE_LEFT)
		remove_task(id+GK_TASK_RESET)

	if(g_has_gk[id])
	{
		if (!g_clip_ammo[id])
			return HAM_IGNORED

		new Float:push[3]

		pev(id,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[id],push)

		xs_vec_mul_scalar(push, g_current_mode[id] > MODE_LEFT ? get_pcvar_float(cvar_recoil_gk) : 0.0, push)
		xs_vec_add(push, cl_pushangle[id], push)
		set_pev(id,pev_punchangle, push)

		if(g_current_mode[id] == MODE_SKILL3 || g_current_mode[id] == MODE_SKILL4)
		{
			if(g_current_mode[id] == MODE_SKILL3)
				g_Muzzleflash[id] = 1
			else
				g_Muzzleflash[id] = 2
			
			return HAM_IGNORED
		}

		if (g_current_mode[id] > MODE_LEFT)
			return HAM_IGNORED

		if(g_clip_counter[id] <= 2)
		{
			if(g_clip_counter[id] == 2)
			{
				g_Muzzleflash[id] = 1
				fm_play_weapon_animation(id, GK_SHOOT_LAST)
				g_current_mode[id] = MODE_LEFT
				fm_set_weapon_idle_time(id, weapon_gk, 0.5)
			}
			else
			{
				g_current_mode[id] = MODE_RIGHT
				g_Muzzleflash[id] = 1
				fm_play_weapon_animation(id, GK_SHOOT)
			}
		}
		else
		{
			if(g_clip_counter[id] == 5)
			{
				g_Muzzleflash[id] = 2
				fm_play_weapon_animation(id, GK_SHOOT2_LAST)
				g_current_mode[id] = MODE_RIGHT
				fm_set_weapon_idle_time(id, weapon_gk, 0.5)
				set_task(0.3, "fix_counter", id+GK_TASK_FIX)
				
			}
			else 
			{
				g_Muzzleflash[id] = 2
				g_current_mode[id] = MODE_LEFT
				fm_play_weapon_animation(id, GK_SHOOT2)
			}
		}

		emit_sound(id, CHAN_WEAPON, GK_Sounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}

	return HAM_IGNORED
}

public fix_counter(id)
{
	id -= GK_TASK_FIX
	
	if(is_user_alive(id))
		g_clip_counter[id] = 0
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_GK)
		{
			if(g_has_gk[attacker] && g_current_mode[attacker] < MODE_SKILL1)
			{	
				switch(g_HitGroup[attacker])
				{
					case HIT_HEAD: damage = get_pcvar_num(cvar_dmg_gk) * 1.5
					case HIT_LEFTARM .. HIT_RIGHTLEG: damage = get_pcvar_num(cvar_dmg_gk) * 0.75
					case HIT_CHEST, HIT_STOMACH: damage = float(get_pcvar_num(cvar_dmg_gk))
				}

				SetHamParamFloat(4, damage)		
			}
		}
	}
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static TruncatedWeapon[33], iAttacker, iVictim, weapon[32]
	
	copy(weapon, charsmax(weapon), weapon_gk)
	replace(weapon, charsmax(weapon), "weapon_", "")

	get_msg_arg_string(4, TruncatedWeapon, charsmax(TruncatedWeapon))

	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)

	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE

	if(equal(TruncatedWeapon, weapon) && get_user_weapon(iAttacker) == CSW_GK && g_has_gk[iAttacker])
			set_msg_arg_string(4, "gunkata")

	return PLUGIN_CONTINUE
}

public fw_GunKata_ItemPostFrame(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)

	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_gk[id])
		return HAM_IGNORED

	static iClipExtra

	iClipExtra = get_pcvar_num(cvar_clip_gk)
	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_GK)
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)
	new iButton = pev(id, pev_button)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

	if(fInReload && flNextAttack <= 0.0 && g_current_mode[id] < MODE_SKILL1)
	{
		new j = min(iClipExtra - iClip, iBpAmmo)

		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_GK, iBpAmmo-j)

		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}

	new Float: flDelay = get_pcvar_float(cvar_cooldown_gk)

	if(get_gametime() - flDelay >= g_Delay[id])
		GunKata_Dance(id, weapon_entity, iButton)

	return HAM_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(g_current_mode[id] < MODE_SKILL1)
		return FMRES_IGNORED
	
	if(CurButton & IN_ATTACK)
	{
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, CurButton)
	}

	return FMRES_IGNORED
}

public GunKata_Dance(id, weapon_entity, iButton)
{
	if(get_pdata_float(id, m_flNextAttack) > 0.0)
		return

	if(get_pdata_float(weapon_entity, m_flNextSecondaryAttack, WEAP_LINUX_XTRA_OFF) <= 0.0 && iButton & IN_ATTACK2 && iButton & ~IN_ATTACK)
	{
		set_pev(id, pev_weaponmodel2, GK_P_MODEL2)
		
		new gk_range = get_pcvar_num(cvar_radius_gk)
		
		make_stalker(id)

		switch(g_current_mode[id])
		{
			case MODE_RIGHT .. MODE_LEFT:
			{
				g_current_mode[id] = MODE_SKILL1
				remove_task(id+GK_TASK_RESET)
				fm_play_weapon_animation(id, GK_SKILL1)
				make_senpai(id, 0)
				emit_sound(id, CHAN_WEAPON, GK_Sounds[7], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				fm_set_weapon_idle_time(id, weapon_gk, 0.5)
				gk_slash(id, get_pcvar_num(cvar_dmg_gk) * 2, gk_range)
				set_task(1.5, "reset_mode", id+GK_TASK_RESET)
			}
			case MODE_SKILL1:
			{
				g_current_mode[id] = MODE_SKILL2
				remove_task(id+GK_TASK_RESET)
				fm_play_weapon_animation(id, GK_SKILL2)
				make_senpai(id, 1)
				emit_sound(id, CHAN_WEAPON, GK_Sounds[8], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				fm_set_weapon_idle_time(id, weapon_gk, 0.5)
				gk_slash(id, get_pcvar_num(cvar_dmg_gk) * 2, gk_range)
				set_task(1.5, "reset_mode", id+GK_TASK_RESET)
			}
			case MODE_SKILL2:
			{
				g_current_mode[id] = MODE_SKILL3
				remove_task(id+GK_TASK_RESET)
				fm_play_weapon_animation(id, GK_SKILL3)
				ExecuteHamB(Ham_Weapon_PrimaryAttack, weapon_entity)
				make_senpai(id, 2)
				emit_sound(id, CHAN_WEAPON, GK_Sounds[9], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				fm_set_weapon_idle_time(id, weapon_gk, 1.0)
				gk_slash(id, get_pcvar_num(cvar_dmg_gk) * 2, gk_range)
				set_task(1.5, "reset_mode", id+GK_TASK_RESET)
			}
			case MODE_SKILL3:
			{
				g_current_mode[id] = MODE_SKILL4
				remove_task(id+GK_TASK_RESET)
				fm_play_weapon_animation(id, GK_SKILL4)
				make_senpai(id, 3)
				emit_sound(id, CHAN_WEAPON, GK_Sounds[10], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				set_task(0.5, "last_effect", id+GK_TASK_LAST)
				fm_set_weapon_idle_time(id, weapon_gk, 1.0)
				gk_slash(id, get_pcvar_num(cvar_dmg_gk) * 2, gk_range)
				set_task(1.5, "reset_mode", id+GK_TASK_RESET)
			}
			case MODE_SKILL4:
			{
				g_current_mode[id] = MODE_SKILL5
				remove_task(id+GK_TASK_RESET)
				fm_play_weapon_animation(id, GK_SKILL5)
				make_senpai(id, 4)
				emit_sound(id, CHAN_WEAPON, GK_Sounds[11], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				fm_set_weapon_idle_time(id, weapon_gk, 0.5)
				gk_slash(id, get_pcvar_num(cvar_dmg_gk) * 2, gk_range)
				set_task(1.0, "reset_mode", id+GK_TASK_RESET)
			}
			case MODE_SKILL5:
			{
				g_current_mode[id] = MODE_SKILL_LAST
				remove_task(id+GK_TASK_RESET)
				fm_play_weapon_animation(id, GK_SKILL_LAST)
				make_senpai(id, 5)
				set_task(0.4, "last_effect", id+GK_TASK_LAST)
				fm_set_weapon_idle_time(id, weapon_gk, 0.5)
				gk_slash(id, get_pcvar_num(cvar_dmg_gk) * 2, gk_range)
				set_task(1.0, "reset_mode", id+GK_TASK_RESET)
			}
		}
	}
}

public gk_slash(id, damage, range)
{
	new temp[2], weapon = get_user_weapon(id, temp[0], temp[1])
	
	if (weapon != CSW_GK || !g_has_gk[id])
		return
	
	if(g_current_mode[id] < MODE_SKILL1)
		return

	static Float:origin[3], Float:vSrc[3], Float:angles[3], Float:v_forward[3], Float:v_right[3], Float:v_up[3], Float:gun_position[3], Float:player_origin[3], Float:player_view_offset[3]
	pev(id, pev_v_angle, angles)
	engfunc(EngFunc_MakeVectors, angles)
	global_get(glb_v_forward, v_forward)
	global_get(glb_v_right, v_right)
	global_get(glb_v_up, v_up)

	pev(id, pev_origin, player_origin)
	pev(id, pev_view_ofs, player_view_offset)
	xs_vec_add(player_origin, player_view_offset, gun_position)
	
	xs_vec_mul_scalar(v_right, 0.0, v_right)

	if ((pev(id, pev_flags) & FL_DUCKING) == FL_DUCKING)
		xs_vec_mul_scalar(v_up, 6.0, v_up)
	else
		xs_vec_mul_scalar(v_up, -2.0, v_up)

	xs_vec_add(gun_position, v_forward, origin)
	xs_vec_add(origin, v_right, origin)
	xs_vec_add(origin, v_up, origin)
		
	vSrc[0] = origin[0]
	vSrc[1] = origin[1]
	vSrc[2] = origin[2]

	static Float:flOrigin[3] , Float:flDistance , Float:originplayer[3]
	
	for(new victim = 0; victim <= g_maxplayers; victim++)
	{
		if(is_user_alive(victim) && zp_get_user_zombie(victim))
		{
			pev(victim, pev_origin, flOrigin)
			pev(id, pev_origin, originplayer)

			if(!get_can_see(flOrigin, originplayer))
				continue
		
			flDistance = get_distance_f(vSrc, flOrigin)   
				
			if(flDistance <= float(range))
			{	
				new Float:dmg = float(damage)
				
				ExecuteHamB(Ham_TakeDamage, victim , id , id, dmg, DMG_BULLET)		
				make_blood(victim, dmg)
			}
		}
	}
	
}

public last_effect(id)
{
	id -= GK_TASK_LAST

	if(get_user_weapon(id) != CSW_GK || !g_has_gk[id])
		return

	new weapon_entity = fm_find_ent_by_owner(-1, weapon_gk, id)

	switch(g_current_mode[id])
	{
		case MODE_SKILL4: ExecuteHamB(Ham_Weapon_PrimaryAttack, weapon_entity)
		case MODE_SKILL_LAST: create_explosion(id)
	}
}

stock make_stalker(id)
{
	if(g_current_mode[id] < MODE_SKILL1)
		return

	new Float:flOrigin[3]
	
	pev(id, pev_origin, flOrigin)

	new gk_stalker = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target")) 

	if(!pev_valid(gk_stalker))
		return

	set_pev(gk_stalker, pev_classname, GK_FASTEFFECT_CLASSNAME)

	engfunc(EngFunc_SetOrigin, gk_stalker, flOrigin)

	set_pev(gk_stalker, pev_movetype, MOVETYPE_FOLLOW)

	set_pev(gk_stalker, pev_aiment, id)

	engfunc(EngFunc_SetModel, gk_stalker, GK_Effects[0])

	set_pev(gk_stalker, pev_solid, SOLID_NOT)

	set_pev(gk_stalker, pev_animtime, get_gametime())
	
	set_pev(gk_stalker, pev_framerate, 1.0)
	
	set_pev(gk_stalker, pev_sequence, 1)

	set_pev(gk_stalker, pev_nextthink, get_gametime() + 1.0)
}

stock make_senpai(id, anim)
{
	if(get_user_weapon(id) != CSW_GK || !g_has_gk[id])
		return

	new Float:flOrigin[3], Float:flAimOrigin[3], iButton 
	
	pev(id, pev_origin, flOrigin)
	fm_get_aim_origin(id, flAimOrigin)
	iButton = pev(id, pev_button)

	new gk_senpai = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target")) 

	if(!pev_valid(gk_senpai))
		return

	set_pev(gk_senpai, pev_classname, GK_SHADOW_CLASSNAME)

	engfunc(EngFunc_SetOrigin, gk_senpai, flOrigin)

	fm_set_aim(gk_senpai, flAimOrigin)

	engfunc(EngFunc_SetModel, gk_senpai, GK_Effects[2])

	set_pev(gk_senpai, pev_solid, SOLID_NOT)

	set_pev(gk_senpai, pev_animtime, 2.0)
	
	set_pev(gk_senpai, pev_framerate, 1.0)
	
	iButton & IN_DUCK ? set_pev(gk_senpai, pev_sequence, anim + 6) : set_pev(gk_senpai, pev_sequence, anim)

	set_pev(gk_senpai, pev_life, get_gametime() + 2.0)

	set_pev(gk_senpai, pev_nextthink, get_gametime() + 1.0)

}

public create_explosion(id)
{
	if(get_user_weapon(id) != CSW_GK || !g_has_gk[id])
		return

	new Float:flOrigin[3]

	pev(id, pev_origin, flOrigin)

	new gk_hole = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target")) 

	if(!pev_valid(gk_hole))
		return

	set_pev(gk_hole, pev_classname, GK_EXP_CLASSNAME)
	
	engfunc(EngFunc_SetModel, gk_hole, GK_Effects[1])

	engfunc(EngFunc_SetOrigin, gk_hole, flOrigin)

	set_pev(gk_hole, pev_solid, SOLID_NOT)

	set_pev(gk_hole, pev_scale, get_pcvar_num(cvar_radius_gk) / 10000)

	set_pev(gk_hole, pev_animtime, get_gametime())

	set_pev(gk_hole, pev_framerate, 1.0)
	
	set_pev(gk_hole, pev_sequence, 1)

	set_pev(gk_hole, pev_life, get_gametime() + 0.5)

	set_pev(gk_hole, pev_nextthink, get_gametime() + 0.1)

	emit_sound(id, CHAN_WEAPON, GK_Sounds[13], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	static victim
	victim = -1
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, flOrigin, float(get_pcvar_num(cvar_radius_gk)))) != 0)
	{
		if (!is_user_alive(victim) || !zp_get_user_zombie(victim))
			continue
		
		new Float:vec[3]
		new Float:oldvelo[3]

		pev(victim, pev_velocity, oldvelo)
		
		fm_create_velocity_vector(victim, id, vec)
		
		vec[0] += oldvelo[0]
		vec[1] += oldvelo[1]
		
		set_pev(victim, pev_velocity, vec)
	}
}

stock fm_get_aim_origin(index, Float:origin[3])
{
	new Float:start[3], Float:view_ofs[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);

	new Float:dest[3];
	pev(index, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 9999.0, dest);
	xs_vec_add(start, dest, dest);

	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0);
	get_tr2(0, TR_vecEndPos, origin);

	return 1;
}

stock fm_set_aim(ent, Float:origin[3])
{
	static Float:ent_origin[3], Float:angles[3]

	pev(ent, pev_origin, ent_origin)
    
	xs_vec_sub(origin, ent_origin, origin)

	xs_vec_normalize(origin, origin)

	vector_to_angle(origin, angles)
    
	angles[0] = 0.0
    
	set_pev(ent, pev_angles, angles)
}

public fw_Think(ent)
{
	if(!pev_valid(ent)) 	
		return FMRES_IGNORED

	new ClassName[32]
	pev(ent, pev_classname, ClassName, charsmax(ClassName))

	if(equal(ClassName, GK_EXP_CLASSNAME))
	{
		if(pev(ent, pev_life) - get_gametime() <= 0)
		{
			set_pev(ent, pev_flags, FL_KILLME)
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_IGNORED
		}
	}
	else if(equal(ClassName, GK_SHADOW_CLASSNAME))
	{
		if(pev(ent, pev_life) - get_gametime() <= 0)
		{
			set_pev(ent, pev_flags, FL_KILLME)
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_IGNORED
		}
	}
	else if(equal(ClassName, GK_FASTEFFECT_CLASSNAME))
	{
		static id
		id = pev(ent, pev_aiment)

		if(g_current_mode[id] < MODE_SKILL1)
		{
			set_pev(ent, pev_flags, FL_KILLME)
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_IGNORED
		}
	}
	else if(equal(ClassName, GK_HANDS_CLASSNAME))
	{
		static id
		id = pev(ent, pev_aiment)

		if(g_current_mode[id] < MODE_SKILL1)
		{
			set_pev(ent, pev_flags, FL_KILLME)
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_IGNORED
		}
	}

	set_pev(ent, pev_nextthink, get_gametime() + 0.1)

	return FMRES_IGNORED
}

public reset_mode(id)
{
	id -= GK_TASK_RESET

	new weapon_entity = fm_find_ent_by_owner(-1, weapon_gk, id)

	if(get_user_weapon(id) != CSW_GK || !g_has_gk[id])
		return

	if(g_current_mode[id] == MODE_SKILL_LAST)
	{
		g_current_mode[id] = MODE_RIGHT
		g_clip_counter[id] = 0
		ExecuteHamB(Ham_Weapon_Reload, weapon_entity)
	}

	else
	{
		g_current_mode[id] = MODE_RIGHT
		g_clip_counter[id] = 0
		ExecuteHamB(Ham_Item_Deploy, weapon_entity)
	}

	g_Delay[id] = get_gametime()
	set_pev(id, pev_weaponmodel2, GK_P_MODEL)
}

stock get_can_see(Float:ent_origin[3], Float:target_origin[3])
{
	new Float:hit_origin[3]
	fm_trace_line(-1, ent_origin, target_origin, hit_origin)						

	if (!vector_distance(hit_origin, target_origin))
		return 1

	return 0
}

stock make_blood(id , Float:Damage)
{
	new bloodColor = ExecuteHam(Ham_BloodColor, id)
	new Float:origin[3]
	pev(id, pev_origin, origin)

	if (bloodColor == -1)
		return

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(bloodColor)
	write_byte(min(max(3, floatround(Damage)/5), 16))
	message_end()
}

public fw_GunKata_Reload(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)

	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_gk[id])
		return HAM_IGNORED

	if(g_current_mode[id] >= MODE_SKILL1)
		return HAM_SUPERCEDE

	static iClipExtra

	if(g_has_gk[id])
		iClipExtra = get_pcvar_num(cvar_clip_gk)

	g_gk_TmpClip[id] = -1

	new iBpAmmo = cs_get_user_bpammo(id, CSW_GK)
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE

	if (iClip >= iClipExtra)
		return HAM_SUPERCEDE

	g_gk_TmpClip[id] = iClip

	return HAM_IGNORED
}

public fw_GunKata_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_gk[id])
		return HAM_IGNORED

	if (g_gk_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_gk_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	fm_set_weapon_idle_time(id, weapon_gk, GK_RELOAD_TIME)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF) 

	switch(g_current_mode[id])
	{
		case MODE_RIGHT: fm_play_weapon_animation (id, GK_RELOAD)
		case MODE_LEFT:
		{
			fm_play_weapon_animation (id, GK_RELOAD2)
			g_current_mode[id] = MODE_RIGHT
			g_clip_counter[id] = 0
		}
	}

	set_pdata_string(id, (492) * 4, "dualpistols", -1 , 20)
	
	return HAM_IGNORED
}

public fw_CheckVisibility(iEntity, pSet)
{
	if(iEntity != g_Muzzleflash_Ent[MODE_RIGHT] || iEntity != g_Muzzleflash_Ent[MODE_LEFT])	
		return FMRES_IGNORED

	forward_return(FMV_CELL, 1)
	return FMRES_SUPERCEDE
}

public fw_AddToFullPack_post(esState, iE, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	static Float:flOrigin[3]
	pev(iPlayer, pev_origin, flOrigin)

	if(iEnt == g_Muzzleflash_Ent[MODE_RIGHT])
	{
		if(g_Muzzleflash[iHost] == 1)
		{
			set_es(esState, ES_Frame, float(random_num(0, 2)))
				
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, 255.0)
			
			g_Muzzleflash[iHost] = 0
		}
			
		set_es(esState, ES_Skin, iHost)
		set_es(esState, ES_Body, MODE_RIGHT + 1)
		set_es(esState, ES_AimEnt, iHost)
		set_es(esState, ES_MoveType, MOVETYPE_FOLLOW)
	}
	else if (iEnt == g_Muzzleflash_Ent[MODE_LEFT])
	{
		if(g_Muzzleflash[iHost] == 2)
		{
			set_es(esState, ES_Frame, float(random_num(0, 2)))
				
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, 255.0)
			
			g_Muzzleflash[iHost] = 0
		}
			
		set_es(esState, ES_Skin, iHost)
		set_es(esState, ES_Body, MODE_LEFT + 2)
		set_es(esState, ES_AimEnt, iHost)
		set_es(esState, ES_MoveType, MOVETYPE_FOLLOW)
	}
	if(fm_is_ent_classname(iEnt, GK_SHADOW_CLASSNAME) && fm_entity_range(iEnt, iHost) <= 10.0)
	{
		set_es(esState, ES_RenderMode, kRenderTransAdd)
		set_es(esState, ES_RenderAmt, 0.0)
	}
}


stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock fm_set_weapon_idle_time(id, const class[], Float:IdleTime)
{
	static weapon_ent
	weapon_ent = fm_find_ent_by_owner(-1, class, id)

	if(!pev_valid(weapon_ent))
		return

	set_pdata_float(weapon_ent, m_flNextPrimaryAttack, IdleTime, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(weapon_ent, m_flNextSecondaryAttack, IdleTime, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(weapon_ent, m_flTimeWeaponIdle, IdleTime + 0.50, WEAP_LINUX_XTRA_OFF)
}

stock fm_play_weapon_animation(const id, const Sequence)
{
	set_pev(id, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id)
	write_byte(Sequence)
	write_byte(pev(id, pev_body))
	message_end()
}

stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0)
{
	new strtype[11] = "classname", ent = index;

	switch (jghgtype)
	{
		case 1: strtype = "target";
		case 2: strtype = "targetname";
	}

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}

	return ent;
}

stock fm_give_item(index, const item[])
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item));
	
	if (!pev_valid(ent))
		return 0;

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save)
		return ent;

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}

stock Check_Counter(id, weapon, ammo)
{
	if(g_nCurWeapon[id][0] != weapon)
	{  
		g_nCurWeapon[id][0] = weapon  
		g_nCurWeapon[id][1] = ammo
		return  
	}  

	if(g_nCurWeapon[id][1] < ammo)
	{  
		g_nCurWeapon[id][1] = ammo  
		return
	}

	if(g_nCurWeapon[id][1] == ammo)
		return

	g_nCurWeapon[id][0] = weapon 
	g_nCurWeapon[id][1] = ammo

	g_clip_counter[id]++
}

stock fm_create_velocity_vector(victim, attacker, Float:velocity[3])
{
	if(0 < victim <= g_maxplayers)
	{
		if(!zp_get_user_zombie(victim) || !is_user_alive(attacker))
		return 0;

		new Float:vicorigin[3], Float:attorigin[3]

		pev(victim, pev_origin, vicorigin)
		pev(attacker, pev_origin, attorigin)
		
		new Float:origin2[3]

		origin2[0] = vicorigin[0] - attorigin[0]
		origin2[1] = vicorigin[1] - attorigin[1]
		
		new Float:largestnum
		
		if(floatabs(origin2[0]) > largestnum)
			largestnum = floatabs(origin2[0])
		
		if(floatabs(origin2[1]) > largestnum)
			largestnum = floatabs(origin2[1])
		
		origin2[0] /= largestnum
		origin2[1] /= largestnum
		
		velocity[0] = (origin2[0] * (200.0 * 1000)) / floatround(fm_entity_range(victim, attacker))
		velocity[1] = (origin2[1] * (200.0 * 1000)) / floatround(fm_entity_range(victim, attacker))
		
		if(velocity[0] <= 20.0 || velocity[1] <= 20.0)
			velocity[2] = random_float(200.0 , 275.0)
	}
	return 1;
}

stock fm_get_user_weapon_entity(id, wid = 0)
{
	new weap = wid, clip, ammo;
	if (!weap && !(weap = get_user_weapon(id, clip, ammo)))
		return 0;

	if(!pev_valid(weap))
		return 0

	new class[32];
	get_weaponname(weap, class, sizeof class - 1);

	return fm_find_ent_by_owner(-1, class, id);
}

stock fm_trace_line(ignoreent, const Float:start[3], const Float:end[3], Float:ret[3])
{
	engfunc(EngFunc_TraceLine, start, end, ignoreent == -1 ? 1 : 0, ignoreent, 0);

	new ent = get_tr2(0, TR_pHit);
	get_tr2(0, TR_vecEndPos, ret);

	return pev_valid(ent) ? ent : 0;
}

stock Float:fm_entity_range(ent1, ent2)
{
	new Float:origin1[3], Float:origin2[3]
	
	pev(ent1, pev_origin, origin1)
	pev(ent2, pev_origin, origin2)

	return get_distance_f(origin1, origin2)
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));

	return 1;
}

stock bool:fm_is_ent_classname(index, const classname[])
{
	if (!pev_valid(index))
		return false;

	new class[32];
	pev(index, pev_classname, class, sizeof class - 1);

	if (equal(class, classname))
		return true;

	return false;
}

stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}
