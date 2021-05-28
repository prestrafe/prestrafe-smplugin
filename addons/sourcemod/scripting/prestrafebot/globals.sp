// Backend address
char gC_HostName[255];
int gI_Port;

// Plugin variables
bool gB_LateLoaded;
// Remaining timeout variables, these are never used in KZ as every KZ map lasts only one round
int gI_TimeoutsCT;
int gI_TimeoutsT;
int gI_PreviousTimeoutsCT;
int gI_PreviousTimeoutsT;
// Client authkeys
Handle gH_PrestrafeCookie;
char gC_AuthKeys[MAXPLAYERS + 1][128];

// Globalcheck variables
bool gB_GOKZGlobal;
bool gB_APIKeyCheck;
bool gB_ModeCheck[MODE_COUNT];
bool gB_BannedCommandsCheck;
char gC_CurrentMap[64];
char gC_CurrentMapPath[PLATFORM_MAX_PATH];
ConVar gCV_gokz_settings_enforcer;
int gI_EnforcerOnFreshMap;
bool gB_GloballyVerified[MAXPLAYERS + 1];

