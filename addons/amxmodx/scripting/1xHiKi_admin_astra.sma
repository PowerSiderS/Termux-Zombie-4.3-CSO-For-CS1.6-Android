#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <reapi>
#include <fun>
#include <xs>
#include <zombieplague>

native remove_astra(id)

#define PLUGIN "Astra"
#define VERSION "1.0"
#define AUTHOR "Jenessee"

//#define DEBUG 1 // Çökme olduğunda sebebi kolayca bulmak için açabilirsiniz.

//Buraya istediğiniz değeri girebilirsiniz ama değer diğer itemlerinkiyle aynı olursa silahlar birbiriyle çakışır.
new const Astra_WeaponID = 34324;

// Bunu false yaparsanız elektrik efektleri servere eklenmeyecek true yaparsanız eklenir.
new const bool:ActivateSprites = true;

//Silahın kullandığı dosyaları buradan değiştirebilirsiniz.
new const Resources[][] = 
{
	"models/v_guillotineex.mdl", // 0	 Server-side Model Dosyaları
	"models/p_guillotineex.mdl", // 1	
	"models/guillotineex_projectile1.mdl", // 2
	"models/guillotineex_projectile2.mdl", // 3

	"weapons/guillotineex_shoot_1_start.wav", // 4 	Server-side Ses Dosyaları 
	"weapons/guillotineex_shoot-1_end.wav", // 5
	"weapons/guillotineex_shoot-1_exp.wav", // 6
	"weapons/guillotineex_shoot-2_exp.wav", // 7
	"weapons/guillotine_explode.wav", // 8
	"weapons/combatknife_wall.wav", // 9

	"sound/weapons/guillotineex_catch.wav", // 10  Client-side Ses Dosyaları
	"sound/weapons/guillotineex_draw.wav", // 11
	"sound/weapons/guillotineex_draw_empty.wav", // 12
	"sound/weapons/guillotineex_idle1.wav", // 13
	"sound/weapons/guillotineex_idle2.wav", // 14

	"sprites/weapon_guillotineex.txt", // 15  Client-side Silah Hud Dosyaları
	"sprites/guiex.spr", // 16	
	
	"sprites/ef_buffng7_magazine_exp.spr", // 17 Client-side sprite efektleri 
	"sprites/ef_stunrifle_xbeam.spr", // 18	
	"sprites/muzzleflash81.spr"  // 19
}

new Last_WeaponID[MAX_PLAYERS+1]; // Oyuncunun son kullandığı silahın Silah id`sine eşitlenir.
new Last_WeaponEntityID[MAX_PLAYERS+1]; // Oyuncunun son kullandığı silahın Entity id`sine eşitlenir.
new Last_ProjectileEntity[MAX_PLAYERS+1]; // Oyuncunun son fırlattığı mermiye eşitlenir.
new bool:Player_Alive[MAX_PLAYERS+1]; // Oyuncunun canlı olup olmadığını sorgulamak için kullanılır.
new Float:Projectile_Touch_Delay[MAX_PLAYERS+1][MAX_PLAYERS+1]; // Merminin oyuncuya sürekli dokunmasını engellemek için kullanılır.
new g_Team[MAX_PLAYERS+1];
new BloodSprites[2];
new Cvars[8];
new Sprite_Effects[3];
new bool:ZombieMode, bool:ZombiePlague = false, bool:Biohazard = false;
new Message_WeaponList;
new bool:gHasAstra[33];
#if defined DEBUG
new g_LogLine, g_LogName[128];
#endif

//new g_msgWeapPickup;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	GameLog("Astra plugin_init");

	// Yeni round başlarken çalışır.
	register_event("HLTV", "New_Round", "a", "1=0", "2=0");
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");

	// Oyuncunun eline aldığı silahı öğrenmemiz için gereklidir. 
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "CBasePlayerWeapon_DefaultDeploy", false);
	
	// Oyuncuya silah verildiğinde çalışır.
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "CBasePlayer_AddPlayerItem", false);
	
	// Oyuncu canlanınca çalışır.
	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", true); 

	// Oyuncu ölünce çalışır.
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed", true);
	
	// Bıçağın vuruşlarını engellemeyi sağlar.
	register_forward(FM_UpdateClientData, "UpdateClientData_Post", 1);

	// Bıçağın ele alınma sesini kapatmak için gerekli.
	register_forward(FM_EmitSound, "EmitSound");

	// Takım değişince çalışır.
	register_event("TeamInfo", "Change_Team" , "a");

	// Bıçağın vuruşlarını engellemeyi sağlar.
	RegisterHam(Ham_Item_PostFrame, "weapon_knife", "Item_PostFrame");

	Cvars[0] = register_cvar("astra_cutter_attack_damage", "100.0");
	Cvars[1] = register_cvar("astra_beheading_attack_damage", "60.0");
	Cvars[2] = register_cvar("astra_cutter attack_push", "600.0");
	Cvars[3] = register_cvar("astra_beheading_attack_push", "200.0");
	Cvars[4] = register_cvar("astra_head_sensing_distance", "25.0");
	Cvars[5] = register_cvar("astra_electricity_spread_damage", "100.0");
	Cvars[6] = register_cvar("astra_electric_spread_distance", "150.0");
	Cvars[7] = register_cvar("astra_headshot_time", "3.0");
		
	register_clcmd("weapon_guillotineex", "Hook_Astra"); // Silahın hudları değiştiği için silahı ele almada sorunlar olabiliyor. Konsola weapon_guillotineex yazınca ele bıçak gelecek.
	
	Message_WeaponList = get_user_msgid("WeaponList");
	//g_msgWeapPickup = get_user_msgid("WeapPickup");

	#if defined DEBUG
	static MapName[32]; get_mapname(MapName, 31)
	static Time[64]; get_time("%m-%d-%Y - %H-%M", Time, 63)
	
	formatex(g_LogName, 127, "%s - %s", MapName, Time);
	#endif
}

public plugin_precache()
{
	GameLog("Astra plugin_precache");

	new index, Size = sizeof(Resources);
	for(index = 0; index < Size; index++)
	{
		switch(index)
		{
			case 0..3: precache_model(Resources[index]); // Model dosyalarını oyun motoruna ekliyor ve modelleri servere giren oyunculara indirtiyor.
			case 4..9: precache_sound(Resources[index]); // Ses dosyalarını oyun motoruna ekliyor ve sesleri servere giren oyunculara indirtiyor.	
			case 10..16: precache_generic(Resources[index]); // Dosyaları oyun motoruna eklemiyor ve dosyaları servere giren oyunculara indirtiyor.
			case 17..19: 
			{
				if(ActivateSprites) Sprite_Effects[index-17] = precache_model(Resources[index]); // Client-side gösterilecek spriteler ama yine de oyun motoruna eklemek zorundayız çünkü oyunda bozuk duruyorlar.
			}
		}		
	}
	
	// Kan efektleri için gerekli.
	BloodSprites[0] = precache_model("sprites/bloodspray.spr");
	BloodSprites[1] = precache_model("sprites/blood.spr");
	
	// Loop yapan sesleri kapatmak için gerekli.
	precache_sound("common/null.wav");
}

public plugin_natives()
{
	register_native("give_astra", "give_astra_native", 1);
	register_native("get_astra", "get_astra_native", 1);
	register_native("remove_astra", "remove_astra_native", 1);
}

public get_astra_native(id)
{
	return gHasAstra[id]
}
public give_astra_native(id)
{
	gHasAstra[id] = true;

	rg_remove_item(id, "weapon_knife");
	rg_give_item(id, "weapon_knife");
}
public remove_astra_native(id)
{
	gHasAstra[id] = false;

	rg_remove_item(id, "weapon_knife");
	rg_give_item(id, "weapon_knife");
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id) || get_user_weapon(id) != CSW_KNIFE || zp_get_user_zombie(id) || zp_get_user_survivor(id) ||  !gHasAstra[id])
		return PLUGIN_HANDLED;

	set_pev(id, pev_viewmodel2, Resources[0])
	set_pev(id, pev_weaponmodel2, Resources[1])

	return PLUGIN_CONTINUE;
}

public client_disconnected(clientIndex)
{
	GameLog("Astra client_disconnected");

	gHasAstra[clientIndex] = false;

	Player_Alive[clientIndex] = false; // oyuncu öldü
	new iMissileEntityID = Last_ProjectileEntity[clientIndex];
	Last_ProjectileEntity[clientIndex] = -1;
	if(iMissileEntityID != -1 && !is_nullent(iMissileEntityID)) // Oyuncu canlanınca mermi patlatılır.
	{
		Missile_Explode(iMissileEntityID); // Mermiyi patlatır.
	}
}

public New_Round()
{
	GameLog("Astra New_Round");

	// Terröristlere astra verebilmek için bunun kapalı olması gerekiyor.
	ZombieMode = false;

	if(!Biohazard && is_biomod_active()) Biohazard = true;
	if(!ZombiePlague && is_zpmod_active()) ZombiePlague = true;
}

// Biohazard - İlk zombi çıktığında
// Biohazard - Takım Değişikliği
public event_infect(const clientIndex)
{
	GameLog("Astra event_infect");

	ZombieMode = true; // Terröristlere astra vermeyi kapatmak için açık olması gerekiyor.
	remove_astra(clientIndex)

	g_Team[clientIndex] = 1; // Terröristler

	new iMissileEntityID = Last_ProjectileEntity[clientIndex];
	Last_ProjectileEntity[clientIndex] = -1;
	if(iMissileEntityID != -1 && !is_nullent(iMissileEntityID)) // Takım değişiminde mermi patlatılır.
	{
		Missile_Explode(iMissileEntityID); // Mermiyi patlatır.
	}
}

// Zombie Plague - Takım Değişikliği
public zp_user_humanized_pre(id)
{
	GameLog("Astra zp_user_humanized_pre");

	g_Team[id] = 2; // Counter Terröristler

	if(zp_get_user_survivor(id)){
		remove_astra(id)
	}

	new iMissileEntityID = Last_ProjectileEntity[id];
	Last_ProjectileEntity[id] = -1;
	if(iMissileEntityID != -1 && !is_nullent(iMissileEntityID)) // Takım değişiminde mermi patlatılır.
	{
		Missile_Explode(iMissileEntityID); // Mermiyi patlatır.
	}	
}

// Zombie Plague - İlk zombi çıktığında
public zp_user_infected_pre(id)
{
	GameLog("Astra zp_user_infected_pre");

	ZombieMode = true;
	remove_astra(id)

	g_Team[id] = 1; // Terröristler

	new iMissileEntityID = Last_ProjectileEntity[id];
	Last_ProjectileEntity[id] = -1;
	if(iMissileEntityID != -1 && !is_nullent(iMissileEntityID)) // Takım değişiminde mermi patlatılır.
	{
		Missile_Explode(iMissileEntityID); // Mermiyi patlatır.
	}	
}

public zp_user_humanized_post(id)
{
	GameLog("Astra zp_user_humanized_pre");

	g_Team[id] = 2; // Counter Terröristler

	if(zp_get_user_survivor(id)){
		remove_astra(id)
	}

	new iMissileEntityID = Last_ProjectileEntity[id];
	Last_ProjectileEntity[id] = -1;
	if(iMissileEntityID != -1 && !is_nullent(iMissileEntityID)) // Takım değişiminde mermi patlatılır.
	{
		Missile_Explode(iMissileEntityID); // Mermiyi patlatır.
	}	
}

public zp_user_infected_post(id)
{
	GameLog("Astra zp_user_infected_pre");

	ZombieMode = true;
	remove_astra(id)

	g_Team[id] = 1; // Terröristler

	new iMissileEntityID = Last_ProjectileEntity[id];
	Last_ProjectileEntity[id] = -1;
	if(iMissileEntityID != -1 && !is_nullent(iMissileEntityID)) // Takım değişiminde mermi patlatılır.
	{
		Missile_Explode(iMissileEntityID); // Mermiyi patlatır.
	}	
}

public Hook_Astra(const id)
{
	engclient_cmd(id, "weapon_knife"); 
	return PLUGIN_HANDLED
}

public CBasePlayerWeapon_DefaultDeploy(const iWeaponEntityID, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[], const skiplocal) 
{
	GameLog("Astra CBasePlayerWeapon_DefaultDeploy");

	new clientIndex = get_member(iWeaponEntityID, m_pPlayer); // İşlemin uygulandığı oyuncunun kimliği bu değişkendir.
	new WeaponID = get_entvar(iWeaponEntityID, var_impulse); // Mevcut silahın kimliği bu değişkendir eğer bu değişken Astranın çalışması için gerekli kimliğe sahipse Astra çalışacaktır değilse çalışmayacaktır. 
    	if(WeaponID == Astra_WeaponID)
	{
        	SetHookChainArg(2, ATYPE_STRING, Resources[0]); // Silahın viewmodelini ayarlamamızı sağlar
        	SetHookChainArg(3, ATYPE_STRING, Resources[1]); // Silahın playermodelini ayarlamamızı sağlar
		SetHookChainArg(4, ATYPE_INTEGER, Last_ProjectileEntity[clientIndex] != -1 ? 4 : 3); // Silahı elimize alınca yapacağı animasyonu ayarlamamızı sağlar.

		SetThink(iWeaponEntityID, "WeaponAstra_IdleThink"); // Silaha hazır olma animasyonu yaptırmak için gereklidir.
       		set_entvar(iWeaponEntityID, var_nextthink, get_gametime() + 1.15); // Silahın ne kadar süre sonra hazır olma animasyonu yapması gerektiğini giriyoruz. 

		Last_WeaponID[clientIndex] = WeaponID; // Değişkeni mevcut kullandığımız silahın kimliğine eşitler.
		Last_WeaponEntityID[clientIndex] = iWeaponEntityID; // Değişkeni Astranın Entity id`sine eşitler.
	} else if(Last_WeaponEntityID[clientIndex] != NULLENT) {
		// Elimizde önceden Astra vardı ama artık başka bir silah var Astra silahının işlemlerini buradan kapatabiliriz.
		if(!is_nullent(Last_WeaponEntityID[clientIndex])) SetThink(Last_WeaponEntityID[clientIndex], ""); // Silahın tuş atamaları işlemlerini iptal eder.
		Last_WeaponID[clientIndex] = WeaponID; // Değişkeni mevcut kullandığımız silahın kimliğine eşitler.
		Last_WeaponEntityID[clientIndex] = NULLENT; // Değişkeni var olmayan Entity id`sine eşitler.
	}
}

public CBasePlayer_AddPlayerItem(const clientIndex, const iWeaponEntityID)
{
	GameLog("Astra CBasePlayer_AddPlayerItem");

	new WeaponIdType:iId = get_member(iWeaponEntityID, m_iId);

	if(iId == WEAPON_KNIFE)
	{
		if(gHasAstra[clientIndex])
		{

			new iMissileEntityID = Last_ProjectileEntity[clientIndex];
			Last_ProjectileEntity[clientIndex] = -1;
			if(iMissileEntityID != -1 && !is_nullent(iMissileEntityID)) 
			{
				Missile_Explode(iMissileEntityID);
			}

			set_entvar(iWeaponEntityID, var_impulse, Astra_WeaponID);
			
			message_begin(MSG_ONE_UNRELIABLE, Message_WeaponList, _, clientIndex);
			write_string("weapon_guillotineex");
			write_byte(-1);
			write_byte(-1);
			write_byte(-1);
			write_byte(-1);
			write_byte(2);
			write_byte(1);
			write_byte(CSW_KNIFE);
			write_byte(0);
			message_end();
		} else {
			message_begin(MSG_ONE_UNRELIABLE, Message_WeaponList, _, clientIndex);
			write_string("weapon_knife");
			write_byte(-1);
			write_byte(-1);
			write_byte(-1);
			write_byte(-1);
			write_byte(2);
			write_byte(1);
			write_byte(CSW_KNIFE);
			write_byte(0);
			message_end();
		}
	}
	
	return HC_CONTINUE;
}

public CBasePlayer_Spawn(const clientIndex)
{
	GameLog("Astra CBasePlayer_Spawn");

	Player_Alive[clientIndex] = true; // oyuncu yaşıyor
	new iMissileEntityID = Last_ProjectileEntity[clientIndex];
	Last_ProjectileEntity[clientIndex] = -1;
	if(iMissileEntityID != -1 && !is_nullent(iMissileEntityID))  // Oyuncu canlanınca mermi patlatılır.
	{
		Missile_Explode(iMissileEntityID); // Mermiyi patlatır.
	}
}

public CBasePlayer_Killed(const clientIndex)
{
	GameLog("Astra CBasePlayer_Killed");

	Player_Alive[clientIndex] = false; // oyuncu öldü
	new iMissileEntityID = Last_ProjectileEntity[clientIndex];
	Last_ProjectileEntity[clientIndex] = -1;
	if(iMissileEntityID != -1 && !is_nullent(iMissileEntityID))  // Oyuncu ölünce mermi patlatılır.
	{
		Missile_Explode(iMissileEntityID); // Mermiyi patlatır.
	}
}

public UpdateClientData_Post(clientIndex, sendweapons, cd_handle)
{
    	if (Last_WeaponEntityID[clientIndex] <= 0)
        	return FMRES_IGNORED;

	set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001);     
    	return FMRES_HANDLED;
}

public EmitSound(const clientIndex, const channel, const sample[])
{
	if((clientIndex > 0 && clientIndex < MAX_PLAYERS+1) && Last_WeaponEntityID[clientIndex] != NULLENT)
	{
		GameLog("Astra EmitSound");
		if(equal(sample, "weapons/knife_deploy1.wav")) 
		{
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public Change_Team()
{
	GameLog("Astra Change_Team");
    	new clientIndex = read_data(1);
    	new Team[2]; read_data(2, Team , 1);
	new CurrentTeam = g_Team[clientIndex];
        switch(Team[0])
       	{
            	case 'T': 
            	{
                	g_Team[clientIndex] = 1; // Terröristler
            	}
            	case 'C': 
            	{
                	g_Team[clientIndex] = 2; // Counter Terröristler
            	}
            	case 'S':
            	{
              	 	g_Team[clientIndex] = 0; // İzleyiciler
            	}
        }

	new iMissileEntityID = Last_ProjectileEntity[clientIndex];
	Last_ProjectileEntity[clientIndex] = -1;
	if(CurrentTeam != g_Team[clientIndex] && iMissileEntityID != -1 && !is_nullent(iMissileEntityID)) // Takım değişiminde mermi patlatılır.
	{
		Missile_Explode(iMissileEntityID); // Mermiyi patlatır.
	}
} 

public Item_PostFrame(const Entity)
{	
	if (Last_WeaponEntityID[get_entvar(Entity, var_owner)] > 0) return HAM_SUPERCEDE
	return HAM_IGNORED
}

public WeaponAstra_IdleThink(const iWeaponEntityID)
{
	GameLog("Astra WeaponAstra_IdleThink");

	new clientIndex = get_entvar(iWeaponEntityID, var_owner); // İşlemin uygulandığı oyuncunun kimliği bu değişkendir.

	new Viewmodel_Anim = get_entvar(clientIndex, var_weaponanim); // Viewmodelde çalışan animasyonun kodunu çekmeye yarar.

	switch(Viewmodel_Anim)
	{
		case 6: UTIL_SendWeaponAnim(clientIndex, 3), set_entvar(iWeaponEntityID, var_nextthink, get_gametime() + 1.15); // Eğer mermi kaybetme animasyonu yapıyorsa idle animasyonu için bu thinki tekrar çalıştıracak.
		case 3: 
		{
			UTIL_SendWeaponAnim(clientIndex, 0);
			SetThink(iWeaponEntityID, "WeaponAstra_ButtonThink");
			set_entvar(iWeaponEntityID, var_nextthink, get_gametime());
			// idle animasyonu yapıldı ve tuş atamalarının ayarlandığı thinke geçildi.
		}
		default: 	
		{
			UTIL_SendWeaponAnim(clientIndex, Last_ProjectileEntity[clientIndex] != -1 ? 1 : 0); 
			if(Last_ProjectileEntity[clientIndex] == -1)
			{
				SetThink(iWeaponEntityID, "WeaponAstra_ButtonThink");
				set_entvar(iWeaponEntityID, var_nextthink, get_gametime());
				// Eğer mermi fırlatılmamışsa tuş atamalarının ayarlandığı thinke geçilebilir.
			}
		}
	}
}

public WeaponAstra_ButtonThink(const iWeaponEntityID)
{
	// Eğer oyuncu bu silahı kaybederse think otomatik duracaktır o yüzden oyuncu bu silaha sahip mi ya da oyuncu serverde mi diye sorgulamaya gerek yok.
	new clientIndex = get_entvar(iWeaponEntityID, var_owner); // İşlemin uygulandığı oyuncunun kimliği bu değişkendir.
	new Button = get_entvar(clientIndex, var_button); // Oyuncunun şuan hangi tuşlara bastığını bu değişken belirtir.
	new Float:Time = get_gametime(); // Mapın bitmesi için kalan süreye eşit değişken.

	if(Button & IN_ATTACK) // Farenin sol tıkıyla mermi fırlatılır.
	{
		GameLog("Astra WeaponAstra_ButtonThink");
		new iMissileEntityID = Create_Missile(); // Fırlatılacak mermiyi burda yaratıyoruz.
		if(iMissileEntityID != NULLENT) 		
		{	
			Last_ProjectileEntity[clientIndex] = iMissileEntityID;
			
			Player_Animation(clientIndex, "ref_shoot_knife", 1.0); // Oyuncunun karakter modeline bıçakla vurma animasyonu yaptırır.
			UTIL_SendWeaponAnim(clientIndex, 7);  // Silahın viewmodeline mermi atma animasyonu yaptırmamızı sağlar. Animasyon kodunu model dosyasını açarak öğrenebilirsiniz.
			emit_sound(clientIndex, CHAN_WEAPON, Resources[4], 1.0, 0.4, 0, 94 + random_num(0, 45)); // Silahın mermi atma sesi bu kodla çalınıyor.          

			SetThink(iWeaponEntityID, "WeaponAstra_IdleThink"); // Silaha hazır olma animasyonu yaptırmak için gereklidir.
       			set_entvar(iWeaponEntityID, var_nextthink, get_gametime() + 0.75); // Silahın ne kadar süre sonra hazır olma animasyonu yapması gerektiğini giriyoruz. 

			new MissileTrigger = get_entvar(iMissileEntityID, var_iuser3); // Mermiyle triggeri birbirine bağlamıştık bu sayede kolayca Triggerin id`sini mermiden çekebilirim. 
			set_entvar(iMissileEntityID, var_iuser1, clientIndex); // Merminin sahibi olan oyuncuyu bir değişkene eşitliyoruz.
			set_entvar(MissileTrigger, var_iuser1, clientIndex); // Triggerin sahibi olan oyuncuyu bir değişkene eşitliyoruz.

			set_entvar(MissileTrigger, var_iuser2, iWeaponEntityID); // Silahı triggere bağlıyoruz çünkü trigger oyuncuya hasar verirken silaha ihtiyacımız olacak.

			// Mermiyle silahı değişkenlerle birbirine eşitliyoruzki mermide veya silahın üzerinde ayar yaparken birbirlerinin kimliğini kolaylıkla çekebilelim.
			set_entvar(iWeaponEntityID, var_iuser2, iMissileEntityID);
			set_entvar(iMissileEntityID, var_iuser2, iWeaponEntityID);
			set_entvar(iMissileEntityID, var_team, g_Team[clientIndex]); // Zombi modlarında insanken mermiyi fırlatıp zombiye dönüşürken olan bugları ortadan kaldırmamız için gereklidir.
			set_entvar(MissileTrigger, var_team, g_Team[clientIndex]); // Zombi modlarında insanken mermiyi fırlatıp zombiye dönüşürken olan bugları ortadan kaldırmamız için gereklidir.

			new Float:Angles[3], Float:Origin[3], Float:Velocity[3]; get_entvar(clientIndex, var_origin, Origin), Origin[2] += 15.0, get_entvar(clientIndex, var_v_angle, Angles), Angles[0] *= -1.0; // Oyuncunun bakış açısını çekip gerekli hale getiriyoruz.
			set_entvar(iMissileEntityID, var_angles, Angles);  // Merminin düzgün yöne bakmasını sağlıyor.
			set_entvar(iMissileEntityID, var_origin, Origin); // Merminin düzgün yerde olmasını sağlıyor.
  			velocity_by_aim(clientIndex, 1500, Velocity); // Merminin oyuncunun baktığı yöne gitmesi için gerekli hız vektörünü ayarlıyor.
			set_entvar(iMissileEntityID, var_velocity, Velocity); // Hız vektörünü varlığa uyguluyor.
			emit_sound(iMissileEntityID, CHAN_ITEM, Resources[6], 1.0, 0.4, 0, 94 + random_num(0, 45)); // Varlığın ses çıkarmasını sağlıyor.
			return; // return ekliyoruz çünkü silahın tuşlarını sürekli kullanmadığımız için thinki iptal ediyoruz.
		}
	}

	set_entvar(iWeaponEntityID, var_nextthink, Time); // Bir sonraki think işleminin çalışması için olması gereken süreyi giriyoruz.
}

Create_Missile()
{
	GameLog("Astra Create_Missile");

      	new iMissileEntityID = rg_create_entity("info_target"); // İşlevsiz yeni bir varlık yarattık değişkenide varlığın id`sine eşitledik.
	new MissileTrigger = rg_create_entity("info_target"); // İşlevsiz yeni bir varlık yarattık değişkenide varlığın id`sine eşitledik.
   	if (iMissileEntityID != NULLENT && MissileTrigger != NULLENT)
   	{
		// Burda dıştan bakınca görünecek modelin ayarları yapılıyor. Duvarlara çarpan dokunan varlık bu. 
		//remove_task(iMissileEntityID+Astra_WeaponID); // Başka bir eklenti tarafından bu idye sahip zamanlama varsa onu iptal ediyor.
		new Float:Mins[3] = { -1.0, -1.0, -1.0 }; // Dar alanlardan rahatça geçebilmesi için büyüklük değerini olabildiğince küçük giriyoruz.
		new Float:Maxs[3] = { 1.0, 1.0, 1.0 };

		engfunc(EngFunc_SetModel, iMissileEntityID, Resources[2]); // Varlığa uygulanacak model bu kodla sağlanıyor.
		set_entvar(iMissileEntityID, var_movetype, MOVETYPE_FLY); // Varlığa havada asılı kalma özelliği veriyor.
		set_entvar(iMissileEntityID, var_solid, SOLID_TRIGGER); // Varlık bu sayede oyuncuların içinden geçecek ve dokunma işlemini çalıştıracak hale geliyor ama duvarlara hala çarpabilir.

		set_entvar(iMissileEntityID, var_rendermode, kRenderTransAdd);
		set_entvar(iMissileEntityID, var_renderamt, 255.0); // Varlığa parlama veriyor.

		set_entvar(iMissileEntityID, var_animtime, get_gametime());
		set_entvar(iMissileEntityID, var_framerate, 1.0);	// Modelin animasyon yapma hızını ayarlıyor. "default: 1.0"
		set_entvar(iMissileEntityID, var_sequence, 0); // Modelin yapacağı animasyon kodunu girip animasyon yaptırabilirsiniz.  

		//set_entvar(iMissileEntityID, var_iuser4, 0); // Bunu buraya yazmaya gerek yok çünkü yeni varlık yaratılırken zaten otomatik 0`a eşit oluyor. Merminin geri dönme, hedefe gitme vb. aşamaları bu değişkenle belirtiliyor.

		set_entvar(iMissileEntityID, var_mins, Mins); // Varlığın büyüklüğünü ayarlıyor.
		set_entvar(iMissileEntityID, var_maxs, Maxs); // Varlığın büyüklüğünü ayarlıyor.

         	SetTouch(iMissileEntityID, "Missile_Touch"); // Mermi duvara çarpınca nasıl tepki vereceğini ayarlamak için gereklidir.
		SetThink(iMissileEntityID, "Missile_Think");
		set_entvar(iMissileEntityID, var_nextthink, get_gametime() + 0.75);

// 	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		// Burda oyuncuya dokunulduğunu algılayacak trigger entity ayarları yapılıyor. 2 varlık yaratmamızın sebebi mermi bu sayede dar alanlardan rahatça geçebilecek ve düşmana dokunma mesafesini dilediğimiz gibi ayarlayabileceğiz.
		//remove_task(MissileTrigger+Astra_WeaponID);

		Mins[0] = -12.0;
		Mins[1] = -12.0;
		Mins[2] = -16.5;

		Maxs[0] = 12.0;
		Maxs[1] = 12.0;
		Maxs[2] = 16.5;

		engfunc(EngFunc_SetModel, MissileTrigger, Resources[2]); // Varlığa uygulanacak model bu kodla sağlanıyor.
		
		set_entvar(MissileTrigger, var_movetype, MOVETYPE_FLY); // Varlığa havada asılı kalma özelliği veriyor.
		set_entvar(MissileTrigger, var_solid, SOLID_TRIGGER); // Varlık bu sayede oyuncuların içinden geçecek ve dokunma işlemini çalıştıracak hale geliyor ama duvarlara hala çarpabilir.

		set_entvar(MissileTrigger, var_rendermode, kRenderTransTexture); // Bu varlığı görünmez yapıyor.

		set_entvar(MissileTrigger, var_mins, Mins); // Varlığın büyüklüğünü ayarlıyor.
		set_entvar(MissileTrigger, var_maxs, Maxs); // Varlığın büyüklüğünü ayarlıyor.

       	 	SetTouch(MissileTrigger, "MissileTrigger_Touch"); // Mermi oyuncuya dokununca nasıl tepki vereceğini ayarlamak için gereklidir.
		SetThink(MissileTrigger, "MissileTrigger_Think"); // Mermiyi sürekli olması gerektiği yere ışınlar. Dokunma işleminin düzgün çalışması için gereklidir.
		set_entvar(MissileTrigger, var_nextthink, get_gametime());

		// Mermiyle Triggeri değişkenlerle birbirine eşitliyoruzki mermide veya triggerin üzerinde ayar yaparken birbirlerinin kimliğini kolaylıkla çekebilelim.
		set_entvar(MissileTrigger, var_iuser3, iMissileEntityID);
		set_entvar(iMissileEntityID, var_iuser3, MissileTrigger);

		return iMissileEntityID;
      	}
	return NULLENT;
}

public Missile_Think(const iMissileEntityID)
{	
	set_entvar(iMissileEntityID, var_iuser4, 1); // Varlık uzaklaştı ve sahibine geri dönüyor.
	SetThink(iMissileEntityID, "Missile_FollowOwner"); // Varlık sahibine geri dönme işlemleri için gerekli.
	set_entvar(iMissileEntityID, var_nextthink, get_gametime());
}

public Missile_FollowOwner(const iMissileEntityID)
{	
	new clientIndex = get_entvar(iMissileEntityID, var_iuser1);

	new Float:MissileOrigin[3], Float:OwnerOrigin[3], Float:Distance; get_entvar(iMissileEntityID, var_origin, MissileOrigin), get_entvar(clientIndex, var_origin, OwnerOrigin); // Merminin ve oyuncunun konumunu değişkene çeker.
	Distance = get_distance_f(MissileOrigin, OwnerOrigin); // Mermiyle sahibinin arasındaki uzaklığa eşittir.
	if(Distance <= 70.0) // Uzaklık 70 incden küçükse mermiyi yakalar.
	{
		GameLog("Astra Missile_FollowOwner");

		new iWeaponEntityID = Last_WeaponEntityID[clientIndex];
		if(iWeaponEntityID != NULLENT)
		{
			Player_Animation(clientIndex, "ref_shoot_knife", 1.0); // Oyuncunun karakter modeline bıçakla vurma animasyonu yaptırır.
			emit_sound(iMissileEntityID, CHAN_ITEM, "common/null.wav", 1.0, 0.4, 0, 94 + random_num(0, 45)); // Varlık yok olunca sesini kapatmak için gerekli.
			Last_ProjectileEntity[clientIndex] = -1;
			new MissileTrigger = get_entvar(iMissileEntityID, var_iuser3);
			set_entvar(MissileTrigger, var_flags, FL_KILLME);  // Triggeri yok eder.
			set_entvar(iMissileEntityID, var_flags, FL_KILLME); // Mermiyi yok eder.
			UTIL_SendWeaponAnim(clientIndex, 5);  // Silahın viewmodeline mermi yakalama animasyonu yaptırmamızı sağlar. Animasyon kodunu model dosyasını açarak öğrenebilirsiniz.
			emit_sound(clientIndex, CHAN_WEAPON, Resources[5], 1.0, 0.4, 0, 94 + random_num(0, 45)); // Silahın mermi yakalama sesi bu kodla çalınıyor.   
			SetThink(iWeaponEntityID, "WeaponAstra_IdleThink"); // Silaha hazır olma animasyonu yaptırmak için gereklidir.
       			set_entvar(iWeaponEntityID, var_nextthink, get_gametime() + 1.35); // Silahın ne kadar süre sonra hazır olma animasyonu yapması gerektiğini giriyoruz. 
		} else {
			Missile_Explode(iMissileEntityID); // Mermiyi patlatır.
		}
		return
	}

	Hook_Entity(iMissileEntityID, OwnerOrigin, Distance*3.0, clientIndex, false); // Mermiyi sahibine doğru çeker. Ne kadar uzaksa o kadar hızlı gelir.
	set_entvar(iMissileEntityID, var_nextthink, get_gametime());
}

public Missile_Touch(const iMissileEntityID, const EntityIndex)
{	
	if (EntityIndex > 0 && EntityIndex < MAX_PLAYERS+1) // Oyuncuya dokunuyorsa iptal
		return
	if(EntityIndex == get_entvar(iMissileEntityID, var_iuser3)) // Mermi eğer triggere dokunursa iptal
		return
		
	new clientIndex = get_entvar(iMissileEntityID, var_iuser1); // Silahın sahibini çeker.

	if(get_entvar(EntityIndex, var_takedamage) == DAMAGE_YES) 
	{
		GameLog("Astra Missile_Touch");
		ExecuteHamB(Ham_TakeDamage, EntityIndex, get_entvar(iMissileEntityID, var_iuser2), clientIndex, get_pcvar_float(Cvars[0]), DMG_BULLET); // Haritada kırılabilen nesnelere hasar verir.
	}
	
	new szClassName[33]; get_entvar(EntityIndex, var_classname, szClassName, charsmax(szClassName));
	if(equal(szClassName, "weaponbox")) // Yerdeki silahlara çarpmayı engelliyor.
		return;
	
	new MissileState = get_entvar(iMissileEntityID, var_iuser4); // Varlığın hangi aşamada olduğunu bu değişkenle çekebiliriz.
	if(!MissileState) 
	{
		GameLog("Astra Missile_Touch2");
		new Float:Origin[3]; get_entvar(iMissileEntityID, var_origin, Origin);
		if(ActivateSprites)
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, Origin[0])
			engfunc(EngFunc_WriteCoord, Origin[1])
			engfunc(EngFunc_WriteCoord, Origin[2] - 10)
			write_short(Sprite_Effects[2]) //	Merminin duvara çarpınca çıkardığı efekt.
			write_byte(3)
			write_byte(25)
			write_byte(14)
			message_end()
		}
		
		new Float:Range = get_pcvar_float(Cvars[6]);
		if(Range > 0.0 && !(Biohazard && !ZombieMode) && !(ZombiePlague && !ZombieMode)) // Eğer elektrik akımı mesafesi girilmişse hasar uygulanır.
		{
			Electricity(clientIndex, iMissileEntityID, Origin, Range, get_pcvar_float(Cvars[5]), 0);
		}
		
		emit_sound(iMissileEntityID, CHAN_WEAPON, Resources[9], 1.0, 0.4, 0, 94 + random_num(0, 45)); // Duvara çarpma sesi çalar.
		set_entvar(iMissileEntityID, var_iuser4, 1); // Varlık duvara çarptı ve sahibine geri dönüyor.
		SetThink(iMissileEntityID, "Missile_FollowOwner"); // Varlık sahibine geri dönme işlemleri için gerekli.
		set_entvar(iMissileEntityID, var_nextthink, get_gametime());
		return;
	} 
	

	Missile_Explode(iMissileEntityID); // Mermiyi patlatır.
}

public MissileTrigger_Think(const MissileTrigger)
{	
	new iMissileEntityID = get_entvar(MissileTrigger, var_iuser3);
	new Float:Origin[3]; get_entvar(iMissileEntityID, var_origin, Origin); // Merminin olması gerektiği konumu çeker.
	set_entvar(MissileTrigger, var_origin, Origin); // Mermiyi sürekli olması gerektiği yere ışınlar. Dokunma işleminin düzgün çalışması için gereklidir.
	set_entvar(MissileTrigger, var_nextthink, get_gametime());
}

public MissileTrigger_Touch(const MissileTrigger, const VictimIndex)
{	
	if (VictimIndex <= 0 || VictimIndex > MAX_PLAYERS+1) // Oyuncu dışında herşeye dokunuyorsa iptal
		return
	new Float:Time = get_gametime();
	new clientIndex = get_entvar(MissileTrigger, var_iuser1);

	if(Projectile_Touch_Delay[clientIndex][VictimIndex] > Time) // Mermi oyuncuya 0.1 saniyede bir dokunur.
		return

	GameLog("Astra MissileTrigger_Touch");

	Projectile_Touch_Delay[clientIndex][VictimIndex] = Time + 0.1; // Mermi oyuncuya 0.1 saniyede bir dokunur.
	new friendlyfire = get_cvar_num("mp_friendlyfire"); // Takım arkadaşına saldırmak açık mı
	if(VictimIndex != clientIndex && Player_Alive[VictimIndex] && !(!friendlyfire && g_Team[VictimIndex] == g_Team[clientIndex]) && !(Biohazard && !ZombieMode) && !(ZombiePlague && !ZombieMode)) // Canlı ve aynı takımda olmayan oyuncuları düşman sayar f
	{
		new iMissileEntityID = get_entvar(MissileTrigger, var_iuser3);
		new HitGroup = Get_MissileWeaponHitGroup(MissileTrigger);
		new Float:Origin[3]; get_entvar(iMissileEntityID, var_origin, Origin);
		new Float:HeadOrigin[3], Float:HeadAngles[3];
		engfunc(EngFunc_GetBonePosition, VictimIndex, 8, HeadOrigin, HeadAngles); // Düşman oyuncunun kafasının konumunu çekiyor.
		HeadOrigin[2] += 10.0;
		if(get_distance_f(HeadOrigin, Origin) <= get_pcvar_float(Cvars[4])) HitGroup = HIT_HEAD; // Mermi kafadan 30 incden az uzaklıktaysa kafadan sayılır.
		if(HitGroup == HIT_HEAD) // Kafadan vurulduğu için mermi değişime uğrar.
		{		
			set_entvar(iMissileEntityID, var_fuser1, Time + get_pcvar_float(Cvars[7])); // Merminin kafada ne kadar süre kalacağını ayarlıyor.
			set_entvar(iMissileEntityID, var_enemy, friendlyfire); // Takım arkadaşına saldırmak açık mı kaydediyor.
			set_entvar(iMissileEntityID, var_owner, VictimIndex);  // Düşman mermiyi sahiplendi.
			set_entvar(MissileTrigger, var_owner, VictimIndex);  // Düşman mermiyi sahiplendi.
			set_entvar(iMissileEntityID, var_effects, 8192); // Mermi sahibine görünmez olacak şekilde ayarlandı.
			SetTouch(iMissileEntityID, ""); // Dokunma fonksiyonları kapatılıyor.
			SetTouch(MissileTrigger, ""); // Dokunma fonksiyonları kapatılıyor.
			set_entvar(iMissileEntityID, var_velocity, {0.1, 0.1, 0.1}); // Varlığın hızını kesiyor.
			set_entvar(MissileTrigger, var_velocity, {0.1, 0.1, 0.1}); // Varlığın hızını kesiyor.
			SetThink(iMissileEntityID, "MissileThink_FollowPlayerHead"); // Düşmanın kafasına yerleşiyor. 
			set_entvar(iMissileEntityID, var_nextthink, get_gametime()); 
			SetThink(MissileTrigger, "TriggerThink_GivePlayerDamage"); // Düşmana hasar veriyor.
			set_entvar(MissileTrigger, var_nextthink, get_gametime() + 0.2);
			emit_sound(iMissileEntityID, CHAN_ITEM, Resources[7], 1.0, 0.4, 0, 94 + random_num(0, 45)); // Varlığın ses çıkarmasını sağlıyor.
			engfunc(EngFunc_SetModel, iMissileEntityID, Resources[3]); // Model değişimi.
		} 

		set_pdata_int(VictimIndex, 75, HitGroup, 5); // Mermi vücudun hangi bölümündeyse o bölüme hasar verir.
   		ExecuteHamB(Ham_TakeDamage, VictimIndex, get_entvar(MissileTrigger, var_iuser2), clientIndex, get_pcvar_float(Cvars[0]) * Damage_Multiplier(HitGroup), DMG_BULLET); // Hasar verme kodu
		set_pdata_float(VictimIndex, 108, 1.0, 5); // Sersemletmeyi kaldırır.
		new Float:Knockback = get_pcvar_float(Cvars[2]);
		if(Knockback > 0.0) // Eğer ittirme girilmişse ittirme etkisi uygulanır.
		{
			new Float:AttackerOrigin[3]; get_entvar(clientIndex, var_origin, AttackerOrigin);
			Hook_Entity(VictimIndex, AttackerOrigin, Knockback, 0, true)
		}
		SpawnBlood(Origin, get_pdata_int(VictimIndex, 89), HitGroup); // Kan çıkartma
	}
}

public MissileThink_FollowPlayerHead(const iMissileEntityID)
{	
	new Enemy = get_entvar(iMissileEntityID, var_owner); // Kafasında mermi olan oyuncunun id`si.
	new FriendlyFire = get_entvar(iMissileEntityID, var_enemy); // Takım arkadaşına saldırmak değer 1 e eşitse açık 0 ise kapalıdır.
	if(!Player_Alive[Enemy] || get_entvar(iMissileEntityID, var_fuser1) <= get_gametime() || (!FriendlyFire && g_Team[Enemy] == get_entvar(iMissileEntityID, var_team))) // Düşman öldüyse veya aynı takımdaysa mermi geri döner (friendlyfire yoksa).
	{
		GameLog("Astra MissileThink_FollowPlayerHead");
		Projectile_Touch_Delay[get_entvar(iMissileEntityID, var_iuser1)][Enemy] = get_gametime() + 0.6; 
		new MissileTrigger = get_entvar(iMissileEntityID, var_iuser3);
		MissileTrigger_Think(MissileTrigger);
		set_entvar(iMissileEntityID, var_owner, 0);
		set_entvar(MissileTrigger, var_owner, 0);
		set_entvar(iMissileEntityID, var_iuser4, 1); // Varlık uzaklaştı ve sahibine geri dönüyor.
		SetThink(iMissileEntityID, "Missile_FollowOwner"); // Varlık sahibine geri dönme işlemleri için gerekli.
		set_entvar(iMissileEntityID, var_nextthink, get_gametime());
		set_entvar(iMissileEntityID, var_effects, 0); // Görünmezliği kapatıyor.
		engfunc(EngFunc_SetModel, iMissileEntityID, Resources[2]);
		emit_sound(iMissileEntityID, CHAN_ITEM, Resources[6], 1.0, 0.4, 0, 94 + random_num(0, 45)); // Varlığın ses çıkarmasını sağlıyor.
		SetTouch(MissileTrigger, "MissileTrigger_Touch");
		SetThink(MissileTrigger, "MissileTrigger_Think"); // Mermiyi sürekli olması gerektiği yere ışınlar. Dokunma işleminin düzgün çalışması için gereklidir.
		set_entvar(MissileTrigger, var_nextthink, get_gametime());
		SetTouch(iMissileEntityID, "Missile_Touch");
		return
	}    
	new Float:HeadOrigin[3], Float:HeadAngles[3];
	engfunc(EngFunc_GetBonePosition, Enemy, 8, HeadOrigin, HeadAngles); // Düşman oyuncunun kafasının konumunu çekiyor.
	HeadOrigin[2] += 10.0;
	set_entvar(iMissileEntityID, var_origin, HeadOrigin); // Mermiyi sürekli olması gerektiği yere ışınlar.
	set_entvar(iMissileEntityID, var_velocity, {0.1, 0.1, 0.1}); // Merminin animasyonunun pürüzsüz görünmesini sağlar.
	set_entvar(iMissileEntityID, var_nextthink, get_gametime());
}

public TriggerThink_GivePlayerDamage(const MissileTrigger)
{
	new Enemy = get_entvar(MissileTrigger, var_owner);

	if (!is_valid_ent(Enemy) || !is_valid_ent(MissileTrigger) || !pev_valid(Enemy) || !pev_valid(MissileTrigger)) {
    		return HAM_IGNORED;
	}
 
 	if(Enemy > 0)
	{
		GameLog("Astra TriggerThink_GivePlayerDamage");
		new clientIndex = get_entvar(MissileTrigger, var_iuser1); 
		new iMissileEntityID = get_entvar(MissileTrigger, var_iuser3);
		new Float:Origin[3]; get_entvar(iMissileEntityID, var_origin, Origin);
		SpawnBlood(Origin, get_pdata_int(Enemy, 89), HIT_HEAD); // Kan çıkartma
		set_pdata_int(Enemy, 75, 1, 5); // Mermi vücudun hangi bölümündeyse o bölüme hasar verir.
   		ExecuteHamB(Ham_TakeDamage, Enemy, get_entvar(MissileTrigger, var_iuser2), clientIndex, get_pcvar_float(Cvars[1]), DMG_BULLET); // Hasar verme kodu
		set_pdata_float(Enemy, 108, 1.0, 5); // Sersemletmeyi kaldırır.
		new Float:Knockback = get_pcvar_float(Cvars[3]);
		if(Knockback > 0.0) // Eğer ittirme girilmişse ittirme etkisi uygulanır.
		{
			new Float:AttackerOrigin[3]; get_entvar(clientIndex, var_origin, AttackerOrigin);
			Hook_Entity(Enemy, AttackerOrigin, Knockback, 0, true)
		}

		new Float:Range = get_pcvar_float(Cvars[6]);
		if(Range > 0.0) // Eğer elektrik akımı mesafesi girilmişse hasar uygulanır.
		{
			Electricity(clientIndex, iMissileEntityID, Origin, Range, get_pcvar_float(Cvars[5]), Enemy);
		}
		set_entvar(MissileTrigger, var_nextthink, get_gametime() + 0.2);
	}
	return HAM_IGNORED
}

Electricity(const clientIndex, const iMissileEntityID, const Float:Origin[3], const Float:Range, const Float:RealDamage, const Enemy)
{
	GameLog("Astra Electricity");

	new Knife = get_entvar(iMissileEntityID, var_iuser2);
	new Float:Damage, TotalPlayer = 0, Float:VictimOrigin[3], Float:Distance, EntTeam = get_entvar(iMissileEntityID, var_team);
	new friendlyfire = get_cvar_num("mp_friendlyfire");
	for(new Player = 1; Player <= 32; Player++)
	{
		if(Player == Enemy)
			continue
		if(TotalPlayer >= 4) break; 
		if(!Player_Alive[Player] || (!friendlyfire && g_Team[Player] == EntTeam))
			continue
		get_entvar(Player, var_origin, VictimOrigin)
		Distance = get_distance_f(Origin, VictimOrigin);
		if(Distance > Range)
			continue

		TotalPlayer++
		Damage = floatmax(1.0, RealDamage - (Distance * (RealDamage / Range))) // Konumdan uzaklaştıkça hasar düşer.
		set_pdata_int(Player, 75, HIT_CHEST, 5)
		ExecuteHamB(Ham_TakeDamage, Player, Knife, clientIndex, Damage, DMG_BULLET)
		set_pdata_float(Player, 108, 1.0, 5); // Sersemleme etkisini ortadan kaldırır.
		if(ActivateSprites) Create_EnergyBeam(iMissileEntityID, Player, Origin, VictimOrigin)
	}
}

public Create_EnergyBeam(Ent, Enemy, const Float:Origin[3], const Float:VicOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, {0.0, 0.0, 0.0}, 0);
	write_byte(TE_BEAMENTS);
        write_short(Enemy); // start entity
	write_short(Ent); // start entity
	write_short(Sprite_Effects[1]);
	write_byte(0);		// byte (starting frame) 
	write_byte(0);		// byte (frame rate in 0.1's) 
	write_byte(2);		// byte (life in 0.1's) 
	write_byte(13);		// byte (line width in 0.1's) 
	write_byte(10);		// byte (noise amplitude in 0.01's) 
	write_byte(42);		// byte,byte,byte (color) (R)
	write_byte(212);		// (G)
	write_byte(255);		// (B)
	write_byte(255);		// byte (brightness)
	write_byte(40);		// byte (scroll speed in 0.1's)
	message_end();

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, VicOrigin[0]);
	engfunc(EngFunc_WriteCoord, VicOrigin[1]);
	engfunc(EngFunc_WriteCoord, VicOrigin[2] - 10);
	write_short(Sprite_Effects[2]);
	write_byte(5);
	write_byte(25);
	write_byte(14);
	message_end();
}

Missile_Explode(const iMissileEntityID)
{
	GameLog("Missile_Explode");

	new MissileTrigger = get_entvar(iMissileEntityID, var_iuser3); // Triggeri çeker
	new clientIndex = get_entvar(iMissileEntityID, var_iuser1); // Silahın sahibini çeker
	new iWeaponEntityID = get_entvar(iMissileEntityID, var_iuser2); // Silahı çeker.
	if(iWeaponEntityID != NULLENT) 
	{
		Last_ProjectileEntity[clientIndex] = -1;

		if(Last_WeaponEntityID[clientIndex] != NULLENT) 
		{
			UTIL_SendWeaponAnim(clientIndex, 6);  // Silahın viewmodeline mermi kırılma animasyonu yaptırmamızı sağlar. Animasyon kodunu model dosyasını açarak öğrenebilirsiniz.

			SetThink(iWeaponEntityID, "WeaponAstra_IdleThink"); // Silaha eline alma animasyonu yaptırmak için gereklidir.
			set_entvar(iWeaponEntityID, var_nextthink, get_gametime() + 1.0); // Silahın ne kadar süre sonra hazır olma animasyonu yapması gerektiğini giriyoruz. 
		}
	} 
	if(ActivateSprites)
	{
		new Float:Origin[3]; get_entvar(iMissileEntityID, var_origin, Origin);
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_EXPLOSION);
		engfunc(EngFunc_WriteCoord, Origin[0]);
		engfunc(EngFunc_WriteCoord, Origin[1]);
		engfunc(EngFunc_WriteCoord, Origin[2]-15);
		write_short(Sprite_Effects[0]);
		write_byte(5);
		write_byte(35);
		write_byte(14);
		message_end();
	}
	SetThink(MissileTrigger, "");
	SetThink(iMissileEntityID, "");
	SetTouch(MissileTrigger, "");
	SetTouch(iMissileEntityID, "");
	set_entvar(MissileTrigger, var_flags, FL_KILLME);  // Triggeri yok eder.
	set_entvar(iMissileEntityID, var_flags, FL_KILLME);  // Mermiyi yok eder.
	emit_sound(iMissileEntityID, CHAN_ITEM, Resources[8], 1.0, 0.4, 0, 94 + random_num(0, 45)); // Varlığın ses çıkarmasını sağlıyor.
}

Hook_Entity(const Entity, const Float:Target[3], const Float:Speed, const Owner, const bool:Type)
{
	new Float:EntityOrigin[3], Float:Velocity[3], Float:OwnerVelocity[3]; get_entvar(Entity, var_origin, EntityOrigin);
	new Float:Distance = get_distance_f(EntityOrigin, Target);
	new Float:fl_Time = Distance / Speed;

	if(Type) 
	{
		get_entvar(Entity, var_velocity, OwnerVelocity)
		Velocity[0] = (EntityOrigin[0] - Target[0]) / fl_Time;
		Velocity[1] = (EntityOrigin[1] - Target[1]) / fl_Time;
		Velocity[2] = OwnerVelocity[2];
	} else {
		Velocity[0] = (Target[0] - EntityOrigin[0]) / fl_Time;
		Velocity[1] = (Target[1] - EntityOrigin[1]) / fl_Time;
		Velocity[2] = (Target[2] - EntityOrigin[2]) / fl_Time;
	}

	if(Owner)
	{	
		if(!Type) get_entvar(Owner, var_velocity, OwnerVelocity)
		xs_vec_add(Velocity, OwnerVelocity, Velocity)
	}

	set_entvar(Entity, var_velocity, Velocity)
}    

UTIL_SendWeaponAnim(const clientIndex, const Sequence) 
{
	// Oyuncunun viewmodelinin hangi animasyonu yaptığını sonradan öğrenebilmemiz için gereklidir.
	set_entvar(clientIndex, var_weaponanim, Sequence);
	
	// Oyuncunun viewmodel animasyonu için client-side işlem yaptırır.
	message_begin(MSG_ONE, SVC_WEAPONANIM, _, clientIndex);
	write_byte(Sequence);
	write_byte(0);
	message_end();	
}

SpawnBlood(const Float:Origin[3], const iColor, const iBody)
{
	new Blood_Scale;
	switch (iBody)
	{
		case 1: Blood_Scale = 15; // Eğer kafaya vurulmuşsa kan daha büyük çıkar.
		default: Blood_Scale = 10;
	}

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, Origin[0]);
	engfunc(EngFunc_WriteCoord, Origin[1]);
	engfunc(EngFunc_WriteCoord, Origin[2]);
	write_short(BloodSprites[0]);
	write_short(BloodSprites[1]);
	write_byte(iColor);
	write_byte(Blood_Scale);
	message_end();
}    

Float:Damage_Multiplier(const iBody)
{
	new Float:X
	switch (iBody)
	{
		case 1: X = 4.0
		case 2: X = 1.0
		case 3: X = 1.25
		default: X = 0.75
	}
	return X
}

Get_MissileWeaponHitGroup(const iEnt)
{
	new Float:flStart[3], Float:flEnd[3];
	
	get_entvar(iEnt, var_origin, flStart);
	get_entvar(iEnt, var_velocity, flEnd);
	xs_vec_add(flStart, flEnd, flEnd);
	
	new ptr = create_tr2();
	engfunc(EngFunc_TraceLine, flStart, flEnd, 0, iEnt, ptr);
	
	new iHitGroup
	iHitGroup = get_tr2(ptr, TR_iHitgroup)
	free_tr2(ptr);
	
	return iHitGroup;
}                 

// Player modeline animasyon yaptırır.
Player_Animation(const clientIndex, const AnimName[], const Float:framerate)
{
	new AnimNum, Float:FrameRate, Float:GroundSpeed, bool:Loops;
	if ((AnimNum=lookup_sequence(clientIndex,AnimName,FrameRate,Loops,GroundSpeed))==-1) AnimNum=0;

	if (!Loops || (Loops && get_entvar(clientIndex, var_sequence)!=AnimNum))
	{
		set_entvar(clientIndex, var_sequence, AnimNum);
		set_entvar(clientIndex, var_frame, 0.0);
		set_entvar(clientIndex, var_animtime, get_gametime());	
		set_entvar(clientIndex, var_framerate, framerate);
	}

	set_pdata_int(clientIndex, 40, Loops, 4);
	set_pdata_int(clientIndex, 39, 0, 4);

	set_pdata_float(clientIndex, 36, FrameRate, 4);
	set_pdata_float(clientIndex, 37, GroundSpeed, 4);
	set_pdata_float(clientIndex, 38, get_gametime(), 4);

	set_pdata_int(clientIndex, 73, 28, 5);
	set_pdata_int(clientIndex, 74, 28, 5);
	set_pdata_float(clientIndex, 220, get_gametime(), 5);
}              

public GameLog(const Message[], any:...)
{
	#if defined DEBUG
	static Text[128]; vformat(Text, sizeof(Text) - 1, Message, 2)
	server_print("[Astra] Log: %s", Text)
	
	g_LogLine++
	static Url[128]
	
	formatex(Url, 127, "astra/log/%s.txt", g_LogName)
	write_file(Url, Text, g_LogLine)
	#endif
}

bool:is_biomod_active()
{
	if(!get_cvar_pointer("bh_starttime"))
	{
		return false
	}
	return true;
}

bool:is_zpmod_active()
{
	if(!get_cvar_pointer("zp_block_suicide"))
	{
		return false
	}
	return true;

}

stock SET_WeaponList(PlayerID, const szWeaponName[], iPrimaryAmmoID, iAmmoMaxAmount, iSecondaryAmmoID, iSecondaryAmmoMaxAmount, iSlotID, iNumberInSlot, iWeaponID, iFlags) {
	//new WeaponIdType:iId = get_member(PlayerID, m_iId);

	/*if(get_user_weapon(PlayerID) == CSW_KNIFE){
		if(get_bit(g_iAstraBitID, PlayerID)){
			set_entvar(PlayerID, var_impulse, Astra_WeaponID);
		}
	}*/
	
	message_begin(MSG_ONE, Message_WeaponList, _, PlayerID);
	write_string(szWeaponName);
	write_byte(iPrimaryAmmoID);
	write_byte(iAmmoMaxAmount);
	write_byte(iSecondaryAmmoID);
	write_byte(iSecondaryAmmoMaxAmount);
	write_byte(iSlotID);
	write_byte(iNumberInSlot);
	write_byte(iWeaponID);
	write_byte(iFlags);
	message_end();
}

stock SET_WeapPickup(PlayerID, iId) {
	message_begin(MSG_ONE, 92, _, PlayerID);
	write_byte(iId);
	message_end();
}