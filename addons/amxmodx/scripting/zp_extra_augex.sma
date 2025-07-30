#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <engine>

#define PLUGIN 					"[ZP] Extra: CSO Weapon Augex"
#define VERSION 				"1.0"
#define AUTHOR 					"KORD_12.7"

#pragma ctrlchar '\'

//**********************************************
//* Weapon Settings.                           *
//**********************************************

#define WPNLIST
#define LIGHT 

// Main
#define WEAPON_KEY				794834
#define WEAPON_NAME 				"weapon_augex"

#define WEAPON_DAMAGE  	  			1.0
#define WEAPON_REFERANCE			"weapon_ak47"
#define WEAPON_MAX_CLIP				30
#define WEAPON_DEFAULT_AMMO			90
#define RADIUS_DMG 				300.0	
#define DMG_EXP 				450.0	
#define WEAPON_PUNCHANGLE 			-2.0

#define WEAPON_TIME_NEXT_IDLE 			10.0
#define WEAPON_TIME_NEXT_ATTACK 		0.1 
#define WEAPON_TIME_NEXT_ATTACK_B 		3.5
#define WEAPON_TIME_DELAY_DEPLOY 		1.0
#define WEAPON_TIME_DELAY_RELOAD 		3.0

#define ZP_ITEM_NAME				"Burning Aug" 
#define ZP_ITEM_COST				35

// Models
#define MODEL_WORLD				"models/w_augex.mdl"
#define MODEL_VIEW				"models/v_augex.mdl"
#define MODEL_PLAYER				"models/p_augex.mdl"

// Sounds
#define SOUND_FIRE				"weapons/augex-1.wav"
#define SOUND_FIRE_B				"weapons/augex_shoot3.wav"

// Sprites
#define WEAPON_HUD_TXT				"sprites/weapon_augex.txt"
#define WEAPON_HUD_SPR_1			"sprites/640hud160.spr"
#define WEAPON_HUD_SPR_2			"sprites/640hud7.spr"
#define WEAPON_HUD_SPR_3			"sprites/640hud2.spr"

// Animation
#define ANIM_EXTENSION				"carbine"

// Animation sequences
enum
{	
	ANIM_IDLE,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT,
	ANIM_SHOOT_USELESS,
	ANIM_SHOOT2,
	ANIM_SHOOT_EMPTY
};
//**********************************************
//* Some macroses.                             *
//**********************************************

#define MDLL_Spawn(%0)			dllfunc(DLLFunc_Spawn, %0)
#define MDLL_Touch(%0,%1)		dllfunc(DLLFunc_Touch, %0, %1)
#define MDLL_USE(%0,%1)			dllfunc(DLLFunc_Use, %0, %1)

#define SET_MODEL(%0,%1)		engfunc(EngFunc_SetModel, %0, %1)
#define SET_ORIGIN(%0,%1)		engfunc(EngFunc_SetOrigin, %0, %1)

#define PRECACHE_MODEL(%0)		engfunc(EngFunc_PrecacheModel, %0)
#define PRECACHE_SOUND(%0)		engfunc(EngFunc_PrecacheSound, %0)
#define PRECACHE_GENERIC(%0)		engfunc(EngFunc_PrecacheGeneric, %0)

#define MESSAGE_BEGIN(%0,%1,%2,%3)	engfunc(EngFunc_MessageBegin, %0, %1, %2, %3)
#define MESSAGE_END()			message_end()

#define WRITE_ANGLE(%0)			engfunc(EngFunc_WriteAngle, %0)
#define WRITE_BYTE(%0)			write_byte(%0)
#define WRITE_COORD(%0)			engfunc(EngFunc_WriteCoord, %0)
#define WRITE_STRING(%0)		write_string(%0)
#define WRITE_SHORT(%0)			write_short(%0)

#define BitSet(%0,%1) 			(%0 |= (1 << (%1 - 1)))
#define BitClear(%0,%1) 		(%0 &= ~(1 << (%1 - 1)))
#define BitCheck(%0,%1) 		(%0 & (1 << (%1 - 1)))

//**********************************************
//* PvData Offsets.                            *
//**********************************************

// Linux extra offsets
#define extra_offset_weapon		4
#define extra_offset_player		5

new g_bitIsConnected;

#define m_rgpPlayerItems_CWeaponBox	34

// CBasePlayerItem
#define m_pPlayer			41
#define m_pNext				42
#define m_iId                        	43

// CBasePlayerWeapon
#define m_fInSuperBullets		30
#define m_fInCheckShoots		39
#define m_fFireOnEmpty 			45
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle		48
#define m_iPrimaryAmmoType		49
#define m_iClip				51
#define m_fInReload			54
#define m_flAccuracy 			62
#define m_iLastZoom 			109

// CBaseMonster
#define m_flNextAttack			83

// CBasePlayer
#define m_fResumeZoom       		110
#define m_iFOV				363
#define m_rgpPlayerItems_CBasePlayer	367
#define m_pActiveItem			373
#define m_rgAmmo_CBasePlayer		376
#define m_szAnimExtention		492

#define IsValidPev(%0) 			(pev_valid(%0) == 2)

#define INSTANCE(%0)			((%0 == -1) ? 0 : %0)

#define IsCustomItem(%0) 		(pev(%0, pev_impulse) == WEAPON_KEY)

//**********************************************
//* Let's code our weapon.                     *
//**********************************************
new const GRENADE_MODEL[] = "models/grenade.mdl"
new const GRENADE_TRAIL[] = "sprites/laserbeam.spr"
new const GRENADE_EXPLOSION[] = "sprites/zerogxplode.spr"

new sTrail, sExplo
new iBlood[3];

Weapon_OnPrecache()
{
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_SOUNDS_FROM_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_PLAYER);
	sTrail = precache_model(GRENADE_TRAIL);
	sExplo = precache_model(GRENADE_EXPLOSION);
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_FIRE_B);
	
	#if defined WPNLIST
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_1);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_2);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_3);
	#endif
	
	iBlood[0] = PRECACHE_MODEL("sprites/bloodspray.spr");
	iBlood[1] = PRECACHE_MODEL("sprites/blood.spr");
	iBlood[2] = PRECACHE_MODEL("sprites/smoke.spr");
}

Weapon_OnSpawn(const iItem)
{
	// Setting world model.
	SET_MODEL(iItem, MODEL_WORLD);
}

Weapon_OnDeploy(const iItem, const iPlayer, const iClip, const iShoots, const iCheckShoots, const iAmmoPrimary)
{
	#pragma unused iClip, iCheckShoots, iAmmoPrimary
		
	static iszViewModel;
	if (iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, MODEL_VIEW)))
	{
		set_pev_string(iPlayer, pev_viewmodel2, iszViewModel);
	}
	
	static iszPlayerModel;
	if (iszPlayerModel || (iszPlayerModel = engfunc(EngFunc_AllocString, MODEL_PLAYER)))
	{
		set_pev_string(iPlayer, pev_weaponmodel2, iszPlayerModel);
	}

	set_pdata_int(iItem, m_fInReload, 0, extra_offset_weapon);

	set_pdata_string(iPlayer, m_szAnimExtention * 4, ANIM_EXTENSION, -1, extra_offset_player * 4);
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_DEPLOY, extra_offset_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_DEPLOY, extra_offset_player);

	Weapon_DefaultDeploy(iPlayer, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
	
	SetExtraAmmo(iPlayer, iShoots);
	MsgHook_WeaponList(iItem, iPlayer, 1, iShoots);
}

Weapon_OnHolster(const iItem, const iPlayer, const iClip, const iShoots, const iCheckShoots, const iAmmoPrimary)
{
	#pragma unused iPlayer, iClip, iCheckShoots, iAmmoPrimary
	
	set_pdata_int(iItem, m_fInReload, 0, extra_offset_weapon);
	set_pdata_int(iItem, m_fInCheckShoots, 0, extra_offset_weapon);
	if(!user_has_weapon(iPlayer,28,-1))
	{	
		SetExtraAmmo(iPlayer, 0);
		MsgHook_WeaponList(iItem, iPlayer, -1, iShoots);
	}
}

Weapon_OnIdle(const iItem, const iPlayer, const iClip, const iShoots, const iCheckShoots, const iAmmoPrimary)
{
	#pragma unused iClip, iCheckShoots, iAmmoPrimary, iShoots

	ExecuteHamB(Ham_Weapon_ResetEmptySound, iItem);
	
	if (get_pdata_float(iItem, m_flTimeWeaponIdle, extra_offset_weapon) > 0.0)
	{
		return;
	}
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_IDLE, extra_offset_weapon);
	
	Weapon_SendAnim(iPlayer, ANIM_IDLE);
}

Weapon_OnReload(const iItem, const iPlayer, const iClip, const iShoots, const iCheckShoots, const iAmmoPrimary)
{
	#pragma unused iCheckShoots, iAmmoPrimary, iShoots
	
	if (min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary) <= 0)
	{
		return;
	}
	
	set_pdata_int(iItem, m_iClip, 0, extra_offset_weapon);
	
	ExecuteHam(Ham_Weapon_Reload, iItem);
	
	set_pdata_int(iItem, m_iClip, iClip, extra_offset_weapon);
	
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_RELOAD, extra_offset_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_RELOAD, extra_offset_weapon);
	
	Weapon_SendAnim(iPlayer, ANIM_RELOAD);
}

Weapon_OnPrimaryAttack(const iItem, const iPlayer, const iClip, const iShoots, const iCheckShoots, const iAmmoPrimary)
{
	#pragma unused iAmmoPrimary, iCheckShoots, iShoots
	
	CallOrigFireBullets3(iItem, iPlayer);
	
	if (iClip <= 0)
	{
		if (get_pdata_int(iItem, m_fFireOnEmpty, extra_offset_player))
		{
			ExecuteHamB(Ham_Weapon_PlayEmptySound, iItem);
			set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, extra_offset_weapon);
		}
		return;
	}
	
	static iFlags, iAnimDesired; 
	static szAnimation[64];iFlags = pev(iPlayer, pev_flags);
	
	Weapon_SendAnim(iPlayer, ANIM_SHOOT);
				
	formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXTENSION);
								
	if ((iAnimDesired = lookup_sequence(iPlayer, szAnimation)) == -1)
	{
		iAnimDesired = 0;
	}
					
	set_pev(iPlayer, pev_sequence, iAnimDesired);
	static Float:punchAngle[3];
	punchAngle[0] = WEAPON_PUNCHANGLE;
	punchAngle[1] = float(random_num(-100, 100)) / 100.0;
	punchAngle[2] = 0.0;
	set_pev(get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon), pev_punchangle, punchAngle);
	set_pdata_float(iItem, m_flAccuracy, 0.2 ,extra_offset_weapon)
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_ATTACK + 0.6, extra_offset_weapon);
	
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
}

Weapon_OnSecondaryAttack(const iItem, const iPlayer, const iClip, const iShoots, const iCheckShoots, const iAmmoPrimary)
{
	#pragma unused iClip, iCheckShoots, iAmmoPrimary
	
	if (iShoots <= 0)
	{
		if (get_pdata_int(iItem, m_fFireOnEmpty, extra_offset_player))
		{
			ExecuteHamB(Ham_Weapon_PlayEmptySound, iItem);
			set_pdata_float(iItem, m_flNextSecondaryAttack, 0.2, extra_offset_weapon);
		}
	
		return;
	}
	
	static iFlags, iAnimDesired; 
	static szAnimation[64];iFlags = pev(iPlayer, pev_flags);
	MakeRecoil(pev(iItem, pev_owner))
	Weapon_SendAnim(iPlayer, ANIM_SHOOT2);
				
	formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXTENSION);
								
	if ((iAnimDesired = lookup_sequence(iPlayer, szAnimation)) == -1)
	{
		iAnimDesired = 0;
	}
			
	set_pev(iPlayer, pev_sequence, iAnimDesired);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK_B, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_TIME_NEXT_ATTACK_B, extra_offset_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_ATTACK_B + 0.6, extra_offset_weapon);

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE_B, 0.9, ATTN_NORM, 0, PITCH_NORM);
	if(iShoots==1)
	{
		Weapon_SendAnim(iPlayer, ANIM_SHOOT_EMPTY);
	}
	else
	{
		Weapon_SendAnim(iPlayer, ANIM_SHOOT2);
	}
	set_pdata_int(iItem, m_fInSuperBullets, (iShoots-1), extra_offset_weapon);
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE_B, 0.9, ATTN_NORM, 0, PITCH_NORM);
	SetExtraAmmo(iPlayer, iShoots-1);
	FireGrenade(iPlayer)
}
public MakeRecoil(id)
{
	static Float:punchAngle[3];
	punchAngle[0] = -4.0;
	punchAngle[1] = float(random_num(-600, 600)) / 100.0;
	punchAngle[2] = 0.0;
	set_pev(id, pev_punchangle, punchAngle);
}

//*********************************************************************
//*           Don't modify the code below this line unless            *
//*          	 you know _exactly_ what you are doing!!!             *
//*********************************************************************

#define MSGID_WEAPONLIST 78

new g_iItemID;
#define IsCustomItem(%0) (pev(%0, pev_impulse) == WEAPON_KEY)

public plugin_precache()
{
	Weapon_OnPrecache();
	
	#if defined WPNLIST
	register_clcmd(WEAPON_NAME, "Cmd_WeaponSelect");
	#endif
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_logevent("NewRound", 2, "1=Round_Start")
	register_forward(FM_UpdateClientData,				"FakeMeta_UpdateClientData_Post",true);
	register_forward(FM_PlaybackEvent,				"FakeMeta_PlaybackEvent",	 false);
	register_forward(FM_SetModel,					"FakeMeta_SetModel",		 false);
	RegisterHam(Ham_Spawn, 			"weaponbox", 		"HamHook_Weaponbox_Spawn_Post", true);

	RegisterHam(Ham_TraceAttack,		"func_breakable",	"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_TraceAttack,		"info_target", 		"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_TraceAttack,		"player", 		"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_Touch,					"info_target",		"touch", false);
	RegisterHam(Ham_Item_Deploy,		WEAPON_REFERANCE, 	"HamHook_Item_Deploy_Post",	true);
	RegisterHam(Ham_Item_Holster,		WEAPON_REFERANCE, 	"HamHook_Item_Holster",		false);
	RegisterHam(Ham_Item_AddToPlayer,	WEAPON_REFERANCE, 	"HamHook_Item_AddToPlayer",	false);
	RegisterHam(Ham_Item_PostFrame,		WEAPON_REFERANCE, 	"HamHook_Item_PostFrame",	false);
	RegisterHam(Ham_Weapon_Reload,		WEAPON_REFERANCE, 	"HamHook_Item_Reload",		false);
	RegisterHam(Ham_Weapon_WeaponIdle,	WEAPON_REFERANCE, 	"HamHook_Item_WeaponIdle",	false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERANCE, 	"HamHook_Item_PrimaryAttack",	false);	
	g_iItemID = zp_register_extra_item(	ZP_ITEM_NAME, 		ZP_ITEM_COST, 			ZP_TEAM_HUMAN);
}
public FireGrenade(id)
{
	static Float:origin[3],Float:velocity[3],Float:angles[3]
	pev(id,pev_angles,angles)
	static ent; ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	get_weapon_position(id, origin, 10.0, get_cvar_num("cl_righthand")?8.0: -8.0, -5.0)
	set_pev( ent, pev_classname, "augex_grenade" )
	set_pev( ent, pev_solid, SOLID_BBOX )
	set_pev( ent, pev_movetype, MOVETYPE_TOSS )
	engfunc ( EngFunc_SetSize  , ent, Float:{ -0.1, -0.1, -0.1 }, Float:{ 0.1, 0.1, 0.1 } );
	engfunc ( EngFunc_SetModel , ent, GRENADE_MODEL );
	engfunc ( EngFunc_SetOrigin, ent, origin );
	set_pev( ent, pev_angles, angles )
	set_pev( ent, pev_owner, id )
	set_pev( ent, pev_nextthink, get_gametime( ))
	set_pev(ent, pev_speed, velocity) 
	velocity_by_aim( id,1500,velocity )
	set_pev( ent, pev_velocity, velocity )
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // Temporary entity ID
	write_short(ent) // Entity
	write_short(sTrail) // Sprite index
	write_byte(3) // Life
	write_byte(3) // Line width
	write_byte(255) // Red
	write_byte(255) // Green
	write_byte(255) // Blue
	write_byte(100) // Alpha
	message_end() 
}
public touch(ptr, ptd)
{
	// If ent is valid
	if (pev_valid(ptr))
	{	
		// Get classnames
		static classname[32]
		pev(ptr, pev_classname, classname, 31)
		// Our ent
		if(equal(classname, "augex_grenade"))
		{
			// Get it's origin
			new Float:originF[3]
			pev(ptr, pev_origin, originF)
			engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0)
			write_byte(TE_WORLDDECAL)
			engfunc(EngFunc_WriteCoord, originF[0])
			engfunc(EngFunc_WriteCoord, originF[1])
			engfunc(EngFunc_WriteCoord, originF[2])
			write_byte(engfunc(EngFunc_DecalIndex,"{scorch3"))
			message_end()
			// Draw explosion
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION) // Temporary entity ID
			engfunc(EngFunc_WriteCoord, originF[0]) // engfunc because float
			engfunc(EngFunc_WriteCoord, originF[1])
			engfunc(EngFunc_WriteCoord, originF[2])
			write_short(sExplo) // Sprite index
			write_byte(45) // Scale
			write_byte(25) // Framerate
			write_byte(0) // Flags
			message_end()	
			static classnameptd[32]; pev(ptd, pev_classname, classnameptd, 31);
			if (equali(classnameptd, "func_breakable")) ExecuteHamB(Ham_TakeDamage, ptd, 0, 0, 500.0, DMG_GENERIC);
			static pOwner; pOwner = pev(ptr,pev_owner);
			static pevVictim, Float:flDistance,Float:fDamage;          
			pevVictim  = FM_NULLENT;
			while((pevVictim = engfunc(EngFunc_FindEntityInSphere, pevVictim, originF, RADIUS_DMG)) != 0)
			{
				flDistance = entity_range(ptr,pevVictim);
				fDamage = floatsub(DMG_EXP,floatmul(floatdiv(DMG_EXP,RADIUS_DMG),flDistance));	
				if(!is_user_alive(pevVictim))
					continue;
				if( !zp_get_user_zombie(pevVictim))
					continue;
				if(fDamage > 0.0)
				{
					ExecuteHamB(Ham_TakeDamage, pevVictim, ptr, pOwner, fDamage, DMG_BULLET);
				}
				//���� ������ �������� ������ ������ � ����� ��� ��������� �����
				//message_begin ( MSG_ONE_UNRELIABLE, get_user_msgid ( "ScreenShake" ), {0,0,0}, pevVictim)
				//write_short ( 0xFFFF ) // Amplitude
				//write_short ( 1<<13 ) // Duration
				//write_short ( 0xFFFF ) // Frequency
				//message_end ( )
			}
			engfunc( EngFunc_RemoveEntity, ptr );
		}
	}
}
public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_iItemID)
	{
		static iShoots; iShoots = get_pdata_int(id, m_fInSuperBullets, extra_offset_weapon)
		Weapon_Give(id, iShoots);
	}
}

public plugin_natives()
{ 
	register_native("GetAugex", "NativeGiveWeapon", true) 
}

public NativeGiveWeapon(iPlayer, iShoots)
{
	Weapon_Give(iPlayer, iShoots);
}
public FakeMeta_UpdateClientData_Post(const iPlayer, const iSendWeapons, const CD_Handle)
{
	static iActiveItem;iActiveItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);
	
	if (!IsValidPev(iActiveItem) || !IsCustomItem(iActiveItem))
	{
		return FMRES_IGNORED;
	}

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
	return FMRES_IGNORED;
}


//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

	#define _call.%0(%1,%2) \
									\
	Weapon_On%0							\
	(								\
		%1, 							\
		%2,							\
									\
		get_pdata_int(%1, m_iClip, extra_offset_weapon),	\
		get_pdata_int(%1, m_fInSuperBullets, extra_offset_weapon), \
		get_pdata_int(iItem, m_fInCheckShoots, extra_offset_weapon), \
		GetAmmoInventory(%2, PrimaryAmmoIndex(%1))		\
	) 
public NewRound()
{
	new iPlayer, iItem, iShoots;
	iShoots = get_pdata_int(iItem, m_fInSuperBullets, extra_offset_weapon)
	if(!CheckItem(iItem, iPlayer)) 
	{
		return HAM_IGNORED;
	}
	SetExtraAmmo(iPlayer, iShoots);
	return HAM_SUPERCEDE;
}
public HamHook_Item_Deploy_Post(const iItem)
{
	new iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.Deploy(iItem, iPlayer);
	return HAM_IGNORED;
}

public HamHook_Item_Holster(const iItem)
{
	new iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	set_pev(iPlayer, pev_viewmodel, 0);
	set_pev(iPlayer, pev_weaponmodel, 0);
	
	_call.Holster(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_WeaponIdle(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}

	_call.Idle(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_Reload(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.Reload(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_PrimaryAttack(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	_call.PrimaryAttack(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_PostFrame(const iItem)
{
	static iPlayer;
	static iButton;
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}

	if (get_pdata_int(iItem, m_fInReload, extra_offset_weapon))
	{
		new iClip		= get_pdata_int(iItem, m_iClip, extra_offset_weapon); 
		new iPrimaryAmmoIndex	= PrimaryAmmoIndex(iItem);
		new iAmmoPrimary	= GetAmmoInventory(iPlayer, iPrimaryAmmoIndex);
		new iAmount		= min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary);
		
		set_pdata_int(iItem, m_iClip, iClip + iAmount, extra_offset_weapon);
		set_pdata_int(iItem, m_fInReload, false, extra_offset_weapon);

		SetAmmoInventory(iPlayer, iPrimaryAmmoIndex, iAmmoPrimary - iAmount);
	}
	
	if ((iButton = pev(iPlayer, pev_button)) & IN_ATTACK2 && get_pdata_float(iItem, m_flNextSecondaryAttack, extra_offset_weapon) <= 0.0)
	{
		_call.SecondaryAttack(iItem, iPlayer);
		set_pev(iPlayer, pev_button, iButton & ~IN_ATTACK2);
	}
	
	return HAM_IGNORED;
}	

//**********************************************
//* Fire Bullets.                              *
//**********************************************

CallOrigFireBullets3(const iItem, const iPlayer)
{
	static fm_hooktrace;fm_hooktrace=register_forward(FM_TraceLine,"FakeMeta_TraceLine",true)
	
	state FireBullets: Enabled;
	static Float: vecPuncheAngle[3];
	pev(iPlayer, pev_punchangle, vecPuncheAngle);
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	set_pev(iPlayer, pev_punchangle, vecPuncheAngle);
	state FireBullets: Disabled;
	
	unregister_forward(FM_TraceLine,fm_hooktrace,true)
}

public FakeMeta_PlaybackEvent() <FireBullets: Enabled>
{
	return FMRES_SUPERCEDE;
}

public FakeMeta_TraceLine(Float:vecStart[3], Float:VecEnd[3], iFlags, Ignore, iTrase)// Chrescoe1
{
	if (iFlags & IGNORE_MONSTERS)
	{
		return FMRES_IGNORED;
	}
	
	static iHit;
	static Decal;
	static glassdecal;
	static Float:vecPlaneNormal[3];
	static Float:vecEndPos[3];
	
	iHit=get_tr2(iTrase,TR_pHit);
	
	if (!glassdecal)
	{
		glassdecal=engfunc( EngFunc_DecalIndex, "{bproof1" );
	}
	
	if(iHit>0 && pev_valid(iHit))
		if(pev(iHit,pev_solid)!=SOLID_BSP)return FMRES_IGNORED;
		else if(pev(iHit,pev_rendermode)!=0)Decal=glassdecal;
		else Decal=random_num(41,45);
	else Decal=random_num(41,45);
	
	get_tr2(iTrase, TR_vecEndPos, vecEndPos);
	get_tr2(iTrase, TR_vecPlaneNormal, vecPlaneNormal);
	
	MESSAGE_BEGIN(MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
	WRITE_BYTE(TE_GUNSHOTDECAL);
	WRITE_COORD(vecEndPos[0]);
	WRITE_COORD(vecEndPos[1]);
	WRITE_COORD(vecEndPos[2]);
	WRITE_SHORT(iHit > 0 ? iHit : 0);
	WRITE_BYTE(Decal);
	MESSAGE_END();
	
	MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, vecEndPos, 0);
	WRITE_BYTE(TE_STREAK_SPLASH)
	WRITE_COORD(vecEndPos[0]);
	WRITE_COORD(vecEndPos[1]);
	WRITE_COORD(vecEndPos[2]);
	WRITE_COORD(vecPlaneNormal[0] * random_float(20.0,30.0));
	WRITE_COORD(vecPlaneNormal[1] * random_float(20.0,30.0));
	WRITE_COORD(vecPlaneNormal[2] * random_float(20.0,30.0));
	WRITE_BYTE(198);	//Colorid
	WRITE_SHORT(10);	//Count
	WRITE_SHORT(3);		//Speed
	WRITE_SHORT(60);	//Random speed
	MESSAGE_END();

	return FMRES_IGNORED;
}

public HamHook_Entity_TraceAttack(const iEntity, const iAttacker, const Float: flDamage) <FireBullets: Enabled>
{
	static iItem;

	if (!BitCheck(g_bitIsConnected, iAttacker) || !IsValidPev(iAttacker))
	{
		return;
	}
	
	iItem = get_pdata_cbase(iAttacker, m_pActiveItem, extra_offset_player);
	
	if (!IsValidPev(iItem))
	{
		return;
	}
	
	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

public MsgHook_Death()			</* Empty statement */>		{ /* Fallback */ }
public MsgHook_Death()			<FireBullets: Disabled>		{ /* Do notning */ }

public FakeMeta_PlaybackEvent() 	</* Empty statement */>		{ return FMRES_IGNORED; }
public FakeMeta_PlaybackEvent() 	<FireBullets: Disabled>		{ return FMRES_IGNORED; }

public HamHook_Entity_TraceAttack() 	</* Empty statement */>		{ /* Fallback */ }
public HamHook_Entity_TraceAttack() 	<FireBullets: Disabled>		{ /* Do notning */ }

Weapon_Create(const Float: vecOrigin[3] = {0.0, 0.0, 0.0}, const Float: vecAngles[3] = {0.0, 0.0, 0.0})
{
	new iWeapon;

	static iszAllocStringCached;
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, WEAPON_REFERANCE)))
	{
		iWeapon = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (!IsValidPev(iWeapon))
	{
		return FM_NULLENT;
	}
	
	MDLL_Spawn(iWeapon);
	SET_ORIGIN(iWeapon, vecOrigin);
	
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, extra_offset_weapon);
	set_pdata_int(iWeapon, m_fInSuperBullets, 0, extra_offset_weapon);
	set_pdata_int(iWeapon, m_fInCheckShoots, 0, extra_offset_weapon);
	
	set_pev(iWeapon, pev_impulse, WEAPON_KEY);
	set_pev(iWeapon, pev_angles, vecAngles);
	
	Weapon_OnSpawn(iWeapon);
	
	return iWeapon;
}

Weapon_Give(const iPlayer, const iShoots)
{
	if (!IsValidPev(iPlayer))
	{
		return FM_NULLENT;
	}
	new iWeapon, Float: vecOrigin[3];
	pev(iPlayer, pev_origin, vecOrigin);
	
	if ((iWeapon = Weapon_Create(vecOrigin)) != FM_NULLENT)
	{
		Player_DropWeapons(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));
		
		set_pev(iWeapon, pev_spawnflags, pev(iWeapon, pev_spawnflags) | SF_NORESPAWN);
		MDLL_Touch(iWeapon, iPlayer);
		set_pdata_int(iWeapon, m_fInSuperBullets, (iShoots+10), extra_offset_weapon);
		SetExtraAmmo(iPlayer, (iShoots+10));
		SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iWeapon), WEAPON_DEFAULT_AMMO);
		
		return iWeapon;
	}
	
	return FM_NULLENT;
}

Player_DropWeapons(const iPlayer, const iSlot)
{
	new szWeaponName[32], iItem = get_pdata_cbase(iPlayer, m_rgpPlayerItems_CBasePlayer + iSlot, extra_offset_player);

	while (IsValidPev(iItem))
	{
		pev(iItem, pev_classname, szWeaponName, charsmax(szWeaponName));
		engclient_cmd(iPlayer, "drop", szWeaponName);

		iItem = get_pdata_cbase(iItem, m_pNext, extra_offset_weapon);
	}
}

Weapon_SendAnim(const iPlayer, const iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, iPlayer);
	WRITE_BYTE(iAnim);
	WRITE_BYTE(0);
	MESSAGE_END();
}
stock Weapon_DefaultDeploy(const iPlayer, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[])
{
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	set_pev(iPlayer, pev_weaponmodel2, szWeaponModel);
	set_pev(iPlayer, pev_fov, 90.0);
	
	set_pdata_int(iPlayer, m_iFOV, 90, extra_offset_player);
	set_pdata_int(iPlayer, m_fResumeZoom, 0, extra_offset_player);
	set_pdata_int(iPlayer, m_iLastZoom, 90, extra_offset_player);
	
	set_pdata_string(iPlayer, m_szAnimExtention * 4, szAnimExt, -1, extra_offset_player * 4);
	
	Weapon_SendAnim(iPlayer, iAnim);
}

stock SetExtraAmmo(const iPlayer, const iClip)
{
	MESSAGE_BEGIN(MSG_ONE, get_user_msgid("AmmoX"), {0.0,0.0,0.0}, iPlayer);
	WRITE_BYTE(1);
	WRITE_BYTE(iClip);
	MESSAGE_END();
}

stock Player_SetAnimation(const iPlayer, const szAnim[])
{
	   if(!is_user_alive(iPlayer))return;
		
	   #define ACT_RANGE_ATTACK1   28
	   
	   // Linux extra offsets
	   #define extra_offset_animating   4
	   
	   // CBaseAnimating
	   #define m_flFrameRate      36
	   #define m_flGroundSpeed      37
	   #define m_flLastEventCheck   38
	   #define m_fSequenceFinished   39
	   #define m_fSequenceLoops   40
	   
	   // CBaseMonster
	   #define m_Activity      73
	   #define m_IdealActivity      74
	   
	   // CBasePlayer
	   #define m_flLastAttackTime   220
	   
	   new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
	      
	   if ((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
	   {
	      iAnimDesired = 0;
	   }
   
	   new Float: flGametime = get_gametime();
	
	   set_pev(iPlayer, pev_frame, 0.0);
	   set_pev(iPlayer, pev_framerate, 1.0);
	   set_pev(iPlayer, pev_animtime, flGametime );
	   set_pev(iPlayer, pev_sequence, iAnimDesired);
	   
	   set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, extra_offset_animating);
	   set_pdata_int(iPlayer, m_fSequenceFinished, 0, extra_offset_animating);
	   
	   set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, extra_offset_animating);
	   set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, extra_offset_animating);
	   set_pdata_float(iPlayer, m_flLastEventCheck, flGametime , extra_offset_animating);
	   
	   set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, extra_offset_player);
	   set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, extra_offset_player);   
	   set_pdata_float(iPlayer, m_flLastAttackTime, flGametime , extra_offset_player);
}

public client_putinserver(id)
{
	BitSet(g_bitIsConnected, id);
}

public client_disconnect(id)
{
	BitClear(g_bitIsConnected, id);
}

//**********************************************
//* Weapon list update.                        *
//**********************************************

#if defined WPNLIST
public Cmd_WeaponSelect(const iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERANCE);
	return PLUGIN_HANDLED;
}
#endif

public HamHook_Item_AddToPlayer(const iItem, const iPlayer, const iShoots)
{
	switch(pev(iItem, pev_impulse))
	{
		case 0: 
		{
			#if defined WPNLIST
			MsgHook_WeaponList(iItem, iPlayer, -1, 0);
			#endif
		}
		case WEAPON_KEY: 
		{
			#if defined WPNLIST
			MsgHook_WeaponList(iItem, iPlayer, 1, iShoots);
			#endif
			SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem), pev(iItem, pev_iuser2));
		}
	}
	
	return HAM_IGNORED;
}

public MsgHook_WeaponList(iItem, iPlayer, iByte, iShoots)
{
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, iPlayer);
	write_string(IsCustomItem(iItem) ? WEAPON_NAME : WEAPON_REFERANCE);
	write_byte(2);
	write_byte(90);
	write_byte(iByte);
	write_byte(10);
	write_byte(0);
	write_byte(1);
	write_byte(CSW_AK47);
	write_byte(0);
	message_end();
}


//**********************************************
//* Weaponbox world model.                     *
//**********************************************

public HamHook_Weaponbox_Spawn_Post(const iWeaponBox)
{
	if (IsValidPev(iWeaponBox))
	{
		state (IsValidPev(pev(iWeaponBox, pev_owner))) WeaponBox: Enabled;
	}
	
	return HAM_IGNORED;
}

public FakeMeta_SetModel(const iEntity) <WeaponBox: Enabled>
{
	state WeaponBox: Disabled;
	
	if (!IsValidPev(iEntity))
	{
		return FMRES_IGNORED;
	}
	
	#define MAX_ITEM_TYPES	6
	
	for (new i, iItem; i < MAX_ITEM_TYPES; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, extra_offset_weapon);
		
		if (IsValidPev(iItem) && IsCustomItem(iItem))
		{
			SET_MODEL(iEntity, MODEL_WORLD);	
			set_pev(iItem, pev_iuser2, GetAmmoInventory(pev(iEntity,pev_owner), PrimaryAmmoIndex(iItem)))
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public FakeMeta_SetModel()	</* Empty statement */>	{ /*  Fallback  */ return FMRES_IGNORED; }
public FakeMeta_SetModel() 	< WeaponBox: Disabled >	{ /* Do nothing */ return FMRES_IGNORED; }

//**********************************************
//* Ammo Inventory.                            *
//**********************************************

PrimaryAmmoIndex(const iItem)
{
	return get_pdata_int(iItem, m_iPrimaryAmmoType, extra_offset_weapon);
}

GetAmmoInventory(const iPlayer, const iAmmoIndex)
{
	if (iAmmoIndex == -1)
	{
		return -1;
	}

	return get_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, extra_offset_player);
}

SetAmmoInventory(const iPlayer, const iAmmoIndex, const iAmount)
{
	if (iAmmoIndex == -1)
	{
		return 0;
	}

	set_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, iAmount, extra_offset_player);
	return 1;
}

bool: CheckItem(const iItem, &iPlayer)
{
	if (!IsValidPev(iItem) || !IsCustomItem(iItem))
	{
		return false;
	}
	
	iPlayer = get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon);
	
	if (!IsValidPev(iPlayer) || !BitCheck(g_bitIsConnected, iPlayer))
	{
		return false;
	}
	
	return true;
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
	
	fOrigin[0]= fOrigin[0] + Forward[0] + Right[0] + Up[0]
	fOrigin[1] = fOrigin[1] + Forward[1] + Right[1] + Up[1]
	fOrigin[2] = fOrigin[2] + Forward[2] + Right[2] + Up[2]
}

PRECACHE_SOUNDS_FROM_MODEL(const szModelPath[])
{
	new iFile;
	
	if ((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for (new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);

			for (k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if (iEvent != 5004)
				{
					continue;
				}

				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if (strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					PRECACHE_SOUND(szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
