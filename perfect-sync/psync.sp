#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Handle:cvarEnabled;

new bool:PLUGIN_ENABLED;
int ROCKETS[20];
int shoots;

int Owner;

public Plugin:myinfo =
{
  name = "Perfect Sync",
  author = "Master Cake",
  description = "This plugin makes perfect syncs",
  version = "1.0",
  url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
  cvarEnabled = CreateConVar("sm_plugin_enabled", "0", "Enable/Disable Plugin", _, true, 0.0, true, 1.0);
  PLUGIN_ENABLED = GetConVarBool(cvarEnabled);
  RegAdminCmd("sm_setpson", ADMINSY_Command, 0, "Enable/disable Pefrect Sync plugin");
  RegConsoleCmd("sm_makesync", SY_Command, "Command to enable sync for realised rockets");
}

public Action:ADMINSY_Command(myClient, args)
{
  if (args > 0 ) {
    ReplyToCommand(myClient, "[SM] This command has no arguments!");
    return Plugin_Continue;
  }
  else
  {
    if (!PLUGIN_ENABLED)
    {
      PLUGIN_ENABLED = true;
      shoots = 0;
      ReplyToCommand(myClient, "[SM] Plugin Enabled!");
    }
    else
    {
      PLUGIN_ENABLED = false;
      ReplyToCommand(myClient, "[SM] Plugin Disabled!");
    }
  }
  return Plugin_Handled;
}

public Action:SY_Command(myClient, args)
{
  if (args > 0 ) {
    ReplyToCommand(myClient, "[SM] This command has no arguments!");
    return Plugin_Continue;
  }
  else
  {
    if (PLUGIN_ENABLED)
    {
      int len = sizeof(ROCKETS);
      static Float:Pos[3];
      GetClientEyePosition(Owner, Pos);
      for (new i = 0; i < len; i++)
      {
        if (IsValidEntity(ROCKETS[i]))
        {
          Pos[2] += 0.01;
          TeleportEntity(ROCKETS[i], Pos, NULL_VECTOR, NULL_VECTOR);
        }
      }
    }
  }
  return Plugin_Handled;
}

public OnEntityCreated(myEntity, const String:sClassName[])
{
  if(PLUGIN_ENABLED)
  {
    if (StrEqual(sClassName,"tf_projectile_rocket"))
    {
      SDKHook(myEntity, SDKHook_Spawn, Hook_OnRocketSpawn);
    }
  }
}

public Hook_OnRocketSpawn(myEntity)
{
  new myEntityRef = EntIndexToEntRef(myEntity);
  static prevEntityRef = -1;
  if (PLUGIN_ENABLED && prevEntityRef != myEntityRef)
  {
    prevEntityRef = myEntityRef;

    Owner = GetEntPropEnt(myEntity, Prop_Data, "m_hOwnerEntity");

    if (shoots < 20)
    {
      ROCKETS[shoots] = myEntity;
      shoots++;
    }
    else
    {
      shoots = 0;
      shoots++;
    }
  }
}

stock bool:IsValidClient(myClient, bool:bReplay = true)
{
  if(myClient <= 0 || myClient > MaxClients || !IsClientInGame(myClient))
    return false;
  if(bReplay && (IsClientSourceTV(myClient) || IsClientReplay(myClient)))
    return false;
  return true;
}