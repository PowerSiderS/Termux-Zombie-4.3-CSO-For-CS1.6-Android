#include<amxmodx>
#include<fakemeta>
#include<hamsandwich>
#include<zombieplague>

#define weapon_name		"weapon_deagle"
#define weapon_new		"weapon_dart_pistol"

#define ANIM_IDLE		0
#define ANIM_SHOOT_1		1
#define ANIM_SHOOT_2		2
#define ANIM_RELOAD		3
#define ANIM_DRAW		4
#define ANIM_SHOOT_EMPTY	5

#define IDLE_TIME		2.003
#define DRAW_TIME		1.003
#define RELOAD_TIME		4.033

#define pData_Player				5
#define pData_Item				4

#define pDataKey_WeaponBoxItems			34

#define pDataKey_iOwner				41
#define pDataKey_iNext				42
#define pDataKey_iId				43

#define pDataKey_flNextPrimaryAttack		46
#define pDataKey_flNextSecondaryAttack		47
#define pDataKey_flNextTimeWeaponIdle		48
#define pDataKey_iPrimaryAmmoType		49
#define pDataKey_iClip				51
#define pDataKey_iInReload			54
#define pDataKey_iSpecialReload			55
#define pDataKey_iShotsFired			64
#define pDataKey_iState				74

#define pDataKey_iLastHitGroup			75
#define pDataKey_flNextAttack			83

#define pDataKey_iPlayerItems			367
#define pDataKey_iActiveItem			373	
#define pDataKey_ibpAmmo			376

#define pDataKey_szAnimExtention                1968

#define WEAPON_KEY				133568909876543456
#define Is_CustomItem(%0)			(pev(%0,pev_impulse)==WEAPON_KEY)

#define model_v		"models/addons/v_dart_pistol.mdl"
#define model_p		"models/addons/p_dart_pistol.mdl"
#define model_w		"models/addons/w_dart_pistol.mdl"

#define weapon_punchangle		0.0	
#define weapon_damage			1.25
#define weapon_aspeed                   1.1			

#define weapon_ammo	5
#define weapon_bpammo	35
#define sound_shot	"addons/dart_pistol_fire1.wav"
#define sound_empty     "addons/dart_pistol_empty1.wav"

#define shock_damage    250.0
#define shock_radius    80.0

new Msg_WeaponList
new g_AllocString_V,g_AllocString_P
new g_Shock
new Float:g_VecEndTrace[3],g_Id;
new gMaxPlayers
new g_item

public plugin_precache(){
	engfunc(EngFunc_PrecacheModel,model_v)
	engfunc(EngFunc_PrecacheModel,model_p)
	engfunc(EngFunc_PrecacheModel,model_w)
	g_AllocString_V=engfunc(EngFunc_AllocString,model_v)
	g_AllocString_P=engfunc(EngFunc_AllocString,model_p)
	
	engfunc(EngFunc_PrecacheSound,sound_shot)
	engfunc(EngFunc_PrecacheSound,sound_empty)
	engfunc(EngFunc_PrecacheSound,"addons/dart_pistol_clip_in1.wav")
	engfunc(EngFunc_PrecacheSound,"addons/dart_pistol_clip_in2.wav")
	engfunc(EngFunc_PrecacheSound,"addons/dart_pistol_clip_in3.wav")
	engfunc(EngFunc_PrecacheSound,"addons/dart_pistol_clip_out1.wav")
	engfunc(EngFunc_PrecacheSound,"addons/dart_pistol_clip_out2.wav")
	engfunc(EngFunc_PrecacheSound,"addons/dart_pistol_draw1.wav")
	engfunc(EngFunc_PrecacheSound,"addons/dart_pistol_explosion1.wav")
	
	g_Shock=engfunc(EngFunc_PrecacheModel,"sprites/addons/dart_pistol_explosion1.spr")
	
	engfunc(EngFunc_PrecacheGeneric,"sprites/weapon_dart_pistol.txt")
	
	g_item=zp_register_extra_item("Dart Pistol", 15, ZP_TEAM_HUMAN)
	
	register_forward(FM_Spawn,"HookFm_Spawn",0)
}
public plugin_init(){
	RegisterHam(Ham_Item_Deploy,weapon_name,"HookHam_Weapon_Deploy",1)
	RegisterHam(Ham_Item_AddToPlayer,weapon_name,"HookHam_Weapon_Add",1)
	RegisterHam(Ham_Item_PostFrame,weapon_name,"HookHam_Weapon_Frame",0)
	
	RegisterHam(Ham_Weapon_Reload,weapon_name,"HookHam_Weapon_Reload",0)
	RegisterHam(Ham_Weapon_WeaponIdle,weapon_name,"HookHam_Weapon_Idle",0)
	RegisterHam(Ham_Weapon_PrimaryAttack,weapon_name,"HookHam_Weapon_PrimaryAttack",0)
	RegisterHam(Ham_TakeDamage,"player","HookHam_TakeDamage")
	
	register_forward(FM_SetModel,"HookFm_SetModel")
	
	register_forward(FM_UpdateClientData,"HookFm_UpdateClientData",1)
	
	gMaxPlayers=get_maxplayers()
	
	Msg_WeaponList=get_user_msgid("WeaponList");
	register_clcmd(weapon_new,"hook_item")
	/* register_clcmd("say /dart_pistol","get_item"); */
}
/* public plugin_natives(){
	register_native("give_dart_pistol","get_item",1);
} */
public get_item(id){
	UTIL_DropWeapon(id,2);
	new weapon=make_weapon();if(weapon<=0)return
	if(!ExecuteHamB(Ham_AddPlayerItem,id,weapon)){engfunc(EngFunc_RemoveEntity,weapon);return;}
	ExecuteHam(Ham_Item_AttachToPlayer,weapon,id)
	new ammotype=pDataKey_ibpAmmo+get_pdata_int(weapon,pDataKey_iPrimaryAmmoType,pData_Item)
	new ammo=get_pdata_int(id,ammotype,pData_Player)
	if(ammo<weapon_bpammo)set_pdata_int(id,ammotype,weapon_bpammo,pData_Player)
	set_pdata_int(weapon,pDataKey_iClip,weapon_ammo,pData_Item)
	emit_sound(id,CHAN_ITEM,"items/gunpickup2.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM)
}
public zp_extra_item_selected(id, itemid) {
	if(itemid != g_item) return;
	get_item(id);
}
public hook_item(id){
	engclient_cmd(id,weapon_name)
	return PLUGIN_HANDLED
}
public HookHam_Weapon_Deploy(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED
	static id;id=get_pdata_cbase(ent,pDataKey_iOwner,pData_Item)
	
	set_pev_string(id,pev_viewmodel2,g_AllocString_V)
	set_pev_string(id,pev_weaponmodel2,g_AllocString_P)
	set_pdata_float(ent,pDataKey_flNextPrimaryAttack,DRAW_TIME,pData_Item)
	set_pdata_float(ent,pDataKey_flNextSecondaryAttack,DRAW_TIME,pData_Item)
	set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,DRAW_TIME,pData_Item)
	Play_WeaponAnim(id,ANIM_DRAW)
	set_pdata_int(ent, pDataKey_iSpecialReload, 0, pData_Item)
	set_pdata_string(id,pDataKey_szAnimExtention,"onehanded",-1,20);
	g_Id=id;
	return HAM_IGNORED
}
public HookHam_Weapon_Add(ent,id){
	switch(pev(ent,pev_impulse)){
		case WEAPON_KEY:Weaponlist(id,true)
		case 0:Weaponlist(id,false)
	}
	return HAM_IGNORED
}
public HookHam_Weapon_Frame(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED;
	static id;id=get_pdata_cbase(ent,pDataKey_iOwner,pData_Item);
	if(get_pdata_int(ent,pDataKey_iInReload,pData_Item)){
		static clip,ammotype,ammo,j
		clip=get_pdata_int(ent,pDataKey_iClip,pData_Item);
		ammotype=pDataKey_ibpAmmo+get_pdata_int(ent,pDataKey_iPrimaryAmmoType,pData_Item);
		ammo=get_pdata_int(id,ammotype,pData_Player);
		j=min(weapon_ammo-clip,ammo);
		set_pdata_int(ent,pDataKey_iClip,clip+j,pData_Item);
		set_pdata_int(id,ammotype,ammo-j,pData_Player);
		set_pdata_int(ent,pDataKey_iInReload,0,pData_Item);
	}
	return HAM_IGNORED;
}
public HookHam_Weapon_Reload(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED;
	
	static clip;clip=get_pdata_int(ent,pDataKey_iClip,pData_Item);
	if(clip>=weapon_ammo)return HAM_SUPERCEDE;
	
	static id;id=get_pdata_cbase(ent,pDataKey_iOwner,pData_Item);
	if(get_pdata_int(id,pDataKey_ibpAmmo+get_pdata_int(ent,pDataKey_iPrimaryAmmoType,pData_Item),pData_Player)<=0)return HAM_SUPERCEDE
	
	set_pdata_int(ent,pDataKey_iClip,0,pData_Item);
	ExecuteHam(Ham_Weapon_Reload,ent);
	set_pdata_int(ent,pDataKey_iClip,clip,pData_Item);
	set_pdata_int(ent,pDataKey_iInReload,1,pData_Item);
	set_pdata_float(ent,pDataKey_flNextPrimaryAttack,RELOAD_TIME,pData_Item)
	set_pdata_float(ent,pDataKey_flNextSecondaryAttack,RELOAD_TIME,pData_Item)
	set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,RELOAD_TIME,pData_Item)
	set_pdata_float(id,pDataKey_flNextAttack,RELOAD_TIME,pData_Player)
	Play_WeaponAnim(id,ANIM_RELOAD)
	return HAM_SUPERCEDE;
}
public HookHam_Weapon_Idle(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED
	if(get_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,pData_Item)>0.0)return HAM_IGNORED
	set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,IDLE_TIME,pData_Item)
	Play_WeaponAnim(get_pdata_cbase(ent,pDataKey_iOwner,pData_Item),ANIM_IDLE)
	return HAM_SUPERCEDE
}
public HookHam_Weapon_PrimaryAttack(ent){
	if(!Is_CustomItem(ent))return HAM_IGNORED
	if(get_pdata_int(ent,pDataKey_iShotsFired,pData_Item)!=0)return HAM_SUPERCEDE
	static ammo;ammo=get_pdata_int(ent,pDataKey_iClip,pData_Item);
	static id;id=get_pdata_cbase(ent,pDataKey_iOwner,pData_Item)
	if(ammo<=0){
		ExecuteHam(Ham_Weapon_PlayEmptySound,ent);
		Play_WeaponAnim(id,ANIM_SHOOT_EMPTY)
		emit_sound(id,CHAN_WEAPON,sound_empty,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
		set_pdata_float(ent,pDataKey_flNextPrimaryAttack,weapon_aspeed,pData_Item)
		set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,2.0,pData_Item)
		return HAM_SUPERCEDE
	}
		
	static Float:user_punchangle[3];pev(id,pev_punchangle,user_punchangle)
	static fm_hooktrace;fm_hooktrace=register_forward(FM_TraceLine,"HookFm_TraceLine",true)
	static fm_playbackevent;fm_playbackevent=register_forward(FM_PlaybackEvent,"HookFm_PlayBackEvent",false)
	
	state FireBullets: Enabled;
	ExecuteHam(Ham_Weapon_PrimaryAttack,ent)
	state FireBullets: Disabled;
	
	unregister_forward(FM_TraceLine,fm_hooktrace,true)
	unregister_forward(FM_PlaybackEvent,fm_playbackevent,false)
	
	set_pdata_int(ent, pDataKey_iSpecialReload, 0, pData_Item)
	
	Play_WeaponAnim(id,random_num(ANIM_SHOOT_1,ANIM_SHOOT_2))
	set_pdata_int(ent,pDataKey_iClip,ammo-1,pData_Item)
	set_pdata_float(ent,pDataKey_flNextTimeWeaponIdle,2.0,pData_Item)
	static Float:user_newpunch[3];pev(id,pev_punchangle,user_newpunch)
	
	user_newpunch[0]=user_punchangle[0]+(user_newpunch[0]-user_punchangle[0])*weapon_punchangle
	user_newpunch[1]=user_punchangle[1]+(user_newpunch[1]-user_punchangle[1])*weapon_punchangle
	user_newpunch[2]=user_punchangle[2]+(user_newpunch[2]-user_punchangle[2])*weapon_punchangle
	set_pev(id,pev_punchangle,user_newpunch)

	emit_sound(id,CHAN_WEAPON,sound_shot,VOL_NORM,ATTN_NORM,0,PITCH_NORM)

	set_pdata_float(ent,pDataKey_flNextPrimaryAttack,weapon_aspeed,pData_Item)
	
	new Float:Origin[3]
	get_weapon_position(id,Origin,.add_forward=10.0,.add_right=17.0,.add_up=-10.5)
		
	new Float:Velo[3]
	Velo[0]=g_VecEndTrace[0]-Origin[0]
	Velo[1]=g_VecEndTrace[1]-Origin[1]
	Velo[2]=g_VecEndTrace[2]-Origin[2]
		
	vec_normalize(Velo,Velo)
	vec_mul_scalar(Velo,4096.0,Velo)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_USERTRACER)
	engfunc(EngFunc_WriteCoord,Origin[0])
	engfunc(EngFunc_WriteCoord,Origin[1])
	engfunc(EngFunc_WriteCoord,Origin[2])
	engfunc(EngFunc_WriteCoord,Velo[0])
	engfunc(EngFunc_WriteCoord,Velo[1])
	engfunc(EngFunc_WriteCoord,Velo[2])
	write_byte(35)
	write_byte(5)
	write_byte(8)
	message_end()
	
	return HAM_SUPERCEDE
}
public HookHam_TakeDamage(victim,inflictor,attacker,Float:damage)<FireBullets: Enabled>{ 
	SetHamParamFloat(4,damage*weapon_damage);
	return HAM_OVERRIDE;
}
public HookHam_TakeDamage()<FireBullets: Disabled>{ 
	return HAM_IGNORED;
}
public HookHam_TakeDamage()<>{
	return HAM_IGNORED;
}
public HookFm_SetModel(ent){ 
	static i,classname[32],item;pev(ent,pev_classname,classname,31);
	if(!equal(classname,"weaponbox"))return FMRES_IGNORED;
	for(i=0;i<6;i++){
		item=get_pdata_cbase(ent,pDataKey_WeaponBoxItems+i,4);
		if(item>0 && Is_CustomItem(item)){
			engfunc(EngFunc_SetModel,ent,model_w);
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
	
	g_VecEndTrace=vecEnd
	
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
	
	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,g_VecEndTrace,0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord,g_VecEndTrace[0]);
	engfunc(EngFunc_WriteCoord,g_VecEndTrace[1]);
	engfunc(EngFunc_WriteCoord,g_VecEndTrace[2]);
	write_short(g_Shock);
	write_byte(5);
	write_byte(150);
	message_end();
	
	for(new i=1;i<=gMaxPlayers;i++){ 
		if(is_user_alive(i)){
			static Float:enemy[3];pev(i, pev_origin, enemy);    
			new Float:Distance=get_distance_f(g_VecEndTrace, enemy);
			if(i!=g_Id&&get_user_team(i)!=get_user_team(g_Id)&&Distance<=shock_radius&&zp_get_user_zombie(i)){ 
				emit_sound(i,CHAN_AUTO,"addons/dart_pistol_explosion1.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM)
				ExecuteHamB(Ham_TakeDamage,i,0,g_Id,shock_damage,DMG_BURN);
			}
		}
	}
	
	return FMRES_IGNORED
}
public HookFm_UpdateClientData(id,SendWeapons,CD_Handle){
	static item;item=get_pdata_cbase(id,pDataKey_iActiveItem,pData_Player)
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
		RegisterHamFromEntity(Ham_TakeDamage,id,"HookHam_TakeDamage",0)
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
	static iEntity;iEntity=get_pdata_cbase(id,(pDataKey_iPlayerItems+slot),pData_Player);
	if(iEntity>0){
		static iNext,szWeaponName[32];
		do{
			iNext=get_pdata_cbase(iEntity,pDataKey_iNext,4);
			if(get_weaponname(get_pdata_int(iEntity,pDataKey_iId,4),szWeaponName,31))
				engclient_cmd(id,"drop",szWeaponName)
		} while((iEntity=iNext)>0);
	}
}
stock Play_WeaponAnim(id,anim){
	set_pev(id,pev_weaponanim,anim)
	message_begin(MSG_ONE_UNRELIABLE,SVC_WEAPONANIM,_,id)
	write_byte(anim)
	write_byte(0)
	message_end()
}
stock Weaponlist(id,bool:set){
	if(!is_user_connected(id))return
	message_begin(MSG_ONE,Msg_WeaponList,_,id);
	write_string(set==false?weapon_name:weapon_new);
	write_byte(8);
	write_byte(weapon_bpammo);
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
	vec_add(fOrigin,ViewOfs,fOrigin)
	pev(id,pev_v_angle,Angles)
	engfunc(EngFunc_MakeVectors,Angles)
	global_get(glb_v_forward,Forward)
	global_get(glb_v_right,Right)
	global_get(glb_v_up,Up)
	vec_mul_scalar(Forward,add_forward,Forward)
	vec_mul_scalar(Right,add_right,Right)
	vec_mul_scalar(Up,add_up,Up)
	fOrigin[0]=fOrigin[0]+Forward[0]+Right[0]+Up[0]
	fOrigin[1]=fOrigin[1]+Forward[1]+Right[1]+Up[1]
	fOrigin[2]=fOrigin[2]+Forward[2]+Right[2]+Up[2]
}
vec_add(const Float:in1[],const Float:in2[],Float:out[]){
	out[0]=in1[0]+in2[0];
	out[1]=in1[1]+in2[1];
	out[2]=in1[2]+in2[2];
}
vec_mul_scalar(const Float:vec[],Float:scalar,Float:out[]){
	out[0]=vec[0]*scalar;
	out[1]=vec[1]*scalar;
	out[2]=vec[2]*scalar;
}
vec_normalize(const Float:vec[],Float:out[]){
	new Float:invlen=rsqrt(vec[0]*vec[0]+vec[1]*vec[1]+vec[2]*vec[2]);
	out[0]=vec[0]*invlen;
	out[1]=vec[1]*invlen;
	out[2]=vec[2]*invlen;
}
Float:rsqrt(Float:x){
	new Float:xhalf=x*0.5;
	
	new i=_:x;
	i=0x5f375a84 - (i>>1);
	x=Float:i;
			
	x=x*(1.5-xhalf*x*x);
	x=x*(1.5-xhalf*x*x);
	x=x*(1.5-xhalf*x*x);
		
	return x;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
