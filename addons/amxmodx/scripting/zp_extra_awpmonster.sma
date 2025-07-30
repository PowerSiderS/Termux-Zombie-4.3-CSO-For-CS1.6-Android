#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define monster_WEAPONKEY 		1231231313
#define MAX_PLAYERS  		32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF		4
#define m_fKnown					44
#define m_flNextPrimaryAttack 		46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF	5
#define m_flNextAttack				83

#define monster_RELOAD_TIME	3.6
#define monster_SHOOT1		1
#define monster_SHOOT2		2
#define monster_RELOAD		4
#define monster_DRAW		5

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "drkwp/awp-11.wav" }

new monster_V_MODEL[64] = "models/drkwp/v_awpmonster.mdl"
new monster_P_MODEL[64] = "models/p_awp.mdl"
new monster_W_MODEL[64] = "models/w_awp.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new cvar_dmg_monster, cvar_recoil_monster, g_itemid_monster, cvar_clip_monster, cvar_spd_monster, cvar_monster_ammo
new g_MaxPlayers, g_orig_event_monster, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_monster[33], g_clip_ammo[33], g_monster_TmpClip[33], oldweap[33]
new punk_sprite

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init()
{
	register_plugin("[ZP] Extra: AWP Monster", "1.0", "darkness")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_awp", "fw_monster_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_awp", "fw_monster_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_awp", "fw_monster_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_awp", "monster_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_awp", "monster_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_awp", "monster_Reload_Post", 1)
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

	cvar_dmg_monster = register_cvar("zp_monster_dmg", "1.37")
	cvar_recoil_monster = register_cvar("zp_monster_recoil", "4.57")
	cvar_clip_monster = register_cvar("zp_monster_clip", "5")
	cvar_spd_monster = register_cvar("zp_monster_spd", "1.3")
	cvar_monster_ammo = register_cvar("zp_monster_ammo", "100")
	
	g_itemid_monster = zp_register_extra_item("Awp Monster", 27, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(monster_V_MODEL)
	precache_model(monster_P_MODEL)
	precache_model(monster_W_MODEL)
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	
	precache_sound("weapons/AWM-MONSTER/boltup.wav")
	precache_sound("weapons/AWM-MONSTER/clipin.wav")
	precache_sound("weapons/AWM-MONSTER/clipout.wav")
	precache_sound("weapons/AWM-MONSTER/deploy.wav")
	precache_sound("weapons/AWM-MONSTER/ins.wav")
	precache_sound("weapons/AWM-MONSTER/reload.wav")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	punk_sprite = precache_model("sprites/ef_gib_fire1.spr")	

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public weapon_hook(id)
{
    	engclient_cmd(id, "weapon_awp")
    	return PLUGIN_HANDLED
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_AWP) return
	
	if(!g_has_monster[iAttacker]) return

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	write_coord_f(flEnd[0])
	write_coord_f(flEnd[1])
	write_coord_f(flEnd[2])
	write_short(iAttacker)
	write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
	message_end()
}

public zp_user_humanized_post(id)
{
	g_has_monster[id] = false
}

public plugin_natives ()
{
	register_native("give_weapon_monster", "native_give_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_monster(id)
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/awp.sc", name))
	{
		g_orig_event_monster = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_monster[id] = false
}

public client_disconnected(id)
{
	g_has_monster[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_monster[id] = false
	}
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_awp.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_awp", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_monster[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, monster_WEAPONKEY)
			
			g_has_monster[iOwner] = false
			
			entity_set_model(entity, monster_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_monster(id)
{
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_awp")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_monster))
		cs_set_user_bpammo (id, CSW_AWP, get_pcvar_num(cvar_monster_ammo))	
		UTIL_PlayWeaponAnimation(id, monster_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
	}
	g_has_monster[id] = true
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_itemid_monster)
		return

	give_monster(id)
}

public fw_monster_AddToPlayer(monster, id)
{
	if(!is_valid_ent(monster) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(monster, EV_INT_WEAPONKEY) == monster_WEAPONKEY)
	{
		g_has_monster[id] = true
		
		entity_set_int(monster, EV_INT_WEAPONKEY, 0)
	}
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if (use_type == USE_STOPPED && is_user_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))
}

public fw_Item_Deploy_Post(weapon_ent)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	replace_weapon_models(owner, weaponid)
}

public CurrentWeapon(id)
{
     replace_weapon_models(id, read_data(2))

     if(read_data(2) != CSW_AWP || !g_has_monster[id])
          return
     
     static Float:iSpeed
     if(g_has_monster[id])
          iSpeed = get_pcvar_float(cvar_spd_monster)
     
     static weapon[32],Ent
     get_weaponname(read_data(2),weapon,31)
     Ent = find_ent_by_owner(-1,weapon,id)
     if(Ent)
     {
          static Float:Delay
          Delay = get_pdata_float( Ent, 46, 4) * iSpeed
          if (Delay > 0.0)
          {
               set_pdata_float(Ent, 46, Delay, 4)
          }
     }
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_AWP:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			
			if(g_has_monster[id])
			{
				set_pev(id, pev_viewmodel2, monster_V_MODEL)
				set_pev(id, pev_weaponmodel2, monster_P_MODEL)
				if(oldweap[id] != CSW_AWP) 
				{
					UTIL_PlayWeaponAnimation(id, monster_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_AWP || !g_has_monster[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_monster_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_monster[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_monster) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_monster_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if(g_has_monster[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_monster),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(monster_SHOOT1, monster_SHOOT2))
		
		static Float:plrViewAngles[3], Float:VecEnd[3], Float:VecDir[3], Float:PlrOrigin[3]
		pev(Player, pev_v_angle, plrViewAngles)

		static Float:VecSrc[3], Float:VecDst[3]
	
		//VecSrc = pev->origin + pev->view_ofs
		pev(Player, pev_origin, PlrOrigin)
		pev(Player, pev_view_ofs, VecSrc)
		xs_vec_add(VecSrc, PlrOrigin, VecSrc)

		//VecDst = VecDir * 8192.0
		angle_vector(plrViewAngles, ANGLEVECTOR_FORWARD, VecDir);
		xs_vec_mul_scalar(VecDir, 8192.0, VecDst);
		xs_vec_add(VecDst, VecSrc, VecDst);
	
		new hTrace = create_tr2()
		engfunc(EngFunc_TraceLine, VecSrc, VecDst, 0, Player, hTrace)
		get_tr2(hTrace, TR_vecEndPos, VecEnd);

		create_tracer_water(Player, VecSrc, VecEnd)	
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_AWP)
		{
			if(g_has_monster[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_monster))
		}
	}
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "awp") && get_user_weapon(iAttacker) == CSW_AWP)
	{
		if(g_has_monster[iAttacker])
			set_msg_arg_string(4, "awp")
	}
	return PLUGIN_CONTINUE
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public monster_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_monster[id])
          return HAM_IGNORED

     static iClipExtra
     
     iClipExtra = get_pcvar_num(cvar_clip_monster)
     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_AWP)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_AWP, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
     }
     return HAM_IGNORED
}

public monster_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_monster[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_has_monster[id])
          iClipExtra = get_pcvar_num(cvar_clip_monster)

     g_monster_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_AWP)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_monster_TmpClip[id] = iClip

     return HAM_IGNORED
}

public monster_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_monster[id])
		return HAM_IGNORED

	if (g_monster_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_monster_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, monster_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, monster_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, monster_RELOAD)

	return HAM_IGNORED
}

stock create_tracer_water(id, Float:fVec1[3], Float:fVec2[3])
{
	static iVec1[3]
	FVecIVec(fVec1, iVec1)

	static Float:origin[3], Float:vSrc[3], Float:angles[3], Float:v_forward[3], Float:v_right[3], Float:v_up[3], Float:gun_position[3], Float:player_origin[3], Float:player_view_offset[3]
	pev(id, pev_v_angle, angles)
	engfunc(EngFunc_MakeVectors, angles)
	global_get(glb_v_forward, v_forward)
	global_get(glb_v_right, v_right)
	global_get(glb_v_up, v_up)

	//m_pPlayer->GetGunPosition( ) = pev->origin + pev->view_ofs
	pev(id, pev_origin, player_origin)
	pev(id, pev_view_ofs, player_view_offset)
	xs_vec_add(player_origin, player_view_offset, gun_position)

	xs_vec_mul_scalar(v_forward, 24.0, v_forward)
	xs_vec_mul_scalar(v_right, 3.0, v_right)

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

	new Float:dist = get_distance_f(vSrc, fVec2)
	new CountDrops = floatround(dist / 50.0)
	
	if (CountDrops > 20)
		CountDrops = 20
	
	if (CountDrops < 2)
		CountDrops = 2

	message_begin(MSG_PAS, SVC_TEMPENTITY, iVec1)
	write_byte(TE_SPRITETRAIL)
	engfunc(EngFunc_WriteCoord, vSrc[0])
	engfunc(EngFunc_WriteCoord, vSrc[1])
	engfunc(EngFunc_WriteCoord, vSrc[2])
	engfunc(EngFunc_WriteCoord, fVec2[0])
	engfunc(EngFunc_WriteCoord, fVec2[1])
	engfunc(EngFunc_WriteCoord, fVec2[2])
	write_short(punk_sprite)
	write_byte(CountDrops)
	write_byte(0)
	write_byte(1)
	write_byte(60)
	write_byte(10)
	message_end()

	message_begin(MSG_PAS, SVC_TEMPENTITY, iVec1)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, fVec2[0])
	engfunc(EngFunc_WriteCoord, fVec2[1])
	engfunc(EngFunc_WriteCoord, fVec2[2])
	engfunc(EngFunc_WriteCoord, vSrc[0])
	engfunc(EngFunc_WriteCoord, vSrc[1])
	engfunc(EngFunc_WriteCoord, vSrc[2])
	write_short(punk_sprite)
	write_byte(6)
	write_byte(200) 
	write_byte(1)
	write_byte(100)
	write_byte(0)
	write_byte(64); write_byte(64); write_byte(192);
	write_byte(192)
	write_byte(250) 
	message_end()
}

stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}