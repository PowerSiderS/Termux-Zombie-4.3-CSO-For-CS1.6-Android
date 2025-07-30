#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "Weapon DEL"
#define VERSION "1.1"
#define AUTHOR "VaMp1r41K"

#define V_MODEL "models/v_delfx_z.mdl"
#define P_MODEL "models/q_del.mdl"
#define W_MODEL "models/q_del.mdl"
#define HUD_KILL "delfx_z"
#define HUD_HOOK "weapon_delfx_z.mdl"

#define CSW_BASEDON CSW_USP
#define weapon_basedon "weapon_usp"

const Float: WEAPON_DRAW_DISTANCE = 100.0;
const Float: WEAPON_DRAW_DAMAGE = 150.0;
const Float: WEAPON_DRAW_KNOCKBACK = 150.0;

const Float: WEAPON_SKILL_DISTANCE = 100.0;
const Float: WEAPON_SKILL_DAMAGE = 350.0;
const Float: WEAPON_SKILL_KNOCKBACK = 200.0;


const Float: DAMAGE = 70.0
const Float: DISTANCE = 8192.0
#define CLIP 12
#define BPAMMO 180
#define SPEED 1.0
#define RECOIL 1.0
#define RELOAD_TIME 25/35.0
#define SKILL_TIME 19/35.0
new Float:EntitySecondaryFireRate = 1.2; // Темп стрельбы 2 режима
new Float:EntityFireRate = 0.2; // Темп стрельбы 1 режима

#define SHOOT_ANIM 1
#define DRAW_ANIM 3
#define RELOAD_ANIM 2
#define AMIM_SKILL 4

#define COMMAND_GET "give_del"

#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47

#define m_pNext 42
#define m_iId 43
#define linux_diff_weapon 4
#define linux_diff_player 5
#define m_LastHitGroup 75
#define m_flPainShock 108
#define m_iPlayerTeam 114
#define m_rpgPlayerItems 367

#define WEAPON_SECRETCODE 156851
#define WEAPON_EVENT "events/usp.sc"
#define OLD_W_MODEL "models/w_usp.mdl"
#define FIRE_SOUND "weapons/charger5-1.wav"

new g_Had_Weapon, g_Old_Weapon[33], Float:g_Recoil[33][3], g_Clip[33]
new g_weapon_event, g_ShellId, g_SmokePuff_SprId
new g_HamBot, g_Msg_CurWeapon
new g_Item;

/* ~ [ TraceLine: Attack Angles ] ~ */
new Float: flAngles_Forward[] =
{ 
	0.0, 
	2.5, -2.5, 5.0, -5.0, 7.5, -7.5, 10.0, -10.0, 12.5, -12.5, 
	15.0, -15.0, 17.5, -17.5, 20.0, -20.0, 22.5, -22.5, 25.0, -25.0
};

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new gl_iszModelIndex_BloodSpray,
	gl_iszModelIndex_BloodDrop

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")	
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_basedon, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_basedon, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack,	weapon_basedon,	"Ham_Weapon_SecondaryAttack_Pre", 1);
	RegisterHam(Ham_Item_AddToPlayer, weapon_basedon, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_basedon, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_basedon, "fw_Weapon_Reload_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_basedon, "fw_Item_PostFrame")		
	
	g_Msg_CurWeapon = get_user_msgid("CurWeapon")
	register_clcmd(COMMAND_GET, "Get_Weapon")
	register_clcmd(HUD_HOOK, "hook_weapon")
	g_Item = zp_register_extra_item("Del", 40, ZP_TEAM_HUMAN)
}
public hook_weapon(id) engclient_cmd(id, weapon_basedon)
public message_DeathMsg()
{
	// get value data
	static killer, weapon[32], weaponid
	killer = get_msg_arg_int(1)
	get_msg_arg_string(4, weapon, charsmax(weapon))
	format(weapon, charsmax(weapon), "weapon_%s", weapon)
	weaponid = get_weaponid(weapon)	
	
	
	if (Get_BitVar(g_Had_Weapon,killer) && weaponid==CSW_BASEDON)
	{
		// get sprites weapon
		new sprites_wpn[32]
		format(sprites_wpn, charsmax(sprites_wpn), "%s", HUD_KILL)
		
		// send deathmsg
		set_msg_arg_string(4, sprites_wpn)
		return PLUGIN_CONTINUE
	}
		
	return PLUGIN_CONTINUE
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	engfunc(EngFunc_PrecacheSound, FIRE_SOUND)
	
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	g_ShellId = engfunc(EngFunc_PrecacheModel, "models/rshell.mdl")	
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	// Model Index
	gl_iszModelIndex_BloodSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
	gl_iszModelIndex_BloodDrop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");

}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name))
		g_weapon_event = get_orig_retval()		
}

public client_putinserver(id)
{
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_RegisterHam", id)
	}
}

public Do_RegisterHam(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player")	
}

public zp_extra_item_selected(iPlayer, iItemID)
{
	if(iItemID == g_Item)
		Get_Weapon(iPlayer);
}

public Get_Weapon(id)
{
	if(!is_user_alive(id))
		return
	
	UTIL_DropWeapon(id, 2);
	Set_BitVar(g_Had_Weapon, id)
	fm_give_item(id, weapon_basedon)	
	
	// Set Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_BASEDON)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, CLIP)
	
	cs_set_user_bpammo(id, CSW_BASEDON,BPAMMO)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, g_Msg_CurWeapon, {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_BASEDON)
	write_byte(CLIP)
	message_end()	
}

public Remove_Weapon(id)
{
	UnSet_BitVar(g_Had_Weapon, id)
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_BASEDON && g_Old_Weapon[id] != CSW_BASEDON) && Get_BitVar(g_Had_Weapon, id))
	{
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, "")
		
		UTIL_FakeTraceLine(id, WEAPON_DRAW_DISTANCE, WEAPON_DRAW_DAMAGE, WEAPON_DRAW_KNOCKBACK, flAngles_Forward, 10, true);
		set_weapon_anim(id, DRAW_ANIM)
		Draw_NewWeapon(id, CSWID)
	} 
	else if((CSWID == CSW_BASEDON && g_Old_Weapon[id] == CSW_BASEDON) && Get_BitVar(g_Had_Weapon, id)) 
	{
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_BASEDON)
		if(!pev_valid(Ent))
		{
			g_Old_Weapon[id] = get_user_weapon(id)
			return
		}
		
		set_pdata_float(Ent, 46, get_pdata_float(Ent, 46, 4) * SPEED, 4)
	} 
	else if(CSWID != CSW_BASEDON && g_Old_Weapon[id] == CSW_BASEDON) Draw_NewWeapon(id, CSWID)
	
	g_Old_Weapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_BASEDON)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_BASEDON)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_Weapon, id))
		{
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
			engfunc(EngFunc_SetModel, ent, P_MODEL)	
			
		}
	} else {
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_BASEDON)
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 			
	}
	
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_BASEDON && Get_BitVar(g_Had_Weapon, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, invoker))
		return FMRES_IGNORED
	if(eventid != g_weapon_event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	set_weapon_anim(invoker, SHOOT_ANIM)
	emit_sound(invoker, CHAN_WEAPON, FIRE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	Eject_Shell(invoker, g_ShellId, 0.0)
		
	return FMRES_SUPERCEDE
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon; weapon = fm_find_ent_by_owner(-1, weapon_basedon, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Weapon, iOwner))
		{
			Remove_Weapon(iOwner)
			
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)		
	
	Make_BulletHole(Attacker, flEnd, Damage)
	Make_BulletSmoke(Attacker, Ptr)

	SetHamParamFloat( 3, DAMAGE );
	
	return HAM_IGNORED
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, Attacker))
		return HAM_IGNORED
		
	SetHamParamFloat( 3, DAMAGE );

	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack(Ent)
{
	static id; id = pev(Ent, pev_owner)
	pev(id, pev_punchangle, g_Recoil[id])
	
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	static id; id = pev(Ent, pev_owner)
	
	if(Get_BitVar(g_Had_Weapon, id))
	{
		static Float:Push[3]
		pev(id, pev_punchangle, Push)
		xs_vec_sub(Push, g_Recoil[id], Push)
		
		xs_vec_mul_scalar(Push, RECOIL, Push)
		xs_vec_add(Push, g_Recoil[id], Push)
		set_pev(id, pev_punchangle, Push)
	}
}

public Ham_Weapon_SecondaryAttack_Pre(const item)
{
	new id = pev(item, pev_owner)
	if(Get_BitVar(g_Had_Weapon, id))
	{
		set_weapon_anim(id, AMIM_SKILL)
	//	emit_sound(id, CHAN_WEAPON, FIRE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_FakeTraceLine(id, WEAPON_SKILL_DISTANCE, WEAPON_SKILL_DAMAGE, WEAPON_SKILL_KNOCKBACK, flAngles_Forward, 10, true);
		set_pdata_float(id, 83, SKILL_TIME, 5)
		
		set_pdata_float(item, m_flNextPrimaryAttack, EntityFireRate, linux_diff_weapon);
		set_pdata_float(item, m_flNextSecondaryAttack, EntitySecondaryFireRate, linux_diff_weapon);
//		set_member(item, m_Weapon_flNextPrimaryAttack, EntityFireRate);
//		set_member(item, m_Weapon_flNextSecondaryAttack, EntityFireRate);
	}
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		Set_BitVar(g_Had_Weapon, id)
		set_pev(ent, pev_impulse, 0)
	}		

	return HAM_HANDLED	
}

public fw_Item_PostFrame(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(is_user_alive(id) && Get_BitVar(g_Had_Weapon, id))
	{	
		static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
		static bpammo; bpammo = cs_get_user_bpammo(id, CSW_BASEDON)
		static iClip; iClip = get_pdata_int(ent, 51, 4)
		static fInReload; fInReload = get_pdata_int(ent, 54, 4)
		
		if(fInReload && flNextAttack <= 0.0)
		{
			static temp1; temp1 = min(CLIP - iClip, bpammo)

			set_pdata_int(ent, 51, iClip + temp1, 4)
			cs_set_user_bpammo(id, CSW_BASEDON, bpammo - temp1)		
			
			set_pdata_int(ent, 54, 0, 4)
			
			fInReload = 0
		}		
	}
	
	return HAM_IGNORED	
}

public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Weapon, id))
		return HAM_IGNORED
	
	g_Clip[id] = -1
	
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_BASEDON)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	
	if(bpammo <= 0) return HAM_SUPERCEDE
	
	if(iClip >= CLIP) return HAM_SUPERCEDE		
		
	g_Clip[id] = iClip

	return HAM_HANDLED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Weapon, id))
		return HAM_IGNORED

	if (g_Clip[id] == -1)
		return HAM_IGNORED
	
	set_pdata_int(ent, 51, g_Clip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	
	set_weapon_anim(id, RELOAD_ANIM)
	set_pdata_float(id, 83, RELOAD_TIME, 5)

	return HAM_HANDLED
}

stock UTIL_FakeTraceLine(iPlayer, Float: flDistance, Float: flDamage, Float: flKnockBack, Float: flSendAngles[], iSendAngles, bool: bDoDamage)
{
	enum
	{
		SLASH_HIT_NONE = 0,
		SLASH_HIT_WORLD,
		SLASH_HIT_ENTITY
	};

	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);

	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);

	new Float: vecForward[3], Float: vecRight[3], Float: vecUp[3];
	engfunc(EngFunc_AngleVectors, vecAngles, vecForward, vecRight, vecUp);
		
	new iTrace = create_tr2();

	new Float: flTan, Float: flMul;
	new iHitList[10], iHitCount = 0;

//	new bool: bSpriteCreated = false;
	new Float: vecEnd[3];
	new Float: flFraction;
	new pHit, pHitEntity = SLASH_HIT_NONE;
	new iHitResult = SLASH_HIT_NONE;

	for(new i; i < iSendAngles; i++)
	{
		flTan = floattan(flSendAngles[i], degrees);

		vecEnd[0] = (vecForward[0] * flDistance) + (vecRight[0] * flTan * flDistance) + vecUp[0];
		vecEnd[1] = (vecForward[1] * flDistance) + (vecRight[1] * flTan * flDistance) + vecUp[1];
		vecEnd[2] = (vecForward[2] * flDistance) + (vecRight[2] * flTan * flDistance) + vecUp[2];
			
		flMul = (flDistance/vector_length(vecEnd));
		xs_vec_mul_scalar(vecEnd, flMul, vecEnd);
		xs_vec_add(vecEnd, vecOrigin, vecEnd);

		engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
		get_tr2(iTrace, TR_flFraction, flFraction);

		if(flFraction == 1.0)
		{
			engfunc(EngFunc_TraceHull, vecOrigin, vecEnd, HULL_HEAD, iPlayer, iTrace);
			get_tr2(iTrace, TR_flFraction, flFraction);
		
			engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
			pHit = get_tr2(iTrace, TR_pHit);
		}
		else pHit = get_tr2(iTrace, TR_pHit);

		if(pHit == iPlayer) continue;

		static bool: bStop; bStop = false;
		for(new iHit = 0; iHit < iHitCount; iHit++)
		{
			if(iHitList[iHit] == pHit)
			{
				bStop = true;
				break;
			}
		}
		if(bStop == true) continue;

		iHitList[iHitCount] = pHit;
		iHitCount++;

		if(flFraction != 1.0)
			if(!iHitResult) iHitResult = SLASH_HIT_WORLD;

		static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);
		if(pHit > 0 && pHitEntity != pHit)
		{
			if(bDoDamage)
			{
				if(pev(pHit, pev_solid) == SOLID_BSP && !(pev(pHit, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
				{
					ExecuteHamB(Ham_TakeDamage, pHit, iPlayer, iPlayer, flDamage, DMG_NEVERGIB|DMG_CLUB);
				}
				else
				{
					UTIL_FakeTraceAttack(pHit, iPlayer, flDamage, vecForward, iTrace, DMG_NEVERGIB|DMG_CLUB);
					if(flKnockBack > 0.0) UTIL_FakeKnockBack(pHit, vecForward, flKnockBack);
				}
			}

			iHitResult = SLASH_HIT_ENTITY;
			pHitEntity = pHit;
		}
	}

	free_tr2(iTrace);

/*	static iSound; iSound = -1;
	switch(iHitResult)
	{
		case SLASH_HIT_WORLD: iSound = random_num(8, 9);
		case SLASH_HIT_ENTITY: iSound = random_num(6, 7);
	}

//	if(bDoDamage && iSound != -1)
//		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[iSound], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
*/
	return iHitResult == SLASH_HIT_NONE ? false : true;
}

stock UTIL_FakeTraceAttack(iVictim, iAttacker, Float: flDamage, Float: vecDirection[3], iTrace, ibitsDamageBits)
{
	static Float: flTakeDamage; pev(iVictim, pev_takedamage, flTakeDamage);

	if(flTakeDamage == DAMAGE_NO) return 0; 
	if(!(is_user_alive(iVictim))) return 0;

	if(is_user_connected(iVictim)) 
	{
		if(get_pdata_int(iVictim, m_iPlayerTeam, linux_diff_player) == get_pdata_int(iAttacker, m_iPlayerTeam, linux_diff_player)) 
			return 0;
	}

	static iHitgroup; iHitgroup = get_tr2(iTrace, TR_iHitgroup);
	static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	static iBloodColor; iBloodColor = ExecuteHamB(Ham_BloodColor, iVictim);
	
	if(is_user_alive(iVictim))
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

stock UTIL_FakeKnockBack(iVictim, Float: vecDirection[3], Float: flKnockBack) 
{
	if(!(is_user_alive(iVictim))) return 0;
	if(!zp_get_user_zombie(iVictim)) return 0;

	set_pdata_float(iVictim, m_flPainShock, 1.0, linux_diff_player);

	static Float: vecVelocity[3]; pev(iVictim, pev_velocity, vecVelocity);
	if(pev(iVictim, pev_flags) & FL_DUCKING) flKnockBack *= 0.7;

	vecVelocity[0] = vecDirection[0] * flKnockBack;
	vecVelocity[1] = vecDirection[1] * flKnockBack;
	vecVelocity[2] = 200.0;

	set_pev(iVictim, pev_velocity, vecVelocity);
	
	return 1;
}

public UTIL_BloodDrips(Float: vecOrigin[3], iColor, iAmount)
{
	if(iAmount > 255) iAmount = 255;
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(gl_iszModelIndex_BloodSpray);
	write_short(gl_iszModelIndex_BloodDrop);
	write_byte(iColor);
	write_byte(min(max(3, iAmount / 10), 16));
	message_end();
}


stock Make_BulletHole(id, Float:Origin[3], Float:Damage)
{
	// Find target
	static Decal; Decal = random_num(41, 45)
	static LoopTime; 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0; i < LoopTime; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(Decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(Decal)
		message_end()
	}
}

public Make_BulletSmoke(id, TrResult)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(TrResult, TR_vecEndPos, vecSrc)
	get_tr2(TrResult, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_SmokePuff_SprId)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}


stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, Float:multi, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	static Float:EntVelocity[3]
	
	pev(ent, pev_velocity, EntVelocity)
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	static Float:fl_Time; fl_Time = distance_f / speed
	static Float:fl_Time2; fl_Time2 = distance_f / (speed * multi)
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time2) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time2) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time2) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time2) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}

	xs_vec_add(EntVelocity, fl_Velocity, fl_Velocity)
	set_pev(ent, pev_velocity, fl_Velocity)
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	static Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	static Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	static Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	static Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

stock Eject_Shell(id, Shell_ModelIndex, Float:Time) // By Dias
{
	static Ent; Ent = get_pdata_cbase(id, 373, 5)
	if(!pev_valid(Ent))
		return

        set_pdata_int(Ent, 57, Shell_ModelIndex, 4)
        set_pdata_float(id, 111, get_gametime() + Time)
}
/* -> Weapon Animation <- */
stock UTIL_SendWeaponAnim(const iDest, const pReceiver, const item, const iAnim) 
{
	static iBody; iBody = get_entvar(item, var_body);
	set_entvar(pReceiver, var_weaponanim, iAnim);

	message_begin(iDest, SVC_WEAPONANIM, .player = pReceiver);
	write_byte(iAnim);
	write_byte(iBody);
	message_end();

	if (get_entvar(pReceiver, var_iuser1))
		return;

	static i, iCount, pSpectator, aSpectators[MAX_PLAYERS];
	get_players(aSpectators, iCount, "bch");

	for (i = 0; i < iCount; i++)
	{
		pSpectator = aSpectators[i];

		if (get_entvar(pSpectator, var_iuser1) != OBS_IN_EYE)
			continue;

		if (get_entvar(pSpectator, var_iuser2) != pReceiver)
			continue;

		set_entvar(pSpectator, var_weaponanim, iAnim);

		message_begin(iDest, SVC_WEAPONANIM, .player = pSpectator);
		write_byte(iAnim);
		write_byte(iBody);
		message_end();
	}
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

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}
