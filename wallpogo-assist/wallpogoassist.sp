#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new bool:WP_ENABLED [MAXPLAYERS + 1];
new bool:WB_INFORMED [MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Wall Pogo Assistant",
	author = "Master Cake",
	description = "This plugin hepls jumpers to learn wall pogo",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_wp", WP_Command, "Command to enable Wall Pogo Assistant");
	RegConsoleCmd("sm_wp_stat", WP_STAT_Command, "Command to check Wall Pogo Assistant plugin status");
	HookEvent("player_spawn", OnPlayerSpawn);
}

public OnClientPutInServer(myClient)
{
	WP_ENABLED[myClient] = false;
	WB_INFORMED[myClient] = false;
}

public Action:WP_Command(myClient, args)
{
    if (args > 0 ) {
   		ReplyToCommand(myClient, "[SM] This command has no arguments");
   		return Plugin_Continue;
    }
    else {
    	if (!WP_ENABLED[myClient]) {
    		WP_ENABLED[myClient] = true;
    		ReplyToCommand(myClient, "[SM] Wall Pogo Assistant Enabled!");
    	}
    	else {
    		WP_ENABLED[myClient] = false;
    		ReplyToCommand(myClient, "[SM] Wall Pogo Assistant Disabled!");
    	}
    }

    return Plugin_Handled;
}

public Action:WP_STAT_Command(int myClient, int args)
{
    if (args > 0 ) {
   		ReplyToCommand(myClient, "[SM] This command has no arguments");
   		return Plugin_Continue;
    }
    else {
    	if (!WP_ENABLED[myClient]) {
    		ReplyToCommand(myClient, "[SM] Your Wall Pogo Assistant is Disabled now.");
    	}
    	else {
    		ReplyToCommand(myClient, "[SM] Your Wall Pogo Assistant is Enabled now.");
    	}
    }

    return Plugin_Handled;
}

public Action:OnPlayerRunCmd(myClient, &iButtons, &iImpulse, Float:fVel[3], Float:fAngles[3], &iWeapon)
{
	if(IsPlayerAlive(myClient) && IsValidClient(myClient) && WP_ENABLED[myClient] && iButtons & IN_DUCK)
	{
    	static float:FL_Angles[3];
    	GetClientEyeAngles(myClient, FL_Angles);
    	if (FL_Angles[0] >= 69.0 && FL_Angles[0] <= 80.0)
    	{
    		SetHudTextParams(0.44, 0.4, 0.1, 0, 255, 0, 0, 0, 0.1, 0.1, 0.1);
    		ShowHudText(myClient, -1, "▲▲▲▲▲▲▲");
    		return Plugin_Continue;
    	}
    	if (FL_Angles[0] >= 81.0 && FL_Angles[0] <= 82.5)
    	{
    		SetHudTextParams(0.44, 0.6, 0.1, 255, 0, 0, 0, 0, 0.1, 0.1, 0.1);
    		ShowHudText(myClient, -1, "▼▼▼▼▼▼▼");
    		return Plugin_Continue;
    	}
    	//[69-80] = UP; [81 - 82.5] - DOWN
	}
	return Plugin_Continue;
}

public Action:OnPlayerSpawn(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new myClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(myClient))
		return Plugin_Continue;

	if(!WB_INFORMED[myClient])
	{
		PrintToChat(myClient, "Type '!wp' in chat to enable/disable Wall Pogo Assistant");
		WB_INFORMED[myClient] = true;
	}
	return Plugin_Continue;
}

stock bool:IsValidClient(myClient, bool:bReplay = true)
{
	if(myClient <= 0 || myClient > MaxClients || !IsClientInGame(myClient))
		return false;
	if(bReplay && (IsClientSourceTV(myClient) || IsClientReplay(myClient)))
		return false;
	return true;
}