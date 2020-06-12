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

public ConsoleVarChange(Handle:CVar, const String:oldValue[], const String:newValue[])
{
	if(CVar == g_pluginEnabled)
	{
		PL_Enabled = GetConVarBool(g_pluginEnabled);
	}
}

public OnClientPutInServer(myClient)
{
	WP_ENABLED[myClient] = false;
	FOL_ENABLED[myClient] = false;
}

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
 * Checks client validity
 * @param myEntity        Entity index.
 * @param Replay          Logical bool parameter.
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
 * Gets vector where player looks
 * @param myEntity        Entity index.
 * @param FL_TargetPos    Output buffer.
 */
 stock void GetTargetOfPlayerEye(int myEntity, float FL_TargetPos[3])
 {
 	float FL_Pos[3];
 	float FL_Ang[3];

 	GetClientEyePosition(myEntity, FL_Pos);
 	GetClientEyeAngles(myEntity, FL_Ang);

 	Handle Trace = TR_TraceRayFilterEx(FL_Pos, FL_Ang, MASK_SHOT_HULL, RayType_Infinite, TraceFilter, myEntity);

 	if(TR_DidHit(Trace))
	{
		TR_GetEndPosition(FL_TargetPos, Trace);
	}
	delete Trace;
 }