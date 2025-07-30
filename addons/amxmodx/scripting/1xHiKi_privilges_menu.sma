/**
 * =============================================================================
 *
 *  Privileges Menu For Zombie Plague 4.3 - Made For CS1.6 Android (Online/Offline)
 *  Allows players with privileges to access to special menu's and get a lot of features and special weapons
 *
 *  ViP Menu -> 50HP/AP/ARMOR || Guns -> GunKato && Bazook
 *  Admin Menu -> 150HP/AP/ARMOR || Guns -> M249 Nexon && Link Gun && Shiring Heat Rod || Knifes -> Astra CSO
 *  Boss Menu -> 300HP/AP/ARMOR || Guns -> Ak47 Beast && Janus-3 && Dragon Cannon && M95 Tiger
 *
 *  Plugin Name -> Privilege's Plugin (ViP/ADMIN/BOSS)
 *  Description -> Allow Players To Get Special Features/Guns
 *  Author -> PowerSiderS.X Dark (KiLiDARK)
 *  URL -> https://www.youtube.com/@moha_kun
 *
 *  Contact *
 *  Discord -> PowerSiderS.X Dark#7338
 *  Telegram -> @moha_kun
 *
 * =============================================================================
 */

#include <amxmodx>
#include <amxmisc>
#include <zombieplague>
#include <fakemeta>
#include <engine>
#include <fun>

#define PLUGIN "[ZM] VIP/ADMIN/BOSS MENU"
#define VERSION "v2.0"
#define AUTHOR "PowerSiderS.X DARK (KiLiDARK)"

// Tag Chat
new const PX[] = "ZM";

// Natives: ViP Items
native give_gk(id) // GunKato
native give_bazooka(id) // Bazooka 

// Natives: Admin Items
native give_buffm249(id) // M249 Nexon
native give_linkgun(id) // Link Gun
native give_magicmg(id) // Shining Heart Rod
native give_astra(id) // Give Astra CSO
native remove_astra(id) // Remove Astra CSO

// Natives: Boss Items
native give_ak47beast(id) // Ak47 Beast
native give_janus3(id) // Janus-3
native give_cannonex(id) // Dragon Cannon
//native give_m95tiger(id) // M95 Tiger
native give_azhi(id) // Azhi Dahaka

// ViP Functions
new limit_ammo_vip[33], used_armor_vip[33], used_health_vip[33]
new last_used_gunkato[33], last_used_bazooka[33]
new cvar_limit_ammo_vip, g_cvar_ammo_packs_vip, round_counter1

// Admin Functions
new limit_ammo_admin[33], used_armor_admin[33], used_health_admin[33]
new last_used_buffm249[33], last_used_linkgun[33], last_used_magicmg[33]
new cvar_limit_ammo_admin, g_cvar_ammo_packs_admin, round_counter2

// Boss Functions
new limit_ammo_boss[33], used_armor_boss[33], used_health_boss[33]
new last_used_ak47beast[33], last_used_janus3[33], last_used_cannonex[33], last_used_azhi[33] //, last_used_m95tiger[33]
new cvar_limit_ammo_boss, g_cvar_ammo_packs_boss, round_counter3

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	// ViP CVAR's
	cvar_limit_ammo_vip = register_cvar("zp_vip_limitammo", "2")
	g_cvar_ammo_packs_vip = register_cvar("zp_vip_ammopacks", "25")
	
	// Admin CVAR's
	cvar_limit_ammo_admin = register_cvar("zp_admin_limitammo", "3")
	g_cvar_ammo_packs_admin = register_cvar("zp_admin_ammopacks", "50")
	
	// Boss CVAR's
	cvar_limit_ammo_boss = register_cvar("zp_boss_limitammo", "6")
	g_cvar_ammo_packs_boss = register_cvar("zp_boss_ammopacks", "50")
}

public event_round_start()
{
	round_counter1++
	round_counter2++
	round_counter3++
	for(new i = 1; i <= get_maxplayers(); i++)
	{
		// ViP Limits
		limit_ammo_vip[i] = 0
		used_armor_vip[i] = false
		used_health_vip[i] = false
		
		// Admin Limits
		limit_ammo_admin[i] = 0
		used_armor_admin[i] = false
		used_health_admin[i] = false
		
		// Boss Limits
		limit_ammo_boss[i] = 0
		used_armor_boss[i] = false
		used_health_boss[i] = false
	}
}

// *** Natives ***
public plugin_natives()
{
	register_native("vip_access", "Menu_VIP", 1)
	register_native("admin_access", "Menu_ADMIN", 1)
	register_native("boss_access", "Menu_BOSS", 1)
}

// *** Privileges Menu's *** 
public Menu_VIP(id)
{
	if(!(get_user_flags(id) & ADMIN_LEVEL_A)) return PLUGIN_HANDLED

	new menuz;
	static amenu[902];
	formatex(amenu,charsmax(amenu),"^^1|• | [ZM] ^^2ViP Menu ^^1|• |^n^^1|• | ^^5By: ^^2PowerSiderS CS ^^1|• |")
	menuz = menu_create(amenu,"vip_menu_handle")
	
	if(used_armor_vip[id])
		formatex(amenu,charsmax(amenu),"^^1|• | \dTake 50 Armor")
	else
		formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take ^^550 ^^2Armor")
	menu_additem(menuz,amenu,"1")

	if(used_health_vip[id])
		formatex(amenu,charsmax(amenu),"^^1|• | \dTake 50 Health")
	else
		formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take ^^550 ^^2Health")
	menu_additem(menuz,amenu,"2")

	if(limit_ammo_vip[id] >= get_pcvar_num(cvar_limit_ammo_vip))
		formatex(amenu,charsmax(amenu),"^^1|• | \dTake 50 Ammo Pack")
	else
		formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take ^^550 ^^2Ammo Pack")
	menu_additem(menuz,amenu,"3")

	if(round_counter1 - last_used_gunkato[id] < 3)
		formatex(amenu,charsmax(amenu),"^^1|• | \dTake GunKato")
	else
		formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take GunKato")
	menu_additem(menuz,amenu,"4")
	
	if(round_counter1 - last_used_bazooka[id] < 3)
	     formatex(amenu,charsmax(amenu),"^^1|• | \dTake Bazooka")
	else
	     formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take Bazooka")
	menu_additem(menuz,amenu,"5")

	menu_setprop(menuz,MPROP_EXIT,MEXIT_ALL)
	menu_display(id,menuz,0)
	return PLUGIN_HANDLED
}

public Menu_ADMIN(id)
{
	if(!(get_user_flags(id) & ADMIN_LEVEL_B)) return PLUGIN_HANDLED

	new menuz;
	static amenu[952];
	formatex(amenu,charsmax(amenu),"^^1|• | [ZM] ^^2Admin Menu ^^1|• |^n^^1|• | ^^5By: ^^2PowerSiderS CS ^^1|• |")
	menuz = menu_create(amenu,"admin_menu_handle")
	
	if(used_armor_admin[id])
		formatex(amenu,charsmax(amenu),"^^1|• | \dTake 150 Armor")
	else
		formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take ^^5150 ^^2Armor")
	menu_additem(menuz,amenu,"1")

	if(used_health_admin[id])
		formatex(amenu,charsmax(amenu),"^^1|• | \dTake 150 Health")
	else
		formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take ^^5150 ^^2Health")
	menu_additem(menuz,amenu,"2")

	if(limit_ammo_admin[id] >= get_pcvar_num(cvar_limit_ammo_admin))
		formatex(amenu,charsmax(amenu),"^^1|• | \dTake 150 Ammo Pack")
	else
		formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take ^^5150 ^^2Ammo Pack")
	menu_additem(menuz,amenu,"3")

	if(round_counter2 - last_used_buffm249[id] < 3)
		formatex(amenu,charsmax(amenu),"^^1|• | \dTake M249 Nexon")
	else
		formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take M249 Nexon")
	menu_additem(menuz,amenu,"4")
	
	if(round_counter2 - last_used_linkgun[id] < 3)
	     formatex(amenu,charsmax(amenu),"^^1|• | \dTake Link Gun")
	else
	     formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take Link Gun")
	menu_additem(menuz,amenu,"5")
	
	if(round_counter2 - last_used_magicmg[id] < 3)
	     formatex(amenu,charsmax(amenu),"^^1|• | \dTake Shining Heart Rod")
	else
	     formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take Shining Heart Rod")
	menu_additem(menuz,amenu,"6")
	
	formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take Astra CSO")
	menu_additem(menuz,amenu,"7")
	
	formatex(amenu,charsmax(amenu),"^^1|• | ^^2Remove Astra CSO")
	menu_additem(menuz,amenu,"8")

	menu_setprop(menuz,MPROP_EXIT,MEXIT_ALL)
	menu_display(id,menuz,0)
	return PLUGIN_HANDLED
}

public Menu_BOSS(id)
{
	if(!(get_user_flags(id) & ADMIN_LEVEL_C)) return PLUGIN_HANDLED

	new menuz;
	static amenu[922];
	formatex(amenu,charsmax(amenu),"^^1|• | [ZM] ^^2Boss Menu ^^1|• |^n^^1|• | ^^5By: ^^2PowerSiderS CS ^^1|• |")
	menuz = menu_create(amenu,"boss_menu_handle")
	
	if(used_armor_boss[id])
		formatex(amenu,charsmax(amenu),"^^1|• | \dTake 300 Armor")
	else
		formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take ^^5300 ^^2Armor")
	menu_additem(menuz,amenu,"1")

	if(used_health_boss[id])
		formatex(amenu,charsmax(amenu),"^^1|• | \dTake 300 Health")
	else
		formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take ^^5300 ^^2Health")
	menu_additem(menuz,amenu,"2")

	if(limit_ammo_boss[id] >= get_pcvar_num(cvar_limit_ammo_boss))
		formatex(amenu,charsmax(amenu),"^^1|• | \dTake 300 Ammo Pack")
	else
		formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take ^^5300 ^^2Ammo Pack")
	menu_additem(menuz,amenu,"3")

	if(round_counter3 - last_used_ak47beast[id] < 3)
		formatex(amenu,charsmax(amenu),"^^1|• | \dTake Ak47 Beast")
	else
		formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take Ak47 Beast")
	menu_additem(menuz,amenu,"4")
	
	if(round_counter3 - last_used_janus3[id] < 3)
	     formatex(amenu,charsmax(amenu),"^^1|• | \dTake Janus-3")
	else
	     formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take Janus-3")
	menu_additem(menuz,amenu,"5")
	
	if(round_counter3 - last_used_cannonex[id] < 3)
	     formatex(amenu,charsmax(amenu),"^^1|• | \dTake Dragon Cannon")
	else
	     formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take Dragon Cannon")
	menu_additem(menuz,amenu,"6")
	
	if(round_counter3 - last_used_azhi[id] < 3)
	     formatex(amenu,charsmax(amenu),"^^1|• | \dTake Azhi Dahaka")
	else
	     formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take Azhi Dahaka")
	menu_additem(menuz,amenu,"7")
	
	/*
	if(round_counter3 - last_used_m95tiger[id] < 3)
	     formatex(amenu,charsmax(amenu),"^^1|• | \dTake M95 Tiger")
	else
	     formatex(amenu,charsmax(amenu),"^^1|• | ^^2Take M95 Tiger")
	menu_additem(menuz,amenu,"8")
	*/
	
	menu_setprop(menuz,MPROP_EXIT,MEXIT_ALL)
	menu_display(id,menuz,0)
	return PLUGIN_HANDLED
}

// *** Menu's Handle ***
public vip_menu_handle(id,menu,item)
{
	if(zp_get_user_nemesis(id) || zp_get_user_zombie(id))
	{
		qury_yazi(id, "^^1[^^5%s^^1] ^^2You Can't Use This Menu", PX)
		return PLUGIN_HANDLED
	}
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	new access,callback,data[6],iname[64]
	menu_item_getinfo(menu,item,access,data,5,iname,63,callback)
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
			if(used_armor_vip[id])
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You already took Armor this round!", PX)
			}
			else if(zp_get_user_zombie(id) || zp_get_user_nemesis(id))
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2This Item For Humans Only!", PX)
			}
			else
			{
				set_user_armor(id, get_user_armor(id) + 50)
				used_armor_vip[id] = true
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You received 50 Armor!", PX)
				set_task(0.1, "Menu_VIP", id)
			}
		}
		case 2:
		{
			if(used_health_vip[id])
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You already took Health this round!", PX)
			}
			else if(zp_get_user_zombie(id) || zp_get_user_nemesis(id))
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2This Item For Humans Only!", PX)
			}
			else
			{
				set_user_health(id, get_user_health(id) + 50)
				used_health_vip[id] = true
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You received 50 Health!", PX)
				set_task(0.1, "Menu_VIP", id)
			}
		}
		case 3:
		{
			if(limit_ammo_vip[id] >= get_pcvar_num(cvar_limit_ammo_vip))
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't Add Ammo Packs Again", PX)
			else
			{
				set_task(0.1, "Menu_VIP", id)
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Added Ammo Packs to your account", PX)
				limit_ammo_vip[id]++
				new g_Packs = zp_get_user_ammo_packs(id)
				zp_set_user_ammo_packs(id, g_Packs + get_pcvar_num(g_cvar_ammo_packs_vip))
			}
		}
		case 4:
		{
			if(round_counter1 - last_used_gunkato[id] < 3)
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2GunKato available in %d round(s)", PX, 3 - (round_counter1 - last_used_gunkato[id]))
			}
			else if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
			{
				give_gk(id)
				set_task(0.1, "Menu_VIP", id)
				last_used_gunkato[id] = round_counter1
				qury_yazi(id, "^^1[^^5%s^^1] ^^2GounKato granted!", PX)
			}
			else
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't use this item now!", PX)
			}
		}
		case 5:
		{
			if(round_counter1 - last_used_bazooka[id] < 3)
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Bazooka available in %d round(s)", PX, 3 - (round_counter1 - last_used_bazooka[id]))
			}
				
			else if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
			{
				give_bazooka(id)
				set_task(0.1, "Menu_VIP", id)
				last_used_bazooka[id] = round_counter1
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Bazooka granted!", PX)
			}
			else
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't use this item now!", PX)
			}
		}
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public admin_menu_handle(id,menu,item)
{
	if(zp_get_user_nemesis(id) || zp_get_user_zombie(id))
	{
		qury_yazi(id, "^^1[^^5%s^^1] ^^2You Can't Use This Menu", PX)
		return PLUGIN_HANDLED
	}
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	new access,callback,data[6],iname[64]
	menu_item_getinfo(menu,item,access,data,5,iname,63,callback)
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
			if(used_armor_admin[id])
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You already took Armor this round!", PX)
			}
			else if(zp_get_user_zombie(id) || zp_get_user_nemesis(id))
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2This Item For Humans Only!", PX)
			}
			else
			{
				set_user_armor(id, get_user_armor(id) + 150)
				used_armor_admin[id] = true
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You received 150 Armor!", PX)
				set_task(0.1, "Menu_ADMIN", id)
			}
		}
		case 2:
		{
			if(used_health_admin[id])
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You already took Health this round!", PX)
			}
			else if(zp_get_user_zombie(id) || zp_get_user_nemesis(id))
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2This Item For Humans Only!", PX)
			}
			else
			{
				set_user_health(id, get_user_health(id) + 150)
				used_health_admin[id] = true
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You received 150 Health!", PX)
				set_task(0.1, "Menu_ADMIN", id)
			}
		}
		case 3:
		{
			if(limit_ammo_admin[id] >= get_pcvar_num(cvar_limit_ammo_admin))
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't Add Ammo Packs Again", PX)
			else
			{
				set_task(0.1, "Menu_ADMIN", id)
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Added Ammo Packs to your account", PX)
				limit_ammo_admin[id]++
				new g_Packs = zp_get_user_ammo_packs(id)
				zp_set_user_ammo_packs(id, g_Packs + get_pcvar_num(g_cvar_ammo_packs_admin))
			}
		}
		case 4:
		{
			if(round_counter2 - last_used_buffm249[id] < 3)
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2M249 Nexon available in %d round(s)", PX, 3 - (round_counter2 - last_used_buffm249[id]))
			}
			else if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
			{
				give_buffm249(id)
				set_task(0.1, "Menu_ADMIN", id)
				last_used_buffm249[id] = round_counter2
				qury_yazi(id, "^^1[^^5%s^^1] ^^2M249 Nexon granted!", PX)
			}
			else
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't use this item now!", PX)
			}
		}
		case 5:
		{
			if(round_counter2 - last_used_linkgun[id] < 3)
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Link Gun available in %d round(s)", PX, 3 - (round_counter2 - last_used_linkgun[id]))
			}
				
			else if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
			{
				give_linkgun(id)
				set_task(0.1, "Menu_ADMIN", id)
				last_used_linkgun[id] = round_counter2
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Link Gun granted!", PX)
			}
			else
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't use this item now!", PX)
			}
		}
		case 6:
		{
			if(round_counter2 - last_used_magicmg[id] < 3)
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Shiring Heart Attack Available in %d round(s)", PX, 3 - (round_counter2 - last_used_magicmg[id]))
			}
				
			else if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
			{
				give_magicmg(id)
				set_task(0.1, "Menu_ADMIN", id)
				last_used_linkgun[id] = round_counter2
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Shiring Heart RoD Granted!", PX)
			}
			else
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't use this item now!", PX)
			}
		}
		case 7:
		{
			if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
			{
				give_astra(id)
			}
			else
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't use this item!", PX)
			}
		}
		case 8:
		{
			if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
			{
				remove_astra(id)
			}
			else
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't use this!", PX)
			}
		}
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public boss_menu_handle(id,menu,item)
{
	if(zp_get_user_nemesis(id) || zp_get_user_zombie(id))
	{
		qury_yazi(id, "^^1[^^5%s^^1] ^^2You Can't Use This Menu", PX)
		return PLUGIN_HANDLED
	}
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	new access,callback,data[6],iname[64]
	menu_item_getinfo(menu,item,access,data,5,iname,63,callback)
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
			if(used_armor_boss[id])
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You already took Armor this round!", PX)
			}
			else if(zp_get_user_zombie(id) || zp_get_user_nemesis(id))
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2This Item For Humans Only!", PX)
			}
			else
			{
				set_user_armor(id, get_user_armor(id) + 300)
				used_armor_boss[id] = true
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You received 300 Armor!", PX)
				set_task(0.1, "Menu_BOSS", id)
			}
		}
		case 2:
		{
			if(used_health_boss[id])
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You already took Health this round!", PX)
			}
			else if(zp_get_user_zombie(id) || zp_get_user_nemesis(id))
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2This Item For Humans Only!", PX)
			}
			else
			{
				set_user_health(id, get_user_health(id) + 300)
				used_health_boss[id] = true
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You received 300 Health!", PX)
				set_task(0.1, "Menu_BOSS", id)
			}
		}
		case 3:
		{
			if(limit_ammo_boss[id] >= get_pcvar_num(cvar_limit_ammo_boss))
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't Add Ammo Packs Again", PX)
			else
			{
				set_task(0.1, "Menu_BOSS", id)
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Added Ammo Packs to your account", PX)
				limit_ammo_boss[id]++
				new g_Packs = zp_get_user_ammo_packs(id)
				zp_set_user_ammo_packs(id, g_Packs + get_pcvar_num(g_cvar_ammo_packs_boss))
			}
		}
		case 4:
		{
			if(round_counter3 - last_used_ak47beast[id] < 3)
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Ak47 Beast Available in %d round(s)", PX, 3 - (round_counter3 - last_used_ak47beast[id]))
			}
			else if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
			{
				give_ak47beast(id)
				set_task(0.1, "Menu_BOSS", id)
				last_used_ak47beast[id] = round_counter3
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Ak47 Beast Granted!", PX)
			}
			else
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't use this item now!", PX)
			}
		}
		case 5:
		{
			if(round_counter3 - last_used_janus3[id] < 3)
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Janus-3 available in %d round(s)", PX, 3 - (round_counter3 - last_used_janus3[id]))
			}
				
			else if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
			{
				give_janus3(id)
				set_task(0.1, "Menu_BOSS", id)
				last_used_janus3[id] = round_counter3
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Janus-3 granted!", PX)
			}
			else
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't use this item now!", PX)
			}
		}
		case 6:
		{
			if(round_counter3 - last_used_cannonex[id] < 3)
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Dragon Cannon Available in %d round(s)", PX, 3 - (round_counter3 - last_used_cannonex[id]))
			}
				
			else if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
			{
				give_cannonex(id)
				set_task(0.1, "Menu_BOSS", id)
				last_used_cannonex[id] = round_counter3
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Dragon Cannon Granted!", PX)
			}
			else
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't use this item now!", PX)
			}
		}
		case 7:
		{
			if(round_counter3 - last_used_azhi[id] < 3)
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Azhi Dahaka Available in %d round(s)", PX, 3 - (round_counter3 - last_used_azhi[id]))
			}
				
			else if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
			{
				give_azhi(id)
				set_task(0.1, "Menu_BOSS", id)
				last_used_azhi[id] = round_counter3
				qury_yazi(id, "^^1[^^5%s^^1] ^^2Azhi Dahaka Granted!", PX)
			}
			else
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't use this item now!", PX)
			}
		}
		/*
		case 8:
		{
			if(round_counter3 - last_used_m95tiger[id] < 3)
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2M95 Tiger Available in %d round(s)", PX, 3 - (round_counter3 - last_used_m95tiger[id]))
			}
				
			else if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
			{
				//give_m95tiger(id)
				set_task(0.1, "Menu_BOSS", id)
				last_used_m95tiger[id] = round_counter3
				qury_yazi(id, "^^1[^^5%s^^1] ^^2M95 Tiger Granted!", PX)
			}
			else
			{
				qury_yazi(id, "^^1[^^5%s^^1] ^^2You can't use this item now!", PX)
			}
		}
		*/
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

// *** Stock Chat Function *** 
stock qury_yazi(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, sizeof(msg) - 1, input, 3)
	
	replace_all(msg, 190, "!n", "^x01")
	replace_all(msg, 190, "!g", "^x04")
	replace_all(msg, 190, "!t", "^x03")
	
	if(id) players[0] = id; else get_players(players, count, "ch")
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