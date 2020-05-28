#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new bool:JB_ENABLED[MAXPLAYERS + 1];
new g_sprite;
new bool:FLAG[MAXPLAYERS + 1];

float FL_Pos[MAXPLAYERS + 1][3];
float FL_PosEnd[MAXPLAYERS + 1][3];
float FL_Vel[MAXPLAYERS + 1][3];

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
    		//CreateTimer(0.0, DrawBeam, myClient, TIMER_REPEAT);
    	}
    	else {
    		JB_ENABLED[myClient] = false;
    		ReplyToCommand(myClient, "[SM] JB Mode Disabled!");
    	}
    }

    return Plugin_Handled;
}

stock Action:DrawBeam(Handle timer, int myClient)
{
    int color[4];
	color[0] = 025;
	color[1] = 144;
	color[2] = 255;
	color[3] = 255;

    if (!JB_ENABLED[myClient])
    {
    	return Plugin_Stop;
    }

    if (!FLAG[myClient])
    {
    	GetClientEyePosition(myClient, FL_Pos[myClient]);
    	FLAG[myClient] = true;
    	return Plugin_Continue;
    }
    if (FLAG[myClient])
    {
    	GetClientEyePosition(myClient, FL_PosEnd[myClient]);
    	TE_SetupBeamPoints(FL_Pos[myClient], FL_PosEnd[myClient], g_sprite, 0, 0, 0, 10.0, 10.0, 10.0, 10, 0.0, color, 0);
    	TE_SendToAll();
    	FLAG[myClient] = false;
    	return Plugin_Continue;
    }
    return Plugin_Continue;
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
			FLAG[myClient] = true;
			return Plugin_Continue;
		}
		if (FLAG[myClient])
		{
			GetClientEyePosition(myClient, FL_PosEnd[myClient]);
			TE_SetupBeamPoints(FL_Pos[myClient], FL_PosEnd[myClient], g_sprite, 0, 0, 0, 15.0, 20.0, 20.0, 10, 0.0, color, 0);
			TE_SendToAll();
			FLAG[myClient] = false;
			return Plugin_Continue;
		}
		return Plugin_Continue;
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