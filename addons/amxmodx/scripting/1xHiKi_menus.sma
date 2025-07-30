#include <amxmodx>
#include <amxmisc>

#define PLUGIN "[ZM] Player's & Privilege's Menu"
#define VERSION "1.0"
#define AUTHOR "PowerSiderS.X Dark (KiLiDARK)"

#define TAG "ZM"

// Privileges Natives
native vip_access(id)
native admin_access(id)
native boss_access(id)

public plugin_init() 
{
	register_plugin("PLUGIN", "VERSION", "AUTHOR")	
}

public plugin_natives()
{
	register_native("players_menu", "Player_Menu", 1)
	register_native("privileges_menu", "Privilege_Menu", 1)
}

public Player_Menu(id) 
{
		new menu, Menuz[800]
		formatex(Menuz, charsmax(Menuz), "^^1|• | ^^2Player's Menu ^^1|• |^n^^1|• | ^^2YouTube.com/@moha_kun ^^1|• |")
		menu = menu_create(Menuz, "Handler_Player")

		formatex(Menuz, charsmax(Menuz), "^^1|• | ^^2Switch Camera ^^1|• |")
		menu_additem(menu, Menuz, "1")
		formatex(Menuz, charsmax(Menuz), "^^1|• | ^^2Get Rewards ^^1|• |")
		menu_additem(menu, Menuz, "2")

		formatex(Menuz, charsmax(Menuz), "^^2Exit")
		
		menu_setprop(menu, MPROP_EXITNAME,Menuz)
		
		menu_display(id, menu, 0)

		return PLUGIN_HANDLED
}

public Handler_Player(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data, 5, iName, 63, callback);

	new key = str_to_num(data);
	
	switch (key)
	{
		case 1:
		{
			if(is_user_alive(id))
			{
				client_cmd(id, "say /cam")
			}
			else
			{
				qury_yazi(id, "^^1[%s] ^^2Not Alive ^^1|| ^^2You're Dead!.");
			}
		}
		case 2:
		{
			client_cmd(id, "say /get")
		}
	}
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public Privilege_Menu(id) 
{
		new menu, Menuz[800]
		formatex(Menuz, charsmax(Menuz), "^^1|• | ^^2Privilege's Menu^^1|• |^n^^1|• | ^^2YouTube.com/@moha_kun ^^1|• |")
		menu = menu_create(Menuz, "Handler_Privileges")

		if(get_user_flags(id) & ADMIN_LEVEL_A)
		{
			formatex(Menuz, charsmax(Menuz), "^^1|• | ^^2ViP Menu ^^1|• |")
		}
		else
		{
			formatex(Menuz, charsmax(Menuz), "^^1|• | \dViP Menu ^^1|• |")
		}
		menu_additem(menu, Menuz, "1")
		
		if(get_user_flags(id) & ADMIN_LEVEL_B)
		{
			formatex(Menuz, charsmax(Menuz), "^^1|• | ^^2Admin Menu ^^1|• |")
		}
		else
		{
			formatex(Menuz, charsmax(Menuz), "^^1|• | \dAdmin Menu ^^1|• |")
		}
		menu_additem(menu, Menuz, "2")
		
		if(get_user_flags(id) & ADMIN_LEVEL_C)
		{
			formatex(Menuz, charsmax(Menuz), "^^1|• | ^^2Boss Menu ^^1|• |")
		}
		else
		{
			formatex(Menuz, charsmax(Menuz), "^^1|• | \dBoss Menu ^^1|• |")
		}
		menu_additem(menu, Menuz, "3")

		formatex(Menuz, charsmax(Menuz), "^^2Exit")
		
		menu_setprop(menu, MPROP_EXITNAME,Menuz)
		
		menu_display(id, menu, 0)

		return PLUGIN_HANDLED
}

public Handler_Privileges(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data, 5, iName, 63, callback);

	new key = str_to_num(data);
	
	switch (key)
	{
		case 1:
		{
			if(get_user_flags(id) & ADMIN_LEVEL_A)
			{
				vip_access(id)
			}
			else
			{
				qury_yazi(id, "^^1[%s] ^^2No Access ^^1|| ^^2You're Not ViP!.");
			}
		}
		case 2:
		{
			if(get_user_flags(id) & ADMIN_LEVEL_B)
			{
				admin_access(id)
			}
			else
			{
				qury_yazi(id, "^^1[%s] ^^2No Access ^^1|| ^^2You're Not Admin!.");
			}
		}
		case 3:
		{
			if(get_user_flags(id) & ADMIN_LEVEL_C)
			{
				boss_access(id)
			}
			else
			{
				qury_yazi(id, "^^1[%s] ^^2No Access ^^1|| ^^2You're Not Boss!.");
			}
		}
	}
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
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