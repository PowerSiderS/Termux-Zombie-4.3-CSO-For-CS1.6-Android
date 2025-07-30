#include <amxmodx>
#include <zombieplague>
#include <hamsandwich>

public plugin_init() {
    register_plugin("ZP: Zombie Health", "1.0", "Yakess")
    
    RegisterHam(Ham_TakeDamage, "player", "fw_Player_TakeDamage_Post", 1)
}

public fw_Player_TakeDamage_Post(id)
{
    new killer = get_user_attacker(id)
    if(zp_get_user_zombie(id)) 
    client_print(killer,print_center,"• [Health: %i] •",get_user_health(id))
}  
