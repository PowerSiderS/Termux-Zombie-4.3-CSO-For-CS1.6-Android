#include < amxmodx >
#include < fakemeta_util >
#include < hamsandwich >

//#define ZP_SUPPORT // Поддержка Zombie Plague 4.3

#if defined ZP_SUPPORT
	#include < zombieplague >
#endif

#define linux_diff_weapon		4
#define linux_diff_player		5

// CBasePlayerItem
#define m_pPlayer				41

#define MAX_CLIENTS				32
#define NADE_TYPE				1337

#define FLAME_CLASSNAME			"ent_flame" // Класснейм огня
#define FLAME_DURATION			5.0 // Сколько будет идти горение
#define FLAME_TIMERESET			0.2 // Через сколько будет наносится урон

// Урон от огня
#if defined ZP_SUPPORT
#define FLAME_DAMAGE			random_float(30.0, 50.0)
#else
#define FLAME_DAMAGE			random_float(3.0, 5.0)
#endif

#define GRENADE_VIEW_MODEL		"models/x/v_molotov.mdl"
#define GRENADE_PLAYER_MODEL	"models/x/p_molotov.mdl"
#define GRENADE_WORLD_MODEL		"models/x/w_molotov.mdl"
#define GRENADE_MODEL_BODY		0

#define GRENADE_EXPLODE_SOUND	"x/molotov_exp.wav"

#if defined ZP_SUPPORT
new g_iItemID;
#endif

new g_iThinkTimes[512];
new g_iszModelIndexSprite;
new g_iUserHasMolotov[MAX_CLIENTS + 1];

public plugin_init()
{
	register_plugin("[AMXX] Grenade: Molotov", "1.0", "xUnicorn (t3rkecorejz)");

	RegisterHam(Ham_Killed, "player", "CPlayer__Killed_Post", .Post = 1);
	RegisterHam(Ham_Think, "grenade", "CGrenade__Think_Pre", .Post = 0);
	RegisterHam(Ham_Think, "info_target", "CEntity__Think_Pre", .Post = 0);
	RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "CGrenade__Item_Deploy_Post", .Post = 1);

	register_forward(FM_SetModel, "FM_Hook_SetModel_Pre", ._post = 0);

	#if defined ZP_SUPPORT
	g_iItemID = zp_regiter_extra_item("Molotov", 10, ZP_TEAM_HUMAN);
	#else
	register_clcmd("say molotov", "Command_GiveMolotov");
	#endif
}

public plugin_precache()
{
	g_iszModelIndexSprite = engfunc(EngFunc_PrecacheModel, "sprites/x/flame.spr");

	engfunc(EngFunc_PrecacheModel, GRENADE_VIEW_MODEL);
	engfunc(EngFunc_PrecacheModel, GRENADE_PLAYER_MODEL);
	engfunc(EngFunc_PrecacheModel, GRENADE_WORLD_MODEL);

	engfunc(EngFunc_PrecacheSound, GRENADE_EXPLODE_SOUND);
}

public client_disconnect(iPlayer) g_iUserHasMolotov[iPlayer] = 0;

#if defined ZP_SUPPORT
public zp_extra_item_selected(iPlayer, iItemID)
{
	if(iItemID == g_iItemID)
		Command_GiveMolotov(iPlayer);
}
#endif

public Command_GiveMolotov(iPlayer)
{
	if(!is_user_alive(iPlayer))
		return PLUGIN_HANDLED;

	if(user_has_weapon(iPlayer, CSW_SMOKEGRENADE))
	{
		g_iUserHasMolotov[iPlayer]++;
		ExecuteHamB(Ham_GiveAmmo, iPlayer, 1, "SmokeGrenade", 32);
		emit_sound(iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}

	if(CPlayer__MakeWeapon(iPlayer)) 
	{
		g_iUserHasMolotov[iPlayer]++;
		emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
	#if defined ZP_SUPPORT
	else return ZP_PLUGIN_HANDLED;
	#else
	else return PLUGIN_HANDLED;
	#endif

	return PLUGIN_HANDLED;
}

public CPlayer__Killed_Post(iVictim) g_iUserHasMolotov[iVictim] = 0;
public CGrenade__Think_Pre(iEntity)
{
	if(!pev_valid(iEntity)) 
		return HAM_IGNORED;

	static Float: flDamageTime; pev(iEntity, pev_dmgtime, flDamageTime);
	
	if(flDamageTime > get_gametime())
		return HAM_IGNORED;

	if(pev(iEntity, pev_flTimeStepSound) == NADE_TYPE)
	{
		MolotovExplode(iEntity);
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public CEntity__Think_Pre(iEntity)
{
	if(!pev_valid(iEntity))
		return HAM_IGNORED;

	static iVictim = -1;

	new szClassName[32], vecOrigin[3], iOwner;
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(equal(szClassName, FLAME_CLASSNAME))
	{
		pev(iEntity, pev_origin, vecOrigin);
		iOwner = pev(iEntity, pev_owner);

		if(g_iThinkTimes[iEntity] == floatround(FLAME_DURATION / FLAME_TIMERESET))
		{
			set_pev(iEntity, pev_flags, FL_KILLME);

			return HAM_IGNORED;
		}

		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, 100.0)))
		{
			if(iOwner == iVictim || !is_user_alive(iVictim))
				continue;

			#if defined ZP_SUPPORT
			if(zp_get_user_zombie(iOwner) || !zp_get_user_zombie(iVictim))
				continue;
			#endif

			ExecuteHamB(Ham_TakeDamage, iVictim, iEntity, iOwner, FLAME_DAMAGE, DMG_BURN | DMG_NEVERGIB);
		}

		g_iThinkTimes[iEntity] += 1;
		set_pev(iEntity, pev_nextthink, get_gametime() + FLAME_TIMERESET);
	}

	return HAM_IGNORED;
}

public CGrenade__Item_Deploy_Post(iEntity)
{
	static iPlayer; iPlayer = get_pdata_cbase(iEntity, m_pPlayer, linux_diff_weapon);

	#if defined ZP_SUPPORT
	if(zp_get_user_zombie(iPlayer))
		return;
	#endif

	if(!g_iUserHasMolotov[iPlayer]) 
		return;

	set_pev(iPlayer, pev_viewmodel2, GRENADE_VIEW_MODEL);
	set_pev(iPlayer, pev_weaponmodel2, GRENADE_PLAYER_MODEL);
}

public FM_Hook_SetModel_Pre(iEntity, const szModel[])
{
	if(!pev_valid(iEntity)) 
		return FMRES_IGNORED;

	static iOwner; iOwner = pev(iEntity, pev_owner);

	if(equal(szModel, "models/w_smokegrenade.mdl"))
	{
		if(g_iUserHasMolotov[iOwner])
		{
			engfunc(EngFunc_SetModel, iEntity, GRENADE_WORLD_MODEL);

			set_pev(iEntity, pev_body, GRENADE_MODEL_BODY);
			set_pev(iEntity, pev_flTimeStepSound, NADE_TYPE);

			g_iUserHasMolotov[iOwner] -= 1;

			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public CPlayer__MakeWeapon(iPlayer)
{
	static iEntity, g_AllocString_E;

	if(g_AllocString_E || (g_AllocString_E = engfunc(EngFunc_AllocString, "weapon_smokegrenade")))
		iEntity = engfunc(EngFunc_CreateNamedEntity, g_AllocString_E);

	if(iEntity <= 0) 
		return 0;

	g_iUserHasMolotov[iPlayer]++;
	set_pev(iEntity, pev_spawnflags, SF_NORESPAWN);
	ExecuteHam(Ham_Spawn, iEntity);

	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iEntity)) 
	{
		set_pev(iEntity, pev_flags, FL_KILLME);
		return 0;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, iEntity, iPlayer);
	return iEntity;
}

MolotovExplode(iEntity)
{
	static Float: vecOrigin[3];
	pev(iEntity, pev_origin, vecOrigin);

	emit_sound(iEntity, CHAN_WEAPON, GRENADE_EXPLODE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	static iReference;

	new iOwner; iOwner = pev(iEntity, pev_owner);

	if(iReference || (iReference = engfunc(EngFunc_AllocString, "info_target")))
	{
		new iFlameEntity = engfunc(EngFunc_CreateNamedEntity, iReference);

		g_iThinkTimes[iFlameEntity] = 0;

		set_pev(iFlameEntity, pev_classname, FLAME_CLASSNAME);
		set_pev(iFlameEntity, pev_solid, SOLID_TRIGGER);
		set_pev(iFlameEntity, pev_movetype, MOVETYPE_TOSS);
		set_pev(iFlameEntity, pev_effects, EF_NODRAW);
		set_pev(iFlameEntity, pev_owner, iOwner);
		set_pev(iFlameEntity, pev_nextthink, get_gametime() + FLAME_TIMERESET);

		engfunc(EngFunc_SetModel, iFlameEntity, "models/w_ak47.mdl");
		engfunc(EngFunc_SetOrigin, iFlameEntity, vecOrigin);
	}

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_SPRITETRAIL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 100.0);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 30.0);
	write_short(g_iszModelIndexSprite);
	write_byte(50);
	write_byte(random_num(27, 30));
	write_byte(random_num(4, 6));
	write_byte(15);
	write_byte(10);
	message_end();

	set_pev(iEntity, pev_flags, FL_KILLME);
}