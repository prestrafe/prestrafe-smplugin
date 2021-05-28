// GOKZ-global has no native for globalcheck, so we have to implement this ourselves.
// This will require reworks with the new GlobalAPI plugin, but that won't be happening any time soon..?

void GlobalCheck_MapStart()
{
	gB_BannedCommandsCheck = true;
	
	// Prevent just reloading the plugin after messing with the map
	// Late loading will break globalcheck, as the plugin doesn't know about gokz-global's gI_EnforcerOnFreshMap state upon late loading.
	if (gB_LateLoaded)
	{
		gB_LateLoaded = false;
	}
	else
	{
		gI_EnforcerOnFreshMap = 1;
	}
	
	// Setup a timer to monitor server/client integrity
	CreateTimer(1.0, IntegrityChecks, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

int GlobalsEnabled()
{	
	if (gI_EnforcerOnFreshMap != -1)
	{
		return gB_GOKZGlobal && gB_APIKeyCheck && gB_BannedCommandsCheck && gCV_gokz_settings_enforcer.BoolValue && gI_EnforcerOnFreshMap && MapCheck();
	}
	return -1;

}

void GC_SetupAPI()
{
	GlobalAPI API;
	API.GetMapName(gC_CurrentMap, sizeof(gC_CurrentMap));
	API.GetMapPath(gC_CurrentMapPath, sizeof(gC_CurrentMapPath));
	API.GetAuthStatus(OnAuthStatusCallback);
	API.GetModeInfo(GOKZ_GL_GetGlobalMode(Mode_Vanilla), OnModeInfoCallback, Mode_Vanilla);
	API.GetModeInfo(GOKZ_GL_GetGlobalMode(Mode_SimpleKZ), OnModeInfoCallback, Mode_SimpleKZ);
	API.GetModeInfo(GOKZ_GL_GetGlobalMode(Mode_KZTimer), OnModeInfoCallback, Mode_KZTimer);
}

// gB_APIKeyCheck

public void GlobalAPI_OnAPIKeyReloaded()
{
	GlobalAPI API;
	API.GetAuthStatus(OnAuthStatusCallback);
}

public int OnAuthStatusCallback(bool failure, bool authenticated)
{
	if (failure)
	{
		LogError("Failed to check API key with Global API.");
		gB_APIKeyCheck = false;
	}
	else
	{
		if (!authenticated)
		{
			LogError("Global API key was found to be missing or invalid.");
		}
		gB_APIKeyCheck = authenticated;
	}
}

// gB_BannedCommandsCheck
Action IntegrityChecks(Handle timer)
{
	for (int i = 0; i < BANNEDPLUGINCOMMAND_COUNT; i++)
	{
		if (CommandExists(gC_BannedPluginCommands[i]))
		{
			Handle bannedIterator = GetPluginIterator();
			char pluginName[128]; 
			bool foundPlugin = false;
			while (MorePlugins(bannedIterator))
			{
				Handle bannedPlugin = ReadPlugin(bannedIterator);
				GetPluginInfo(bannedPlugin, PlInfo_Name, pluginName, sizeof(pluginName));
				if (StrEqual(pluginName, gC_BannedPlugins[i]))
				{
					foundPlugin = true;
					break;
				}
			}
			if (!foundPlugin && gB_BannedCommandsCheck)
			{
				gB_BannedCommandsCheck = false;
			}
			delete bannedIterator;
		}
	}
	
	return Plugin_Handled;
}

// gCV_gokz_settings_enforcer.BoolValue

bool GetSettingsEnforcer()
{
	if (gCV_gokz_settings_enforcer != null)
	{
		return gCV_gokz_settings_enforcer.BoolValue;
	}
	else 
	{
		return false;
	}
}
void InitiateEnforcerCheck()
{
	gCV_gokz_settings_enforcer = FindConVar("gokz_settings_enforcer");
	if (gCV_gokz_settings_enforcer != null)
	{
		gCV_gokz_settings_enforcer.AddChangeHook(OnConVarChanged);
	}
}

// gI_EnforcerOnFreshMap and gCV_gokz_settings_enforcer
public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gCV_gokz_settings_enforcer)
	{
		if (!GetSettingsEnforcer())
		{
			gI_EnforcerOnFreshMap = 0;
		}
	}
}

// MapCheck()
bool MapCheck()
{
	if (!gB_GOKZGlobal)
	{
		return false;
	}
	return GlobalAPI_GetMapGlobalStatus()
	 && GlobalAPI_GetMapID() > 0
	 && GlobalAPI_GetMapFilesize() == FileSize(gC_CurrentMapPath);
}

// gB_ModeCheck[mode]
public void GOKZ_OnModeUnloaded(int mode)
{
	gB_ModeCheck[mode] = false;
}
public int OnModeInfoCallback(bool failure, const char[] name, int latest_version, const char[] latest_version_description, int mode)
{
	if (failure)
	{
		LogError("Failed to check a mode version with Global API.");
	}
	else if (latest_version <= GOKZ_GetModeVersion(mode))
	{
		gB_ModeCheck[mode] = true;
	}
	else
	{
		gB_ModeCheck[mode] = false;
	}
}

// gB_GloballyVerified[client]
public void GlobalAPI_OnPlayer_Joined(int client, bool banned)
{
	gB_GloballyVerified[client] = !banned;
}
