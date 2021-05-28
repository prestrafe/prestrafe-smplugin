#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <cstrike>

#include <SteamWorks>
#include <json>

#include <gokz/core>

#include "prestrafebot/globals.sp"
#include "prestrafebot/auth.sp"
#undef REQUIRE_EXTENSION
#undef REQUIRE_PLUGIN
#include <GlobalAPI-Core>
#include <gokz/global>

#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSION
#include "prestrafebot/globalcheck.sp"
#include "prestrafebot/json.sp"
#include "prestrafebot/senddata.sp"


#pragma newdecls required
#pragma semicolon 1
#pragma dynamic 65536

public Plugin myinfo =
{
	name = "prestrafe-plugin",
	author = "zer0.k",
	description = "",
	version = "0.1"
};

// Plugin events

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	gB_LateLoaded = late;
	return APLRes_Success;
}

public void OnPluginStart() 
{
	gH_PrestrafeCookie = RegClientCookie("prestrafebot-cookie", "Prestrafe Authentication Cookie", CookieAccess_Private);
	
	for (int i = 1; i <= MaxClients; i++)
    {
        if (!AreClientCookiesCached(i))
        {
            continue;
        }        
        OnClientCookiesCached(i);
    }
	if (gB_LateLoaded)
	{
		LogMessage("PrestrafeBot plugin is late loaded, global status check will not work properly!");
		gI_EnforcerOnFreshMap = -1;
	}
	SetupPrestrafeBackend();
	RegConsoleCmd("sm_setprestrafetoken", Command_SetPrestrafeToken, "Set Prestrafe token for server to send data to backend");
	RegConsoleCmd("sm_revokeprestrafetoken", Command_RevokePrestrafeToken, "Remove Prestrafe token from server");

}

public void OnAllPluginsLoaded()
{
	LogMessage("OnAllPluginsLoaded");
	gB_GOKZGlobal = LibraryExists("gokz-global") && LibraryExists("GlobalAPI-Core");
	if (gB_GOKZGlobal)
	{
		InitiateEnforcerCheck();
	}
}

public void OnLibraryAdded(const char[] name)
{
	gB_GOKZGlobal = gB_GOKZGlobal || (StrEqual(name, "gokz-global") && LibraryExists("GlobalAPI-Core")) || (StrEqual(name, "GlobalAPI-Core") && LibraryExists("gokz-global"));
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZGlobal = gB_GOKZGlobal && !StrEqual(name, "gokz-global") && !StrEqual(name, "GlobalAPI-Core");
	gI_EnforcerOnFreshMap = StrEqual(name, "gokz-global") || StrEqual(name, "GlobalAPI-Core");
}

public void OnConfigsExecuted()
{
	if (gB_GOKZGlobal)
	{
		GC_SetupAPI();
	}
}

// Client events

public void OnClientCookiesCached(int client)
{
	GetClientCookie(client, gH_PrestrafeCookie, gC_AuthKeys[client], sizeof(gC_AuthKeys[]));
}

// Other Events
public void OnMapStart()
{
	GlobalCheck_MapStart();
	CreateTimer(15.0, Timer_RandomizeTimeouts, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.0, Timer_SendPlayerData, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void SetupPrestrafeBackend()
{
	KeyValues kv = new KeyValues("Prestrafe");
	
	char sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/prestrafebot.cfg");

	if (!FileExists(sFile))
	{
		SetFailState("[SetupPrestrafeBackend] \"%s\" not found!", sFile);
		return;
	}

	kv.ImportFromFile(sFile);

	if (!kv.GotoFirstSubKey())
	{
		SetFailState("[SetupPrestrafeBackend] Can't find webhook for \"%s\"!", sFile);
		return;
	}
	
	char sBuffer[64];

	kv.GetSectionName(sBuffer, sizeof(sBuffer));
	
	if(StrEqual(sBuffer, "Backend", false))
	{
		kv.GetString("hostname", gC_HostName, sizeof(gC_HostName));
		gI_Port = kv.GetNum("port");
	}
	else
	{
		SetFailState("[SetupPrestrafeBackend] Failed to set hostname and port!");
	}
		
	delete kv;
	
	return;
}