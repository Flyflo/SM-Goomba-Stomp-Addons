#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <colors>
#include <goomba>

new Handle:g_Cvar_StompMinSpeed = INVALID_HANDLE;

new Goomba_SingleStomp[MAXPLAYERS+1] = 0;

#define PL_NAME "Goomba Stomp CSS"
#define PL_DESC "Goomba Stomp CSS plugin"
#define PL_VERSION "1.0.0"

public Plugin:myinfo =
{
    name = PL_NAME,
    author = "Flyflo",
    description = PL_DESC,
    version = PL_VERSION,
    url = "http://www.geek-gaming.fr"
}

public OnPluginStart()
{
    decl String:modName[32];
    GetGameFolderName(modName, sizeof(modName));

    if(!StrEqual(modName, "cstrike", false))
    {
        SetFailState("This plugin only works with Counter-Strike: Source");
    }

    g_Cvar_StompMinSpeed = FindConVar("goomba_minspeed");

    // Support for plugin late loading
    for (new client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            OnClientPutInServer(client);
        }
    }
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_StartTouch, OnStartTouch);
}

public Action:OnStartTouch(client, other)
{
    if(other > 0 && other <= MaxClients)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            decl Float:ClientPos[3];
            decl Float:VictimPos[3];
            GetClientAbsOrigin(client, ClientPos);
            GetClientAbsOrigin(other, VictimPos);

            new Float:HeightDiff = ClientPos[2] - VictimPos[2];

            if((HeightDiff > 61.0) || ((GetClientButtons(other) & IN_DUCK) && (HeightDiff > 45.0)))
            {
                decl Float:vec[3];
                GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);

                if(vec[2] < GetConVarFloat(g_Cvar_StompMinSpeed) * -1.0)
                {
                    if(Goomba_SingleStomp[client] == 0)
                    {
                        if(AreValidStompTargets(client, other))
                        {
                            new immunityResult = CheckImmunity(client, other);

                            if(immunityResult == GOOMBA_IMMUNFLAG_NONE)
                            {
                                if(GoombaStomp(client, other))
                                {
                                    PlayReboundSound(client);
                                }
                                Goomba_SingleStomp[client] = 1;
                                CreateTimer(0.5, SinglStompTimer, client);
                            }
                            else if(immunityResult & GOOMBA_IMMUNFLAG_VICTIM)
                            {
                                CPrintToChat(client, "%t", "Victim Immun");
                            }
                        }
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}

bool:AreValidStompTargets(client, victim)
{
    if(victim <= 0 || victim > MaxClients)
    {
        return false;
    }

    decl String:edictName[32];
    GetEdictClassname(victim, edictName, sizeof(edictName));

    if(!StrEqual(edictName, "player"))
    {
        return false;
    }
    if(!IsPlayerAlive(victim))
    {
        return false;
    }
    if(GetClientTeam(client) == GetClientTeam(victim))
    {
        return false;
    }
    if(GetEntProp(victim, Prop_Data, "m_takedamage", 1) == 0)
    {
        return false;
    }

    return true;
}


public Action:SinglStompTimer(Handle:timer, any:client)
{
    Goomba_SingleStomp[client] = 0;
}
