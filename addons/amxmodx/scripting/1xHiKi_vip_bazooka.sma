#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <engine>
#include <hamsandwich>
#include <zombieplague>
#include <colorchat>

#define IME_PLUGINA "[ZP] Extra: Bazooka"
#define VERZIJA "1.0"
#define AUTOR "B!gBud & Opaki Crnac"

#define TE_EXPLOSION	3
#define TE_BEAMFOLLOW	22
#define TE_BEAMCYLINDER	21

// Bazooka Model
#define V_MODEL_BAZOOKA "models/bazooka/v_rpg.mdl"
#define P_MODEL_BAZOOKA "models/bazooka/p_rpg.mdl"
#define W_MODEL_BAZOOKA "models/bazooka/w_rpg.mdl"
#define ROCKET_MODLE "models/bazooka/rpgrocket.mdl"

// Bazooka Sprites
#define EXPLOSION "sprites/bazooka/bazooka_blue.spr"
#define TRAIL "sprites/bazooka/trail.spr"
#define WHITE "sprites/bazooka/ring.spr"

// Bazooka Sound
new ROCKET_SOUND[64] = "weapons/rocketfire_new.wav"
new getrocket[64] = "items/9mmclip2.wav"

new g_has_bazooka[33], g_item_bazooka
new bool:g_has_rocket[33] = false
new bool:shot[33] = false
new bool:rksound[33] = false

new Float:last_rocket[33] = 0.0
new Float:gltime = 0.0
new Float:g_soun[33] = 0.0
new trail, explosion, white

new cvar_rocket_speed, cvar_rocket_delay, cvar_bazooka_drop, cvar_dmg_rang, cavr_rocket_damage, cvar_bazooka_switchmodel

public plugin_init()
{
    register_plugin(IME_PLUGINA, VERZIJA, AUTOR)

    register_clcmd("drop", "cmdDrop")

    register_event("DeathMsg", "client_death", "a")
    register_event("CurWeapon", "check_models", "be")

    register_forward(FM_StartFrame, "fw_StartFrame")
    register_forward(FM_EmitSound, "fw_EmitSound")

    cvar_rocket_speed = register_cvar("zp_bazooka_rocket_speed", "1500.0")
    cvar_rocket_delay = register_cvar("zp_bazooka_rocket_delay", "12.0")
    cavr_rocket_damage = register_cvar("zp_bazooka_rocket_damage", "1500")
    cvar_dmg_rang = register_cvar("zp_bazooka_damage_radius", "350")
    cvar_bazooka_drop = register_cvar("zp_bazooka_drop", "1")
    cvar_bazooka_switchmodel = register_cvar("zp_bazooka_switchmodel", "1")
}

public plugin_precache()
{
    precache_model(V_MODEL_BAZOOKA)
    precache_model(P_MODEL_BAZOOKA)
    precache_model(W_MODEL_BAZOOKA)
    precache_model(ROCKET_MODLE)

    precache_sound(ROCKET_SOUND)
    precache_sound(getrocket)

    explosion = precache_model(EXPLOSION)
    trail = precache_model(TRAIL)
    white = precache_model(WHITE)
}

public plugin_natives()
{
	register_native("give_bazooka", "give_bazooka_native", 1);
}

public client_putinserver(id)
{
    bazooka_off(id)
}

public client_disconnect(id)
{
    bazooka_off(id)
}

public zp_user_infected_pre(id, infector)
{
    cmdDrop(id)
    g_has_bazooka[id] = false 
    g_has_rocket[id] = false
}

public client_death()
{
    new id = read_data(2)
    if(g_has_bazooka[id])
    {
        if(get_pcvar_num(cvar_bazooka_drop))
        {
            drop_bazooka(id)
        }
        g_has_bazooka[id] = false 
        g_has_rocket[id] = false 

    }
    return PLUGIN_CONTINUE
}

public give_bazooka_native(id)
{
    bazooka_on(id)
}

public check_models(id)
{
    if(zp_get_user_zombie(id) || zp_get_user_nemesis(id) || zp_get_user_survivor(id) || !is_user_alive(id))
        return FMRES_IGNORED

    if(g_has_bazooka[id])
    {
        new clip, ammo 
        new szWeapon = get_user_weapon(id, clip, ammo)

        if(get_pcvar_num(cvar_bazooka_switchmodel))
        {
            if(szWeapon == CSW_KNIFE)
            {
                switchmodel(id) 
            }
        }
        return PLUGIN_CONTINUE
    }
    return PLUGIN_HANDLED
}

public switchmodel(id) 
{
	entity_set_string(id,EV_SZ_viewmodel, V_MODEL_BAZOOKA)
	entity_set_string(id,EV_SZ_weaponmodel, P_MODEL_BAZOOKA)
}

public fw_EmitSound(entity, channel, const sample[])
{
    if(!is_user_alive(entity))
        return FMRES_IGNORED

    new clip, ammo 
    new szWeapon = get_user_weapon(entity, clip, ammo)
    if(g_has_bazooka[entity] && szWeapon == CSW_KNIFE)
    {
        if(equal(sample,"weapons/knife_slash1.wav")) return FMRES_SUPERCEDE
        if(equal(sample,"weapons/knife_slash2.wav")) return FMRES_SUPERCEDE
        
        if(equal(sample,"weapons/knife_deploy1.wav")) return FMRES_SUPERCEDE
        if(equal(sample,"weapons/knife_hitwall1.wav")) return FMRES_SUPERCEDE
        
        if(equal(sample,"weapons/knife_hit1.wav")) return FMRES_SUPERCEDE
        if(equal(sample,"weapons/knife_hit2.wav")) return FMRES_SUPERCEDE
        if(equal(sample,"weapons/knife_hit3.wav")) return FMRES_SUPERCEDE
        if(equal(sample,"weapons/knife_hit4.wav")) return FMRES_SUPERCEDE
        
        if(equal(sample,"weapons/knife_stab.wav")) return FMRES_SUPERCEDE
    }
    return FMRES_IGNORED
}

public fw_StartFrame()
{
    gltime = get_gametime()
    static id 
    for(id = 1; id <= 32; id++)
    {
        foward_bazooka(id)
    }
}

public foward_bazooka(id)
{
    if(!g_has_bazooka[id])
        return FMRES_IGNORED

    check_rocket(id)

    new clip, ammo 
    new szWeapon = get_user_weapon(id, clip, ammo)
    if(szWeapon == CSW_KNIFE)
    {
       if((pev(id, pev_button) & IN_ATTACK2))
       {
            if(g_soun[id] < gltime)
            {
                g_soun[id] = gltime + 1.0
            }

            attack2(id)
       }
    }
    return FMRES_IGNORED
}

public attack2(id)
{
    if(g_has_rocket[id])
    {
        new rocket = create_entity("info_target")
        if(rocket == 0) return PLUGIN_CONTINUE

        entity_set_string(rocket, EV_SZ_classname, "zp_rocket")
        entity_set_model(rocket, ROCKET_MODLE)

        entity_set_size(rocket, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0})
        entity_set_int(rocket, EV_INT_movetype, MOVETYPE_FLY)
        entity_set_int(rocket, EV_INT_solid, SOLID_BBOX)

        new Float:src[3]
        entity_get_vector(id, EV_VEC_origin, src)

        new Float:aim[3], Float:origin[3]
        VelocityByAim(id, 64, aim)
        entity_get_vector(id, EV_VEC_origin, origin)

        src[0] += aim[0]
        src[1] += aim[1]
        entity_set_origin(rocket, src)

        new Float:velocity[3], Float:angles[3]
        VelocityByAim(id, get_pcvar_num(cvar_rocket_speed), velocity)

        entity_set_vector(rocket, EV_VEC_velocity, velocity)
        vector_to_angle(velocity, angles)
        entity_set_vector(rocket, EV_VEC_angles, angles)
        entity_set_edict(rocket, EV_ENT_owner, id)
        entity_set_float(rocket, EV_FL_takedamage, 1.0)

        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(TE_BEAMFOLLOW)
        write_short(rocket)
        write_short(trail)
        write_byte(25)
        write_byte(5)
        write_byte(224)
        write_byte(224)
        write_byte(255)
        write_byte(255)
        message_end()

        emit_sound(rocket, CHAN_WEAPON, ROCKET_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM)

        shot[id] = true
        last_rocket[id] = gltime + get_pcvar_num(cvar_rocket_delay)
    }
    return PLUGIN_CONTINUE
}

public check_rocket(id)
{
    new data[1]
    data[0] = id

    if(last_rocket[id] > gltime)
    {
        g_has_rocket[id] = false 
        rksound[id] = true
    }
    else
    {
        if(shot[id])
        {
            rksound[id] = false 
            shot[id] = false
        }
        rk_sound(id)
        g_has_rocket[id] = true
    }
}

public rk_sound(id)
{
    if(!rksound[id])
    {
        engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, getrocket, 1.0, ATTN_NORM, 0, PITCH_NORM)
        client_print(id, print_center, "[Bazooka] Recargada y Lista !!!")
        rksound[id] = true
    }
    else if(rksound[id])
    {

    }
}

public cmdDrop(id)
{
    if(g_has_bazooka[id])
    {
        new clip, ammo 
        new szWeapon = get_user_weapon(id, clip, ammo)
        if(szWeapon == CSW_KNIFE)
        {
            if(get_pcvar_num(cvar_bazooka_drop))
            {
                drop_bazooka(id)
                if(!zp_get_user_zombie(id))
                {
                    entity_set_string(id,EV_SZ_viewmodel,"models/v_knife.mdl")
                    entity_set_string(id,EV_SZ_weaponmodel,"models/p_knife.mdl")
                }
                return PLUGIN_HANDLED
            }
            else
            {
                client_print(id, print_center, "You can't dsrop a jetpack!")
            }
        }
    }
    return PLUGIN_CONTINUE
}

public drop_bazooka(id)
{
    if(g_has_bazooka[id])
    {
        new Float:aim[3], Float:origin[3]

        VelocityByAim(id, 64, aim)
        entity_get_vector(id, EV_VEC_origin, origin)
        
        origin[0] += aim[0]
        origin[1] += aim[1]
        
        new bazooka = create_entity("info_target")
        entity_set_string(bazooka, EV_SZ_classname, "zp_bazooka")
        entity_set_model(bazooka, W_MODEL_BAZOOKA)	
        
        entity_set_size(bazooka, Float:{-16.0,-16.0,-16.0}, Float:{16.0,16.0,16.0})
        entity_set_int(bazooka, EV_INT_solid, 1)
        
        entity_set_int(bazooka, EV_INT_movetype, 6)
        
        entity_set_vector(bazooka, EV_VEC_origin, origin)
        
        Icon_Energy({255, 255, 0}, 0, id)
        Icon_Energy({128, 128, 0}, 0, id)
        Icon_Energy({0, 255, 0}, 0, id)

        g_has_bazooka[id] = false 
        g_has_rocket[id] = false
    }
}

public pfn_touch(ptr, ptd)
{
    if(is_valid_ent(ptr))
    {
        new classname[32]
        entity_get_string(ptr, EV_SZ_classname, classname, 31)

        if(equal(classname, "zp_bazooka"))
        {
            if(is_valid_ent(ptd))
            {
                new id = ptd
                if(id > 0 && id < 34)
                {
                    if(!g_has_bazooka[id] && !zp_get_user_zombie(id) && is_user_alive(id))
                    {
                        g_has_bazooka[id] = 1
                        g_has_rocket[id] = true 
                        client_cmd(id, "spk items/gunpickup2.wav")
                        engclient_cmd(id, "weapon_knife")
                        switchmodel(id)
                        remove_entity(ptr)
                    }
                }
            }
        }
        else if(equal(classname, "zp_rocket"))
        {
            new Float:fOrigin[3]
            new iOrigin[3]
            entity_get_vector(ptr, EV_VEC_origin, fOrigin)
            FVecIVec(fOrigin, iOrigin)
            bazooka_radius_damage(ptr)
            
            message_begin(MSG_BROADCAST,SVC_TEMPENTITY,iOrigin)
            write_byte(TE_EXPLOSION)
            write_coord(iOrigin[0])
            write_coord(iOrigin[1])
            write_coord(iOrigin[2])
            write_short(explosion)
            write_byte(30)
            write_byte(15)
            write_byte(0)
            message_end()	
            
            message_begin(MSG_ALL,SVC_TEMPENTITY,iOrigin)
            write_byte(TE_BEAMCYLINDER)
            write_coord(iOrigin[0])
            write_coord(iOrigin[1])
            write_coord(iOrigin[2])
            write_coord(iOrigin[0])
            write_coord(iOrigin[1])
            write_coord(iOrigin[2]+200)
            write_short(white)
            write_byte(0)
            write_byte(1)
            write_byte(6)
            write_byte(8)
            write_byte(1)
            write_byte(255)
            write_byte(255)
            write_byte(192)
            write_byte(128)
            write_byte(5)
            message_end()
            
            if(is_valid_ent(ptd)) 
            {
				new classname2[32]
				entity_get_string(ptd, EV_SZ_classname, classname2,31)
				
				if(equal(classname2, "func_breakable"))
					force_use(ptr, ptd)
			}
            
            remove_entity(ptr)
        }
    }
    return PLUGIN_CONTINUE
}

public bazooka_radius_damage(entity)
{
    new id = entity_get_edict(entity, EV_ENT_owner)
    for(new i = 1; i < 33; i++)
    {
        if(is_user_alive(i))
        {
            new disk = floatround(entity_range(entity, i))

            if(disk <= get_pcvar_num(cvar_dmg_rang))
            {
                new hp = get_user_health(i)
                new Float:damage = get_pcvar_float(cavr_rocket_damage)-(get_pcvar_float(cavr_rocket_damage)/get_pcvar_float(cvar_dmg_rang)) * float(disk)

                new Origin[3]
                get_user_origin(i, Origin)

                if(zp_get_user_zombie(id) != zp_get_user_zombie(i))
                {
                    if(hp > damage)
                    {
                        bazooka_take_damage(i, floatround(damage), Origin, DMG_BLAST)
                    }
                    else
                    log_kill(id, i, "Bazooka Rocket", 0)
                }
            }
        }
    }
}

stock log_kill(killer, victim, weapon[], headshot)
{
// code from MeRcyLeZZ
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
	ExecuteHamB(Ham_Killed, victim, killer, 2) // set last param to 2 if you want victim to gib
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)

	message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
	write_byte(killer)
	write_byte(victim)
	write_byte(headshot)
	write_string(weapon)
	message_end()
//
	
	if(get_user_team(killer)!=get_user_team(victim))
		set_user_frags(killer,get_user_frags(killer) +1)
	if(get_user_team(killer)==get_user_team(victim))
		set_user_frags(killer,get_user_frags(killer) -1)
		
	new kname[32], vname[32], kauthid[32], vauthid[32], kteam[10], vteam[10]

	get_user_name(killer, kname, 31)
	get_user_team(killer, kteam, 9)
	get_user_authid(killer, kauthid, 31)
 
	get_user_name(victim, vname, 31)
	get_user_team(victim, vteam, 9)
	get_user_authid(victim, vauthid, 31)
		
	log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", 
	kname, get_user_userid(killer), kauthid, kteam, 
 	vname, get_user_userid(victim), vauthid, vteam, weapon)

 	return PLUGIN_CONTINUE;
}

stock bazooka_take_damage(victim,damage,origin[3],bit) 
{
	message_begin(MSG_ONE,get_user_msgid("Damage"),{0,0,0},victim)
	write_byte(21)
	write_byte(20)
	write_long(bit)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	message_end()
	
	set_user_health(victim,get_user_health(victim)-damage)
}

public Icon_Show(icon[], color[3], mode, id) 
{
			
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusIcon"), {0,0,0}, id);
	write_byte(mode); 	// status (0=hide, 1=show, 2=flash)
	write_string(icon); 	// sprite name
	write_byte(color[0]); 	// red
	write_byte(color[1]); 	// green
	write_byte(color[2]); 	// blue
	message_end();

}

public Icon_Energy(color[3], mode, id) 
{
	
	Icon_Show("item_longjump", color, mode, id)
}

public bazooka_on(id)
{
    new clip, ammo 
    new szWeapon = get_user_weapon(id, clip, ammo)
    if(szWeapon == CSW_KNIFE)
    {
        switchmodel(id)
    }
    else
    {
        engclient_cmd(id, "weapon_knife"), switchmodel(id)
    }

    g_has_rocket[id] = true
    g_has_bazooka[id] = true
}

public bazooka_off(id)
{
    g_has_rocket[id] = false 
    g_has_bazooka[id] = false
}