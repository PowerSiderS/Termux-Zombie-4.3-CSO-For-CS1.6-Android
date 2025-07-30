/*================================================================================
	
	--------------------------------
	-*- [ZP] Extra Items Example -*-
	--------------------------------
	
	~~~~~~~~~~~~~~~
	- Description -
	~~~~~~~~~~~~~~~
	
	This is just an example on how to add additional extra items to ZP.
	
================================================================================*/

#include <amxmodx>
#include <zombieplague>

// Item IDs
new g_itemid1, g_itemid2, g_itemid3

public plugin_init()
{
	register_plugin("[ZP] Additional Extra Items", "0.1", "Example")
	
	// Register the new items and store their IDs for future reference
	g_itemid1 = zp_register_extra_item("My Extra Item 1", 2, ZP_TEAM_ZOMBIE) // Zombies only
	g_itemid2 = zp_register_extra_item("My Extra Item 2", 3, ZP_TEAM_HUMAN | ZP_TEAM_SURVIVOR) // Humans and Survivor only
	g_itemid3 = zp_register_extra_item("My Extra Item 3", 4, ZP_TEAM_NEMESIS) // Nemesis only
}

// Item Selected forward
public zp_extra_item_selected(player, itemid)
{
	// Check if the selected item matches any of our registered ones
	if (itemid == g_itemid1)
		client_print(player, print_chat, "[ZP] You have purchased My extra item 1!")
	else if (itemid == g_itemid2)
		client_print(player, print_chat, "[ZP] You have purchased My extra item 2!")
	else if (itemid == g_itemid3)
		client_print(player, print_chat, "[ZP] You have purchased My extra item 3!")
}
