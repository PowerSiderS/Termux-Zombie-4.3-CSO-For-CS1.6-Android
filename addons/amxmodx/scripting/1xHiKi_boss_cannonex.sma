#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <xs>

#define PLUGIN "Red Dragon Cannon"
#define VERSION "1.0"
#define AUTHOR "Rachel aka Asdian"

#define CSW_CANNONEX CSW_M249
#define weapon_cannonex "weapon_m249"

#define CANNONFIRE_CLASSNAME "cannonex_fire"
#define DRAGON_CLASSNAME "cannonex_dragon"
#define DRAGONFIRE_CLASSNAME "cannonex_dragonfire"
#define DRAGONEFX_CLASSNAME "cannonex_dragonefx"
#define CANNONEXP_CLASSNAME "cannonex_dragonexp"

new const models_used[][] = 
{
	"models/v_cannonex.mdl",		// 0
	"models/p_cannonex.mdl",		// 1
	"models/w_cannonex.mdl",		// 2

	"models/p_cannonexb.mdl",		// 3
	"models/w_cannonexb.mdl",		// 4
	"models/p_cannonexdragonfx.mdl",	// 5
	"models/p_cannonexplo.mdl",		// 6
	"sprites/flame_puff01.spr",		// 7

	"models/cannonexdragon.mdl",		// 8
	
	"models/v_cannonex_d3a3.mdl",		// 9
	"models/p_cannonex_d3a3.mdl",		// 10
	"models/w_cannonex_d3a3.mdl",		// 11

	"models/p_cannonexb_d3a3.mdl",		// 12
	"models/w_cannonexb_d3a3.mdl",		// 13
	"models/p_cannonexdragonfx_d3a3.mdl",	// 14
	"models/p_cannonexplo_d3a3.mdl",	// 15
	"sprites/ef_cannonex_breath_d3a3.spr",	// 16

	"models/cannonexdragon_d3a3.mdl"	// 17
}

new const cannon_sound[][] = 
{
	"weapons/cannonex_shoota.wav",			// 0
	"weapons/cannonex_d_reload1.wav",		// 1
	"weapons/cannonex_dragonfx_idle.wav",		// 2
	"weapons/cannonexplo.wav",			// 3
	"weapons/flamegun-1.wav",			// 4
	"weapons/cannonex_dragon_fire_end.wav",		// 5
	
	"weapons/cannonex_ice_shoota.wav",		// 6
	"weapons/cannonex_ice_d_reload1.wav",		// 7
	"weapons/cannonex_dragon_ice.wav",		// 8
	"weapons/cannonex_dragon_ice_end.wav"		// 9
}

enum _:HIT_RESULT
{
	RESULT_HIT_NONE = 0,
	RESULT_HIT_PLAYER,
	RESULT_HIT_WORLD
}

new g_had_cannonex[33], g_ammo[33], g_mode[33], Float:g_double[33], Float:g_hold[33], g_change[33], Float:g_flame_delay[33][3], g_type[33]
new g_cache_smoke, g_cache_flameburn[2], g_cache_ef_dragon[2], Float:g_cache_frame_flame, g_cache_flame[2]

new cvar_dmgrandom_start, cvar_dmgrandom_end, cvar_radius, cvar_flame_dmg

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("CurWeapon", "event_curweapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	RegisterHam(Ham_Think, "info_target", "fw_think")
	RegisterHam(Ham_Touch, "info_target", "fw_Touch")

	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	
	RegisterHam(Ham_Item_PostFrame, weapon_cannonex, "fw_Item_PostFrame")
	RegisterHam(Ham_Item_AddToPlayer, weapon_cannonex, "fw_item_addtoplayer", 1)
	
	cvar_dmgrandom_start = register_cvar("zp_cannonex_dmgrandom_start", "2000.0")
	cvar_dmgrandom_end = register_cvar("zp_cannonex_dmgrandom_end", "2500.0")
	cvar_radius = register_cvar("zp_cannonex_radius", "350.0")
	cvar_flame_dmg = register_cvar("zp_cannonex_dmg_dragonflame", "250.0")
	
	register_clcmd("rdc_red", "zp_extra_item_selected")
	register_clcmd("rdc_blue", "zp_extra_item_selected2")
	
	register_clcmd("weapon_cannonex", "hook_weapon")
	register_clcmd("buyammo1", "cmd_buy_ammo")
}

public plugin_precache()
{
	new i
	for(i = 0; i < sizeof(models_used); i++)
	{
		if(i == 7) g_cache_flame[0] = engfunc(EngFunc_PrecacheModel, models_used[i])
		if(i ==16) g_cache_flame[1] = engfunc(EngFunc_PrecacheModel, models_used[i])
		engfunc(EngFunc_PrecacheModel, models_used[i])
	}
	for(i = 0; i < sizeof(cannon_sound); i++)
		engfunc(EngFunc_PrecacheSound, cannon_sound[i])

	engfunc(EngFunc_PrecacheGeneric, "sprites/weapon_cannonex.txt")
	g_cache_frame_flame = float(engfunc(EngFunc_ModelFrames, g_cache_flame[0]))

	g_cache_ef_dragon[0] = engfunc(EngFunc_PrecacheModel, "sprites/ef_cannonex.spr")
	g_cache_ef_dragon[1] = engfunc(EngFunc_PrecacheModel, "sprites/ef_cannonex_d3a3.spr")
	g_cache_flameburn[0] = engfunc(EngFunc_PrecacheModel, "sprites/flame_burn01.spr")
	g_cache_flameburn[1] = engfunc(EngFunc_PrecacheModel, "sprites/holybomb_burn.spr")
	g_cache_smoke = engfunc(EngFunc_PrecacheModel, "sprites/smoke_ia.spr")
}

public message_DeathMsg()
{
	static Weapon[33], iAttacker
	get_msg_arg_string(4, Weapon, charsmax(Weapon))
	iAttacker = get_msg_arg_int(1)
	 
	if(!is_user_connected(iAttacker))
		return PLUGIN_CONTINUE
		
	if(equal(Weapon, "m249") && get_user_weapon(iAttacker) == CSW_CANNONEX)
		if(g_had_cannonex[iAttacker]) set_msg_arg_string(4, "cannonex")
	
	return PLUGIN_CONTINUE
}

public hook_weapon(id) engclient_cmd(id, weapon_cannonex)
public cmd_buy_ammo(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return

	g_ammo[id] = g_type[id]?45:30

	if(get_user_weapon(id) != CSW_CANNONEX || !g_had_cannonex[id])
		return
	
	update_ammo(id, g_ammo[id])
}

public plugin_natives()
{
	register_native("give_cannonex", "Gimme_NOW", 1)
}

public Gimme_NOW(id)
{
	Stock_Drop_Slot(id, 1)
	
	g_had_cannonex[id] = 1
	//g_type[id] = type
	g_mode[id] = 0
	g_change[id] = 0
	//g_ammo[id] = type?45:30

	give_item(id, weapon_cannonex)

	set_weapon_list(id)
	update_ammo(id, g_ammo[id])
	set_weapon_anim(id, 2)
}

public update_ammo(id, ammo)
{
	if(!is_user_alive(id))
		return
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), _, id)
	write_byte(1)
	write_byte(CSW_CANNONEX)
	write_byte(-1)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(3)
	write_byte(ammo)
	message_end()
}

public event_curweapon(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_HANDLED
	if(get_user_weapon(id) != CSW_CANNONEX || !g_had_cannonex[id])
		return PLUGIN_HANDLED
	
	set_pev(id, pev_viewmodel2, models_used[g_type[id]?9:0])
	set_pev(id, pev_weaponmodel2, models_used[g_type[id]?(g_mode[id]?12:10):(g_mode[id]?3:1)])
	
	set_weapon_anim(id, g_mode[id] ? 3 : 2)
	set_weapon_list(id)
	update_ammo(id, g_ammo[id])
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_CANNONEX)
	if(!pev_valid(ent)) return PLUGIN_CONTINUE
	
	set_pev(ent, pev_iuser1, g_mode[id]?2:0)
	set_pev(ent, pev_iuser2, 0)
	set_pev(ent, pev_iuser3, 0)
	set_pev(ent, pev_iuser4, 0)
	g_change[id] = 0
	return PLUGIN_CONTINUE
}

public zp_user_infected_post(id)
{
	g_had_cannonex[id] = 0
	g_mode[id] = 0
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_CANNONEX || !g_had_cannonex[id])
		return FMRES_IGNORED
	
	set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001)  
	
	return FMRES_HANDLED
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
	
	static szClassName[33]
	pev(entity, pev_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED;
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, "models/w_m249.mdl"))
	{
		static ent
		ent = find_ent_by_owner(-1, weapon_cannonex, entity)
		
		if(!is_valid_ent(ent))
			return FMRES_IGNORED;
		
		if(g_had_cannonex[iOwner])
		{
			set_pev(ent, pev_impulse, 1028)
			g_had_cannonex[iOwner] = 0

			set_pev(ent, pev_iuser3, g_ammo[iOwner])
			engfunc(EngFunc_SetModel, entity, models_used[g_type[iOwner]?(g_mode[iOwner]?13:11):(g_mode[iOwner]?4:2)])
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public fw_item_addtoplayer(ent, id)
{
	if(!is_valid_ent(ent))
		return HAM_IGNORED
			
	if(pev(ent, pev_impulse) == 1028)
	{
		g_had_cannonex[id] = 1
		set_pev(ent, pev_iuser3, 0)
	
		update_ammo(id, g_ammo[id])
		set_weapon_anim(id, g_mode[id] ? 3 : 2)
		
		set_pev(ent, pev_impulse, 0)
		return HAM_HANDLED
	}
	return HAM_HANDLED
}

public fw_Item_PostFrame(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(get_user_weapon(id) != CSW_CANNONEX || !g_had_cannonex[id])
		return HAM_IGNORED

	new iButton = pev(id,pev_button)

	if(get_pdata_float(ent, 48, 4) <= 0.25 && g_mode[id])
	{
		set_weapon_anim(id, 1)
		set_pdata_float(ent, 48, 3.03, 4)
	}
	
	CannonEX_Configs(id, ent, iButton)
	return HAM_IGNORED
}

public CannonEX_Configs(id, ent, iButton)
{
	new Float:fReset; pev(ent, pev_fuser2, fReset)
	new iCheck = pev(ent, pev_iuser1)
	
	if(g_change[id] && g_hold[id] < get_gametime())
	{
		g_mode[id] = 1
		g_change[id] = 0
		
		if((iButton & IN_ATTACK) && iCheck == 1)
		{
			new Float:origin[3], Float:angles[3];
			engfunc(EngFunc_GetBonePosition, id, 8, origin, angles);
			origin[2] += 50.0
			
			new pEnt2 = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
			
			dllfunc(DLLFunc_Spawn, pEnt2)
			set_pev(pEnt2, pev_classname, DRAGON_CLASSNAME);
			engfunc(EngFunc_SetModel, pEnt2, models_used[g_type[id]?17:8]);
			set_pev(pEnt2, pev_origin, origin);
			set_pev(pEnt2, pev_movetype, MOVETYPE_FOLLOW)		
			set_pev(pEnt2, pev_solid, SOLID_NOT);
			set_pev(pEnt2, pev_owner, id);
			set_pev(pEnt2, pev_gravity, 0.1);
			set_pev(pEnt2, pev_angles, angles);
			engfunc(EngFunc_SetSize, pEnt2, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
			set_pev(pEnt2, pev_frame, 0.0)
			set_pev(pEnt2, pev_animtime, get_gametime())
			set_pev(pEnt2, pev_framerate, 1.0)
			set_pev(pEnt2, pev_sequence, 1)
			set_pev(pEnt2, pev_ltime, get_gametime() + (g_type[id]?9.9:6.6))
			set_pev(pEnt2, pev_nextthink, get_gametime() + 0.1)
			
			set_pev(ent, pev_fuser1, get_gametime() + (g_type[id]?8.1:5.1))
		} else set_pev(ent, pev_fuser1, get_gametime() + 0.01)
		Cannonex_DragonEfx(id, 1)

		static Float:fOrigin[3]
		pev(id, pev_origin, fOrigin)
			
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, fOrigin[0])
		engfunc(EngFunc_WriteCoord, fOrigin[1])
		engfunc(EngFunc_WriteCoord, fOrigin[2])
		write_short(g_cache_ef_dragon[g_type[id]])
		write_byte(3)
		write_byte(30)
		write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND |TE_EXPLFLAG_NOPARTICLES)
		message_end()

		set_pev(id, pev_weaponmodel2, models_used[g_type[id]?12:3])
		
		// Effect End
		new iVictim = -1
		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, fOrigin, 180.0)) != 0)
		{
			if(!pev_valid(iVictim))
				continue
			if(id == iVictim)
				continue
			
			if(iVictim > 33)
			{
				if(!pev(iVictim,pev_takedamage))
					continue
				if(pev(iVictim,pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
					continue
				
				KnifeAttack(id, false, 180.0, 1000.0, 0.0)
			} else {
				if(!can_damage(id, iVictim))
					continue
				
				if(Stock_CheckAngle(id, iVictim) > floatcos(180.0, degrees) && Stock_Is_Direct(id, iVictim))
				{
					KnifeAttack(id, false, 180.0, 1000.0, 350.0)
					Stock_Buff(iVictim, 0, g_cache_flameburn[g_type[id]], 10)
				}
			}
		}
	}

	if(g_mode[id])
	{
		if(get_pdata_float(id, 83, 5) <= 0.0 && get_gametime() >= pev(ent, pev_fuser1))
			set_pev(ent, pev_iuser1, 2)

		if(pev(ent, pev_iuser2) && fReset < get_gametime())
		{
			g_mode[id] = 0
			set_weapon_anim(id, 8)
			set_pev(id, pev_weaponmodel2, models_used[g_type[id]?10:1])
	
			set_pdata_float(ent, 46, 2.5, 4)
			set_pdata_float(ent, 47, 2.5, 4)
			set_pdata_float(ent, 48, 2.51, 4)

			set_pev(ent, pev_iuser1, 0)
			set_pev(ent, pev_iuser2, 0)
		}
	}

	new iShoot = pev(ent, pev_iuser4)
	
	if((iButton & IN_ATTACK) && get_pdata_float(ent, 46, 4) <= 0.0)
	{
		if(!g_ammo[id])
			return

		static Float:fOrigin[3]
		Stock_Get_Postion(id, 10.0, 0.0, -10.0, fOrigin)
			
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, fOrigin[0])
		engfunc(EngFunc_WriteCoord, fOrigin[1])
		engfunc(EngFunc_WriteCoord, fOrigin[2])
		write_short(g_cache_smoke)
		write_byte(1)
		write_byte(20)
		write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND |TE_EXPLFLAG_NOPARTICLES)
		message_end()
		
		set_pdata_float(ent, 46, 3.33, 4)
		set_pdata_float(ent, 47, 3.33, 4)
		set_pdata_float(ent, 48, 3.35, 4)
		
		set_pev(ent, pev_iuser3, random(5) > 3)
		set_pev(ent, pev_iuser4, 1)
		
		g_ammo[id]--
		update_ammo(id, g_ammo[id])

		// Reset
		if(g_mode[id] && iCheck == 2)
		{
			set_pdata_float(ent, 46, 2.53, 4)
			set_pdata_float(ent, 47, 2.53, 4)
			set_pdata_float(ent, 48, 2.53, 4)

			set_pev(ent, pev_iuser2, 1)
			set_pev(ent, pev_fuser2, get_gametime() + 2.25)
		}
		
		if(iCheck) set_weapon_anim(id, iCheck == 2 ? 7 : 5)
		else set_weapon_anim(id, 4)
	}

	iButton &= ~IN_ATTACK
	set_pev(id, pev_button, iButton &~ IN_ATTACK)

	if(iButton & IN_ATTACK2)
	{
		if(g_mode[id] || get_pdata_float(ent, 46, 4) > 0.0)
			return

		set_weapon_anim(id, 6)

		set_pdata_float(ent, 46, 3.0, 4)
		set_pdata_float(ent, 47, 3.0, 4)
		set_pdata_float(ent, 48, 3.36, 4)
		set_pdata_float(id, 83, 3.0, 5)

		g_change[id] = 1
		g_hold[id] = get_gametime() + 3.0
		
		Cannonex_DragonEfx(id)
		set_pev(ent, pev_iuser1, 1)
	}
	
	if(iShoot == 1 || (iShoot == 2 && g_double[id] < get_gametime()))
	{
		set_pev(ent, pev_iuser4, 0)
		emit_sound(id, CHAN_WEAPON, cannon_sound[g_type[id]?(iCheck==2?7:6):(iCheck==2?1:0)], 1.0, ATTN_NORM, 0, random_num(95, 120))
		
		static Float:VirtualVec[3]
		VirtualVec[0] = random_float(-3.5, -7.0)
		VirtualVec[1] = random_float(3.0, -3.0)
		VirtualVec[2] = 0.0
		set_pev(id, pev_punchangle, VirtualVec)	
		
		// Effect
		new iEnt, Float:fSpeed = 240.0, Float:vStart[3], Float:iAngle[3], Float:vVelocity[3], Float:vPlrAngle[3]
		Stock_Get_Postion(id, 55.0, 2.0, 0.0, vStart)
		pev(id, pev_v_angle, vPlrAngle)
		vPlrAngle[1] -= 22.0
		
		for(new i = 0; i < 8; i++)
		{
			vPlrAngle[1] += random_float(0.5, 11.0)
			vPlrAngle[2] += random_float(1.0, 20.0)
	
			angle_vector(vPlrAngle, ANGLEVECTOR_FORWARD, vVelocity)
			xs_vec_mul_scalar(vVelocity, fSpeed, vVelocity)
			
			vStart[2] -= random_float(0.5, 1.5)
	
			iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
			set_pev(iEnt, pev_classname, CANNONFIRE_CLASSNAME)
			set_pev(iEnt, pev_origin, vStart)
			set_pev(iEnt, pev_rendermode, kRenderTransAdd)
			set_pev(iEnt, pev_renderamt, 254.0)
			set_pev(iEnt, pev_animtime, get_gametime())
			set_pev(iEnt, pev_frame, 0.0)
			set_pev(iEnt, pev_scale, 1.6)
			engfunc(EngFunc_SetModel, iEnt, models_used[g_type[id]?16:7])
			engfunc(EngFunc_SetSize, iEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
			dllfunc(DLLFunc_Spawn, iEnt)
			
			iAngle[0] = random_float(-180.0, 180.0)
			iAngle[1] = random_float(-180.0, 180.0)
			iAngle[2] -= random_num(1, 360)
			
			set_pev(iEnt, pev_angles, iAngle)
			set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
			set_pev(iEnt, pev_solid, SOLID_NOT)
			set_pev(iEnt, pev_velocity, vVelocity)
			set_pev(iEnt, pev_owner, id)
			set_pev(iEnt, pev_ltime, get_gametime() + 1.2)
			set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
		}
		
		// Effect End
		new iVictim = -1, Float:fRad = get_pcvar_float(cvar_radius)
		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vStart, fRad)) != 0)
		{
			if(!pev_valid(iVictim))
				continue
			if(id == iVictim)
				continue
			
			if(iVictim > 33)
			{
				if(!pev(iVictim,pev_takedamage))
					continue
				if(pev(iVictim,pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
					continue
				
				KnifeAttack(id, false, get_pcvar_float(cvar_radius), random_float(get_pcvar_float(cvar_dmgrandom_start), get_pcvar_float(cvar_dmgrandom_end)), 0.0)
			} else {
				if(!can_damage(id, iVictim))
					continue
				
				if(Stock_CheckAngle(id, iVictim) > floatcos(fRad, degrees) && Stock_Is_Direct(id, iVictim))
				{
					Stock_Buff(iVictim, 0, g_cache_flameburn[g_type[id]], 10)
					KnifeAttack(id, false, get_pcvar_float(cvar_radius), random_float(get_pcvar_float(cvar_dmgrandom_start), get_pcvar_float(cvar_dmgrandom_end)), 350.0)
				}
			}
		}
		
		if(pev(ent, pev_iuser3)) 
		{
			g_double[id] = get_gametime() + 0.15
			set_pev(ent, pev_iuser3, 0)
			set_pev(ent, pev_iuser4, 2)
		}
	}
}

stock Cannonex_DragonEfx(id, iExp = 0)
{
	new Float:origin[3];
	pev(id, pev_origin, origin)
	
	if(iExp) 
	{
		emit_sound(id, CHAN_VOICE, cannon_sound[3], 1.0, ATTN_NORM, 0, random_num(95, 120))
		origin[2] -= 2.0
	}

	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(iEnt, pev_classname, iExp ? CANNONEXP_CLASSNAME : DRAGONEFX_CLASSNAME)
	
	set_pev(iEnt, pev_origin, origin)
	set_pev(iEnt, pev_frame, 0.0)
	set_pev(iEnt, pev_animtime, get_gametime())
	set_pev(iEnt, pev_framerate, 1.0)
	set_pev(iEnt, pev_sequence, 1)
	engfunc(EngFunc_SetModel, iEnt, models_used[g_type[id]?(iExp?15:14):(iExp?6:5)])
	engfunc(EngFunc_SetSize, iEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	dllfunc(DLLFunc_Spawn, iEnt)
	set_pev(iEnt, pev_solid, SOLID_NOT)
	set_pev(iEnt, pev_owner, id)
	
	new Float:Velocity[3]
	Stock_GetSpeedVector(origin, origin, 1.0, Velocity);
	set_pev(iEnt, pev_velocity, Velocity);
	
	new Float:vecVAngle[3]
	pev(id, pev_angles, vecVAngle);
	
	if(!iExp) vecVAngle[0] = 0.0
	set_pev(iEnt, pev_angles, vecVAngle)
	
	if(!iExp) set_pev(iEnt, pev_ltime, get_gametime() + 3.36)
	set_pev(iEnt, pev_nextthink, get_gametime() + (iExp?0.3:0.01))
}

public fw_think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return

	new id = pev(iEnt, pev_owner)
		
	static szClassName[33]
	pev(iEnt, pev_classname, szClassName, charsmax(szClassName))
	
	if(equal(szClassName, CANNONFIRE_CLASSNAME))
	{
		static Float:fFrame, Float:fLtime
		pev(iEnt, pev_frame, fFrame)
		pev(iEnt, pev_ltime, fLtime)
		
		// Touch something
		fFrame += 1.0
		if(fFrame >= 22.00) 
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
			return
		}
		set_pev(iEnt, pev_frame, fFrame)
		
		if(fLtime < get_gametime())
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
			return
		}			
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
	} else if(equal(szClassName, DRAGONEFX_CLASSNAME))
	{
		set_pev(iEnt, pev_movetype, MOVETYPE_FLY)

		static Float:Origin[3], Float:KhanifahArdhy; 
		pev(id, pev_origin, Origin)
		pev(iEnt, pev_fuser3, KhanifahArdhy)

		Stock_Hook_Ent(iEnt, Origin, 500.0)
		
		if(pev(iEnt, pev_ltime) < get_gametime() || Pub_Check(id))
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
			return
		}

		if(KhanifahArdhy < get_gametime())
		{
			emit_sound(id, CHAN_ITEM, cannon_sound[2], 1.0, ATTN_NORM, 0, random_num(95, 120))
			set_pev(iEnt, pev_fuser3, get_gametime() + 1.03)
		}

		set_pev(iEnt, pev_velocity, Float:{1.0,1.0,1.0});
		set_pev(iEnt, pev_origin, Origin);
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
	} else if(equal(szClassName, DRAGON_CLASSNAME))
	{
		set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
		
		new Float:origin[3],Float:targetOri[3],Float:fOrigin[3], Float:vecAngle[3]
		pev(iEnt, pev_origin, fOrigin)
		pev(id, pev_origin, origin)
		pev(id, pev_v_angle, vecAngle);
		origin[2] += 50.0
		
		vecAngle[0] = 0.0;
		set_pev(iEnt, pev_v_angle, vecAngle);
		set_pev(iEnt, pev_angles, vecAngle);

		static Float:fSpeed
		fSpeed = floatmin(500.0, vector_distance(origin, fOrigin) * 9.0)
		Stock_Hook_Ent(iEnt, origin, fSpeed, 1)

		if(pev(iEnt, pev_ltime) < get_gametime() || Pub_Check(id) || get_user_weapon(id) != CSW_CANNONEX)
		{
			emit_sound(iEnt, CHAN_VOICE, cannon_sound[g_type[id]?9:5], 1.0, ATTN_NORM, 0, random_num(95, 120))
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}

		if(g_flame_delay[id][1] < get_gametime())
		{
			emit_sound(iEnt, CHAN_VOICE, cannon_sound[g_type[id]?8:4], 1.0, ATTN_NORM, 0, random_num(95, 120))
			g_flame_delay[id][1] = get_gametime() + 0.7
		}

		if(g_flame_delay[id][0] < get_gametime())
		{
			static Float:vAvel[3], Float:vAngle[3], Float:vVelocity[3],Float:fOrigin2[3], Float:vPlayerVelocity[3];
			Stock_Get_Postion(iEnt, 10.0, 0.0, 5.0, fOrigin2)
			pev(iEnt, pev_angles, vAngle)
			pev(iEnt, pev_velocity, vPlayerVelocity);
			
			new iFlame = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
			Stock_Get_Postion(iEnt, 200.0, 0.0, -100.0, targetOri)
			Stock_GetSpeedVector(fOrigin2, targetOri, 350.0, vVelocity);
			xs_vec_add(vVelocity, vPlayerVelocity, vVelocity);
			
			dllfunc(DLLFunc_Spawn, iFlame)
			set_pev(iFlame, pev_classname, DRAGONFIRE_CLASSNAME)
			set_pev(iFlame, pev_animtime, get_gametime())
			set_pev(iFlame, pev_framerate, 1.0)
			set_pev(iFlame ,pev_angles, vAngle)
			set_pev(iFlame, pev_movetype, MOVETYPE_FLY)		
			set_pev(iFlame, pev_frame, 1.0)
			set_pev(iFlame, pev_scale, 0.07)
			set_pev(iFlame, pev_rendermode, kRenderTransAdd)
			set_pev(iFlame, pev_renderamt, 100.0)
			engfunc(EngFunc_SetModel, iFlame, models_used[g_type[id]?16:7])
			engfunc(EngFunc_SetSize, iFlame, {0,0,0}, {0,0,0})
			set_pev(iFlame, pev_origin, fOrigin2)
			
			vAvel[2] = random_float(-200.0, 200.0)
			set_pev(iFlame, pev_avelocity, vAvel)
			set_pev(iFlame, pev_velocity, vVelocity)
			set_pev(iFlame, pev_solid, SOLID_TRIGGER)
			set_pev(iFlame, pev_owner, id)
			set_pev(iFlame, pev_nextthink, get_gametime() + 0.05)
			g_flame_delay[id][0] = get_gametime() + 0.05
		}

		set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
	} else if(equal(szClassName, CANNONEXP_CLASSNAME))
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)

	else if(equal(szClassName, DRAGONFIRE_CLASSNAME))
	{
		static iEnemy; iEnemy = pev(iEnt, pev_enemy)
		if(iEnemy && pev_valid(iEnemy))
		{
			if(g_flame_delay[id][2] < get_gametime())
			{
				Stock_Buff(iEnemy, 30, g_cache_flameburn[g_type[id]], 5)
				g_flame_delay[id][2] = get_gametime() + 1.0
			}
		}

		static Float:fSprFrame, Float:fFrameMax;
		fSprFrame = 22.0
		fFrameMax = g_cache_frame_flame;
		
		static Float:fFrame, Float:fScale;
		pev(iEnt, pev_frame, fFrame)
		pev(iEnt, pev_scale, fScale)
		
		//Touch something
		if(get_pdata_int(iEnt, 21, 4))
		{
			set_pev(iEnt, pev_velocity, {0.0, 0.0, 0.0})
			fFrame += (fFrameMax / fSprFrame)
			fScale += (fFrameMax / (fSprFrame * 10))
		} else { //not touch
			if(fFrame > (fFrameMax/3.0))
			{
				fFrame += (fFrameMax / fSprFrame)
				fScale += (fFrameMax / (fSprFrame * 5))
			} else {
				fFrame += (fFrameMax / (fSprFrame * 2))
				fScale += (fFrameMax / (fSprFrame * 8))
			}
		}
		
		if(fFrame >= fFrameMax) 
		{
			set_pev(iEnt, pev_enemy, 0)
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
			return
		}
		
		set_pev(iEnt, pev_frame, fFrame)
		set_pev(iEnt, pev_scale, fScale)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
		return
	}
}

public fw_Touch(iPtr, iPtd)
{
	if(!pev_valid(iPtr))
		return HAM_IGNORED
		
	static Classname[32]
	pev(iPtr, pev_classname, Classname, 31)
	
	new iOwner = pev(iPtr, pev_owner)
	if(equal(Classname, DRAGONFIRE_CLASSNAME))
	{
		if(iOwner == iPtd)
			return HAM_IGNORED
			
		set_pdata_int(iPtr, 21, 1, 4)

		if(iOwner != iPtd) set_pev(iPtr, pev_solid, SOLID_NOT)
		KnifeAttack(iOwner, false, 1999.0, get_pcvar_float(cvar_flame_dmg), 1.0)
		
		if(pev_valid(iPtd) && can_damage(iOwner, iPtd)) 
			set_pev(iPtr, pev_enemy, iPtd)
	}
	return HAM_IGNORED
}

stock Pub_Check(id) return (!is_user_alive(id) || !is_user_connected(id))

stock set_weapon_anim(player, anim)
{
	set_pev(player, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}

public set_weapon_list(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(g_had_cannonex[id] ? "weapon_cannonex" : weapon_cannonex)    // WeaponName
	write_byte(3)                  // PrimaryAmmoID
	write_byte(200)                  // PrimaryAmmoMaxAmount
	write_byte(-1)                   // SecondaryAmmoID
	write_byte(-1)                   // SecondaryAmmoMaxAmount
	write_byte(0)                    // SlotID (0...N)
	write_byte(4)                    // NumberInSlot (1...N)
	write_byte(CSW_CANNONEX)            // WeaponID
	write_byte(0)                   // Flags
	message_end()
}
////////////
stock Stock_GetSpeedVector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed * speed / (new_velocity[0] * new_velocity[0] + new_velocity[1] * new_velocity[1] + new_velocity[2] * new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}
////////////
stock Stock_Drop_Slot(id, iSlot) 
{
	new weapons[32], num = 0
	get_user_weapons(id, weapons, num)
	
	for(new i = 0; i < num; i++)
	{
		new slot = Stock_Get_Wpn_Slot(weapons[i])

		if(iSlot == slot)
		{
			static wname[32]
			get_weaponname(weapons[i], wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock Stock_Get_Wpn_Slot(iWpn)
{
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

	if(PRIMARY_WEAPONS_BIT_SUM & (1<<iWpn)) return 1
	else if(SECONDARY_WEAPONS_BIT_SUM & (1<<iWpn)) return 2
	else if(iWpn == CSW_KNIFE) return 3
	else if(iWpn == CSW_HEGRENADE) return 4
	else if(iWpn == CSW_C4) return 5
	return 6 //FLASHBANG SMOKEBANG
}
/////////
stock Stock_Get_Postion(id, Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp)
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_AngleVectors, vAngle, vForward, vRight, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
////////
stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}
//////
stock Float:Stock_CheckAngle(id,iTarget)
{
	new Float:vOricross[2],Float:fRad,Float:vId_ori[3],Float:vTar_ori[3],Float:vId_ang[3],Float:fLength,Float:vForward[3]
	pev(id, pev_origin, vId_ori)
	pev(iTarget, pev_origin, vTar_ori)
	pev(id, pev_angles, vId_ang)
	
	for(new i = 0; i < 2; i++) vOricross[i] = vTar_ori[i] - vId_ori[i]
	fLength = floatsqroot(vOricross[0] * vOricross[0] + vOricross[1] * vOricross[1])
	
	if(fLength <= 0.0)
	{
		vOricross[0] = 0.0
		vOricross[1] = 0.0
	} else {
		vOricross[0] = vOricross[0] * (1.0 / fLength)
		vOricross[1] = vOricross[1] * (1.0 / fLength)
	}
	engfunc(EngFunc_MakeVectors, vId_ang)
	global_get(glb_v_forward, vForward)
	
	fRad = vOricross[0] * vForward[0] + vOricross[1] * vForward[1]
	return fRad
}

stock Stock_Is_Direct(id, id2)
{
	new Float:v1[3],Float:v2[3], Float:hit_origin[3], tr
	pev(id, pev_origin, v1)
	pev(id2, pev_origin, v2)
	
	engfunc(EngFunc_TraceLine, v1, v2, 1, -1, tr)
	get_tr2(tr, TR_vecEndPos, hit_origin)

	if(!vector_distance(hit_origin, v2))
		return 1
	return 0
}
///////////
stock Stock_Fake_KnockBack(id,iVic,Float:iKb)
{
	if(iVic > 32) return
	if(!can_damage(id, iVic)) return

	new Float:vAttacker[3], Float:vVictim[3], Float:vVelocity[3], flags
	pev(id, pev_origin, vAttacker)
	pev(iVic, pev_origin, vVictim)
	vAttacker[2] = vVictim[2] = 0.0
	flags=pev(id, pev_flags)
	
	xs_vec_sub(vVictim, vAttacker, vVictim)
	new Float:fDistance
	fDistance = xs_vec_len(vVictim)
	xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
	pev(iVic, pev_velocity, vVelocity)
	xs_vec_mul_scalar(vVictim, iKb, vVictim)
	xs_vec_mul_scalar(vVictim, 1.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15

	if(flags &~FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.5, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_pev(iVic, pev_velocity, vVictim)
}
///////
stock Stock_Buff(id, damage, spr, scale)
{
	if(id < 33 && pev_valid(id))
	{
		static Float:vOri[3]
		pev(id, pev_origin, vOri)
		
		if(is_user_alive(id))
		{
			ExecuteHamB(Ham_TakeDamage, id, 0, id, damage, DMG_BURN)
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_SPRITE)
			engfunc(EngFunc_WriteCoord, vOri[0])
			engfunc(EngFunc_WriteCoord, vOri[1])
			engfunc(EngFunc_WriteCoord, vOri[2])
			write_short(spr)
			write_byte(scale)
			write_byte(255)
			message_end()
		}
	}
}
///////
stock KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bitsDamageType = DMG_NEVERGIB | DMG_CLUB)
{
	new Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	GetGunPosition(id, vecSrc);

	pev(id, pev_v_angle, v_angle);
	engfunc(EngFunc_MakeVectors, v_angle);

	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, flRange, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);

	new Float:flFraction; get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);
	
	get_tr2(tr, TR_flFraction, flFraction);

	new iHitResult = RESULT_HIT_NONE;
	
	if (flFraction < 1.0)
	{
		new pEntity = get_tr2(tr, TR_pHit);
		iHitResult = RESULT_HIT_WORLD;
		
		if (pev_valid(pEntity) && (IsPlayer(pEntity) || IsHostage(pEntity)))
		{
			if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
				flDamage *= 1.0;

			iHitResult = RESULT_HIT_PLAYER;
		}

		if (pev_valid(pEntity) && get_tr2(tr, TR_pHit) == pEntity && !(pev(pEntity, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
		{
			engfunc(EngFunc_MakeVectors, v_angle);
			global_get(glb_v_forward, vecForward);

			if (iHitgroup != -1)
				set_tr2(tr, TR_iHitgroup, iHitgroup);

			ExecuteHamB(Ham_TraceAttack, pEntity, id, 20.0, vecForward, tr, bitsDamageType);
			ExecuteHamB(Ham_TakeDamage, pEntity, id, id, flDamage, bitsDamageType)
			Stock_Fake_KnockBack(id, pEntity, flKnockBack)
			
			if (IsAlive(pEntity))
			{
				free_tr2(tr);
				return iHitResult;
			}
		}
	}
	free_tr2(tr);
	return iHitResult;
}

stock IsPlayer(pEntity) return is_user_connected(pEntity)

stock IsHostage(pEntity)
{
	new classname[32]; pev(pEntity, pev_classname, classname, charsmax(classname))
	return equal(classname, "hostage_entity")
}

stock IsAlive(pEntity)
{
	if (pEntity < 1) return 0
	return (pev(pEntity, pev_deadflag) == DEAD_NO && pev(pEntity, pev_health) > 0)
}

stock CheckBack(iEnemy,id)
{
	new Float:anglea[3], Float:anglev[3]
	pev(iEnemy, pev_v_angle, anglea)
	pev(id, pev_v_angle, anglev)
	new Float:angle = anglea[1] - anglev[1] 
	if (angle < -180.0) angle += 360.0
	if (angle <= 45.0 && angle >= -45.0) return 1
	return 0
}

///////
stock Stock_Hook_Ent(ent, Float:TargetOrigin[3], Float:Speed, mode=0)
{
	static Float:fl_Velocity[3],Float:EntOrigin[3],Float:distance_f,Float:fl_Time
	pev(ent, pev_origin, EntOrigin)
	
	if(!mode)
	{
		distance_f = get_distance_f(EntOrigin, TargetOrigin)
		fl_Time = distance_f / Speed
			
		pev(ent, pev_velocity, fl_Velocity)
			
		fl_Velocity[0] = (TargetOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (TargetOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (TargetOrigin[2] - EntOrigin[2]) / fl_Time

		if(vector_length(fl_Velocity) > 1.0) set_pev(ent, pev_velocity, fl_Velocity)
		else set_pev(ent, pev_velocity, Float:{0.01, 0.01, 0.01})
	} else {
		static Float:fl_EntVelocity[3], Float:fl_Acc[3]
		Stock_Directed_Vector(TargetOrigin, EntOrigin, fl_Velocity)
		xs_vec_mul_scalar(fl_Velocity, Speed, fl_Velocity)
		
		for(new i =0; i<3; i++)
		{
			if(fl_Velocity[i] > fl_EntVelocity[i]) 
			{
				fl_Acc[i] = fl_Velocity[i]-fl_EntVelocity[i]
				fl_Acc[i] = floatmin(70.0, fl_Acc[i])
				fl_EntVelocity[i] += fl_Acc[i]
			}
			else if(fl_Velocity[i] < fl_EntVelocity[i])
			{
				fl_Acc[i] = fl_EntVelocity[i]-fl_Velocity[i]
				fl_Acc[i] = floatmin(70.0, fl_Acc[i])
				fl_EntVelocity[i] -= fl_Acc[i]
			}
		}
		set_pev(ent, pev_velocity, fl_EntVelocity)
	}
}

stock Stock_Directed_Vector(Float:start[3],Float:end[3],Float:reOri[3])
{	
	new Float:v3[3]
	v3[0]=start[0]-end[0]
	v3[1]=start[1]-end[1]
	v3[2]=start[2]-end[2]
	new Float:vl = vector_length(v3)
	reOri[0] = v3[0] / vl
	reOri[1] = v3[1] / vl
	reOri[2] = v3[2] / vl
}
stock GetGunPosition(id, Float:vecSrc[3])
{
	new Float:vecViewOfs[3];
	pev(id, pev_origin, vecSrc);
	pev(id, pev_view_ofs, vecViewOfs);
	xs_vec_add(vecSrc, vecViewOfs, vecSrc);
}
