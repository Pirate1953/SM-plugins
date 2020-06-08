#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MODEL_MARKER	"models/extras/info_speech.mdl"
#define SPRITE_BEAM	"materials/sprites/laser.vmt"
#define PLUGIN_VERSION	"1.0.9"

bool JB_ENABLED[MAXPLAYERS + 1];
bool FLAG[MAXPLAYERS + 1];
bool PL_Enabled;

float FL_PosClientPrev[MAXPLAYERS + 1][3];
float FL_PosClient[MAXPLAYERS + 1][3];
float FL_VelClient[MAXPLAYERS + 1][3];

Handle HudDisplay;

ConVar g_pluginEnabled;

int sprite;
int halo;

public Plugin:myinfo =
{
	name = "JB Mode",
	author = "Master Cake",
	description = "Makes you manual jumpBOT for fun",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("jjb_version", PLUGIN_VERSION, "JB Mode Version", FCVAR_REPLICATED | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_pluginEnabled = CreateConVar("jjb_enabled", "1", "Enable JB Mode\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	PL_Enabled = GetConVarBool(g_pluginEnabled);
	HookConVarChange(g_pluginEnabled, ConsoleVarChange);

	RegAdminCmd("sm_jjb", JB_Command, ADMFLAG_GENERIC, "Enable/Disable JB Mode");
	RegAdminCmd("sm_jmb", JBM_Command, ADMFLAG_GENERIC, "Create model entity info speech, it's funny");
	RegAdminCmd("sm_jjbstat", JBS_Command, ADMFLAG_GENERIC, "Changes plugin stat");

	AutoExecConfig(true, "jbmode");

	HudDisplay = CreateHudSynchronizer();
}

public ConsoleVarChange(Handle:CVar, const String:oldValue[], const String:newValue[])
{
	if(CVar == g_pluginEnabled)
	{
		PL_Enabled = GetConVarBool(g_pluginEnabled);
	}
}

public OnMapStart()
{
	sprite = PrecacheModel(SPRITE_BEAM);
	halo = PrecacheModel(SPRITE_BEAM);
	PrecacheModel(MODEL_MARKER);
}

public OnClientPutInServer(myClient)
{
	JB_ENABLED[myClient] = false;
	FLAG[myClient] = false;
}

public Action:JBS_Command(myClient, args)
{
	if (args == 1)
	{
		char arg1[2];
		int stat;
		GetCmdArg(1, arg1, sizeof(arg1));

		stat = StringToInt(arg1);
		if (stat == 1)
		{
			g_pluginEnabled.IntValue = stat;
			PrintToChatAll("[SM]ADMIN: changed JB Mode state to %i", g_pluginEnabled.IntValue);
		}
		if (stat == 0)
		{
			g_pluginEnabled.IntValue = stat;
			PrintToChatAll("[SM]ADMIN: changed JB Mode state to %i", g_pluginEnabled.IntValue);
			for (new i = 1; i <= MAXPLAYERS; i++)
			{
				FLAG[i] = false;
				JB_ENABLED[i] = false;
				SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);
			}
		}
	}
	return Plugin_Handled;
}

public Action:JB_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (!JB_ENABLED[myClient])
    {
    	JB_ENABLED[myClient] = true;
    	SetEntProp(myClient, Prop_Send, "m_bGlowEnabled", 1);
    	ReplyToCommand(myClient, "[SM] JB Mode Enabled!");
    	ClearSyncHud(myClient, HudDisplay);
    	SetHudTextParams(-1.0, -1.0, 1.0, 0, 255, 0, 255, 0, 0.1, 0.1, 0.1);
    	ShowSyncHudText(myClient, HudDisplay, "JB Mode Enabled for you");

    	return Plugin_Continue;
    }

	if (JB_ENABLED[myClient])
    {
    	JB_ENABLED[myClient] = false;
    	SetEntProp(myClient, Prop_Send, "m_bGlowEnabled", 0);
    	ReplyToCommand(myClient, "[SM] JB Mode Disabled!");
    	ClearSyncHud(myClient, HudDisplay);
    	SetHudTextParams(-1.0, -1.0, 1.0, 255, 0, 0, 255, 0, 0.1, 0.1, 0.1);
    	ShowSyncHudText(myClient, HudDisplay, "JB Mode Disabled for you");
    }
	return Plugin_Handled;
}

public Action:JBM_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (JB_ENABLED[myClient])
    {
    	float FL_Pos[3];
    	float FL_Ang[3];
    	float FL_PosHit[3];
    	GetClientEyePosition(myClient, FL_Pos);
    	GetClientEyeAngles(myClient, FL_Ang);
    	int myEnt = CreateEntityByName("prop_dynamic");
    	SetEntityModel(myEnt, MODEL_MARKER);
    	DispatchSpawn(myEnt);
    	SetEntityRenderMode(myEnt, RENDER_TRANSALPHA);

    	Handle Trace = TR_TraceRayFilterEx(FL_Pos, FL_Ang, MASK_SHOT_HULL, RayType_Infinite, TraceFilter);
    	if (TR_DidHit(Trace))
    	{
    		TR_GetEndPosition(FL_PosHit, Trace);
    		FL_PosHit[2] += 20.0;
    	}
    	delete Trace;
    	TeleportEntity(myEnt, FL_PosHit, NULL_VECTOR, NULL_VECTOR);

    	ReplyToCommand(myClient, "[SM] Created Entity");
    }
	else
    {
    	ReplyToCommand(myClient, "[SM] Enable JB Mode first!");
    }

	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(myClient, &myButtons, &myImpulse, Float:myVel[3], Float:myAng[3], &myWeapon)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	GetEntPropVector(myClient, Prop_Data, "m_vecAbsVelocity", FL_VelClient[myClient]);
	if (JB_ENABLED[myClient] && IsPlayerAlive(myClient) && (FL_VelClient[myClient][0] != 0.0 || FL_VelClient[myClient][1] != 0.0 || FL_VelClient[myClient][2] != 0.0))
	{
		int color[4];
		color[0] = 025;
		color[1] = 144;
		color[2] = 255;
		color[3] = 255;

		if(myButtons & IN_DUCK)
		{
			color[0] = 026;
			color[1] = 255;
			color[2] = 095;
			color[3] = 255;
		}

		if(myButtons & IN_DUCK && myButtons & IN_JUMP)
		{
			color[0] = 255;
			color[1] = 241;
			color[2] = 026;
			color[3] = 255;
		}

		if (!FLAG[myClient])
		{
			GetClientEyePosition(myClient, FL_PosClientPrev[myClient]);
			FL_PosClientPrev[myClient][2] -= 20.0;
			FLAG[myClient] = true;
			return Plugin_Continue;
		}
		if (FLAG[myClient])
		{
			GetClientEyePosition(myClient, FL_PosClient[myClient]);
			FL_PosClient[myClient][2] -= 20.0;
			TE_SetupBeamPoints(FL_PosClient[myClient], FL_PosClientPrev[myClient], sprite, halo, 0, 0, 5.0, 25.0, 25.0, 1, 0.0, color, 0);
			TE_SendToAllInRange(FL_PosClient[myClient], RangeType_Visibility, 0.1);
			FLAG[myClient] = false;
			return Plugin_Continue;
		}
	}

	return Plugin_Continue;
}

public bool TraceFilter(int myEntity, int myMask, any myData)
{
	return ((myEntity != myData) && !IsValidClient(myEntity));
}

public void OnEntityCreated(int myEntity, const char[] MyName)
{
	if (StrContains(MyName, "tf_projectile_") == 0)
	{
		if (StrEqual(MyName[14], "rocket"))
		{
			SDKHook(myEntity, SDKHook_SpawnPost, RockSpawn);
		}
		else
		{
			SDKHook(myEntity, SDKHook_SpawnPost, ProjSpawn);
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

		if (IsValidClient(myOwner) && JB_ENABLED[myOwner])
		{
			int color[4];
			color[0] = 128;
			color[1] = 000;
			color[2] = 128;
			color[3] = 255;

			float FL_PosEntity[3];
			float FL_AngEntity[3];
			float FL_PosTarget[3];

			GetClientEyePosition(myOwner, FL_PosClient[myOwner]);
			GetEntPropVector(myEntity, Prop_Data, "m_vecOrigin", FL_PosEntity);
			GetEntPropVector(myEntity, Prop_Data, "m_angRotation", FL_AngEntity);

			Handle Trace = TR_TraceRayFilterEx(FL_PosEntity, FL_AngEntity, MASK_SHOT_HULL, RayType_Infinite, TraceFilter, myEntity);
			if (TR_DidHit(Trace))
			{
				TR_GetEndPosition(FL_PosTarget, Trace);
				TE_SetupBeamPoints(FL_PosEntity, FL_PosTarget, sprite, halo, 0, 0, 5.0, 5.0, 5.0, 1, 1.0, color, 0);
				TE_SendToAllInRange(FL_PosClient[myOwner], RangeType_Visibility, 0.1);
			}
			delete Trace;

			if (IsValidEntity(myEntity) && !TR_PointOutsideWorld(FL_PosEntity))
			{
				int myGlow = AddOutline(myEntity);
				SetVariantColor(color);
				AcceptEntityInput(myGlow, "SetGlowColor");
			}
		}
	}
	return Plugin_Continue;
}

public Action:ProjSpawn(int myEntity)
{
	new myRef = EntIndexToEntRef(myEntity); //Converts an entity index into a serial encoded entity reference.
	static PrevRef = -1;

	if (PL_Enabled && PrevRef != myRef)
	{
		PrevRef = myRef; //To execute the code 1 time in this scope

		int myOwner = GetEntPropEnt(myEntity, Prop_Data, "m_hOwnerEntity");

		if (IsValidClient(myOwner) && JB_ENABLED[myOwner])
		{
			int color[4];
			color[0] = 128;
			color[1] = 000;
			color[2] = 128;
			color[3] = 255;

			if (IsValidEntity(myEntity))
			{
				int myGlow = AddOutline(myEntity);
				SetVariantColor(color);
				AcceptEntityInput(myGlow, "SetGlowColor");
			}

			GetClientEyePosition(myOwner, FL_PosClient[myOwner]);
			TE_SetupBeamFollow(myEntity, sprite, 0, 3.0, 5.0, 5.0, 1, color);
			TE_SendToAllInRange(FL_PosClient[myOwner], RangeType_Visibility, 0.1);
		}
	}
	return Plugin_Continue;
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
 * Creates tf_glow entity for projectile (makes outline)
 * @param myEntity        Entity index.
 */
stock int AddOutline(int myEntity)
{
	char entName[64];
	GetEntPropString(myEntity, Prop_Data, "m_iName", entName, sizeof(entName));

	char strName[126], className[64];
	GetEntityClassname(myEntity, className, sizeof(className));
	Format(strName, sizeof(strName), "%s%i", className, myEntity);
	DispatchKeyValue(myEntity, "targetname", strName);

	int Glow = CreateEntityByName("tf_glow");
	SetVariantString("!activator");
	AcceptEntityInput(Glow, "SetParent", myEntity, Glow);
	DispatchKeyValue(Glow, "targetname", "ProjectileGlow");
	DispatchKeyValue(Glow, "target", strName);
	DispatchKeyValue(Glow, "Mode", "0");
	DispatchSpawn(Glow);
	AcceptEntityInput(Glow, "Enable");

	return Glow;
}