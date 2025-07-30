#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

/* The info of this plugin */
#define PLUGIN_VERSION "0.7"
#define PLUGIN_TAG "^1[^4ZP^1]"

/* Just dont touch it */
#define CAMERA_OWNER EV_INT_iuser1
#define CAMERA_CLASSNAME "trigger_camera"
#define CAMERA_MODEL "models/rpgrocket.mdl"

new bool:g_bInThirdPerson[33] = false;
new g_pCvar_fCameraDistance, g_pCvar_iCameraForced;

public plugin_init() 
{
	register_plugin("Obscura Cam", PLUGIN_VERSION, "Nani (SkumTomteN@Alliedmodders)")

	register_think(CAMERA_CLASSNAME, "FW_CameraThink")
	
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	
	g_pCvar_iCameraForced = register_cvar("cam_forced", "0")
	g_pCvar_fCameraDistance = register_cvar("cam_distance", "150.0")
	
	register_clcmd("say /cam", "CMD_ToggleCam")
	register_clcmd("sayteam /cam", "CMD_ToggleCam")
}

public plugin_precache() 
{
	precache_model(CAMERA_MODEL)
}

public plugin_natives()
{
	register_native("set_user_camera", "Native_SetCamera", 1)
	register_native("get_user_camera", "Native_GetCamera", 1)
}

public Native_SetCamera(iPlayer, Thirdperson)
{
	if(!is_user_alive(iPlayer))
		return;
	
	if(!Thirdperson) 
	{
		Set_CameraEnt(iPlayer)
	}
	else 
	{
		Remove_CameraEnt(iPlayer, 1)
	}
}

public Native_GetCamera(iPlayer)
{
	if(!is_user_connected(iPlayer) || !g_bInThirdPerson[iPlayer])
		return 0;
	
	return 1;
}

public client_disconnect(iPlayer) 
{
	Remove_CameraEnt(iPlayer, 0)
}

public fw_PlayerSpawn_Post(iPlayer) 
{ 
	if(!is_user_alive(iPlayer)) 
		return HAM_IGNORED;
	
	if(g_bInThirdPerson[iPlayer] || get_pcvar_num(g_pCvar_iCameraForced)) 
	{ 
		Set_CameraEnt(iPlayer) 
	} 
	else 
	{ 
		Remove_CameraEnt(iPlayer, 1) 
	} 
	return HAM_HANDLED;
}  

public fw_PlayerKilled_Post(iVictim, iKiller, iShouldGIB)
{	
	if(!is_user_connected(iVictim) || is_user_alive(iVictim))
		return HAM_IGNORED;
	
	if(g_bInThirdPerson[iVictim])
	{
		Remove_CameraEnt(iVictim, 0)
	}
	return HAM_HANDLED;
}

public CMD_ToggleCam(iPlayer) 
{ 
    if(get_pcvar_num(g_pCvar_iCameraForced)) 
    { 
        client_print_color(iPlayer, print_team_default, "%s ^1Camera is forced on ^3third person^1 by server manager!", PLUGIN_TAG) 
        return; 
    } 
     
    g_bInThirdPerson[iPlayer] = ~g_bInThirdPerson[iPlayer] 
     
    if(is_user_alive(iPlayer)) 
    { 
        if(g_bInThirdPerson[iPlayer]) 
        { 
            Set_CameraEnt(iPlayer)  
        } 
        else  
        { 
            Remove_CameraEnt(iPlayer, 1) 
        } 
    } 
    else /* He toggles when not alive */ 
    { 
        client_print_color(iPlayer, print_team_default, "%s ^1Your camera will be ^3%s ^1when you spawn!", PLUGIN_TAG, g_bInThirdPerson[iPlayer] ? "Third Person" : "First Person") 
    } 
}  

public Set_CameraEnt(iPlayer)
{
	new iEnt = create_entity(CAMERA_CLASSNAME);
	if(!is_valid_ent(iEnt)) return;

	entity_set_model(iEnt, CAMERA_MODEL)
	entity_set_int(iEnt, CAMERA_OWNER, iPlayer)
	entity_set_string(iEnt, EV_SZ_classname, CAMERA_CLASSNAME)
	entity_set_int(iEnt, EV_INT_solid, SOLID_NOT)
	entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_FLY)
	entity_set_int(iEnt, EV_INT_rendermode, kRenderTransTexture)

	attach_view(iPlayer, iEnt)

	entity_set_float(iEnt, EV_FL_nextthink, get_gametime())
}

public Remove_CameraEnt(iPlayer, AttachView)
{
	if(AttachView) attach_view(iPlayer, iPlayer)

	new iEnt = -1;
	while((iEnt = find_ent_by_class(iEnt, CAMERA_CLASSNAME)))
	{
		if(!is_valid_ent(iEnt))
			continue;
		
		if(entity_get_int(iEnt, CAMERA_OWNER) == iPlayer) 
		{
			entity_set_int(iEnt, EV_INT_flags, FL_KILLME)
			dllfunc(DLLFunc_Think, iEnt)
		}
	}
}

public FW_CameraThink(iEnt)
{
	new iOwner = entity_get_int(iEnt, CAMERA_OWNER);
	if(!is_user_alive(iOwner) || is_user_bot(iOwner))
		return;
	if(!is_valid_ent(iEnt))
		return;

	new Float:fPlayerOrigin[3], Float:fCameraOrigin[3], Float:vAngles[3], Float:vBack[3];

	entity_get_vector(iOwner, EV_VEC_origin, fPlayerOrigin)
	entity_get_vector(iOwner, EV_VEC_view_ofs, vAngles)
		
	fPlayerOrigin[2] += vAngles[2];
			
	entity_get_vector(iOwner, EV_VEC_v_angle, vAngles)

	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vBack) 

	fCameraOrigin[0] = fPlayerOrigin[0] + (-vBack[0] * get_pcvar_float(g_pCvar_fCameraDistance)) 
	fCameraOrigin[1] = fPlayerOrigin[1] + (-vBack[1] * get_pcvar_float(g_pCvar_fCameraDistance)) 
	fCameraOrigin[2] = fPlayerOrigin[2] + (-vBack[2] * get_pcvar_float(g_pCvar_fCameraDistance)) 

	engfunc(EngFunc_TraceLine, fPlayerOrigin, fCameraOrigin, IGNORE_MONSTERS, iOwner, 0) 
	
	new Float:flFraction; get_tr2(0, TR_flFraction, flFraction) 
	if(flFraction != 1.0)
	{ 
		flFraction *= get_pcvar_float(g_pCvar_fCameraDistance); /* Automatic :) */
	
		fCameraOrigin[0] = fPlayerOrigin[0] + (-vBack[0] * flFraction) 
		fCameraOrigin[1] = fPlayerOrigin[1] + (-vBack[1] * flFraction) 
		fCameraOrigin[2] = fPlayerOrigin[2] + (-vBack[2] * flFraction) 
	} 
	
	entity_set_vector(iEnt, EV_VEC_origin, fCameraOrigin)
	entity_set_vector(iEnt, EV_VEC_angles, vAngles)

	entity_set_float(iEnt, EV_FL_nextthink, get_gametime())
}