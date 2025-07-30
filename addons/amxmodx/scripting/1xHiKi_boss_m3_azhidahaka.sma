#pragma compress 1

#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <fakemeta_util>
#include <zombieplague>

/* ~ ( Macros ) ~ */
#define IsUserValid(%0) bool:(0 < %0 <= 32)
#define GetWeaponClip(%0) get_member(%0, m_Weapon_iClip)
#define SetWeaponClip(%0,%1) set_member(%0, m_Weapon_iClip, %1)
#define GetWeaponAmmoType(%0) get_member(%0, m_Weapon_iPrimaryAmmoType)
#define GetWeaponAmmo(%0,%1) get_member(%0, m_rgAmmo, %1)
#define SetWeaponAmmo(%0,%1,%2) set_member(%0, m_rgAmmo, %1, %2)
#define GetWeaponState(%0) get_member(%0, m_Weapon_iWeaponState)
#define SetWeaponState(%0,%1) set_member(%0, m_Weapon_iWeaponState, %1)

#define WeaponHasSecondaryAmmo(%0) bool:(get_entvar(%0, var_secondary_ammo) > 0)
#define var_secondary_ammo var_gaitsequence
#define m_Weapon_iShotsCount m_Weapon_iGlock18ShotsFired

/* ~ ( Animations ) ~ */
#define ANIM_IDLE_SEQ 0
#define ANIM_SHOOT_SEQ 1
#define ANIM_RELOAD_LOOP_SEQ 3
#define ANIM_RELOAD_END_SEQ 4
#define ANIM_RELOAD_START_SEQ 5
#define ANIM_DRAW_SEQ 6
#define ANIM_IDLE_SEQ_B 7
#define ANIM_SHOOT_SEQ_B 8
#define ANIM_RELOAD_LOOP_SEQ_B 9
#define ANIM_RELOAD_END_SEQ_B 10
#define ANIM_RELOAD_START_SEQ_B 11
#define ANIM_DRAW_SEQ_B 12
#define ANIM_DRAGON_SEQ 13
#define ANIM_CHARGE_START_SEQ 14
#define ANIM_CHARGE_IDLE_SEQ 15
#define ANIM_CHARGE_ATTACK_SEQ 16
#define ANIM_CHARGE_START_SEQ_B 17
#define ANIM_CHARGE_IDLE_SEQ_B 18
#define ANIM_CHARGE_ATTACK_SEQ_B 19

const Float:WEAPON_ANIM_IDLE_TIME = 3.7
const Float:WEAPON_ANIM_SHOOT_TIME = 1.1
const Float:WEAPON_ANIM_RELOAD_LOOP_TIME = 0.4
const Float:WEAPON_ANIM_RELOAD_END = 0.8
const Float:WEAPON_ANIM_RELOAD_START = 0.5
const Float:WEAPON_ANIM_DRAW_TIME = 1.0
const Float:WEAPON_ANIM_DRAGON_TIME = 1.3
const Float:WEAPON_ANIM_CHARGE_START_TIME = 0.3
const Float:WEAPON_ANIM_CHARGE_IDLE_TIME = 1.0
const Float:WEAPON_ANIM_CHARGE_ATTACK_TIME = 1.3

/* ~ ( Variables ) ~ */
enum {
	WeaponState_None,
	WeaponState_Charge,
	WeaponState_Charge_Attack,
};

/* ~ ( Resources & Settings ) ~ */
new const WeaponModelPlayer[] = "models/m3_azhidahaka_re/p_m3dragonex.mdl"
new const WeaponModelView[] = "models/m3_azhidahaka_re/v_m3dragonex.mdl"
new const WeaponModelWorld[] = "models/m3_azhidahaka_re/w_m3dragonex.mdl"
new const WeaponModelDragon[] = "models/m3_azhidahaka_re/misc/ef_m3dragonex.mdl"
const WeaponModelWorldBody = 0;

/* ~ ( For Event Change Weapon ) ~ */
new const Resources[][] = 
{
	"models/m3_azhidahaka_re/v_m3dragonex.mdl",
	"models/m3_azhidahaka_re/p_m3dragonex.mdl"
}

//new const WeaponList[] = "m3_azhidahaka_re/weapon_azhi"
new const WeaponReference[] = "weapon_m3"

new const WeaponSounds[][] =  {
	"weapons/m3_azhidahaka/m3dragonex-1.wav",
	"weapons/m3_azhidahaka/m3dragonex_charge.wav",
	"weapons/m3_azhidahaka/m3dragonex_charge_idle.wav",
	"weapons/m3_azhidahaka/m3dragonex_charge_attack.wav",
	"weapons/m3_azhidahaka/m3dragonex_charge_fx_dragon.wav",
	"weapons/m3_azhidahaka/m3dragonex_dragon_fx.wav"
};
new const WeaponSprites[][] = {
	"sprites/m3_azhidahaka_re/muzzleflash327.spr",
	"sprites/m3_azhidahaka_re/muzzleflash328.spr",
	"sprites/m3_azhidahaka_re/ef_m3dragonex_shoot.spr",
	"sprites/m3_azhidahaka_re/ef_m3dragonex_start.spr",
	"sprites/m3_azhidahaka_re/ef_m3dragonex_loop.spr",
	"sprites/m3_azhidahaka_re/ef_m3dragonex_exp01.spr",
	"sprites/m3_azhidahaka_re/ef_m3dragonex_exp02.spr",
	"sprites/m3_azhidahaka_re/ef_m3dragonex_exp03.spr",
	"sprites/m3_azhidahaka_re/ef_m3dragonex_ball.spr",
	"sprites/m3_azhidahaka_re/ef_m3dragonex_bomb.spr"
}; enum { MuzzleFlash_Shoot, MuzzleFlash_Special, FireMdl, Sprite_Start, Sprite_Loop, Attack_Start, Attack_End = 7, Ball, Ball_Boom };

/* ~ ( Entity Classnames ) ~ */
new const WeaponMuzzleFlash_EntityReference[] = "env_sprite"
new const WeaponSprites_Sprite_EntityName[] = "ent_charge_sprite"
new const Weapon_EntityReference[] = "info_target"
new const WeaponFire_EntityName[][] = {
	"ent_fire_m3_dragonex_mdl",
	"ent_fire_m3_dragonex",
};

new const WeaponMuzzleFlash_EntityName_Shoot[] = "ent_muzzleflash_a"
const Float:WeaponSprites_Fire_Scale = 0.75
const Float:WeaponSprites_Fire_MaxFrame = 23.0
const Float:WeaponSprites_Sprite_Scale = 0.35
const Float:WeaponSprites_Sprite_Start_MaxFrame = 28.0
const Float:WeaponSprites_Sprite_Loop_MaxFrame = 30.0

const Float:WeaponSprites_Attack_MaxFrame = 21.0

new const WeaponSprites_Ball_EntityName[] = "ent_dragon_ball"
const Float:WeaponSprites_Ball_Scale = 0.1
const Float:WeaponSprites_Ball_MaxFrame = 17.0
const Float:WeaponSprites_Ball_FrameRate = 0.05
const Float:WeaponSprites_Ball_Boom_MaxFrame = 23.0
const Float:WeaponSprites_Ball_Boom_FrameRate = 0.02

const Float:WeaponModel_Dragon_Scale = 1.0
const Float:WeaponModel_Dragon_MaxFrame = 121.0
const Float:WeaponModel_Dragon_FrameRate = 1.0

new const WeaponSecondaryAmmoName[] = "ammo_m3_dragonex"
const WeaponSecondaryAmmoIndex = 17;

new const WeaponMuzzleFlash_EntityName_Special[] = "ent_muzzleflash_b"
const Float:WeaponMuzzleFlash_Scale_Shoot = 0.1
const Float:WeaponMuzzleFlash_FrameRate_Shoot = 0.05
const Float:WeaponMuzzleFlash_MaxFrame_Shoot = 14.0

const Float:WeaponMuzzleFlash_Scale_Special = 0.1
const Float:WeaponMuzzleFlash_FrameRate_Special = 0.05
const Float:WeaponMuzzleFlash_MaxFrame_Special = 11.0

const WeaponSetting_MaxAmmoClip = 15
const WeaponSetting_SecondaryAmmoAdd = 20
const WeaponSetting_MaxAmmo = 90
const WeaponSetting_MaxAmmoDefault = 90

const WeaponSetting_FireDamageType = (DMG_BULLET|DMG_NEVERGIB)

const Float:WeaponSetting_ShootRate = 0.5

const Float:WeaponSetting_FireDamage = 450.0
const Float:WeaponSetting_FireSize = 50.0
const Float:WeaponSetting_FireSpeed = 600.0
const Float:WeaponSetting_FireDamageSpeed = 0.2
const Float:WeaponSetting_FireLifeTime = 0.75

const Float:WeaponSetting_ChargeDamage = 750.0
const Float:WeaponSetting_ChargeRadius = 300.0
const Float:WeaponSetting_ChargeTimeStart = 1.0

new const WeaponModel_DragonEntityName[] = "ent_dragon"
const WeaponSetting_MaxSecondaryAmmo = 2
const Float:WeaponSetting_DragonWait = 5.0
const Float:WeaponSetting_DragonDamage = 350.0
const Float:WeaponSetting_DragonDamageRate = 0.2

const Float:WeaponSetting_BallSpeed = 600.0
const Float:WeaponSetting_DragonRadius = 250.0

new g_bHasAzHi[ MAX_PLAYERS + 1 ];

public plugin_natives() register_native("give_azhi", "Native_Give_Weapon");
public plugin_precache() {
	/* ~ ( Hook ) ~ */
//	register_clcmd(WeaponList, "Command_HookWeapon");

	/* ~ ( Models & Sprites ) ~ */
	engfunc(EngFunc_PrecacheModel, WeaponModelPlayer);
	engfunc(EngFunc_PrecacheModel, WeaponModelView);
	engfunc(EngFunc_PrecacheModel, WeaponModelWorld);
	engfunc(EngFunc_PrecacheModel, WeaponModelDragon);
	for(new i = 0; i < sizeof(WeaponSprites); i++) engfunc(EngFunc_PrecacheModel, WeaponSprites[i]);

	/* ~ ( Sounds ) ~ */
	for(new i = 0; i < sizeof(WeaponSounds); i++) engfunc(EngFunc_PrecacheSound, WeaponSounds[i]);

	/* ~ ( Custom Precaches ) ~ */
	Precache_Sounds_From_Model(WeaponModelView);
	//Precache_WeaponList(WeaponList);
}

public client_disconnected( Id ) g_bHasAzHi[ Id ] = false;
public zp_user_infected_pre(id) g_bHasAzHi[ id ] = false;

public plugin_init() {
	register_plugin("(ZP) Weapon: M3 Azhi Dahaka", "1.1", "eziekel | noFame | PowerSiderS");

	/* ~ ( Hamsandwich & ReGameDLL ) ~ */
	RegisterHam(Ham_Weapon_Reload, WeaponReference, "Reload_Pre", false);
	RegisterHam(Ham_Item_PostFrame, WeaponReference, "PostFrame_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle, WeaponReference, "WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack, WeaponReference, "PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack, WeaponReference, "SecondaryAttack_Pre", false);

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "CleanUpMap_Post", true);
	RegisterHam(Ham_Spawn, WeaponReference, "Spawn_Post", true);
	RegisterHam(Ham_Item_Deploy, WeaponReference, "Deploy_Post", true);
	RegisterHam(Ham_Item_Holster, WeaponReference, "Holster_Post", true);
	//RegisterHam(Ham_Item_AddToPlayer, WeaponReference, "AddToPlayer_Post", true);

	/* ~ ( Fakemeta ) ~ */
	register_forward(FM_UpdateClientData, "UpdateClientData_Post", true);
	
	/* ~ ( Events ) ~ */
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
}

/* ~ ( Hook Weapon ) ~ */
public Command_HookWeapon(const pPlayer)  {
	engclient_cmd(pPlayer, WeaponReference);
	return PLUGIN_HANDLED;
}

public bool:Give_Weapon(const pPlayer) {
	if(!is_user_alive(pPlayer))
		return false;

	new pItem = rg_give_item(pPlayer, WeaponReference, GT_DROP_AND_REPLACE)
	g_bHasAzHi[ pPlayer ] = true
	if(is_nullent(pItem))
		return false;

	new iAmmoType = GetWeaponAmmoType(pItem);
	if(GetWeaponAmmo(pPlayer, iAmmoType) < WeaponSetting_MaxAmmoDefault)
		SetWeaponAmmo(pPlayer, WeaponSetting_MaxAmmoDefault, iAmmoType);
	return true;
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id) || get_user_weapon(id) != CSW_M3 || zp_get_user_zombie(id) || zp_get_user_survivor(id) ||  !g_bHasAzHi[id])
		return PLUGIN_HANDLED;

	set_pev(id, pev_viewmodel2, Resources[0])
	set_pev(id, pev_weaponmodel2, Resources[1])

	return PLUGIN_CONTINUE;
}

public Native_Give_Weapon() {
	enum { arg_player = 1 };

	return Give_Weapon(get_param(arg_player));
}

/* ~ ( Entity Functions ) ~ */
public Weapon_Fire(const pItem, const pPlayer, iClip, const Float:flNextAttack) {
	static iShotsCount; iShotsCount = get_member(pItem, m_Weapon_iShotsCount) + 1;

	if(iShotsCount > WeaponSetting_SecondaryAmmoAdd) {
		iShotsCount = 0;
		new iSecondaryAmmo = get_entvar(pItem, var_secondary_ammo);
		if(iSecondaryAmmo < WeaponSetting_MaxSecondaryAmmo)
			UpdateSecondaryAmmo(pItem, pPlayer, ++iSecondaryAmmo);
	}

	set_member(pItem, m_Weapon_iShotsCount, iShotsCount);

	Weapon_Fire_Create_Entity(pItem, pPlayer);

	rg_set_animation(pPlayer, PLAYER_ATTACK1);

	SetWeaponClip(pItem, --iClip);

	new Float:vecPunchAngle[3]; get_entvar(pPlayer, var_punchangle, vecPunchAngle);
	vecPunchAngle[0] -= 0.75;
	set_entvar(pPlayer, var_punchangle, vecPunchAngle);

	WeaponAnim(MSG_ONE, pPlayer, pItem, WeaponHasSecondaryAmmo(pItem) ? ANIM_SHOOT_SEQ :ANIM_SHOOT_SEQ_B);
	emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_member(pItem, m_Weapon_fInSpecialReload, 0);
	set_member(pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME);
	set_member(pItem, m_Weapon_flNextPrimaryAttack, flNextAttack);
	set_member(pItem, m_Weapon_flNextSecondaryAttack, flNextAttack);
}

public Weapon_Fire_Create_Entity(const pItem, const pPlayer) {
	new pEntity = rg_create_entity(Weapon_EntityReference);

	if(is_nullent(pEntity))
		return NULLENT;

	static Float:vecOrigin[3]; GetEyePosition(pPlayer, vecOrigin);
	static Float:vecDirection[3]; GetVectorAiming(pPlayer, vecDirection);

	xs_vec_add_scaled(vecOrigin, vecDirection, 20.0, vecOrigin);
	xs_vec_mul_scalar(vecDirection, WeaponSetting_FireSpeed, vecDirection);
	set_entvar(pEntity, var_velocity, vecDirection);

	engfunc(EngFunc_VecToAngles, vecDirection, vecDirection);
	set_entvar(pEntity, var_angles, vecDirection);

	set_entvar(pEntity, var_classname, WeaponFire_EntityName[0]);
	set_entvar(pEntity, var_solid, SOLID_TRIGGER);
	set_entvar(pEntity, var_movetype, MOVETYPE_FLY);
	set_entvar(pEntity, var_owner, pPlayer);

	set_entvar(pEntity, var_rendermode, kRenderTransAdd);
	set_entvar(pEntity, var_renderamt, 255.0);

	set_entvar(pEntity, var_frame, 0.0);
	set_entvar(pEntity, var_framerate, WeaponSetting_FireLifeTime / WeaponSprites_Fire_MaxFrame);
	set_entvar(pEntity, var_fuser1, WeaponSprites_Fire_MaxFrame);
	set_entvar(pEntity, var_scale, WeaponSprites_Fire_Scale);

	engfunc(EngFunc_SetOrigin, pEntity, vecOrigin);
	engfunc(EngFunc_SetModel, pEntity, WeaponSprites[FireMdl]);
	engfunc(EngFunc_SetSize, pEntity, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});

	new iEnt_FireRandius = Weapon_FireRadius_Create_Entity(pPlayer, pItem);
	if(!is_nullent(iEnt_FireRandius)) {
		set_entvar(pEntity, var_enemy, iEnt_FireRandius);
		set_entvar(iEnt_FireRandius, var_aiment, pEntity);
	}

	set_entvar(pEntity, var_nextthink, get_gametime());

	SetThink(pEntity, "Weapon_Fire_Entity_Think");

	return pEntity;
}

public Weapon_Fire_Entity_Think(const pEntity) {
	if(is_nullent(pEntity)) return;

	static Float:flFrame; get_entvar(pEntity, var_frame, flFrame);
	static Float:flFrameRate; get_entvar(pEntity, var_framerate, flFrameRate);
	static Float:flMaxFrame; flMaxFrame = get_entvar(pEntity, var_fuser1);
	
	if(flFrame < flMaxFrame)
	{
		set_entvar(pEntity, var_frame, ++flFrame);
		set_entvar(pEntity, var_nextthink, get_gametime() + flFrameRate);
		return;
	}

	else
	{
		static pRadiusEnt; pRadiusEnt = get_entvar(pEntity, var_enemy);
		if(!is_nullent(pRadiusEnt))
			KillEntity(pRadiusEnt);
			
		KillEntity(pEntity);
	}
}


public Weapon_FireRadius_Create_Entity(const pPlayer, const pItem)
{
	new pEntity = rg_create_entity(Weapon_EntityReference);

	if(is_nullent(pEntity))
		return NULLENT;

	static Float:vecMin[3], Float:vecMax[3];
	{
		vecMax[0] = vecMax[1] = vecMax[2] = WeaponSetting_FireSize;
		vecMin[0] = vecMin[1] = vecMin[2] = -WeaponSetting_FireSize;
	}

	engfunc(EngFunc_SetSize, pEntity, vecMin, vecMax);

	set_entvar(pEntity, var_classname, WeaponFire_EntityName[1]);
	set_entvar(pEntity, var_solid, SOLID_TRIGGER);
	set_entvar(pEntity, var_movetype, MOVETYPE_FOLLOW);
	set_entvar(pEntity, var_owner, pPlayer);
	set_entvar(pEntity, var_dmg_inflictor, pItem);

	SetTouch(pEntity, "Weapon_FireRadius_Entity_Touch");

	return pEntity;
}

public Weapon_FireRadius_Entity_Touch(const pEntity, const pTouch)
{
	if(!IsUserValid(pTouch))
		return;

	static pOwner; pOwner = get_entvar(pEntity, var_owner);

	if(pTouch == pOwner)
		return;
		
	if(get_user_team(pTouch) != 1) return;

	static Float:flGameTime; flGameTime = get_gametime();
	static Float:flDamageTime; get_entvar(pTouch, var_dmgtime, flDamageTime);
	if(flDamageTime < flGameTime)
	{
		static pInflictor; pInflictor = get_entvar(pEntity, var_dmg_inflictor);
		if(is_nullent(pInflictor))
			pInflictor = pEntity;

		set_member(pTouch, m_LastHitGroup, HIT_GENERIC);
		ExecuteHamB(Ham_TakeDamage, pTouch, pInflictor, pOwner, WeaponSetting_FireDamage, WeaponSetting_FireDamageType);

		set_entvar(pTouch, var_dmgtime, flGameTime + WeaponSetting_FireDamageSpeed);
	}
}

public Charge_Find_Victim(const pItem, const pPlayer, const Float:flRadius) {
	static iVictim, Float:vecVictimOrigin[3], Float:vecOrigin[3]; get_entvar(pPlayer, var_origin, vecOrigin);

	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, flRadius)) > 0) {
		if(iVictim == pPlayer)
			continue;
			
		if(!zp_get_user_zombie(iVictim) || !zp_get_user_nemesis(iVictim)) 
			continue;

		if(!is_user_alive(iVictim))
			continue;

		if(Charge_Check(iVictim))
			continue;

		get_entvar(iVictim, var_origin, vecVictimOrigin);

		Charge_Create_Sprite(pItem, pPlayer, iVictim, vecVictimOrigin);
	}
}

public bool:Charge_Check(const iVictim)
{
	static pEntity; pEntity = NULLENT;

	while((pEntity = fm_find_ent_by_class(pEntity, WeaponSprites_Sprite_EntityName)) > 0)
	{
		if(get_entvar(pEntity, var_aiment) == iVictim)
			return true;
	}

	return false;
}

public Charge_Create_Sprite(const pItem, const pPlayer, const iVictim, const Float:vecVictimOrigin[3])
{
	new pEntity = rg_create_entity(Weapon_EntityReference);

	if(is_nullent(pEntity))
		return NULLENT;
		
	if(get_user_team(iVictim) != 1) return NULLENT;

	set_entvar(pEntity, var_classname, WeaponSprites_Sprite_EntityName);
	set_entvar(pEntity, var_owner, pPlayer);
	set_entvar(pEntity, var_aiment, iVictim);
	set_entvar(pEntity, var_dmg_inflictor, pItem);
	set_entvar(pEntity, var_movetype, MOVETYPE_FOLLOW);
	set_entvar(pEntity, var_solid, SOLID_NOT);

	set_entvar(pEntity, var_rendermode, kRenderTransAdd);
	set_entvar(pEntity, var_renderamt, 255.0);

	set_entvar(pEntity, var_frame, 0.0);
	set_entvar(pEntity, var_framerate, WeaponSetting_ChargeTimeStart / WeaponSprites_Sprite_Start_MaxFrame);
	set_entvar(pEntity, var_fuser1, WeaponSprites_Sprite_Start_MaxFrame);
	set_entvar(pEntity, var_scale, WeaponSprites_Sprite_Scale);

	set_entvar(pEntity, var_iuser1, 1);

	engfunc(EngFunc_SetModel, pEntity, WeaponSprites[Sprite_Start]);
	engfunc(EngFunc_SetOrigin, pEntity, vecVictimOrigin);

	set_entvar(pEntity, var_nextthink, get_gametime());

	SetThink(pEntity, "Charge_Create_Sprite_Think");

	return pEntity;
}

public Charge_Create_Sprite_Think(const pEntity)
{
	if(is_nullent(pEntity))
		return;

	static iVictim; iVictim = get_entvar(pEntity, var_aiment);
	static iOwner; iOwner = get_entvar(pEntity, var_owner);
	static Float:veciVictim[3], Float:veciOwner[3];
	get_entvar(iVictim, var_origin, veciVictim); get_entvar(iOwner, var_origin, veciOwner)
	
	if(get_user_team(iVictim) != 1) return;

	if(get_distance_f(veciVictim, veciOwner) > WeaponSetting_ChargeRadius || !is_user_alive(iVictim))
	{
		KillEntity(pEntity);
		return;
	}

	static iEntityStatus; iEntityStatus = get_entvar(pEntity, var_iuser1);
	static iItem; iItem = get_entvar(pEntity, var_dmg_inflictor);
	static iWeaponState; iWeaponState = GetWeaponState(iItem);
	static Float:flFrame; get_entvar(pEntity, var_frame, flFrame);
	static Float:flFrameRate; get_entvar(pEntity, var_framerate, flFrameRate);
	static Float:flMaxFrame; flMaxFrame = get_entvar(pEntity, var_fuser1);
	static Float:flNextFrame, Float:flNextFrameRate;

	switch(iEntityStatus)
	{
		case 1:
		{
			if(iWeaponState == WeaponState_None || iWeaponState == WeaponState_Charge_Attack)
			{
				KillEntity(pEntity);
				return;
			}

			if(flFrame < flMaxFrame)
			{
				if(flFrame == 0.0)
					emit_sound(iOwner, CHAN_WEAPON, WeaponSounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

				flNextFrame = ++flFrame;
				flNextFrameRate = flFrameRate;
			}

			else 
			{
				set_entvar(pEntity, var_iuser1, 2);
				set_entvar(pEntity, var_fuser1, WeaponSprites_Sprite_Loop_MaxFrame);
				set_entvar(pEntity, var_framerate, 0.1);
				flNextFrame = flNextFrameRate = 0.0;

				engfunc(EngFunc_SetModel, pEntity, WeaponSprites[Sprite_Loop]);
			}
		}

		case 2:
		{
			if(iWeaponState == WeaponState_None)
			{
				KillEntity(pEntity);
				return;
			}

			if(iWeaponState == WeaponState_Charge_Attack)
				set_entvar(pEntity, var_iuser1, 3);

			if(flFrame < flMaxFrame)
			{
				flNextFrame = ++flFrame;
				flNextFrameRate = flFrameRate;
			}
			else 
				flNextFrame = flNextFrameRate = 0.0;
		}

		case 3:
		{
			set_entvar(pEntity, var_iuser1, 4);
			set_entvar(pEntity, var_framerate, 0.04);
			set_entvar(pEntity, var_fuser1, WeaponSprites_Attack_MaxFrame);
			flNextFrame = flNextFrameRate = 0.0;

			engfunc(EngFunc_SetModel, pEntity, WeaponSprites[random_num(Attack_Start, Attack_End)]);
			emit_sound(iVictim, CHAN_WEAPON, WeaponSounds[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			ExecuteHamB(Ham_TakeDamage, iVictim, iItem, iOwner, WeaponSetting_ChargeDamage, WeaponSetting_FireDamageType);
		}

		case 4:
		{
			if(flFrame < flMaxFrame)
			{
				flNextFrame = ++flFrame;
				flNextFrameRate = flFrameRate;
			}
			else 
			{
				KillEntity(pEntity);
				return;
			}
		}
	}

	set_entvar(pEntity, var_frame, flNextFrame);
	set_entvar(pEntity, var_nextthink, get_gametime() + flNextFrameRate);
}

public Dragon_Create_Ball(const pItem, const pPlayer)
{
	new pEntity = rg_create_entity(Weapon_EntityReference);

	if(is_nullent(pEntity))
		return NULLENT;

	static Float:vecDirection[3]; GetVectorAiming(pPlayer, vecDirection);
	static Float:vecOrigin[3]; GetEyePosition(pPlayer, vecOrigin);

	xs_vec_add_scaled(vecOrigin, vecDirection, 20.0, vecOrigin);
	xs_vec_mul_scalar(vecDirection, WeaponSetting_BallSpeed, vecDirection);
	set_entvar(pEntity, var_velocity, vecDirection);

	engfunc(EngFunc_VecToAngles, vecDirection, vecDirection);
	set_entvar(pEntity, var_angles, vecDirection);

	set_entvar(pEntity, var_classname, WeaponSprites_Ball_EntityName);
	set_entvar(pEntity, var_owner, pPlayer);
	set_entvar(pEntity, var_dmg_inflictor, pItem);
	set_entvar(pEntity, var_movetype, MOVETYPE_FLYMISSILE);
	set_entvar(pEntity, var_solid, SOLID_BBOX);

	set_entvar(pEntity, var_rendermode, kRenderTransAdd);
	set_entvar(pEntity, var_renderamt, 255.0);

	set_entvar(pEntity, var_frame, 0.0);
	set_entvar(pEntity, var_framerate, WeaponSprites_Ball_FrameRate);
	set_entvar(pEntity, var_fuser1, WeaponSprites_Ball_MaxFrame);
	set_entvar(pEntity, var_scale, WeaponSprites_Ball_Scale);

	set_entvar(pEntity, var_iuser1, 1);

	engfunc(EngFunc_SetOrigin, pEntity, vecOrigin);
	engfunc(EngFunc_SetModel, pEntity, WeaponSprites[Ball]);
	engfunc(EngFunc_SetSize, pEntity, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});

	set_entvar(pEntity, var_nextthink, get_gametime());

	SetThink(pEntity, "Dragon_Create_Ball_Think");
	SetTouch(pEntity, "Dragon_Create_Ball_Touch");

	return pEntity;
}

public Dragon_Create_Ball_Think(const pEntity)
{
	if(is_nullent(pEntity))
		return;

	static iEntityState; iEntityState = get_entvar(pEntity, var_iuser1);
	static Float:flFrame; get_entvar(pEntity, var_frame, flFrame);
	static Float:flFrameRate; get_entvar(pEntity, var_framerate, flFrameRate);
	static Float:flMaxFrame; flMaxFrame = get_entvar(pEntity, var_fuser1);
	static Float:flNextFrame, Float:flNextThink;

	switch(iEntityState)
	{
		case 1:
		{
			if(flFrame < flMaxFrame)
			{
				flNextFrame = ++flFrame;
				flNextThink = flFrameRate;
			}
			else
				flNextFrame = flNextThink = 0.0;
		}

		case 2:
		{
			set_entvar(pEntity, var_iuser1, 3);
			set_entvar(pEntity, var_fuser1, WeaponSprites_Ball_Boom_MaxFrame);
			set_entvar(pEntity, var_framerate, WeaponSprites_Ball_Boom_FrameRate);
			flNextFrame = flNextThink = 0.0;

			engfunc(EngFunc_SetModel, pEntity, WeaponSprites[Ball_Boom]);
		}	

		case 3:
		{
			if(flFrame < flMaxFrame)
			{
				flNextFrame = ++flFrame;
				flNextThink = flFrameRate;
			}

			else
			{
				static pOwner, pItem, Float:vecOrigin[3];
				pOwner = get_entvar(pEntity, var_owner);
				pItem = get_entvar(pEntity, var_dmg_inflictor);
				get_entvar(pEntity, var_origin, vecOrigin);
				Dragon_Create(pItem, pOwner, vecOrigin);

				KillEntity(pEntity);
				return;
			}			
		}
	}

	set_entvar(pEntity, var_frame, flNextFrame);
	set_entvar(pEntity, var_nextthink, get_gametime() + flNextThink);
}

public Dragon_Create_Ball_Touch(const pEntity, const pTouch)
{
	if(pTouch == get_entvar(pEntity, var_owner))
		return;

	static Float:vecOrigin[3]; get_entvar(pEntity, var_origin, vecOrigin);
	if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
	{
		KillEntity(pEntity);
		return;
	}

	set_entvar(pEntity, var_iuser1, 2);
	set_entvar(pEntity, var_movetype, MOVETYPE_NONE);

	SetTouch(pEntity, "");
}

public Dragon_Create(const pItem, const pPlayer, Float:Origin[3])
{
	new pEntity = rg_create_entity(Weapon_EntityReference);

	if(is_nullent(pEntity))
		return NULLENT;

	set_entvar(pEntity, var_classname, WeaponModel_DragonEntityName);
	set_entvar(pEntity, var_owner, pPlayer);
	set_entvar(pEntity, var_dmg_inflictor, pItem);
	set_entvar(pEntity, var_movetype, MOVETYPE_FLY);
	set_entvar(pEntity, var_solid, SOLID_TRIGGER);

	set_entvar(pEntity, var_rendermode, kRenderTransAdd);
	set_entvar(pEntity, var_renderamt, 255.0);

	set_entvar(pEntity, var_framerate, WeaponModel_Dragon_FrameRate);
	set_entvar(pEntity, var_scale, WeaponModel_Dragon_Scale);

	static Float:vecMin[3], Float:vecMax[3];
	vecMin[0] = vecMin[1] = vecMin[2] = -WeaponSetting_DragonRadius;
	vecMax[0] = vecMax[1] = vecMax[2] = WeaponSetting_DragonRadius;

	engfunc(EngFunc_SetModel, pEntity, WeaponModelDragon);
	engfunc(EngFunc_SetOrigin, pEntity, Origin);
	engfunc(EngFunc_DropToFloor, pEntity);
	Origin[2] += 0.2; engfunc(EngFunc_SetOrigin, pEntity, Origin);
	engfunc(EngFunc_SetSize, pEntity, vecMin, vecMax);

	set_entvar(pEntity, var_animtime, get_gametime());
	set_entvar(pEntity, var_nextthink, get_gametime() + 4.0);

	emit_sound(pEntity, CHAN_WEAPON, WeaponSounds[5], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	SetThink(pEntity, "Dragon_Create_Think");
	SetTouch(pEntity, "Dragon_Create_Touch");

	return pEntity;
}

public Dragon_Create_Think(const pEntity)
{
	if(is_nullent(pEntity)) return;

	KillEntity(pEntity);
}

public Dragon_Create_Touch(const pEntity, const pTouch)
{
	if(!IsUserValid(pTouch))
		return;

	static pOwner; pOwner = get_entvar(pEntity, var_owner);

	if(pTouch == pOwner)
		return;

	if(!is_user_alive(pTouch))
		return;
		
	if(get_user_team(pTouch) != 1) return;

	static Float:flGameTime; flGameTime = get_gametime();
	static Float:flDamageTime; get_entvar(pTouch, var_dmgtime, flDamageTime);
	if(flDamageTime < flGameTime)
	{
		static pInflictor; pInflictor = get_entvar(pEntity, var_dmg_inflictor);
		if(is_nullent(pInflictor))
			pInflictor = pEntity;

		set_member(pTouch, m_LastHitGroup, HIT_GENERIC);
		ExecuteHamB(Ham_TakeDamage, pTouch, pInflictor, pOwner, WeaponSetting_DragonDamage, WeaponSetting_FireDamageType);

		set_entvar(pTouch, var_dmgtime, flGameTime + WeaponSetting_DragonDamageRate);
	}
}



public Reload_Pre(const pItem)
{

	static pPlayer; pPlayer = get_member(pItem, m_pPlayer);

	if(!g_bHasAzHi[ pPlayer ]) return HAM_IGNORED;
	
	ShotgunReload(pPlayer, pItem, WeaponHasSecondaryAmmo(pItem) ? ANIM_RELOAD_START_SEQ :ANIM_RELOAD_START_SEQ_B, WEAPON_ANIM_RELOAD_START, "", WeaponHasSecondaryAmmo(pItem) ? ANIM_RELOAD_LOOP_SEQ :ANIM_RELOAD_LOOP_SEQ_B, WEAPON_ANIM_RELOAD_LOOP_TIME, "");

	return HAM_SUPERCEDE;
}

public PostFrame_Pre(const pItem)
{
	if(is_nullent(pItem))
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member(pItem, m_pPlayer);
	
	if(!g_bHasAzHi[ pPlayer ]) return HAM_IGNORED;
	
	static bitsButton; bitsButton = get_entvar(pPlayer, var_button);
	static bitsWeaponState; bitsWeaponState = GetWeaponState(pItem);
	static iSecondaryAmmo; iSecondaryAmmo = get_entvar(pItem, var_secondary_ammo);
	if(bitsWeaponState == WeaponState_Charge)
	{
		Charge_Find_Victim(pItem, pPlayer, WeaponSetting_ChargeRadius);

		if(~bitsButton & IN_ATTACK2)
		{
			SetWeaponState(pItem, WeaponState_Charge_Attack)

			rg_set_animation(pPlayer, PLAYER_ATTACK1);

			WeaponAnim(MSG_ONE, pPlayer, pItem, WeaponHasSecondaryAmmo(pItem) ? ANIM_SHOOT_SEQ : ANIM_SHOOT_SEQ_B);
			Create_MuzzleFlash(pPlayer, WeaponMuzzleFlash_EntityName_Shoot, WeaponSprites[MuzzleFlash_Shoot], WeaponMuzzleFlash_Scale_Shoot, 255.0, WeaponMuzzleFlash_FrameRate_Shoot, WeaponMuzzleFlash_MaxFrame_Shoot);

			set_member(pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_CHARGE_ATTACK_TIME);
			set_member(pItem, m_Weapon_flNextPrimaryAttack, WEAPON_ANIM_CHARGE_ATTACK_TIME);
			set_member(pItem, m_Weapon_flNextSecondaryAttack, WEAPON_ANIM_CHARGE_ATTACK_TIME);
		}
	}

	if(bitsButton & IN_ATTACK && bitsButton & IN_ATTACK2)
	{
		if(!iSecondaryAmmo)
			return HAM_IGNORED;

		if(get_entvar(pItem, var_starttime) > get_gametime())
			return HAM_IGNORED;

		Dragon_Create_Ball(pItem, pPlayer);

		UpdateSecondaryAmmo(pItem, pPlayer, --iSecondaryAmmo);

		WeaponAnim(MSG_ONE, pPlayer, pItem, ANIM_DRAGON_SEQ);
		Create_MuzzleFlash(pPlayer, WeaponMuzzleFlash_EntityName_Special, WeaponSprites[MuzzleFlash_Special], WeaponMuzzleFlash_Scale_Special, 255.0, WeaponMuzzleFlash_FrameRate_Special, WeaponMuzzleFlash_MaxFrame_Special);
		emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		rg_set_animation(pPlayer, PLAYER_ATTACK1);

		set_entvar(pItem, var_starttime, get_gametime() + WeaponSetting_DragonWait);
		set_member(pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_DRAGON_TIME);
		set_member(pItem, m_Weapon_flNextPrimaryAttack, WEAPON_ANIM_DRAGON_TIME);
		set_member(pItem, m_Weapon_flNextSecondaryAttack, WEAPON_ANIM_DRAGON_TIME);
	}

	return HAM_IGNORED;
}

public WeaponIdle_Pre(const pItem)
{
	if(is_nullent(pItem))
		return HAM_IGNORED;

	if(get_member(pItem, m_Weapon_flTimeWeaponIdle) > 0.0)
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member(pItem, m_pPlayer);
	
	if(!g_bHasAzHi[ pPlayer ]) return HAM_IGNORED;
	
	ShotgunIdle(pPlayer, pItem, WeaponHasSecondaryAmmo(pItem) ? ANIM_IDLE_SEQ :ANIM_IDLE_SEQ_B, WEAPON_ANIM_IDLE_TIME, WeaponHasSecondaryAmmo(pItem) ?  ANIM_RELOAD_END_SEQ :ANIM_RELOAD_END_SEQ_B, WEAPON_ANIM_RELOAD_END, "");

	return HAM_SUPERCEDE;
}

public PrimaryAttack_Pre(const pItem)
{
	if (is_nullent(pItem))
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member(pItem, m_pPlayer);	
	
	if(!g_bHasAzHi[ pPlayer ]) return HAM_IGNORED;
	
	static iClip; iClip = GetWeaponClip(pItem);
	if (!iClip)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, pItem);
		set_member(pItem, m_Weapon_flNextPrimaryAttack, 0.2);

		return HAM_SUPERCEDE;
	}

	
	Weapon_Fire(pItem, pPlayer, iClip, WeaponSetting_ShootRate);

	Create_MuzzleFlash(pPlayer, WeaponMuzzleFlash_EntityName_Shoot, WeaponSprites[MuzzleFlash_Shoot], WeaponMuzzleFlash_Scale_Shoot, 255.0, WeaponMuzzleFlash_FrameRate_Shoot, WeaponMuzzleFlash_MaxFrame_Shoot);

	set_member(pPlayer, m_flNextAttack, WeaponSetting_ShootRate);

	return HAM_SUPERCEDE;
}

public SecondaryAttack_Pre(const pItem)
{
	if (is_nullent(pItem))
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member(pItem, m_pPlayer);
	
	if(!g_bHasAzHi[ pPlayer ]) return HAM_IGNORED;
	
	static bitsWeaponState; bitsWeaponState = GetWeaponState(pItem);
	static iWeaponAnimIndex, Float:flIdleTime, Float:flNextAttack;
	switch(bitsWeaponState)
	{
		case WeaponState_Charge:
		{
			iWeaponAnimIndex = WeaponHasSecondaryAmmo(pItem) ? ANIM_CHARGE_IDLE_SEQ :ANIM_CHARGE_IDLE_SEQ_B;
			flNextAttack = flIdleTime = WEAPON_ANIM_CHARGE_IDLE_TIME;
		}

		default:
		{
			
			bitsWeaponState = WeaponState_Charge;

			emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			iWeaponAnimIndex = WeaponHasSecondaryAmmo(pItem) ? ANIM_CHARGE_START_SEQ : ANIM_CHARGE_IDLE_SEQ_B;
			flNextAttack = flIdleTime = WEAPON_ANIM_CHARGE_START_TIME;
		}
	}

	if (iWeaponAnimIndex != -1 && get_entvar(pPlayer, var_weaponanim) != iWeaponAnimIndex)
		WeaponAnim(MSG_ONE, pPlayer, pItem, iWeaponAnimIndex);

	if (get_member(pItem, m_Weapon_fInSpecialReload) != 0)
		set_member(pItem, m_Weapon_fInSpecialReload, 0);

	SetWeaponState(pItem, bitsWeaponState);
	set_member(pItem, m_Weapon_flTimeWeaponIdle, flIdleTime);
	set_member(pItem, m_Weapon_flNextPrimaryAttack, flNextAttack);
	set_member(pItem, m_Weapon_flNextSecondaryAttack, flNextAttack);

	return HAM_SUPERCEDE;
}



/* ~ ( Hooks Post ) ~ */
public CleanUpMap_Post()
{
	DestroyEntitiesByClass(WeaponSprites_Sprite_EntityName);
	DestroyEntitiesByClass(WeaponSprites_Ball_EntityName);
	DestroyEntitiesByClass(WeaponFire_EntityName[0]);
	DestroyEntitiesByClass(WeaponFire_EntityName[1]);
}

public Spawn_Post(const pItem) 
{
	if(is_nullent(pItem))
		return;

	static pPlayer; pPlayer = get_member(pItem, m_pPlayer);
	if(!g_bHasAzHi[ pPlayer ]) return;
		
	set_member(pItem, m_Weapon_bHasSecondaryAttack, true);
	SetWeaponClip(pItem, WeaponSetting_MaxAmmoClip);
	set_member(pItem, m_Weapon_iDefaultAmmo, WeaponSetting_MaxAmmoDefault);
	//rg_set_iteminfo(pItem, ItemInfo_pszName, WeaponList);
	rg_set_iteminfo(pItem, ItemInfo_iMaxClip, WeaponSetting_MaxAmmoClip);
	rg_set_iteminfo(pItem, ItemInfo_iMaxAmmo1, WeaponSetting_MaxAmmo);
}

public Deploy_Post(const pItem) 
{
	if(is_nullent(pItem))
		return;

	static pPlayer; pPlayer = get_member(pItem, m_pPlayer);
	if(!g_bHasAzHi[ pPlayer ]) return;
	
	set_entvar(pPlayer, var_viewmodel, WeaponModelView);
	set_entvar(pPlayer, var_weaponmodel, WeaponModelPlayer);

	WeaponAnim(MSG_ONE, pPlayer, pItem, WeaponHasSecondaryAmmo(pItem) ? ANIM_DRAW_SEQ :ANIM_DRAW_SEQ_B);

	set_member(pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME);
	set_member(pPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME);
}

public Holster_Post(const pItem)
{
	if(is_nullent(pItem))
		return;

	static pPlayer; pPlayer = get_member(pItem, m_pPlayer);

	if(!g_bHasAzHi[ pPlayer ]) return;
	
	SetWeaponState(pItem, WeaponState_None);
	set_member(pItem, m_Weapon_fInSpecialReload, 0);

	set_member(pItem, m_Weapon_flTimeWeaponIdle, 1.0);
	set_member(pPlayer, m_flNextAttack, 1.0);
}

public AddToPlayer_Post(const pItem, const pPlayer)
{
	if(is_nullent(pItem))
		return;

	if(!g_bHasAzHi[ pPlayer ]) return;
		
	if(get_entvar(pItem, var_owner) <= 0)
	{	
		set_member(pItem, m_Weapon_iSecondaryAmmoType, WeaponSecondaryAmmoIndex);

		rg_set_iteminfo(pItem, ItemInfo_pszAmmo2, WeaponSecondaryAmmoName);
		rg_set_iteminfo(pItem, ItemInfo_iMaxAmmo2, WeaponSetting_MaxSecondaryAmmo);

		set_entvar(pItem, var_secondary_ammo, 0);
	}

	UpdateSecondaryAmmo(pItem, pPlayer, get_entvar(pItem, var_secondary_ammo));
	
	Weapon_List(MSG_ONE, pPlayer, pItem);
}

public UpdateClientData_Post(const pPlayer, const iSendWeapons, const CD_Handle) {
	
	if(!is_user_alive(pPlayer))
		return;
		
	if(get_user_weapon( pPlayer ) != CSW_M3 || !g_bHasAzHi[ pPlayer ]) return;
	
	set_cd(CD_Handle, CD_flNextAttack, 1.0);
}


/* ~ ( Stocks ) ~ */
stock DestroyEntitiesByClass( const szClassName[ ] )
{
	static pEntity; pEntity = NULLENT;
	while ( ( pEntity = fm_find_ent_by_class( pEntity, szClassName ) ) > 0 )
		KillEntity( pEntity );
}

stock UpdateSecondaryAmmo(const pItem, const pPlayer, const iSecondaryAmmo)
{
	set_entvar(pItem, var_secondary_ammo, iSecondaryAmmo);
	SetWeaponAmmo(pPlayer, iSecondaryAmmo, WeaponSecondaryAmmoIndex);

	return true;
}

stock KillEntity(const pEntity)
{
	set_entvar(pEntity, var_flags, FL_KILLME);
	set_entvar(pEntity, var_nextthink, get_gametime());
}

stock ShotgunIdle(const pPlayer, const pItem, const iAnimIdle, const Float:flAnimIdleTime, const iAnimReloadEnd, const Float:flAnimReloadEndTime, const szSoundReloadEnd[] = "")
{
	new iClip = GetWeaponClip(pItem);
	new iAmmoType = GetWeaponAmmoType(pItem);
	new iAmmo = GetWeaponAmmo(pPlayer, iAmmoType);
	new iSpecialReload = get_member(pItem, m_Weapon_fInSpecialReload);

	if (iClip == 0 && iSpecialReload == 0 && iAmmo) ExecuteHamB(Ham_Weapon_Reload, pItem);
	else if (iSpecialReload)
	{
		if (iClip != rg_get_iteminfo(pItem, ItemInfo_iMaxClip) && iAmmo) ExecuteHamB(Ham_Weapon_Reload, pItem);
		else
		{
			WeaponAnim(MSG_ONE, pPlayer, pItem, iAnimReloadEnd);
			if (szSoundReloadEnd[0]) emit_sound( pPlayer, CHAN_WEAPON, szSoundReloadEnd, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

			set_member(pItem, m_Weapon_fInSpecialReload, 0);
			set_member(pItem, m_Weapon_flTimeWeaponIdle, flAnimReloadEndTime);
		}
	}
	else
	{
		WeaponAnim(MSG_ONE, pPlayer, pItem, iAnimIdle);
		set_member(pItem, m_Weapon_flTimeWeaponIdle, flAnimIdleTime);
	}
}

stock bool:ShotgunReload(const pPlayer, const pItem, const iAnimReloadStart, const Float:flReloadStartDelay, const szSoundReloadStart[] = "", const iAnimReload, const Float:flReloadDelay, const szSoundReload[] = "")
{
	new iClip = GetWeaponClip(pItem);
	new iAmmoType = GetWeaponAmmoType(pItem);
	new iAmmo = GetWeaponAmmo(pPlayer, iAmmoType);
	new iSpecialReload = get_member(pItem, m_Weapon_fInSpecialReload);

	if (iAmmo <= 0 || iClip == rg_get_iteminfo(pItem, ItemInfo_iMaxClip) || get_member(pItem, m_Weapon_flNextPrimaryAttack) > 0.0)
		return false;

	switch (iSpecialReload)
	{
		case 0:
		{
			rg_set_animation(pPlayer, PLAYER_RELOAD);
			WeaponAnim(MSG_ONE, pPlayer, pItem, iAnimReloadStart);
			if (szSoundReloadStart[0]) emit_sound( pPlayer, CHAN_WEAPON, szSoundReloadStart, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

			iSpecialReload = 1;
			set_member(pItem, m_Weapon_flNextPrimaryAttack, flReloadStartDelay);
			set_member(pItem, m_Weapon_flNextSecondaryAttack, flReloadStartDelay);
			set_member(pItem, m_Weapon_flTimeWeaponIdle, flReloadStartDelay);
			set_member(pPlayer, m_flNextAttack, flReloadStartDelay);
		}
		case 1:
		{
			if (get_member(pItem, m_Weapon_flTimeWeaponIdle) > 0.0)
				return false;

			WeaponAnim(MSG_ONE, pPlayer, pItem, iAnimReload);
			if (szSoundReload[0]) emit_sound( pPlayer, CHAN_WEAPON, szSoundReload, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

			iSpecialReload = 2;
			set_member(pItem, m_Weapon_flTimeWeaponIdle, flReloadDelay);
		}
		case 2:
		{
			if (get_member(pItem, m_Weapon_flTimeWeaponIdle) > 0.0)
				return false;

			iSpecialReload = 1;
			SetWeaponClip(pItem, ++iClip);
			SetWeaponAmmo(pPlayer, --iAmmo, iAmmoType);
		}
	}
	set_member(pItem, m_Weapon_fInSpecialReload, iSpecialReload);

	return true;
}
stock Weapon_List(const iDest, const pReceiver, const pItem, szWeaponName[MAX_NAME_LENGTH] = "", const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2) 
{
	if (szWeaponName[0] == EOS)
		rg_get_iteminfo(pItem, ItemInfo_pszName, szWeaponName, charsmax(szWeaponName))

	static iMsgId_Weaponlist; if (!iMsgId_Weaponlist) iMsgId_Weaponlist = get_user_msgid("WeaponList");

	message_begin(iDest, iMsgId_Weaponlist, .player = pReceiver);
	write_string(szWeaponName);
	write_byte((iPrimaryAmmoType <= -2) ? GetWeaponAmmoType(pItem) :iPrimaryAmmoType);
	write_byte((iMaxPrimaryAmmo <= -2) ? rg_get_iteminfo(pItem, ItemInfo_iMaxAmmo1) :iMaxPrimaryAmmo);
	write_byte((iSecondaryAmmoType <= -2) ? get_member(pItem, m_Weapon_iSecondaryAmmoType) :iSecondaryAmmoType);
	write_byte((iMaxSecondaryAmmo <= -2) ? rg_get_iteminfo(pItem, ItemInfo_iMaxAmmo2) :iMaxSecondaryAmmo);
	write_byte((iSlot <= -2) ? rg_get_iteminfo(pItem, ItemInfo_iSlot) :iSlot);
	write_byte((iPosition <= -2) ? rg_get_iteminfo(pItem, ItemInfo_iPosition) :iPosition);
	write_byte((iWeaponId <= -2) ? rg_get_iteminfo(pItem, ItemInfo_iId) :iWeaponId);
	write_byte((iFlags <= -2) ? rg_get_iteminfo(pItem, ItemInfo_iFlags) :iFlags);
	message_end();
}

stock GetEyePosition(const pPlayer, Float:vecEyeLevel[3])
{
	static Float:vecOrigin[3]; get_entvar(pPlayer, var_origin, vecOrigin);
	static Float:vecViewOfs[3]; get_entvar(pPlayer, var_view_ofs, vecViewOfs);

	xs_vec_add(vecOrigin, vecViewOfs, vecEyeLevel);
}

stock GetVectorAiming(const pPlayer, Float:vecAiming[3]) 
{
	static Float:vecViewAngle[3]; get_entvar(pPlayer, var_v_angle, vecViewAngle);
	static Float:vecPunchAngle[3]; get_entvar(pPlayer, var_punchangle, vecPunchAngle);

	xs_vec_add(vecViewAngle, vecPunchAngle, vecViewAngle);
	angle_vector(vecViewAngle, ANGLEVECTOR_FORWARD, vecAiming);
}

stock Create_MuzzleFlash(const iPlayer, const szMuzzleClassname[], const szMuzzleModel[], Float:flScale, Float:flTransparency, Float:flFrameRate, Float:flMaxFrame)
{	
	new iMuzzleFlash = rg_create_entity(WeaponMuzzleFlash_EntityReference);
	
	engfunc(EngFunc_SetModel, iMuzzleFlash, szMuzzleModel);
	set_entvar(iMuzzleFlash, var_classname, szMuzzleClassname);
	set_entvar(iMuzzleFlash, var_spawnflags, SF_SPRITE_ONCE);
	set_entvar(iMuzzleFlash, var_aiment, iPlayer);
	set_entvar(iMuzzleFlash, var_owner, iPlayer);
	
	set_entvar(iMuzzleFlash, var_frame, 0.0);
	set_entvar(iMuzzleFlash, var_framerate, flFrameRate);
	set_entvar(iMuzzleFlash, var_fuser1, flMaxFrame);
	
	set_entvar(iMuzzleFlash, var_rendermode, kRenderTransAdd);
	set_entvar(iMuzzleFlash, var_renderamt, flTransparency);
	set_entvar(iMuzzleFlash, var_scale, flScale);
	set_entvar(iMuzzleFlash, var_body, 1);
	
	dllfunc(DLLFunc_Spawn, iMuzzleFlash);
	
	set_entvar(iMuzzleFlash, var_nextthink, get_gametime());
	SetThink(iMuzzleFlash, "MuzzleFlash_Think");
}
public MuzzleFlash_Think(const iMuzzleFlash) {
	if(iMuzzleFlash == NULLENT) return;
	
	static Float:flFrame; get_entvar(iMuzzleFlash, var_frame, flFrame);
	static Float:flFrameRate; get_entvar(iMuzzleFlash, var_framerate, flFrameRate);
	static Float:flMaxFrame; flMaxFrame = get_entvar(iMuzzleFlash, var_fuser1);
	
	if(flFrame < flMaxFrame) {
		set_entvar(iMuzzleFlash, var_frame, ++flFrame);
		set_entvar(iMuzzleFlash, var_nextthink, get_gametime() + flFrameRate);
		return;
	}
	else set_entvar(iMuzzleFlash, var_flags, FL_KILLME);
}

stock WeaponAnim(const iDest, const pReceiver, const pItem, const iAnim) {
	static iBody; iBody = get_entvar(pItem, var_body);
	set_entvar(pReceiver, var_weaponanim, iAnim);

	message_begin(iDest, SVC_WEAPONANIM, .player = pReceiver);
	write_byte(iAnim);
	write_byte(iBody);
	message_end();

	if (get_entvar(pReceiver, var_iuser1)) return;

	static i, iCount, pSpectator, aSpectators[MAX_PLAYERS];
	get_players(aSpectators, iCount, "bch");

	for (i = 0; i < iCount; i++) {
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

stock Get_Weapon_BoxItem(const pWeaponBox) {
	for (new iSlot, pItem; iSlot < MAX_ITEM_TYPES; iSlot++) {
		if (!is_nullent((pItem = get_member(pWeaponBox, m_WeaponBox_rgpPlayerItems, iSlot))))
			return pItem;
	}
	return NULLENT;
}

stock Precache_Sounds_From_Model(const szModelPath[]) {
	new pFile;
	if (!(pFile = fopen(szModelPath, "rt")))
		return;
	
	new szSoundPath[64];
	new iNumSeq, iSeqIndex;
	new iEvent, iNumEvents, iEventIndex;
	
	fseek(pFile, 164, SEEK_SET);
	fread(pFile, iNumSeq, BLOCK_INT);
	fread(pFile, iSeqIndex, BLOCK_INT);
	
	for (new i = 0; i < iNumSeq; i++) {
		fseek(pFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
		fread(pFile, iNumEvents, BLOCK_INT);
		fread(pFile, iEventIndex, BLOCK_INT);
		fseek(pFile, iEventIndex + 176 * i, SEEK_SET);
		
		for (new k = 0; k < iNumEvents; k++) {
			fseek(pFile, iEventIndex + 4 + 76 * k, SEEK_SET);
			fread(pFile, iEvent, BLOCK_INT);
			fseek(pFile, 4, SEEK_CUR);
			
			if (iEvent != 5004) continue;
			
			fread_blocks(pFile, szSoundPath, 64, BLOCK_CHAR);
			
			if (strlen(szSoundPath)) {
				strtolower(szSoundPath);
			#if AMXX_VERSION_NUM < 190
				format(szSoundPath, charsmax(szSoundPath), "sound/%s", szSoundPath);
				engfunc(EngFunc_PrecacheGeneric, szSoundPath);
			#else
				engfunc(EngFunc_PrecacheGeneric, fmt("sound/%s", szSoundPath));
			#endif
			}
		}
	}
	
	fclose(pFile);
}
stock Precache_WeaponList(const szWeaponList[]) {
	new szBuffer[128], pFile;

	format(szBuffer, charsmax(szBuffer), "sprites/%s.txt", szWeaponList);
	engfunc(EngFunc_PrecacheGeneric, szBuffer);

	if (!(pFile = fopen(szBuffer, "rb")))
		return;

	new szSprName[64], iPos;
	while (!feof(pFile)) 
	{
		fgets(pFile, szBuffer, charsmax(szBuffer));
		trim(szBuffer);

		if (!strlen(szBuffer)) 
			continue;

		if ((iPos = containi(szBuffer, "640")) == -1)
			continue;
				
		format(szBuffer, charsmax(szBuffer), "%s", szBuffer[iPos + 3]);		
		trim(szBuffer);

		strtok(szBuffer, szSprName, charsmax(szSprName), szBuffer, charsmax(szBuffer), ' ', 1);
		trim(szSprName);

	#if AMXX_VERSION_NUM < 190
		formatex(szBuffer, charsmax(szBuffer), "sprites/%s.spr", szSprName);
		engfunc(EngFunc_PrecacheGeneric, szBuffer);
	#else
		engfunc(EngFunc_PrecacheGeneric, fmt("sprites/%s.spr", szSprName));
	#endif
	}

	fclose(pFile);
}
