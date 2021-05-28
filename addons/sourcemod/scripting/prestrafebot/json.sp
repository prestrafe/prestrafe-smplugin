JSON_Object GetKZDataJSON(int client)
{
	JSON_Object obj = new JSON_Object();
	obj.SetBool("global", gB_GloballyVerified[client] && gB_ModeCheck[GOKZ_GetCoreOption(client, Option_Mode)]);
	obj.SetInt("teleports", GOKZ_GetTeleportCount(client));
	obj.SetInt("checkpoints", GOKZ_GetCheckpointCount(client));
	obj.SetFloat("time", GOKZ_GetTime(client));
	obj.SetInt("course", GOKZ_GetCourse(client));
	return obj;
}

JSON_Object GetPlayerInfoJSON(int client)
{
	JSON_Object obj = new JSON_Object();
	char buffer[128];

	obj.SetObject("kzdata", GetKZDataJSON(client));

	obj.SetFloat("timeinserver", GetClientTime(client));

	CS_GetClientClanTag(client, buffer, sizeof(buffer));
	obj.SetString("clan", buffer);

	obj.SetString("authkey", gC_AuthKeys[client]);
	
	GetClientName(client, buffer, sizeof(buffer));
	obj.SetString("name", buffer);

	GetClientAuthId(client, AuthId_SteamID64, buffer, sizeof(buffer));
	obj.SetString("steamid", buffer);

	
	return obj;
}

JSON_Object GetServerInfoJSON()
{    
	JSON_Object obj = new JSON_Object();
	char buffer[128];

	obj.SetInt("global", GlobalsEnabled());
	obj.SetInt("timeoutsCTprev", gI_PreviousTimeoutsCT);
	obj.SetInt("timeoutsTprev", gI_PreviousTimeoutsT);
	obj.SetInt("timeoutsCT", gI_TimeoutsCT);
	obj.SetInt("timeoutsT", gI_TimeoutsT);
	GetCurrentMapDisplayName(buffer, sizeof(buffer));
	obj.SetString("mapname", buffer);
	GetConVarString(FindConVar("hostname"), buffer, sizeof(buffer));
	obj.SetString("servername", buffer);
	obj.SetInt("timestamp", GetTime());
	return obj;
}

JSON_Array GetAllPlayersInfoJSON()
{
	JSON_Array arr = new JSON_Array();
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			continue;
		}
		if (gC_AuthKeys[client][0] != '\0')
		{
			arr.PushObject(GetPlayerInfoJSON(client));
		}
	}
	return arr;
}

void GetPrestrafeJSONString(char[] message, int size)
{
	JSON_Object obj = new JSON_Object();
	
	obj.SetObject("playerInfo", GetAllPlayersInfoJSON());
	obj.SetObject("serverInfo", GetServerInfoJSON());
	
	obj.Encode(message, size);
	json_cleanup_and_delete(obj);
}