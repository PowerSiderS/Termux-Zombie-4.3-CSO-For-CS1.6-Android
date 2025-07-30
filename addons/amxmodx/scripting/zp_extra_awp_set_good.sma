#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define CustomMuzzle(%0) (pev(%0, pev_impulse) == g_iszMuzzleKey)
#define Sprite_SetScale(%0,%1) set_pev(%0, pev_scale, %1)

// CSprite
#define m_maxFrame 35

// Muzzle Flash
#define MUZZLE_TIME 0.01 // Время обновления спрайта Muzzle Flash
#define MUZZLE_SPRITE "sprites/laserbeam.spr" // Это наш Muzzle Flash. Меняете его на свой
#define MUZZLE_CLASSNAME "ent_mf_wpn" // Сюда пишем название для нашей энтити с Muzzle Flash'ом
#define MUZZLE_INTOLERANCE 100

new g_iszMuzzleKey

#define DL_FLAGS ADMIN_LEVEL_A

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define dragonl_WEAPONKEY 	822
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

#define dragonl_RELOAD_TIME	3.0
#define dragonl_SHOOT1		1
#define dragonl_SHOOT2		2
#define dragonl_RELOAD		4
#define dragonl_DRAW		5

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "weapons/awp1.wav" }

new dragonl_V_MODEL[64] = "models/set/v_awp.mdl"
new dragonl_P_MODEL[64] = "models/set/p_awp.mdl"
new dragonl_W_MODEL[64] = "models/set/w_awp.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new cvar_dmg_dragonl, cvar_recoil_dragonl, g_itemid_dragonl, cvar_clip_dragonl, cvar_spd_dragonl, cvar_dragonl_ammo
new g_MaxPlayers, g_orig_event_dragonl, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_dragonl[33], g_clip_ammo[33], g_dragonl_TmpClip[33], oldweap[33]

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
	register_plugin("[ZP] Addon: AWP Dragon Lore", "1.0", "Crock / Lars ReEdit: kHRYSTAL")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_awp", "fw_dragonl_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_awp", "fw_dragonl_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_awp", "dragonl_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_awp", "dragonl_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_awp", "dragonl_Reload_Post", 1)
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
	RegisterHam(Ham_Think, "env_sprite", "CMuzzleFlash_Think_Pre", false)
	
	//register_clcmd("setgood", "get_dragonl")

	cvar_dmg_dragonl = register_cvar("zp_dragonl_dmg", "500")
	cvar_recoil_dragonl = register_cvar("zp_dragonl_recoil", "1.0")
	cvar_clip_dragonl = register_cvar("zp_dragonl_clip", "10")
	cvar_spd_dragonl = register_cvar("zp_dragonl_spd", "1.0")
	cvar_dragonl_ammo = register_cvar("zp_dragonl_ammo", "30")
	
	g_itemid_dragonl = zp_register_extra_item("Awp Set Dragonl", 20, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
// Muzzle Flash
    engfunc(EngFunc_PrecacheModel, MUZZLE_SPRITE);

    g_iszMuzzleKey = engfunc(EngFunc_AllocString, MUZZLE_CLASSNAME)
	
	precache_model(dragonl_V_MODEL)
	precache_model(dragonl_P_MODEL)
	precache_model(dragonl_W_MODEL)
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
    	precache_generic("sprites/640hud7.spr")
		
		g_iszMuzzleKey = precache_model("sprites/boss_weapons/hell_exp_flame_1.spr")
	
    	register_clcmd("awp", "weapon_hook")	

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}
	
	stock Sprite_SetTransparency(const iSprite, const iRendermode, const Float: flAmt, const iFx = kRenderFxNone)
{
	set_pev(iSprite, pev_rendermode, iRendermode);
	set_pev(iSprite, pev_renderamt, flAmt);
	set_pev(iSprite, pev_renderfx, iFx);
}

    stock Weapon_MuzzleFlash(const iPlayer, const szMuzzleSprite[], const Float: flScale, const Float: flBrightness, const iAttachment)
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
	
	if(pev_valid(iSprite) != 2)
	{
		return FM_NULLENT;
	}
	
	set_pev(iSprite, pev_model, szMuzzleSprite);
	set_pev(iSprite, pev_spawnflags, SF_SPRITE_ONCE);
	
	set_pev(iSprite, pev_classname, MUZZLE_CLASSNAME);
	set_pev(iSprite, pev_impulse, g_iszMuzzleKey);
	set_pev(iSprite, pev_owner, iPlayer);
	
	set_pev(iSprite, pev_aiment, iPlayer);
	set_pev(iSprite, pev_body, iAttachment);
	
	Sprite_SetTransparency(iSprite, kRenderTransAdd, flBrightness);
	Sprite_SetScale(iSprite, flScale);
	
	dllfunc(DLLFunc_Spawn, iSprite)

	return iSprite;
}
public CMuzzleFlash_Think_Pre(const iSprite)
{
	static Float: flFrame;
	
	if (pev_valid(iSprite) != 2 || !CustomMuzzle(iSprite))
	{
		return HAM_IGNORED;
	}
	
	if (pev(iSprite, pev_frame, flFrame) && ++flFrame - 1.0 < get_pdata_float(iSprite, m_maxFrame, 4))
	{
		set_pev(iSprite, pev_frame, flFrame);
		set_pev(iSprite, pev_nextthink, get_gametime() + MUZZLE_TIME);
		
		return HAM_SUPERCEDE;
	}

	set_pev(iSprite, pev_flags, FL_KILLME);
	return HAM_SUPERCEDE;
}

public get_dragonl(id)
{
	if(get_user_flags(id) & DL_FLAGS)
	{
		give_dragonl(id)
	}
	else
	{
		color_chat(id, "!g[ZP] !yСоздатель плагина kHRYSTAL")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
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
	
	if(!g_has_dragonl[iAttacker]) return

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
	g_has_dragonl[id] = false
}

public plugin_natives ()
{
	register_native("give_weapon_dragonl", "native_give_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_dragonl(id)
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/awp.sc", name))
	{
		g_orig_event_dragonl = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_dragonl[id] = false
}

public client_disconnect(id)
{
	g_has_dragonl[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_dragonl[id] = false
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
	
		if(g_has_dragonl[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, dragonl_WEAPONKEY)
			
			
			entity_set_model(entity, dragonl_W_MODEL)
			
			g_has_dragonl[iOwner] = false
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_dragonl(id)
{
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_awp")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_dragonl))
		cs_set_user_bpammo (id, CSW_AWP, get_pcvar_num(cvar_dragonl_ammo))	
		UTIL_PlayWeaponAnimation(id, dragonl_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
	}
	g_has_dragonl[id] = true
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_itemid_dragonl)
		return

	give_dragonl(id)
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

    if(read_data(2) != CSW_AWP || !g_has_dragonl[id])
        return
     
    static Float:iSpeed
    if(g_has_dragonl[id])
        iSpeed = get_pcvar_float(cvar_spd_dragonl)
     
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
			
			if(g_has_dragonl[id])
			{
				set_pev(id, pev_viewmodel2, dragonl_V_MODEL)
				set_pev(id, pev_weaponmodel2, dragonl_P_MODEL)
				if(oldweap[id] != CSW_AWP) 
				{
					UTIL_PlayWeaponAnimation(id, dragonl_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_AWP || !g_has_dragonl[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_dragonl_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_dragonl[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_dragonl) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_dragonl_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if(g_has_dragonl[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_dragonl),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(dragonl_SHOOT1, dragonl_SHOOT2))
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_AWP)
		{
			if(g_has_dragonl[attacker])
				SetHamParamFloat(4, get_pcvar_float(cvar_dmg_dragonl))
				iszMuzzleKey(victim)
		}
	}
}

public iszMuzzleKey(id)
{
	new origin[3]
	get_user_origin(id, origin)
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE)
	write_coord(origin[0] + random_num(-5, 5))
	write_coord(origin[1] + random_num(-5, 5))
	write_coord(origin[2] + random_num(-10, 10))
	write_short(g_iszMuzzleKey)
	write_byte(random_num(5, 10))
	write_byte(200)
	message_end()
}	

public message_DeathMsg(msg_id, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "awp") && get_user_weapon(iAttacker) == CSW_AWP)
	{
		if(g_has_dragonl[iAttacker])
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

public dragonl_ItemPostFrame(weapon_entity) 
{
    new id = pev(weapon_entity, pev_owner)
    if (!is_user_connected(id))
        return HAM_IGNORED

    if (!g_has_dragonl[id])
        return HAM_IGNORED

    static iClipExtra
     
    iClipExtra = get_pcvar_num(cvar_clip_dragonl)
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

public dragonl_Reload(weapon_entity) 
{
    new id = pev(weapon_entity, pev_owner)
    if (!is_user_connected(id))
        return HAM_IGNORED

    if (!g_has_dragonl[id])
        return HAM_IGNORED

    static iClipExtra

    if(g_has_dragonl[id])
        iClipExtra = get_pcvar_num(cvar_clip_dragonl)

    g_dragonl_TmpClip[id] = -1

    new iBpAmmo = cs_get_user_bpammo(id, CSW_AWP)
    new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

    if (iBpAmmo <= 0)
        return HAM_SUPERCEDE

    if (iClip >= iClipExtra)
        return HAM_SUPERCEDE

    g_dragonl_TmpClip[id] = iClip

    return HAM_IGNORED
}

public dragonl_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_dragonl[id])
		return HAM_IGNORED

	if (g_dragonl_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_dragonl_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, dragonl_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, dragonl_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, dragonl_RELOAD)

	return HAM_IGNORED
}

stock color_chat(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!y", "^1")
	replace_all(msg, 190, "!t", "^3")
	if(id) players[0] = id; else get_players(players, count, "ch")
	{
		for(new i = 0; i < count; i++)
		{
			if(is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
				write_byte(players[i])
				write_string(msg)
				message_end()
			}
		}
	}
}

stock drop_weapons(id, dropwhat)
{
    static weapons[32], num, i, weaponid
    num = 0
    get_user_weapons(id, weapons, num)
     
    for (i = 0; i < num; i++)
    {
        weaponid = weapons[i]
          
        if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)))
        {
            static wname[32]
            get_weaponname(weaponid, wname, charsmax(wname))
            engclient_cmd(id, "drop", wname)
        }
    }
}