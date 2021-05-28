# prestrafe-plugin

## Description ##
SourceMod plugin for Twitch's Prestrafe bot.

## Requirements ##
- Sourcemod and Metamod
- GOKZ-core
- GOKZ-global and GlobalAPI-Core (optional)

## Usage ##
- Configure backend at `addons/sourcemod/config/prestrafebot.cfg`` if necessary. By default it will send data to localhost:1337.
- ``sm_setprestrafetoken <token>`` - Set prestrafe token for server. If set, server will send player data to the backend at frequent interval. 
- ``sm_revokeprestrafetoken`` - Revoke prestrafe token from server.