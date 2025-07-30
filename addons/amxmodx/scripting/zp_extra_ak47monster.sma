#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>
#include <fakemeta_util>

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define akmonster_WEAPONKEY 	231313123
#define MAX_PLAYERS  		32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#define MAXPLAYERS		32
#define NULLENT			-1
#define OFFSET_CLIP		51
#define OFFSET_RELOAD		54
#define LINUX_DIFF		4

#define WEAP_LINUX_XTRA_OFF		4
#define m_fKnown					44
#define m_flNextPrimaryAttack 		46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF	5
#define m_flNextAttack				83

#define AK47MONSTER_RELOAD_TIME	2.4
#define AK47MONSTER_RELOAD		1
#define AK47MONSTER_DRAW		2
#define AK47MONSTER_SHOOT1		3
#define AK47MONSTER_SHOOT2		4

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "drkwp/ak47-2.wav" }

new akmonster_V_MODEL[64] = "models/drkwp/v_ak47monster.mdl"
new akmonster_P_MODEL[64] = "models/p_ak47.mdl"
new akmonster_W_MODEL[64] = "models/w_ak47.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new cvar_dmg_akmonster, cvar_recoil_akmonster, g_itemid_akmonster, cvar_clip_akmonster, cvar_spd_akmonster, cvar_akmonster_ammo, cvar_dmg_exp
new g_MaxPlayers, g_orig_event_akmonster, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_akmonster[33], g_clip_ammo[33], g_akmonster_TmpClip[33], oldweap[33]
new sprexp, punk_sprite

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
	register_plugin("[ZP] Extra: AK47 Monster", "1.0", "darkness")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_ak47", "fw_akmonster_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_akmonster_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_akmonster_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_ak47", "akmonster_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "akmonster_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "akmonster_Reload_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

	cvar_dmg_akmonster = register_cvar("zp_akmonster_dmg", "1.0")
	cvar_recoil_akmonster = register_cvar("zp_akmonster_recoil", "1.0")
	cvar_clip_akmonster = register_cvar("zp_akmonster_clip", "30")
	cvar_spd_akmonster = register_cvar("zp_akmonster_spd", "1.0")
	cvar_akmonster_ammo = register_cvar("zp_akmonster_ammo", "180")
	cvar_dmg_exp = register_cvar("cvar_dmg_exp", "200")
	
	g_itemid_akmonster = zp_register_extra_item("AK47 Monster", 35, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(akmonster_V_MODEL)
	precache_model(akmonster_P_MODEL)
	precache_model(akmonster_W_MODEL)
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	
	precache_sound("weapons/ak47monster/ak47_01.wav")
	precache_sound("weapons/ak47monster/Boltpull.wav")
	precache_sound("weapons/ak47monster/clipin.wav")
	precache_sound("weapons/ak47monster/cliplocked.wav")
	precache_sound("weapons/ak47monster/clipout.wav")
	precache_sound("weapons/ak47monster/deploy.wav")
	precache_sound("weapons/ak47monster/slideback.wav")
	precache_sound("weapons/ak47monster/slideforward.wav")
	precache_sound("weapons/ak47monster/WDraw.wav")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	sprexp = precache_model("sprites/ef_ak47monster.spr")
	punk_sprite = precache_model("sprites/ef_gib_fire1.spr")

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public weapon_hook(id)
{
    	engclient_cmd(id, "weapon_ak47")
    	return PLUGIN_HANDLED
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_AK47) return
	
	if(!g_has_akmonster[iAttacker]) return

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
	g_has_akmonster[id] = false
}

public plugin_natives ()
{
	register_native("give_weapon_akmonster", "native_give_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_akmonster(id)
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/ak47.sc", name))
	{
		g_orig_event_akmonster = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_akmonster[id] = false
}

public client_disconnected(id)
{
	g_has_akmonster[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_akmonster[id] = false
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
	
	if(equal(model, "models/w_ak47.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_ak47", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_akmonster[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, akmonster_WEAPONKEY)
			
			g_has_akmonster[iOwner] = false
			
			entity_set_model(entity, akmonster_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_akmonster(id)
{
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_ak47")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_akmonster))
		cs_set_user_bpammo (id, CSW_AK47, get_pcvar_num(cvar_akmonster_ammo))	
		UTIL_PlayWeaponAnimation(id, AK47MONSTER_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
	}
	g_has_akmonster[id] = true
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_itemid_akmonster)
		return

	give_akmonster(id)
}

public fw_akmonster_AddToPlayer(akmonster, id)
{
	if(!is_valid_ent(akmonster) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(akmonster, EV_INT_WEAPONKEY) == akmonster_WEAPONKEY)
	{
		g_has_akmonster[id] = true
		
		entity_set_int(akmonster, EV_INT_WEAPONKEY, 0)
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

     if(read_data(2) != CSW_AK47 || !g_has_akmonster[id])
          return
     
     static Float:iSpeed
     if(g_has_akmonster[id])
          iSpeed = get_pcvar_float(cvar_spd_akmonster)
     
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
		case CSW_AK47:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			
			if(g_has_akmonster[id])
			{
				set_pev(id, pev_viewmodel2, akmonster_V_MODEL)
				set_pev(id, pev_weaponmodel2, akmonster_P_MODEL)
				if(oldweap[id] != CSW_AK47) 
				{
					UTIL_PlayWeaponAnimation(id, AK47MONSTER_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_AK47 || !g_has_akmonster[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_akmonster_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_akmonster[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_akmonster) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_akmonster_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if(g_has_akmonster[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_akmonster),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(AK47MONSTER_SHOOT1, AK47MONSTER_SHOOT2))
		
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

public fw_CmdStart(Player, UC_Handle, Seed)
{
	if (!is_user_alive(Player) || !g_has_akmonster[Player] || get_user_weapon(Player) != CSW_AK47)
		return FMRES_IGNORED
		
	static buttons ; buttons = get_uc (UC_Handle, UC_Buttons)
	
	if (buttons & IN_ATTACK2)
	{
		if(get_user_weapon(Player) == CSW_AK47 && g_has_akmonster[Player] && get_pdata_float(Player, 83, 5) <= 0.0)
		{
			buttons &= ~IN_ATTACK
			set_uc (UC_Handle, UC_Buttons, buttons)

			static ak47 ; ak47 = find_ent_by_owner(NULLENT, "weapon_ak47", Player)

			static Clip ; Clip = get_pdata_int (ak47, OFFSET_CLIP, LINUX_DIFF)

			if (Clip <= 2) return FMRES_IGNORED

			static Reload ; Reload = get_pdata_int (ak47, OFFSET_RELOAD, LINUX_DIFF)

			if (Reload) return FMRES_IGNORED

			static BpAmmo ; BpAmmo = cs_get_user_bpammo(Player, CSW_AK47)

			sprite_explode(Player)

			static Float:PunchAngles[3]

			PunchAngles[1] = -3.0

			set_pev(Player, pev_punchangle, PunchAngles)

			emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			UTIL_PlayWeaponAnimation(Player, random_num(AK47MONSTER_SHOOT1, AK47MONSTER_SHOOT2))

			set_weapons_timeidle(Player, CSW_AK47, 0.5)	
			set_player_nextattackx(Player, 0.5)

			cs_set_weapon_ammo(ak47, Clip-3)

			if (Clip <= 2 && BpAmmo <= 0)
			{
				ExecuteHamB(Ham_Weapon_PlayEmptySound, ak47)
				return FMRES_IGNORED
			}
		}
	}
	return FMRES_HANDLED
}

stock sprite_explode(id)
{
	if(is_user_alive(id))
	{
		static TE_FLAG
	
		TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
		TE_FLAG |= TE_EXPLFLAG_NOSOUND
		TE_FLAG |= TE_EXPLFLAG_NOPARTICLES

		new Float:originF[3]
		fm_get_aim_origin(id,originF)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, originF[0])
		engfunc(EngFunc_WriteCoord, originF[1])
		engfunc(EngFunc_WriteCoord, originF[2])
		write_short(sprexp)
		write_byte(10)
		write_byte(10)
		write_byte(TE_FLAG)
		message_end()

		new a = FM_NULLENT

		while((a = find_ent_in_sphere(a, originF, 80.0)) != 0)
		{
			if(is_user_alive(a))
			{
				if (id == a)
					continue
				if(!zp_get_user_zombie(a))
					continue
				if(cs_get_user_team(id) == cs_get_user_team(a))
					continue
			}

			if(pev(a, pev_takedamage) != DAMAGE_NO)
			{
				ExecuteHamB(Ham_TakeDamage, a, 0, id, get_pcvar_float(cvar_dmg_exp), DMG_BULLET)
			}
		}
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_AK47)
		{
			if(g_has_akmonster[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_akmonster))
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
	
	if(equal(szTruncatedWeapon, "ak47") && get_user_weapon(iAttacker) == CSW_AK47)
	{
		if(g_has_akmonster[iAttacker])
			set_msg_arg_string(4, "ak47")
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

public akmonster_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_akmonster[id])
          return HAM_IGNORED

     static iClipExtra
     
     iClipExtra = get_pcvar_num(cvar_clip_akmonster)
     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_AK47)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_AK47, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
     }
     return HAM_IGNORED
}

public akmonster_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_akmonster[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_has_akmonster[id])
          iClipExtra = get_pcvar_num(cvar_clip_akmonster)

     g_akmonster_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_AK47)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_akmonster_TmpClip[id] = iClip

     return HAM_IGNORED
}

public akmonster_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_akmonster[id])
		return HAM_IGNORED

	if (g_akmonster_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_akmonster_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, AK47MONSTER_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, AK47MONSTER_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, AK47MONSTER_RELOAD)

	return HAM_IGNORED
}

stock set_player_nextattackx(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(entwpn, 47, TimeIdle, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, WEAP_LINUX_XTRA_OFF)
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