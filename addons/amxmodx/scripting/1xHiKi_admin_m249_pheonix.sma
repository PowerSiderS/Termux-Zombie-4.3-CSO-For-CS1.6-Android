#pragma compress 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>
#include <fakemeta_util>

#define ZITEM_CSW_NAME CSW_M249
#define ZITEM_SC_NAME "events/m249.sc"
#define ZITEM_OLD_MODEL_NAME "models/w_m249.mdl"
#define ZITEM_WEAPON_NAME "weapon_m249"
#define ZITEM_DEATH_ICON_NAME "m249"

new BlockPheonix[33], LineSpr, ExpSpr

#define PHEONIX_UNLOCK_TIME 10.0
#define PHEONIX_FLY_SOUND "zpt/buffm249_scream2.wav"
#define PHEONIX_EXP_SOUND "zpt/buffm249_exp1.wav"
#define PHEONIX_CLASSNAME "__M249Pheonix__"
#define PHEONIX_SPEED_FLY 1000
#define PHEONIX_EXP_RADIUS 150.0
#define PHEONIX_EXP_DAMAGE 500.0
#define PHEONIX_LINE_SPR "sprites/laserbeam.spr"
#define PHEONIX_EXP_SPR "sprites/zpt/ef_cannonex.spr"

new const PHEONIX_MODEL[] = "models/zpt/ef_phoenix2.mdl"

#define ENG_NULLENT -1
#define EV_INT_WEAPONKEY EV_INT_impulse
#define ZITEM_WEAPONKEY 1234501
#define MAX_PLAYERS 32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF 4
#define m_fKnown 44
#define m_flNextPrimaryAttack 46
#define m_flTimeWeaponIdle 48
#define m_iClip 51
#define m_fInReload 54
#define PLAYER_LINUX_XTRA_OFF 5
#define m_flNextAttack 83

#define ANIM_RELOAD_TIME 136/30.0
#define ANIM_SHOOT1 1
#define ANIM_SHOOT2 2
#define ANIM_RELOAD 3
#define ANIM_DRAW 4

#define write_coord_f(%1) engfunc(EngFunc_WriteCoord, %1)

new const Fire_Sounds[][] = { "zpt/buffm249-1.wav" }

new ZITEM_V_MODEL[64] = "models/zpt/v_buffm249.mdl"
new ZITEM_P_MODEL[64] = "models/zpt/p_buffm249.mdl"
new ZITEM_W_MODEL[64] = "models/zpt/w_buffm249.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new g_DMG_ITEM, g_RECOIL_ITEM, g_CLIP_ITEM, g_SPEED_ITEM, g_AMMO_ITEM
new g_MaxPlayers, g_orig_event, g_IsInPrimaryAttack
new Float: cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_ZITEM[33], g_clip_ammo[33], g_TmpClip[33], oldweap[33]

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init() {
	register_plugin( 
	"[ZP] Extra: M249 Pheonix",
	"1.0",
	"Crock / =) (Poprogun4ik) / LARS-DAY[BR]EAKER / MKOD / vk.com/top_amxx" 
	)
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon", "CurrentWeapon", "be", "1=1")
	RegisterHam(Ham_Item_AddToPlayer, ZITEM_WEAPON_NAME, "FW_ZITEM_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for(new i = 1; i < sizeof WEAPONENTNAMES; i++) {
		if(WEAPONENTNAMES[i][0])
			RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	}
	RegisterHam(Ham_Weapon_PrimaryAttack, ZITEM_WEAPON_NAME, "FW_ZITEM_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, ZITEM_WEAPON_NAME, "FW_ZITEM_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, ZITEM_WEAPON_NAME, "FW_ZITEM_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, ZITEM_WEAPON_NAME, "FW_ZITEM_Reload")
	RegisterHam(Ham_Weapon_Reload, ZITEM_WEAPON_NAME, "FW_ZITEM_Reload_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)
	
	register_forward(FM_CmdStart, "FW_TwoClickMouse")
	register_touch(PHEONIX_CLASSNAME, "*", "FW_PheonixTouch")
	
	g_DMG_ITEM = register_cvar("zp_dmg_m249pheonix", "1.9")
	g_RECOIL_ITEM = register_cvar("zp_recoil_m249pheonix", "0.95")
	g_CLIP_ITEM = register_cvar("zp_clip_m249pheonix", "100")
	g_SPEED_ITEM = register_cvar("zp_speed_m249pheonix", "1.15")
	g_AMMO_ITEM = register_cvar("zp_ammo_m249pheonix", "200")
	
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache() {
	precache_model(ZITEM_V_MODEL)
	precache_model(ZITEM_P_MODEL)
	precache_model(ZITEM_W_MODEL)
	for(new i = 0; i < sizeof Fire_Sounds; i++)
		precache_sound(Fire_Sounds[i])
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	
	precache_sound(PHEONIX_FLY_SOUND)
	precache_sound(PHEONIX_EXP_SOUND)
	LineSpr = precache_model(PHEONIX_LINE_SPR)
	ExpSpr = precache_model(PHEONIX_EXP_SPR)
	precache_model(PHEONIX_MODEL)
	
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public fw_TraceAttack(iEnt, iAttacker, Float: flDamage, Float: fDir[3], ptr, iDamageType) {
	if(!is_user_alive(iAttacker))
		return
	
	new g_currentweapon = get_user_weapon(iAttacker)
	
	if(g_currentweapon != ZITEM_CSW_NAME)
		return
	if(!g_ZITEM[iAttacker])
		return
	
	static Float: flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(iEnt) {
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()
	} else {
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	write_coord_f(flEnd[0])
	write_coord_f(flEnd[1])
	write_coord_f(flEnd[2])
	write_short(iAttacker)
	write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS -1)])
	message_end()
}

public zp_user_humanized_post(id)
	g_ZITEM[id] = false
public plugin_natives()
	register_native("give_buffm249", "native_give_weapon_add", 1)
public native_give_weapon_add(id)
	FW_GIVE_ZITEM(id)

public fwPrecacheEvent_Post(type, const name[]) {
	if(equal(ZITEM_SC_NAME, name)) {
		g_orig_event = get_orig_retval()
		
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
	g_ZITEM[id] = false
public client_disconnected(id)
	g_ZITEM[id] = false

public zp_user_infected_post(id) {
	if(zp_get_user_zombie(id))
		g_ZITEM[id] = false
}

public fw_SetModel(entity, model[]) {
	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, ZITEM_OLD_MODEL_NAME)) {
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, ZITEM_WEAPON_NAME, entity)
		
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
		
		if(g_ZITEM[iOwner]) {
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, ZITEM_WEAPONKEY)
			
			g_ZITEM[iOwner] = false
			
			entity_set_model(entity, ZITEM_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public FW_GIVE_ZITEM(id) {
	drop_weapons(id, 1)
	new iWep2 = give_item(id, ZITEM_WEAPON_NAME)
	
	if(iWep2 > 0) {
		cs_set_weapon_ammo(iWep2, get_pcvar_num(g_CLIP_ITEM))
		cs_set_user_bpammo(id, ZITEM_CSW_NAME, get_pcvar_num(g_AMMO_ITEM))
		UTIL_PlayWeaponAnimation(id, ANIM_DRAW)
		set_pdata_float(id, m_flNextAttack, 31/30.0, PLAYER_LINUX_XTRA_OFF)
	}
	g_ZITEM[id] = true
}

public FW_ZITEM_AddToPlayer(ZITEM, id) {
	if(!is_valid_ent(ZITEM) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(ZITEM, EV_INT_WEAPONKEY) == ZITEM_WEAPONKEY) {
		g_ZITEM[id] = true
		
		entity_set_int(ZITEM, EV_INT_WEAPONKEY, 0)
	}
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type) {
	if(use_type == USE_STOPPED && is_user_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))
}

public fw_Item_Deploy_Post(weapon_ent) {
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	replace_weapon_models(owner, weaponid)
}

public CurrentWeapon(id) {
	replace_weapon_models(id, read_data(2))
	
	if(read_data(2) != ZITEM_CSW_NAME || !g_ZITEM[id])
		return
	
	static Float: iSpeed
	
	if(g_ZITEM[id])
		iSpeed = get_pcvar_float(g_SPEED_ITEM)
	
	static weapon[32], Ent
	get_weaponname(read_data(2), weapon, 31)
	Ent = find_ent_by_owner(-1, weapon, id)
	
	if(Ent) {
		static Float: Delay
		Delay = get_pdata_float(Ent, 46, 4) * iSpeed
		
		if(Delay > 0.0)
			set_pdata_float(Ent, 46, Delay, 4)
	}
}

replace_weapon_models(id, weaponid) {
	switch(weaponid) {
		case ZITEM_CSW_NAME: {
			if(zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			
			if(g_ZITEM[id]) {
				set_pev(id, pev_viewmodel2, ZITEM_V_MODEL)
				set_pev(id, pev_weaponmodel2, ZITEM_P_MODEL)
				
				if(oldweap[id] != ZITEM_CSW_NAME) {
					UTIL_PlayWeaponAnimation(id, ANIM_DRAW)
					set_pdata_float(id, m_flNextAttack, 31/30.0, PLAYER_LINUX_XTRA_OFF)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle) {
	if(!is_user_alive(Player) || (get_user_weapon(Player) != ZITEM_CSW_NAME || !g_ZITEM[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time() + 0.001)
	
	return FMRES_HANDLED
}

public FW_ZITEM_PrimaryAttack(Weapon) {
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(!g_ZITEM[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player, pev_punchangle, cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float: delay, Float: origin[3], Float: angles[3], Float: fparam1, Float: fparam2, iParam1, iParam2, bParam1, bParam2) {
	if((eventid != g_orig_event) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if(!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED
	
	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	return FMRES_SUPERCEDE
}

public FW_ZITEM_PrimaryAttack_Post(Weapon) {
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return
	
	if(g_ZITEM[Player]) {
		if(!g_clip_ammo[Player])
			return
		
		new Float: push[3]
		pev(Player, pev_punchangle, push)
		xs_vec_sub(push, cl_pushangle[Player], push)
		
		xs_vec_mul_scalar(push, get_pcvar_float(g_RECOIL_ITEM), push)
		xs_vec_add(push, cl_pushangle[Player], push)
		set_pev(Player, pev_punchangle, push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, ANIM_SHOOT1)
	}
}

public FW_TwoClickMouse(id, uc_handle) {
	if(!g_ZITEM[id] || get_user_weapon(id) != ZITEM_CSW_NAME) return PLUGIN_HANDLED
	
	static button; button = get_uc(uc_handle, UC_Buttons)
	static oldbutton; oldbutton = pev(id, pev_oldbuttons)
	
	if((button & IN_ATTACK2) && !(oldbutton & IN_ATTACK2)) {
		if(BlockPheonix[id] == 0) {
			BlockPheonix[id] = 1
			
			FW_MakePheonix(id)
			UTIL_PlayWeaponAnimation(id, ANIM_SHOOT2)
			set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
			emit_sound(id, CHAN_WEAPON, PHEONIX_FLY_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			
			set_task(PHEONIX_UNLOCK_TIME, "FW_PheonixUnlock", id)
		}
	}
	return PLUGIN_HANDLED
}

public FW_MakePheonix(id) {
	new ent, Float: Origin[3], Float: Angles[3], Float: Velocity[3]
	
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	engfunc(EngFunc_GetAttachment, id, 0, Origin, Angles)
	pev(id, pev_angles, Angles)
	
	set_pev(ent, pev_origin, Origin)
	set_pev(ent, pev_angles, Angles)
	set_pev(ent, pev_solid, 2)
	set_pev(ent, pev_movetype, MOVETYPE_FLYMISSILE)
	set_pev(ent, pev_classname, PHEONIX_CLASSNAME)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_mins, {-1.0, -1.0, -1.0})
	set_pev(ent, pev_maxs, {1.0, 1.0, 1.0})
	
	engfunc(EngFunc_SetModel, ent, PHEONIX_MODEL)
	
	set_entity_anim(ent, 0, 1)
	
	velocity_by_aim(id, PHEONIX_SPEED_FLY, Velocity)
	set_pev(ent, pev_velocity, Velocity)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(ent)
	write_short(LineSpr)
	write_byte(10)
	write_byte(1)
	write_byte(255)
	write_byte(70)
	write_byte(0)
	write_byte(255)
	message_end()
}

stock set_entity_anim(ent, anim, reset_frame) {
	if(!pev_valid(ent)) return
	
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, 1.0)
	if(reset_frame) set_pev(ent, pev_frame, 0.0)
	
	set_pev(ent, pev_sequence, anim)
}

public FW_PheonixTouch(Ent, Touch) {
	if(!pev_valid(Ent)) return
	
	static Float: Origin[3]
	pev(Ent, pev_origin, Origin)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 0.0)
	write_short(ExpSpr)
	write_byte(15)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
	
	emit_sound(Ent, CHAN_BODY, PHEONIX_EXP_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	static Owner; Owner = pev(Ent, pev_owner)
	
	if(is_user_connected(Owner)) {
		static Victim; Victim = -1
		while((Victim = find_ent_in_sphere(Victim, Origin, PHEONIX_EXP_RADIUS)) != 0) {
			if(is_user_alive(Victim)) {
				if(Victim == Owner)
					continue
				if(get_user_weapon(Owner) == CSW_KNIFE)
					engfunc(EngFunc_RemoveEntity, Ent)
			} else {
				if(pev(Victim, pev_takedamage) == DAMAGE_NO)
					continue
			}
			ExecuteHamB(Ham_TakeDamage, Victim, Ent, Owner, PHEONIX_EXP_DAMAGE, DMG_BULLET)
		}
	}
	set_pev(Ent, pev_flags, FL_KILLME)
}

public FW_PheonixUnlock(id) {
	if(BlockPheonix[id] > 0)
		BlockPheonix[id] -= 1
	
	return PLUGIN_HANDLED
}

public fw_TakeDamage(victim, inflictor, attacker, Float: damage) {
	if(victim != attacker && is_user_connected(attacker)) {
		if(get_user_weapon(attacker) == ZITEM_CSW_NAME) {
			if(g_ZITEM[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(g_DMG_ITEM))
		}
	}
}

public message_DeathMsg(msg_id, msg_dest, id) {
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, ZITEM_DEATH_ICON_NAME) && get_user_weapon(iAttacker) == ZITEM_CSW_NAME) {
		if(g_ZITEM[iAttacker])
			set_msg_arg_string(4, ZITEM_DEATH_ICON_NAME)
	}
	return PLUGIN_CONTINUE
}

stock fm_cs_get_current_weapon_ent(id)
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
stock fm_cs_get_weapon_ent_owner(ent)
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)

stock UTIL_PlayWeaponAnimation(const Player, const Sequence) {
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public FW_ZITEM_ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_ZITEM[id])
		return HAM_IGNORED
	
	static iClipExtra
	
	iClipExtra = get_pcvar_num(g_CLIP_ITEM)
	new Float: flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)
	
	new iBpAmmo = cs_get_user_bpammo(id, ZITEM_CSW_NAME)
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)
	
	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF)
	
	if(fInReload && flNextAttack <= 0.0) {
		new j = min(iClipExtra - iClip, iBpAmmo)
		
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, ZITEM_CSW_NAME, iBpAmmo - j)
		
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}
	return HAM_IGNORED
}

public FW_ZITEM_Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_ZITEM[id])
		return HAM_IGNORED
	
	static iClipExtra
	
	if(g_ZITEM[id])
		iClipExtra = get_pcvar_num(g_CLIP_ITEM)
	
	g_TmpClip[id] = -1
	
	new iBpAmmo = cs_get_user_bpammo(id, ZITEM_CSW_NAME)
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)
	
	if(iBpAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= iClipExtra)
		return HAM_SUPERCEDE
	
	g_TmpClip[id] = iClip
	
	return HAM_IGNORED
}

public FW_ZITEM_Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_ZITEM[id])
		return HAM_IGNORED
	if(g_TmpClip[id] == -1)
		return HAM_IGNORED
	
	set_pdata_int(weapon_entity, m_iClip, g_TmpClip[id], WEAP_LINUX_XTRA_OFF)
	
	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, ANIM_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)
	
	set_pdata_float(id, m_flNextAttack, ANIM_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)
	
	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)
	
	UTIL_PlayWeaponAnimation(id, ANIM_RELOAD)
	
	return HAM_IGNORED
}

stock drop_weapons(id, dropwhat) {
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	for(i = 0; i < num; i++) {
		weaponid = weapons[i]
		
		if(dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) {
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}