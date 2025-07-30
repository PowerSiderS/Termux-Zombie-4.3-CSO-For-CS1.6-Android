#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>

#define PLUGIN "[ZP/TERMUX] Score HUD"
#define VERSION "v1.0"
#define AUTHOR "PowerSiderS.X DARK (KiLiDARK)"

// Score Round
new g_winh ,g_winz, g_roundhud

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
	set_task (0.6,"showhud",_,_,_,"b");
	g_roundhud = 1
}

// Event New Round
public event_roundstart()
{
	g_roundhud = g_winh + g_winz + 1
}

// Show Score HUD
public showhud()
{
	new red = 0, green = 150, blue = 255
	
	set_hudmessage(red, green, blue, -1.0, 0.00, 0, 0.5, 2.0, 0.08, 6.0)
	show_hudmessage(0, "• | Zombies: %d [%d] | Round: %d | [%d] %d :Humans | •^n• | Termux CSO Mod By PowerSiderS | •", 
		fn_get_zombies(), g_winz, g_roundhud, g_winh, fn_get_humans())
}

public zp_round_ended(winteam)
{
	if(winteam == WIN_ZOMBIES)
		g_winz++
	else
		g_winh++
}

// Get Alive Players [H/Z]
fn_get_humans()
{
	static iAlive, id
	iAlive = 0
	
	for (id = 1; id <= 32; id++)
	{
		if (is_user_alive(id) && !zp_get_user_zombie(id))
			iAlive++
	}
	
	return iAlive;
}

fn_get_zombies()
{
	static iAlive, id
	iAlive = 0
	
	for (id = 1; id <= 32; id++)
	{
		if (is_user_alive(id) && zp_get_user_zombie(id))
			iAlive++
	}
	
	return iAlive;
}
