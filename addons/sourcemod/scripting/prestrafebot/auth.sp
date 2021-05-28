Action Timer_RandomizeTimeouts(Handle timer, any data)
{
	RandomizeTimeouts();
	return Plugin_Continue;
}

void RandomizeTimeouts()
{
	gI_PreviousTimeoutsCT = GameRules_GetProp("m_nCTTimeOuts");
	gI_PreviousTimeoutsT  = GameRules_GetProp("m_nTerroristTimeOuts");
	gI_TimeoutsCT = GetRandomInt(0,65535);
	gI_TimeoutsT = GetRandomInt(0,65535);
	GameRules_SetProp("m_nCTTimeOuts", gI_TimeoutsCT);
	GameRules_SetProp("m_nTerroristTimeOuts", gI_TimeoutsT);
}

public Action Command_SetPrestrafeToken(int client, int args)
{
	if (args < 1)
	{
		PrintToConsole(client, "[SM] Usage: sm_setprestrafetoken <token>");
		return Plugin_Handled;
	}
	char buffer[128];
	GetCmdArg(1, buffer, sizeof(buffer));
	SetPrestrafeToken(client, buffer);
	return Plugin_Handled;
}

public Action Command_RevokePrestrafeToken(int client, int args)
{
	Format(gC_AuthKeys[client], sizeof(gC_AuthKeys[]), "");
	
	SetClientCookie(client, gH_PrestrafeCookie, gC_AuthKeys[client]);
	PrintToChat(client, "Prestrafe token revoked. Server will no longer send your KZ data to the Prestrafe backend.");
	return Plugin_Handled;
}

void SetPrestrafeToken(int client, char[] token)
{
	Format(gC_AuthKeys[client], sizeof(gC_AuthKeys[]), "%s", token);
	SetClientCookie(client, gH_PrestrafeCookie, gC_AuthKeys[client]);
	PrintToChat(client, "Prestrafe token set! Server will now regularly send your KZ data to the Prestrafe backend.");
}