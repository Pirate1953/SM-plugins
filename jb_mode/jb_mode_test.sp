#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new bool:JB_ENABLED[MAXPLAYERS + 1];
new g_sprite;
new bool:FLAG[MAXPLAYERS + 1];

float FL_PosTarget[MAXPLAYERS + 1][3];
float FL_Ang[MAXPLAYERS + 1][3];
float FL_Pos[MAXPLAYERS + 1][3];
float FL_PosEnd[MAXPLAYERS + 1][3];
float FL_Vel[MAXPLAYERS + 1][3];

float FL_PosEntity[MAXPLAYERS + 1][3];

public Plugin:myinfo =
{
	name = "JB Mode",
	author = "Master Cake",
	description = "Just Simple Plugin LOL",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_jjb", JB_Command, "Command to enable/disable JB Mode");
}

public OnMapStart()
{
	g_sprite = PrecacheModel("materials/sprites/laser.vmt");
}

public OnClientPutInServer(myClient)
{
	JB_ENABLED[myClient] = false;
	FLAG[myClient] = false;
}

public Action:JB_Command(myClient, args)
{
    if (args > 0 ) {
   		ReplyToCommand(myClient, "[SM] This command has no arguments!");
   		return Plugin_Continue;
    }
    else {
    	if (!JB_ENABLED[myClient]) {
    		JB_ENABLED[myClient] = true;
    		ReplyToCommand(myClient, "[SM] JB Mode Enabled!");
    	}
    	else {
    		JB_ENABLED[myClient] = false;
    		ReplyToCommand(myClient, "[SM] JB Mode Disabled!");
    	}
    }

    return Plugin_Handled;
}

public Action:OnPlayerRunCmd(myClient, &myButtons, &myImpulse, Float:fVel[3], Float:fAngles[3], &myWeapon)
{
	GetEntPropVector(myClient, Prop_Data, "m_vecAbsVelocity", FL_Vel[myClient]);
	if(IsPlayerAlive(myClient) && IsValidClient(myClient) && JB_ENABLED[myClient] && (FL_Vel[myClient][0] != 0.0 || FL_Vel[myClient][1] != 0.0 || FL_Vel[myClient][2] != 0.0))
	{
		int color[4];
		color[0] = 025;
		color[1] = 144;
		color[2] = 255;
		color[3] = 255;

		if (!FLAG[myClient])
		{
			GetClientEyePosition(myClient, FL_Pos[myClient]);
			FL_Pos[myClient][2] -= 20.0;
			FLAG[myClient] = true;
			return Plugin_Continue;
		}
		if (FLAG[myClient])
		{
			GetClientEyePosition(myClient, FL_PosEnd[myClient]);
			FL_PosEnd[myClient][2] -= 20.0;
			TE_SetupBeamPoints(FL_Pos[myClient], FL_PosEnd[myClient], g_sprite, 0, 0, 0, 5.0, 25.0, 25.0, 10, 0.0, color, 0);
			TE_SendToAll();
			FLAG[myClient] = false;
			return Plugin_Continue;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public bool TraceFilter(int myEntity, int myMask, any myData) {
	return myEntity != myData && !IsValidClient(myEntity);
}

public void OnEntityCreated(int myEntity, const char[] sClassName) {
	if (StrContains(sClassName, "tf_projectile_") == 0) {
		if (StrEqual(sClassName[14], "rocket")) {
			SDKHook(myEntity, SDKHook_SpawnPost, Hook_RocketSpawn);
		} else {
			//TODO
		}
	}
}

public Action:Hook_RocketSpawn(int myEntity)
{
	new myEntityRef = EntIndexToEntRef(myEntity); //Converts an entity index into a serial encoded entity reference.
	static prevEntityRef = -1;
	int Owner = GetEntPropEnt(myEntity, Prop_Data, "m_hOwnerEntity");

	if (!IsValidClient(Owner)) {
		return Plugin_Continue;
	}

	if (JB_ENABLED[Owner] && prevEntityRef != myEntityRef)
	{
		prevEntityRef = myEntityRef; //To execute the code 1 time in this scope

		int color[4];
		color[0] = 128;
		color[1] = 000;
		color[2] = 128;
		color[3] = 255;

		GetClientEyePosition(Owner, FL_Pos[Owner]);
		GetClientEyeAngles(Owner, FL_Ang[Owner]);

		GetEntPropVector(myEntity, Prop_Data, "m_vecOrigin", FL_PosEntity[Owner]);

		Handle hTr = TR_TraceRayFilterEx(FL_Pos[Owner], FL_Ang[Owner], MASK_SHOT_HULL, RayType_Infinite, TraceFilter, Owner);
		if (TR_DidHit(hTr))
		{
			TR_GetEndPosition(FL_PosTarget[Owner], hTr);
			TE_SetupBeamPoints(FL_PosEntity[Owner], FL_PosTarget[Owner], g_sprite, 0, 0, 0, 5.0, 5.0, 5.0, 10, 0.0, color, 0);
			TE_SendToAll();
		}
		delete hTr;
	}
	return Plugin_Continue;
}

stock bool:IsValidClient(myClient, bool:bReplay = true)
{
  if(myClient <= 0 || myClient > MaxClients || !IsClientInGame(myClient))
    return false;
  if(bReplay && (IsClientSourceTV(myClient) || IsClientReplay(myClient) || IsClientObserver(myClient)))
    return false;
  return true;
}