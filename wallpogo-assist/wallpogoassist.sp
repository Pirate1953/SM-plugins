#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION	"1.0.1"

bool WP_ENABLED[MAXPLAYERS + 1];
bool FOL_ENABLED[MAXPLAYERS + 1];
bool PL_Enabled;

Handle HudDisplay;

ConVar g_pluginEnabled;

public Plugin:myinfo =
{
	name = "Wall Pogo Assistant",
	author = "Master Cake",
	description = "This plugin helps jumpers to learn Wall Pogo",
	version = PLUGIN_VERSION,
	url = ""
};

/**
 * Called when the plugin is fully initialized and all known external references are resolved
 */
public OnPluginStart()
{
	CreateConVar("wp_version", PLUGIN_VERSION, "Wall Pogo Assistant Version", FCVAR_REPLICATED | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_pluginEnabled = CreateConVar("wp_enabled", "1", "Enable Wall Pogo Assistant\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	PL_Enabled = GetConVarBool(g_pluginEnabled);

	HookConVarChange(g_pluginEnabled, ConsoleVarChange);

	RegConsoleCmd("sm_wp", WP_Command, "Command to enable/disable Wall Pogo Assistant");

	RegAdminCmd("sm_followrockets", FOL_Command, ADMFLAG_GENERIC, "Command to enable/disable Follow Rockets Mode");

	AutoExecConfig(true, "wp");
	HudDisplay = CreateHudSynchronizer();
}

/**
 * Called when a console variable's value is changed
 */
public ConsoleVarChange(Handle:CVar, const String:oldValue[], const String:newValue[])
{
	if(CVar == g_pluginEnabled)
	{
		PL_Enabled = GetConVarBool(g_pluginEnabled);
	}
}

/**
 * Called when the plugin is fully initialized and all known external references are resolved
 * @param myClient - Client index
 */
public OnClientPutInServer(myClient)
{
	WP_ENABLED[myClient] = false;
	FOL_ENABLED[myClient] = false;
}

/**
 * Enables Wall Pogo Assistant for client
 * @param myClient - Client index
 * @param args - Number of arguments that were in the argument string
 * @return - Action
 */
public Action:WP_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (!WP_ENABLED[myClient])
	{
    	WP_ENABLED[myClient] = true;
    	ReplyToCommand(myClient, "[SM] Wall Pogo Assistant Enabled!");
    	return Plugin_Continue;
    }
	if (WP_ENABLED[myClient])
    {
    	WP_ENABLED[myClient] = false;
    	ReplyToCommand(myClient, "[SM] Wall Pogo Assistant Disabled!");
    }

	return Plugin_Handled;
}

/**
 * Enables Follow Rockets Mode for client
 * @param myClient - Client index
 * @param args - Number of arguments that were in the argument string
 * @return - Action
 */
public Action:FOL_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (!FOL_ENABLED[myClient])
	{
    	FOL_ENABLED[myClient] = true;
    	ReplyToCommand(myClient, "[SM] Follow Rockets Mode Enabled!");
    	return Plugin_Continue;
    }

	if (FOL_ENABLED[myClient])
    {
    	FOL_ENABLED[myClient] = false;
    	ReplyToCommand(myClient, "[SM] Follow Rockets Mode Disabled!");
    }

	return Plugin_Handled;
}

/**
 * Called when a clients movement buttons are being processed
 * @param myClient - Client index
 * @param myButtons - Copyback buffer containing the current commands
 * @param myImpulse - Copyback buffer containing the current impulse command
 * @param myVel - Players desired velocity
 * @param myAng - Players desired view angles
 * @param myWeapon - Entity index of the new weapon if player switches weapon, 0 otherwise
 * @return - Action
 */
public Action:OnPlayerRunCmd(myClient, &myButtons, &myImpulse, Float:myVel[3], Float:myAng[3], &myWeapon)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if(IsPlayerAlive(myClient) && IsValidClient(myClient) && WP_ENABLED[myClient] && myButtons & IN_DUCK)
	{
    	float FL_Angles[3];
    	GetClientEyeAngles(myClient, FL_Angles);

    	if (FL_Angles[0] >= 75.0 && FL_Angles[0] <= 79.9)
    	{
    		ClearSyncHud(myClient, HudDisplay);
    		SetHudTextParams(0.475, 0.4, 0.1, 0, 0, 255, 0, 0, 0.1, 0.1, 0.1);
    		ShowSyncHudText(myClient, HudDisplay, "▲▲▲");
    		return Plugin_Continue;
    	}
    	if (FL_Angles[0] >= 80.55 && FL_Angles[0] <= 81.0)
    	{
    		ClearSyncHud(myClient, HudDisplay);
    		SetHudTextParams(0.475, 0.55, 0.1, 0, 255, 0, 0, 0, 0.1, 0.1, 0.1);
    		ShowSyncHudText(myClient, HudDisplay, "▼▼▼");
    		return Plugin_Continue;
    	}

    	if (FL_Angles[0] >= 80.0 && FL_Angles[0] <= 80.54)
    	{
    		ClearSyncHud(myClient, HudDisplay);
    		SetHudTextParams(0.44, 0.483, 0.1, 255, 255, 0, 0, 0, 0.1, 0.1, 0.1);
    		ShowSyncHudText(myClient, HudDisplay, "►►►    ◄◄◄");
    		return Plugin_Continue;
    	}
	}
	return Plugin_Continue;
}

/**
 * Creates the hook when entity is created
 * @param myEntity - Entity index for which function creates the hook
 * @param MyName - Class name
 */
public void OnEntityCreated(int myEntity, const char[] MyName)
{
	if (StrContains(MyName, "tf_projectile_") == 0)
	{
		if (StrEqual(MyName[14], "rocket"))
		{
			SDKHook(myEntity, SDKHook_SpawnPost, RockSpawn);
		}
	}
}

/**
 * Creates the timer when entity (rocket) is released
 * @param myEntity - Entity index for which function creates the beam
 * @return - Action
 */
public Action:RockSpawn(int myEntity)
{
	new myRef = EntIndexToEntRef(myEntity); //Converts an entity index into a serial encoded entity reference.
	static PrevRef = -1;

	if (PL_Enabled && PrevRef != myRef)
	{
		PrevRef = myRef; //To execute the code 1 time in this scope

		int myOwner = GetEntPropEnt(myEntity, Prop_Data, "m_hOwnerEntity");

		if (IsValidClient(myOwner) && FOL_ENABLED[myOwner])
		{
			CreateTimer(0.0005, rocketCheck, myEntity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

/**
 * Changes velocity, rotation and abs vectors for the given entity
 * @param myEntity - Entity index for which function changes vectors
 * @return - Action
 */
public Action:rocketCheck(Handle timer, int myEntity)
{
	if(!IsValidEntity(myEntity))
	{
		return Plugin_Stop;
	}

	int myOwner = GetEntPropEnt(myEntity, Prop_Data, "m_hOwnerEntity");
	float FL_PosEntity[3];
	float FL_AngEntity[3];
	float FL_VelEntity[3];

	float FL_TargetPos[3];
	float FL_TargetVec[3];

	float FL_MidVector[3];

	if (FOL_ENABLED[myOwner])
	{
		GetTargetOfPlayerEye(myOwner, FL_TargetPos);

		GetEntPropVector(myEntity, Prop_Data, "m_vecAbsOrigin", FL_PosEntity);
		GetEntPropVector(myEntity, Prop_Data, "m_angRotation", FL_AngEntity);
		GetEntPropVector(myEntity, Prop_Data, "m_vecAbsVelocity", FL_VelEntity);

		float FL_VelRock = GetVectorLength(FL_VelEntity);

		SubtractVectors(FL_TargetPos, FL_PosEntity, FL_TargetVec); //Distance to target

		AddVectors(FL_VelEntity, FL_TargetVec, FL_MidVector);
		AddVectors(FL_VelEntity, FL_MidVector, FL_VelEntity);
		NormalizeVector(FL_VelEntity, FL_VelEntity);

		GetVectorAngles(FL_VelEntity, FL_AngEntity);
		SetEntPropVector(myEntity, Prop_Data, "m_angRotation", FL_AngEntity);

		ScaleVector(FL_VelEntity, FL_VelRock); //Scales vector to initial value size
		SetEntPropVector(myEntity, Prop_Data, "m_vecAbsVelocity", FL_VelEntity);

		return Plugin_Continue;
	}
	return Plugin_Continue;
}

/**
 * Filters the entity
 * @param myEntity - Entity index for filtering
 * @param MyName - Mask for filtering
 * @param myData - Data for filtering
 * @return - True to allow the current entity to be hit, otherwise false
 */
public bool TraceFilter(int myEntity, int myMask, any myData)
{
	if (myEntity <= 0)
		return true;
	if (myEntity == myData)
		return false;

	char myClassName[128];
	GetEdictClassname(myEntity, myClassName, sizeof(myClassName));
	if(StrEqual(myClassName,"func_respawnroomvisualizer", false))
	{
		return false;
	}
	else
	{
		return true;
	}
}

/////////////////////////////// <-- STOCKS --> ////////////////////////////////////////////////

/**
 * Returns false if client is invalid, true otherwise
 * @param myClient - Client index
 * @param Replay - Logical bool parameter
 * @return - False if client is invalid, true otherwise
 */
stock bool:IsValidClient(myClient, bool:Replay = true)
{
  if(myClient <= 0 || myClient > MaxClients || !IsClientInGame(myClient))
    return false;
  if(Replay && (IsClientSourceTV(myClient) || IsClientReplay(myClient) || IsClientObserver(myClient)))
    return false;
  return true;
}

/**
 * Gets position vector where client looks
 * @param myClient - Client index
 * @param FL_TargetPos - Output buffer that stores received vector
 */
 stock void GetTargetOfPlayerEye(int myClient, float FL_TargetPos[3])
 {
 	float FL_Pos[3];
 	float FL_Ang[3];

 	GetClientEyePosition(myClient, FL_Pos);
 	GetClientEyeAngles(myClient, FL_Ang);

 	Handle Trace = TR_TraceRayFilterEx(FL_Pos, FL_Ang, MASK_SHOT_HULL, RayType_Infinite, TraceFilter, myClient);

 	if(TR_DidHit(Trace))
	{
		TR_GetEndPosition(FL_TargetPos, Trace);
	}
	delete Trace;
 }