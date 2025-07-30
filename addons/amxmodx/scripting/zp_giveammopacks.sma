#include <amxmodx>
#include <amxmisc>
#include <zombieplague>
#include <dhudmessage>

#define PLUGIN "Get Ammo Packs"
#define VERSION "1.0"
#define AUTHOR "ShaunCraft"

new bool:lotto[33]
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say /get", "freeap")
}

public freeap(id)
{
	new ap = zp_get_user_ammo_packs(id)
	
	if(lotto[id])
	{
		client_print_color(id, "!y[!gZP!y] !tRetry again !tafter map !tchanges to !tget more !tAmmoPacks!.")
	}
	else
	{
	new irandom = random_num(0,220)
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	
	switch(irandom)
	{
		case 0 .. 10:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g19 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 19)
		}
		case 11 .. 20:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g20 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 20)
		}
		case 21 .. 30:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g21 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 21)
		}
		case 31 .. 40:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g22 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 22)
		}
		case 41 .. 50:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g23 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 23)
		}
		case 51 .. 60:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g24 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 24)
		}
		case 61 .. 70:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g25 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 25)

		}
		case 71 .. 80:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g26 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 26)
		}
		case 81 .. 90:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g27 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 27)
		}
		case 91 .. 100:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g28 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 28)
		}
		case 101 .. 110:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g29 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 29)
		}
		case 111 .. 120:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g30 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 30)
		}
		case 121 .. 130:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g31 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 31)
		}
		case 131 .. 140:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g32 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 32)
		}
		case 141 .. 150:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g33 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 33)
		}
		case 151 .. 160:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g34 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 34)
		}
		case 161 .. 170:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g35 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 35)
		}
		case 171 .. 180:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g36 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 36)
		}
		case 181 .. 190:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g37 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 37)
		}
		case 191 .. 200:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g38 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 38)
		}
		case 201 .. 210:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g39 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 39)
		}
		case 211 .. 220:
		{
			client_print_color(id, "!y[!gZP!y] !tYou have !tjust received !g40 !tAmmoPacks, !ttry again !tafter map !tchanges!")
			zp_set_user_ammo_packs(id, ap + 40)
		}
		
	}
	lotto[id] = true
}
}

stock client_print_color(const id, const input[], any:...)  
{
	new count = 1, players[32];
	static msg[191];  
	vformat(msg, 190, input, 3);  
	replace_all(msg, 190, "!g", "^x04"); // Green Color  
	replace_all(msg, 190, "!y", "^x01"); // Default Color  
	replace_all(msg, 190, "!t", "^x03"); // Team Color  
	
	if (id) players[0] = id; else get_players(players, count, "ch");  
	{
		for (new i = 0; i < count; i++)  
		{
			if (is_user_connected(players[i]))  
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);  
				write_byte(players[i]);  
				write_string(msg);  
				message_end();  
			}
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
