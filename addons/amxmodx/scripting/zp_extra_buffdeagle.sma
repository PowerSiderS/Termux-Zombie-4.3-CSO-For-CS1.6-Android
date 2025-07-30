#include < amxmodx >
#include < fakemeta_util >
#include < engine >
#include < hamsandwich >
#include < xs >

#include < zombieplague >
#include < ColorChat >

#define weapon_name				"weapon_deagle"
#define weapon_new				"zmo/weapon_bloodhunter"

#define IDLE_TIME				2.03
#define DRAW_TIME				1.26
#define RELOAD_TIME				3.53
#define FIRE_TIME				1.03
#define THROW_TIME				0.86
#define CHARGE_TIME				1.36

#define ACT_RANGE_ATTACK1		28

#define LunDiff_Player			5
#define LunDiff_Item			4

#define m_rgpPlayerItems		34

#define m_flFrameRate			36
#define m_flGroundSpeed			37
#define m_flLastEventCheck		38
#define m_fSequenceFinished		39
#define m_fSequenceLoops		40

#define m_pPlayer				41
#define m_pNext					42
#define m_iId					43

#define m_flNextPrimaryAttack	46
#define m_flNextSecondaryAttack	47
#define m_flTimeWeaponIdle		48
#define m_iPrimaryAmmoType		49
#define m_iClip					51
#define m_fInReload				54
#define m_fInSpecialReload		55
#define m_fWeaponState			74
#define m_iShotsFired			64
#define m_iFOV					363

#define m_Activity				73
#define m_IdealActivity			74

#define m_LastHitGroup			75
#define m_flNextAttack			83

#define m_rpgPlayerItems		367
#define m_pActiveItem			373	
#define m_rgAmmo				376
#define m_flEjectBrass			111
#define m_iShellLate			57 

#define m_flLastAttackTime		220
#define m_szAnimExtention		1968

#define WEAPON_KEY				123132
#define Is_CustomItem(%0)		(pev(%0,pev_impulse)==WEAPON_KEY)

#define model_v					"models/zmo/v_bloodhunter.mdl"
#define model_p					"models/zmo/p_bloodhunter.mdl"
#define model_w					"models/zmo/w_bloodhunter.mdl"
#define model_s					"models/zmo/s_bloodhunter.mdl"
#define WEAPON_BODY 10

#define sound_fire				"weapons/bloodhunter-1.wav"
#define sound_throw				"weapons/bloodhunter_throwa.wav"
#define sound_up				"weapons/bloodhunter_change.wav"

#define blood_null				0
#define blood_small				5
#define blood_half				10
#define blood_full				15

new g_AllocString_V,g_AllocString_P;
new g_Blood[512],g_Status[512];
new sExplo;
new gMaxPlayers;
new Msg_WeaponList;
new Cvar[7];

enum {
	IDLE_NULL1,
	IDLE_SMALL1,
	IDLE_HALF1,
	IDLE_FULL1,
	FIRE_CHARGE1,
	FIRE_CHARGE2,
	FIRE_CHARGE3,
	FIRE_NULL1,
	FIRE_SMALL1,
	FIRE_HALF1,
	FIRE_FULL1,
	THROW_NULL1,
	THROW_SMALL1,
	THROW_HALF1,
	THROW_FULL1,
	RELOAD_NULL1,
	RELOAD_SMALL1,
	RELOAD_HALF1,
	RELOAD_FULL1,
	DRAW_NULL1,
	DRAW_SMALL1,
	DRAW_HALF1,
	DRAW_FULL1
}
public plugin_precache(){
	engfunc(EngFunc_PrecacheModel,model_v);
	engfunc(EngFunc_PrecacheModel,model_p);
	engfunc(EngFunc_PrecacheModel,model_w);
	engfunc(EngFunc_PrecacheModel,model_s);
	
	g_AllocString_V=engfunc(EngFunc_AllocString,model_v);
	g_AllocString_P=engfunc(EngFunc_AllocString,model_p);
	
	engfunc(EngFunc_PrecacheSound,sound_fire);
	engfunc(EngFunc_PrecacheSound,sound_throw);
	engfunc(EngFunc_PrecacheSound,sound_up);
	
	precache_generic("sprites/zmo/weapon_bloodhunter.txt")
	precache_generic("sprites/zmo/640hud145.spr")
	precache_generic("sprites/zmo/640hud17.spr")
	precache_generic("sprites/zmo/640hud7.spr")
	precache_sound("weapons/bloodhunter_clipin.wav")
	precache_sound("weapons/bloodhunter_clipout.wav")
	precache_sound("weapons/bloodhunter_draw.wav")
	precache_sound("weapons/bloodhunter_drawa.wav")
	precache_sound("weapons/bloodhunter_drawb.wav")
	precache_sound("weapons/bloodhunter_drawc.wav")
	precache_sound("weapons/bloodhunter_idle.wav")
	precache_sound("weapons/bloodhunter_reloada_clipin.wav")
	precache_sound("weapons/bloodhunter_reloada_clipout.wav")
	precache_sound("weapons/bloodhunter_reloadb_clipin.wav")
	precache_sound("weapons/bloodhunter_reloadc_clipin.wav")
	
	sExplo=engfunc(EngFunc_PrecacheModel,"sprites/zmo/ef_bloodhunter3.spr");
	
	register_clcmd(weapon_new,"hook_item");
	
	register_forward(FM_Spawn,"HookFm_Spawn",0);
}
new g_iItemID;
public plugin_init(){
	register_plugin ( "[ZMO] Weapon: Deagle Crimson Hunter" , "1.0" , "Chrescoe1 , PlaneShift" );
	RegisterHam(Ham_Item_Deploy,weapon_name,"fw_Weapon_Deploy_Post",1);
	RegisterHam(Ham_Item_PostFrame,weapon_name,"fw_Weapon_PostFrame",0);
	RegisterHam(Ham_Item_AddToPlayer,weapon_name,"fw_Weapon_AddToPlayer_Post",1)
	
	RegisterHam(Ham_Weapon_Reload,weapon_name,"fw_Weapon_Reload",0);
	RegisterHam(Ham_Weapon_WeaponIdle,weapon_name,"fw_Weapon_WeaponIdle",0);
	RegisterHam(Ham_Weapon_PrimaryAttack,weapon_name,"fw_Weapon_PrimaryAttack",0);
	RegisterHam(Ham_TakeDamage,"player","fw_TakeDamage");

	RegisterHam(Ham_Touch, "weaponbox", "fw_Touch");
	
	register_forward(FM_SetModel,"fw_SetModel");
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post",1);
	
	gMaxPlayers=get_maxplayers();
	Msg_WeaponList=get_user_msgid("WeaponList");
	
	Cvar [ 0 ] = register_cvar ( "zp_deaglebuff_damage" ,		"0.97" );
	Cvar [ 1 ] = register_cvar ( "zp_deaglebuff_recoil" ,		"1.0" );
	Cvar [ 2 ] = register_cvar ( "zp_deaglebuff_speed" ,		"0.2" );
	Cvar [ 3 ] = register_cvar ( "zp_deaglebuff_ammo" ,			"30" );
	Cvar [ 4 ] = register_cvar ( "zp_deaglebuff_clip" ,			"90" );
	Cvar [ 5 ] = register_cvar ( "zp_deaglebuff_damage_ex" ,	"900.0" );
	Cvar [ 6 ] = register_cvar ( "zp_deaglebuff_distance" ,		"150.0" );

	g_iItemID = zp_register_extra_item("Deagle Crimson Hunter", 70, ZP_TEAM_HUMAN)
	
	register_touch("buff_deagle_grenade","*","fw_Weapon_Touch");
}
public plugin_natives ( ) {
	register_native ( "ZMO_GiveUserBuffDeagle" , "get_item" , 1 );
}
public hook_item(id){
	engclient_cmd(id,weapon_name)
	return PLUGIN_HANDLED
}
public zp_extra_item_selected(iPlayer, iItemID) {
	if(iItemID == g_iItemID)
		get_item(iPlayer);
}
public get_item(id){
	if(zp_get_user_zombie(id))return;
	
	UTIL_DropWeapon(id,2);
	
	new weapon=make_weapon();if(weapon<=0)return;
	if(!ExecuteHamB(Ham_AddPlayerItem,id,weapon)){engfunc(EngFunc_RemoveEntity,weapon);return;}
	ExecuteHam(Ham_Item_AttachToPlayer,weapon,id);
	
	new ammotype=m_rgAmmo+get_pdata_int(weapon,m_iPrimaryAmmoType,LunDiff_Item);
	new ammo=get_pdata_int(id,ammotype,LunDiff_Player);
	if(ammo<get_pcvar_num ( Cvar [ 4 ] ))set_pdata_int(id,ammotype,get_pcvar_num ( Cvar [ 4 ] ),LunDiff_Player);
	set_pdata_int(weapon,m_iClip,get_pcvar_num ( Cvar [ 3 ] ),LunDiff_Item);
	
	emit_sound(id,CHAN_ITEM,"items/gunpickup2.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM);
}
public fw_Weapon_Deploy_Post(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED;
	static id;id=get_pdata_cbase(ent,m_pPlayer,LunDiff_Item);

	set_pev_string(id,pev_viewmodel2,g_AllocString_V);
	set_pev_string(id,pev_weaponmodel2,g_AllocString_P);
	set_pdata_float(ent,m_flNextPrimaryAttack,DRAW_TIME,LunDiff_Item);
	set_pdata_float(ent,m_flNextSecondaryAttack,DRAW_TIME,LunDiff_Item);
	set_pdata_float(ent,m_flTimeWeaponIdle,DRAW_TIME,LunDiff_Item);
	
	if(g_Blood[ent]>=blood_null&&g_Blood[ent]<blood_small)Play_WeaponAnim(id,DRAW_NULL1);
	else if(g_Blood[ent]>=blood_small&&g_Blood[ent]<blood_half)Play_WeaponAnim(id,DRAW_SMALL1);
	else if(g_Blood[ent]>=blood_half&&g_Blood[ent]<blood_full)Play_WeaponAnim(id,DRAW_HALF1);
	else if(g_Blood[ent]>=blood_full)Play_WeaponAnim(id,DRAW_FULL1);
	
	set_pdata_string(id,m_szAnimExtention,"dualpistols",-1,20);
	
	return HAM_IGNORED
}
public fw_Weapon_PostFrame(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED;
	
	static id;id=get_pdata_cbase(ent,m_pPlayer,LunDiff_Item);
	static button;button=pev(id,pev_button);
	static clip,ammotype,ammo,j;
	
	if(get_pdata_int(ent,m_fInReload,LunDiff_Item)==1){
		clip=get_pdata_int(ent,m_iClip,LunDiff_Item);
		ammotype=m_rgAmmo+ get_pdata_int(ent,m_iPrimaryAmmoType,LunDiff_Item);
		ammo=get_pdata_int(id,ammotype,LunDiff_Player);
		
		j=min(get_pcvar_num ( Cvar [ 3 ] )-clip,ammo);
		
		set_pdata_int(ent,m_iClip,clip+j,LunDiff_Item);
		set_pdata_int(id,ammotype,ammo-j,LunDiff_Player);
		set_pdata_int(ent,m_fInReload,0,LunDiff_Item);
	}
	
	if(((button&IN_ATTACK2)&&get_pdata_float(ent,m_flNextSecondaryAttack,LunDiff_Item)<=0.0)){
		if(g_Blood[ent]>=blood_full){
			Play_WeaponAnim(id,THROW_FULL1);
		
			//set_pdata_string(id,m_szAnimExtention,"grenade",-1,20);
			
			emit_sound(id,CHAN_WEAPON,sound_throw,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
		
			set_pdata_float(ent,m_flNextPrimaryAttack,THROW_TIME,LunDiff_Item);
			set_pdata_float(ent,m_flNextSecondaryAttack,THROW_TIME,LunDiff_Item);
			set_pdata_float(ent,m_flTimeWeaponIdle,THROW_TIME,LunDiff_Item);
			set_pdata_float(id,m_flNextAttack,THROW_TIME,LunDiff_Player);
		
			g_Blood[ent]=blood_null;
			
			static szAnimation [ 32 ]; 
			format( szAnimation , charsmax ( szAnimation ) , pev( id , pev_flags ) & FL_DUCKING ? "crouch_shoot_grenade" : "ref_shoot_grenade" );
			UTIL_PlayerAnimation( id , szAnimation );
			
			fw_Weapon_Throw(id);
		}
	}
	
	static Float:gametime[512];
	if(g_Blood[ent]==blood_null){
		if(get_pdata_float(ent,m_flNextSecondaryAttack,LunDiff_Item)<=0.0){
			if(pev(id,pev_weaponanim)==THROW_FULL1){
				if((gametime[ent]+THROW_TIME)<get_gametime()){
					gametime[ent]=get_gametime();
					ExecuteHamB(Ham_Item_Deploy,ent);
					set_pdata_string(id,m_szAnimExtention,"dualpistols",-1,20);
				}
			}
		}
	}
	
	return HAM_IGNORED;
}
public fw_Weapon_AddToPlayer_Post(ent,id){
	switch(pev(ent,pev_impulse)){
		case WEAPON_KEY:Weaponlist(id,true);
		case 0:Weaponlist(id,false);
	}
	return HAM_IGNORED;
}
public fw_Weapon_Reload(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED;
	
	static clip;clip=get_pdata_int(ent,m_iClip,LunDiff_Item);
	if(clip>=get_pcvar_num ( Cvar [ 3 ] ))return HAM_SUPERCEDE;
	
	static id;id=get_pdata_cbase(ent,m_pPlayer,LunDiff_Item);
	if(get_pdata_int(id,m_rgAmmo+get_pdata_int(ent,m_iPrimaryAmmoType,LunDiff_Item),LunDiff_Player)<=0)return HAM_SUPERCEDE
	
	set_pdata_int(ent,m_iClip,0,LunDiff_Item);
	ExecuteHam(Ham_Weapon_Reload,ent);
	set_pdata_int(ent,m_iClip,clip,LunDiff_Item);
	set_pdata_float(ent,m_flNextPrimaryAttack,RELOAD_TIME,LunDiff_Item)
	set_pdata_float(ent,m_flNextSecondaryAttack,RELOAD_TIME,LunDiff_Item)
	set_pdata_float(ent,m_flTimeWeaponIdle,RELOAD_TIME,LunDiff_Item)
	set_pdata_float(id,m_flNextAttack,RELOAD_TIME,LunDiff_Player) 
	set_pdata_int(ent,m_fInReload,1,LunDiff_Item);
	
	if(g_Blood[ent]>=blood_null&&g_Blood[ent]<blood_small)Play_WeaponAnim(id,RELOAD_NULL1);
	else if(g_Blood[ent]>=blood_small&&g_Blood[ent]<blood_half)Play_WeaponAnim(id,RELOAD_SMALL1);
	else if(g_Blood[ent]>=blood_half&&g_Blood[ent]<blood_full)Play_WeaponAnim(id,RELOAD_HALF1);
	else if(g_Blood[ent]>=blood_full)Play_WeaponAnim(id,RELOAD_FULL1);
	
	return HAM_SUPERCEDE;
}
public fw_Weapon_WeaponIdle(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED;
	
	if(get_pdata_float(ent,m_flTimeWeaponIdle,LunDiff_Item)>0.0)return HAM_IGNORED;
	
	static id;id=get_pdata_cbase(ent,m_pPlayer,LunDiff_Item);
	set_pdata_float(ent,m_flTimeWeaponIdle,IDLE_TIME,LunDiff_Item);
	
	if(g_Blood[ent]>=blood_null&&g_Blood[ent]<blood_small)Play_WeaponAnim(id,IDLE_NULL1);
	else if(g_Blood[ent]>=blood_small&&g_Blood[ent]<blood_half)Play_WeaponAnim(id,IDLE_SMALL1);
	else if(g_Blood[ent]>=blood_half&&g_Blood[ent]<blood_full)Play_WeaponAnim(id,IDLE_HALF1);
	else if(g_Blood[ent]>=blood_full)Play_WeaponAnim(id,IDLE_FULL1);
	
	return HAM_SUPERCEDE
}
public fw_Weapon_PrimaryAttack(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED
	
	static ammo;ammo=get_pdata_int(ent,m_iClip,LunDiff_Item);
	if(ammo<=0){
		ExecuteHam(Ham_Weapon_PlayEmptySound,ent);
		set_pdata_float(ent,m_flNextPrimaryAttack,get_pcvar_float ( Cvar [ 2 ] ),LunDiff_Item)
		return HAM_SUPERCEDE
	}
	
	if(get_pdata_int(ent,m_iShotsFired,LunDiff_Item)!=0)return HAM_SUPERCEDE
		
	static id;id=get_pdata_cbase(ent,m_pPlayer,LunDiff_Item)
	static Float:user_punchangle[3];pev(id,pev_punchangle,user_punchangle)
	static fm_hooktrace;fm_hooktrace=register_forward(FM_TraceLine,"HookFm_TraceLine",true)
	static fm_playbackevent;fm_playbackevent=register_forward(FM_PlaybackEvent,"HookFm_PlayBackEvent",false)
	
	state FireBullets:Enabled;
	ExecuteHam(Ham_Weapon_PrimaryAttack,ent)
	state FireBullets:Disabled;
	
	unregister_forward(FM_TraceLine,fm_hooktrace,true)
	unregister_forward(FM_PlaybackEvent,fm_playbackevent,false)
	
	if ( g_Status [ ent ] == 0 ) {
		if ( g_Blood [ ent ] >= blood_null && g_Blood [ ent ] < blood_small ) Play_WeaponAnim ( id , FIRE_NULL1 );
		else if ( g_Blood [ ent ] >= blood_small && g_Blood [ ent ] < blood_half ) Play_WeaponAnim ( id , FIRE_SMALL1 );
		else if ( g_Blood [ ent ] >= blood_half && g_Blood [ ent ] < blood_full ) Play_WeaponAnim ( id , FIRE_HALF1 );
		else if ( g_Blood [ ent ] >= blood_full ) Play_WeaponAnim ( id , FIRE_FULL1 );
			
		set_pdata_float ( ent , m_flNextPrimaryAttack , get_pcvar_float ( Cvar [ 2 ] ) , LunDiff_Item );
	}
	else if ( g_Status [ ent ] == 1 ) {
		if ( g_Blood [ ent ] >= blood_small && g_Blood [ ent ] < blood_half ) Play_WeaponAnim ( id , FIRE_CHARGE1 );
		if ( g_Blood [ ent ] >= blood_half && g_Blood [ ent ] < blood_full) Play_WeaponAnim ( id , FIRE_CHARGE2 );
		if ( g_Blood [ ent ] >= blood_full ) Play_WeaponAnim ( id , FIRE_CHARGE3 );
		
		g_Status [ ent ] = 0;
		//set_pdata_float ( ent , m_flNextPrimaryAttack , CHARGE_TIME , LunDiff_Item );
	}
	
	emit_sound(id,CHAN_WEAPON,sound_fire,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
	
	set_pdata_int(ent,m_iClip,ammo-1,LunDiff_Item)
	set_pdata_float(ent,m_flTimeWeaponIdle,CHARGE_TIME,LunDiff_Item)
	static Float:user_newpunch[3];pev(id,pev_punchangle,user_newpunch)
	
	user_newpunch[0]=user_punchangle[0]+(user_newpunch[0]-user_punchangle[0])*get_pcvar_float ( Cvar [ 1 ] )
	user_newpunch[1]=user_punchangle[1]+(user_newpunch[1]-user_punchangle[1])*get_pcvar_float ( Cvar [ 1 ] )
	user_newpunch[2]=user_punchangle[2]+(user_newpunch[2]-user_punchangle[2])*get_pcvar_float ( Cvar [ 1 ] )
	set_pev(id,pev_punchangle,user_newpunch)
	
	return HAM_SUPERCEDE
}
public fw_Weapon_Throw(id){
	static Float:StartOrigin[3],Float:TargetOrigin[3],Float:angles[3],Float:angles_fix[3];
	get_weapon_position(id,StartOrigin,.add_forward=30.0,.add_right=8.0,.add_up=10.0)
	
	pev(id,pev_v_angle,angles);
	static Ent;Ent=engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"));
	if(!pev_valid(Ent))return;
	
	angles_fix[0]=360.0-angles[0];
	angles_fix[1]=angles[1];
	angles_fix[2]=angles[2];
	
	set_pev(Ent,pev_movetype,MOVETYPE_TOSS);
	set_pev(Ent,pev_owner,id);
	entity_set_string(Ent,EV_SZ_classname,"buff_deagle_grenade");
	engfunc(EngFunc_SetModel,Ent,model_s);
	set_pev(Ent,pev_mins,{-0.1,-0.1,-0.1});
	set_pev(Ent,pev_maxs,{0.1,0.1,0.1});
	set_pev(Ent,pev_origin,StartOrigin);
	set_pev(Ent,pev_angles,angles_fix);
	set_pev(Ent,pev_gravity,1.0);
	set_pev(Ent,pev_solid,SOLID_BBOX);
	set_pev(Ent,pev_frame,0.0);
	
	static Float:Velocity[3];fm_get_aim_origin(id,TargetOrigin);
	get_speed_vector(StartOrigin,TargetOrigin,700.0,Velocity);
	set_pev(Ent,pev_velocity,Velocity);
}
public fw_Weapon_Touch(ent,id) {
	if(!pev_valid(ent))return;
	
	new Float:originX[3];
	pev(ent,pev_origin,originX);
	
	engfunc(EngFunc_MessageBegin,MSG_PAS,SVC_TEMPENTITY,originX,0);
	write_byte(TE_WORLDDECAL);
	engfunc(EngFunc_WriteCoord,originX[0]);
	engfunc(EngFunc_WriteCoord,originX[1]);
	engfunc(EngFunc_WriteCoord,originX[2]);
	write_byte(engfunc(EngFunc_DecalIndex,"{scorch3"));
	message_end();
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord,originX[0]);
	engfunc(EngFunc_WriteCoord,originX[1]);
	engfunc(EngFunc_WriteCoord,originX[2]+50);
	write_short(sExplo);
	write_byte(25);
	write_byte(30);
	write_byte(0);
	message_end();
	
	fw_Weapon_Damage(ent);
	
	remove_entity(ent);
}
public fw_Weapon_Damage(ent){
	static Owner;Owner=pev(ent,pev_owner);
	static Attacker;
	
	if(!is_user_alive(Owner)){
		Attacker=0;
		return;
	} 
	else Attacker=Owner;
	
	for(new i=0;i<gMaxPlayers;i++){
		if(!is_user_alive(i))continue;
		if(entity_range(i,ent)>get_pcvar_float ( Cvar [ 6 ] ) )continue;
		if(!zp_get_user_zombie(i))continue;

		ExecuteHamB(Ham_TakeDamage,i,Owner,Attacker,get_pcvar_float( Cvar [ 5 ] ),DMG_BULLET);
	}
}
public fw_Touch(iItem, iPlayer) 
{ 
	if(!pev_valid(iItem) || !is_user_alive(iPlayer) || zp_get_user_zombie(iPlayer)) 
		return HAM_IGNORED; 

	new szModelName[32]; 
	pev(iItem, pev_model, szModelName, charsmax(szModelName)); 

	if(equal(szModelName, model_w) && pev(iItem, pev_body) == WEAPON_BODY) 
	{ 
		if( ~get_user_flags(iPlayer) & ADMIN_LEVEL_B ) 
		{
			static Float: flLastTouch[33];
			new Float: flGameTime = get_gametime(); 

			if(flLastTouch[iPlayer] < flGameTime) 
			{ 
				flLastTouch[iPlayer] = flGameTime + 1.5;
				client_print_color(iPlayer, print_team_default, "^4[ZMO] ^1Данное оружие доступно только для ^3Buff игроков^1!");
			}

			return HAM_SUPERCEDE; 
		} 
	} 

	return HAM_IGNORED; 
}
public fw_TakeDamage(victim,inflictor,attacker,Float:damage)<FireBullets:Enabled>{ 
	static item;item=get_pdata_cbase(attacker,m_pActiveItem,LunDiff_Player);
	
	SetHamParamFloat(4,damage* get_pcvar_float ( Cvar [ 0 ] ) );
	
	if(is_user_alive(victim)){
		if(zp_get_user_zombie(victim)){
			if(Is_CustomItem(item)){
				if(g_Blood[item]<blood_full+1)g_Blood[item]++;
				
				if(g_Blood[item]==blood_small)emit_sound(attacker,CHAN_AUTO,sound_up,VOL_NORM,ATTN_NORM,0,PITCH_NORM),g_Status[item]=1;
				else if(g_Blood[item]==blood_half)emit_sound(attacker,CHAN_AUTO,sound_up,VOL_NORM,ATTN_NORM,0,PITCH_NORM),g_Status[item]=1;
				else if(g_Blood[item]==blood_full)emit_sound(attacker,CHAN_AUTO,sound_up,VOL_NORM,ATTN_NORM,0,PITCH_NORM),g_Status[item]=1;
			}
		}
	}
	
	return HAM_OVERRIDE;
}
public fw_TakeDamage()<FireBullets:Disabled>{ 
	return HAM_IGNORED;
}
public fw_TakeDamage()<>{
	return HAM_IGNORED;
}
public fw_SetModel(ent){ 
	static i,classname[32],item;pev(ent,pev_classname,classname,31);
	if(!equal(classname,"weaponbox"))return FMRES_IGNORED;
	
	for(i=0;i<6;i++){
		item=get_pdata_cbase(ent,m_rgpPlayerItems+i,LunDiff_Item);
		if(item>0&&Is_CustomItem(item)){
			engfunc(EngFunc_SetModel,ent,model_w);
			set_pev(ent, pev_body, WEAPON_BODY);
			UTIL_SetRendering(ent, 19, 255, 0, 0, 0, 0.0);
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}
public HookFm_PlayBackEvent(){ 
	return FMRES_SUPERCEDE
}
public HookFm_TraceLine(Float:tr_start[3],Float:tr_end[3],tr_flag,tr_ignore,tr){
	if(tr_flag&IGNORE_MONSTERS)return FMRES_IGNORED;
	
	static hit;hit=get_tr2(tr,TR_pHit)
	static Decal
	static glassdecal;if(!glassdecal)glassdecal=engfunc(EngFunc_DecalIndex,"{bproof1")
	hit=get_tr2(tr,TR_pHit)
	
	if(hit>0&&pev_valid(hit))
		if(pev(hit,pev_solid)!=SOLID_BSP)return FMRES_IGNORED
		else if(pev(hit,pev_rendermode)!=0)Decal=glassdecal
		else Decal=random_num(41,45)
	else Decal=random_num(41,45)

	static Float:vecEnd[3];get_tr2(tr,TR_vecEndPos,vecEnd)
	
	engfunc(EngFunc_MessageBegin,MSG_PAS,SVC_TEMPENTITY,vecEnd,0)
	write_byte(TE_GUNSHOTDECAL)
	engfunc(EngFunc_WriteCoord,vecEnd[0])
	engfunc(EngFunc_WriteCoord,vecEnd[1])
	engfunc(EngFunc_WriteCoord,vecEnd[2])
	write_short(hit>0?hit:0)
	write_byte(Decal)
	message_end()
	
	static Float:WallVector[3];get_tr2(tr,TR_vecPlaneNormal,WallVector)
	
	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,vecEnd,0);
	write_byte(TE_STREAK_SPLASH)
	engfunc(EngFunc_WriteCoord,vecEnd[0]);
	engfunc(EngFunc_WriteCoord,vecEnd[1]);
	engfunc(EngFunc_WriteCoord,vecEnd[2]);
	engfunc(EngFunc_WriteCoord,WallVector[0]*random_float(25.0,30.0));
	engfunc(EngFunc_WriteCoord,WallVector[1]*random_float(25.0,30.0));
	engfunc(EngFunc_WriteCoord,WallVector[2]*random_float(25.0,30.0));
	write_byte(111)
	write_short(12)
	write_short(3)
	write_short(75)	
	message_end()
	
	return FMRES_IGNORED
}
public fw_UpdateClientData_Post(id,SendWeapons,CD_Handle){
	static item;item=get_pdata_cbase(id,m_pActiveItem,LunDiff_Player)
	if(item<=0||!Is_CustomItem(item))return FMRES_IGNORED
	
	set_cd(CD_Handle,CD_flNextAttack,99999.0)
	
	return FMRES_HANDLED
}
public HookFm_Spawn(id){
	if(pev_valid(id)!=2)return FMRES_IGNORED
	
	static ClName[32];pev(id,pev_classname,ClName,31)
	if(strlen(ClName)<5)return FMRES_IGNORED
	
	static Trie:ClBuffer;if(!ClBuffer)ClBuffer=TrieCreate()
	if(!TrieKeyExists(ClBuffer,ClName)){
		TrieSetCell(ClBuffer,ClName,1)
		RegisterHamFromEntity(Ham_TakeDamage,id,"fw_TakeDamage",0)
	}
	
	return FMRES_IGNORED
}
stock make_weapon(){
	static ent;
	static g_AllocString_E;
	if(g_AllocString_E||(g_AllocString_E=engfunc(EngFunc_AllocString,weapon_name)))
		ent=engfunc(EngFunc_CreateNamedEntity,g_AllocString_E)
	else return 0
	
	if(ent<=0)return 0;
	
	set_pev(ent,pev_spawnflags,SF_NORESPAWN);
	set_pev(ent,pev_impulse,WEAPON_KEY);
	ExecuteHam(Ham_Spawn,ent)
	
	return ent
}
stock UTIL_DropWeapon(id,slot){
	static iEntity;iEntity=get_pdata_cbase(id,(m_rpgPlayerItems+slot),LunDiff_Player);
	if(iEntity>0){
		static iNext,szWeaponName[32];
		do{
			iNext=get_pdata_cbase(iEntity,m_pNext,LunDiff_Item);
			if(get_weaponname(get_pdata_int(iEntity,m_iId,LunDiff_Item),szWeaponName,31))
				engclient_cmd(id,"drop",szWeaponName)
		} 
		while((iEntity=iNext)>0);
	}
}
stock UTIL_SetRendering(iPlayer, iFx = 0, iRed = 255, iGreen = 255, iBlue = 255, iRender = 0, Float:flAmount = 16.0) {
	static Float: flColor[3];
	
	flColor[0] = float(iRed);
	flColor[1] = float(iGreen);
	flColor[2] = float(iBlue);
	
	set_pev(iPlayer, pev_renderfx, iFx);
	set_pev(iPlayer, pev_rendercolor, flColor);
	set_pev(iPlayer, pev_rendermode, iRender);
	set_pev(iPlayer, pev_renderamt, flAmount);
}
public Play_WeaponAnim(pPlayer, iSequence) {
	set_pev(pPlayer, pev_weaponanim, iSequence);
	
	message_begin( MSG_ONE_UNRELIABLE , SVC_WEAPONANIM , _ , pPlayer );
	write_byte( iSequence );
	write_byte( 0 );

	message_end();

	
	return iSequence;
}
stock Weaponlist(id,bool:set){
	if(!is_user_connected(id))return
	message_begin(MSG_ONE,Msg_WeaponList,_,id);
	write_string(set==false?weapon_name:weapon_new);
	write_byte(8);
	write_byte(get_pcvar_num ( Cvar [ 4 ] ));
	write_byte(-1);
	write_byte(-1);
	write_byte(1);
	write_byte(1);
	write_byte(26);
	write_byte(0);
	message_end();
}
stock get_weapon_position(id,Float:fOrigin[3],Float:add_forward=0.0,Float:add_right=0.0,Float:add_up=0.0){
	static Float:Angles[3],Float:ViewOfs[3],Float:vAngles[3]
	static Float:Forward[3],Float:Right[3],Float:Up[3]
	
	pev(id,pev_v_angle,vAngles)
	pev(id,pev_origin,fOrigin)
	pev(id,pev_view_ofs,ViewOfs)
	
	xs_vec_add(fOrigin,ViewOfs,fOrigin)
	pev(id,pev_v_angle,Angles)
	engfunc(EngFunc_MakeVectors,Angles)
	
	global_get(glb_v_forward,Forward)
	global_get(glb_v_right,Right)
	global_get(glb_v_up,Up)
	
	xs_vec_mul_scalar(Forward,add_forward,Forward)
	xs_vec_mul_scalar(Right,add_right,Right)
	xs_vec_mul_scalar(Up,add_up,Up)
	
	fOrigin[0]=fOrigin[0]+Forward[0]+Right[0]+Up[0]
	fOrigin[1]=fOrigin[1]+Forward[1]+Right[1]+Up[1]
	fOrigin[2]=fOrigin[2]+Forward[2]+Right[2]+Up[2]
}
stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3]){
	new_velocity[0]=origin2[0]-origin1[0];
	new_velocity[1]=origin2[1]-origin1[1];
	new_velocity[2]=origin2[2]-origin1[2];
	
	static Float:num;num=floatsqroot(speed*speed/(new_velocity[0]*new_velocity[0]+new_velocity[1]*new_velocity[1]+new_velocity[2]*new_velocity[2]));
	
	new_velocity[0]*=num;
	new_velocity[1]*=num;
	new_velocity[2]*=num;
	
	return 1;
}
public UTIL_PlayerAnimation( pPlayer , szAnimation [ ] ) { // By KORD_12.7
	static iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
	if( ( iAnimDesired = lookup_sequence( pPlayer , szAnimation , flFrameRate , bLoops , flGroundSpeed ) ) == -1 ) iAnimDesired = 0;
	static Float: flGameTime; flGameTime = get_gametime ( );
	
	set_pev( pPlayer , pev_frame , 0.0 );
	set_pev( pPlayer , pev_framerate , 1.0 );
	set_pev( pPlayer , pev_animtime , flGameTime );
	set_pev( pPlayer , pev_sequence , iAnimDesired );
	
	set_pdata_int( pPlayer , m_fSequenceLoops , bLoops , 4 );
	set_pdata_int( pPlayer , m_fSequenceFinished , 0 , 4 );
	set_pdata_float( pPlayer , m_flFrameRate , flFrameRate , 4 );
	set_pdata_float( pPlayer , m_flGroundSpeed , flGroundSpeed , 4 );
	set_pdata_float( pPlayer , m_flLastEventCheck , flGameTime , 4 );
	set_pdata_int( pPlayer , m_Activity , ACT_RANGE_ATTACK1 , 5 );
	set_pdata_int( pPlayer , m_IdealActivity , ACT_RANGE_ATTACK1 , 5 );  
	set_pdata_float( pPlayer , m_flLastAttackTime , flGameTime , 5 );
}
