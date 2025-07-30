#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>

#define PLUGIN "[ZP/TERMUX] Score HUD && Countdown"
#define VERSION "v1.0"
#define AUTHOR "SNAFFY / PowerSiderS.X DARK (KiLiDARK)"

// Score Round
new g_winh ,g_winz, g_roundhud

// Countdown Round
new countdown, countdown_snd

new const countdown_sounds[][]=
{
	"1xHiKi/count/1.wav", 
	"1xHiKi/count/2.wav", 
	"1xHiKi/count/3.wav", 
	"1xHiKi/count/4.wav", 
	"1xHiKi/count/5.wav", 
	"1xHiKi/count/6.wav",
	"1xHiKi/count/7.wav", 
	"1xHiKi/count/8.wav", 
	"1xHiKi/count/9.wav", 
	"1xHiKi/count/10.wav"
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")

	set_task (0.6,"showhud",_,_,_,"b");

	g_roundhud = 1
}

public plugin_precache() 
{
	for(new i = 0; i < sizeof countdown_sounds; i++)
		engfunc(EngFunc_PrecacheSound, countdown_sounds[i])
}

// Event New Round
public event_roundstart()
{
	remove_task(1444)
	
	countdown = 20
	countdown_snd = 9
	g_roundhud = g_winh + g_winz + 1
	
	start_countdown()
}

// Show Countdown HUD
public start_countdown()
{
	if(countdown >= 1)
	{
		set_hudmessage(10, 170, 255, -1.0, 0.26, 0, 1.0, 1.0, 0.1, 0.1)
		show_hudmessage(0, "New Round: Infection Mode (%d Second's Left!)", countdown)
		set_task(1.0,"start_countdown", 1444)
		
		if(countdown <= 10)
		{
			play_sound(0, countdown_sounds[countdown_snd])
			countdown_snd--
		}
		
		countdown--
	}
}

// Show Score HUD
public showhud()
{
	new red = 0, green = 150, blue = 255
	
	set_hudmessage(red, green, blue, -1.0, 0.00, 0, 0.5, 2.0, 0.08, 3.0)
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

stock play_sound(p_id, const ses[])
{
	if(equal(ses[strlen(ses)-4], ".mp3"))
	{
		if(p_id == 0)
			client_cmd(0,"mp3 play ^"sound/%s^"",ses)
		else if(is_user_connected(p_id))
			client_cmd(p_id,"mp3 play ^"sound/%s^"",ses)
	}
	else if(equal(ses[strlen(ses)-4], ".wav"))
	{
		if(p_id == 0)
			emit_sound(0, CHAN_AUTO, ses, VOL_NORM, ATTN_NORM , 0, PITCH_NORM)
		else if(is_user_connected(p_id))
			emit_sound(p_id, CHAN_AUTO, ses, VOL_NORM, ATTN_NORM , 0, PITCH_NORM)
	}
}