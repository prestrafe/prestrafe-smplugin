Action Timer_SendPlayerData(Handle timer, any data)
{
	SendPlayerData();
	return Plugin_Continue;
}

void SendPlayerData()
{
	bool send;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			continue;
		}
		if (gC_AuthKeys[client][0] != '\0')
		{
			send = true;
			break;
		}
	}
	if (!send) return;
	char message[32768]; // Sufficient for worst case scenario, 64 players
	GetPrestrafeJSONString(message, sizeof(message));
	
	char url[512];
	Format(url, sizeof(url), "http://%s:%i/sm/update", gC_HostName, gI_Port);
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, url);

	bool settimeout = SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 10);
	bool setheader = SteamWorks_SetHTTPRequestHeaderValue(hRequest, "header", "headervalue");
	bool setbody = SteamWorks_SetHTTPRequestRawPostBody(hRequest, "application/json", message, strlen(message));
	bool setcallback = SteamWorks_SetHTTPCallbacks(hRequest, POSTCallback);

	if(!hRequest || !settimeout || !setheader || !setbody || !setcallback) 
	{
		LogError("Error in setting request properties, cannot send request");
		CloseHandle(hRequest);
		return;
	}

	if (!SteamWorks_SendHTTPRequest(hRequest))
	{
		LogError("Error sending request!");
		CloseHandle(hRequest);
		return;
	}
	
}

public void POSTCallback( Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	if(!bRequestSuccessful || bFailure) 
	{
		// Putting this in comments because we don't want to flood the server log if the prestrafe backend is down.
		// LogError("There was an error in the request");
		CloseHandle(hRequest);
		return;
	}

	if(eStatusCode != k_EHTTPStatusCode200OK) 
	{
		PrintToServer("Expected status 200, but got %d instead!", eStatusCode);
		CloseHandle(hRequest);
		return;
	}
}
