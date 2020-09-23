#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>


ConVar g_cvarNoclipSpeed;
ConVar g_cvarNoclipAccelerate;

char g_sOriginalNoclipSpeed[16];
char g_sOriginalNoclipAccelerate[16];

float g_flClientNoclipSpeed[MAXPLAYERS + 1];
bool g_bClientNoclipAccelerate[MAXPLAYERS + 1];


public void OnPluginStart() {
    g_cvarNoclipSpeed = FindConVar("sv_noclipspeed");
    g_cvarNoclipSpeed.Flags &= ~(FCVAR_NOTIFY|FCVAR_REPLICATED);
    g_cvarNoclipAccelerate = FindConVar("sv_noclipaccelerate");
    g_cvarNoclipAccelerate.Flags &= ~(FCVAR_NOTIFY|FCVAR_REPLICATED);
    PrintToServer("%d %d", g_cvarNoclipSpeed.IntValue, g_cvarNoclipAccelerate.IntValue);

    RegConsoleCmd("sm_noclipspeed", cmdNoclipSpeed,
                  "Set your personal noclip speed.");
    RegConsoleCmd("sm_noclipaccel", cmdNoclipAccel,
                  "Toggle your personal noclip acceleration.");
}


public void OnPluginEnd() {
    g_cvarNoclipSpeed.Flags |= FCVAR_NOTIFY|FCVAR_REPLICATED;
    g_cvarNoclipAccelerate.Flags |= FCVAR_NOTIFY|FCVAR_REPLICATED;
}


public void OnClientPutInServer(int client) {
    g_flClientNoclipSpeed[client] = 0.0;
    g_bClientNoclipAccelerate[client] = true;

    SDKHook(client, SDKHook_PreThink, PlayerPreThink);
    SDKHook(client, SDKHook_PostThinkPost, PlayerPostThinkPost);
}


public Action cmdNoclipSpeed(int client, int args)
{
    if (args < 1) {
        ReplyToCommand(client, "Must specify a value.");
        return Plugin_Continue;
    }

    char arg[65];
    GetCmdArg(1, arg, sizeof(arg));
    float flSpeed = StringToFloat(arg);

    if (flSpeed <= 0.0) {
        ReplyToCommand(client, "Value must be a number.");
        return Plugin_Continue;
    }

    g_flClientNoclipSpeed[client] = flSpeed;
    char value[16];
    FloatToString(flSpeed, value, sizeof(value));
    SendConVarValue(client, g_cvarNoclipSpeed, value);
    ReplyToCommand(client, "Noclip speed set to %f.", flSpeed);
    return Plugin_Continue;
}


public Action cmdNoclipAccel(int client, int args)
{
    g_bClientNoclipAccelerate[client] = !g_bClientNoclipAccelerate[client];
    if (g_bClientNoclipAccelerate[client]) {
        char value[16];
        g_cvarNoclipAccelerate.GetString(value, sizeof(value));
        SendConVarValue(client, g_cvarNoclipAccelerate, value);
        ReplyToCommand(client, "Noclip acceleration now ENABLED.");
    }
    else {
        SendConVarValue(client, g_cvarNoclipAccelerate, "0");
        ReplyToCommand(client, "Noclip acceleration now DISABLED.");
    }
    return Plugin_Continue;
}


public Action PlayerPreThink(int client) {
    float flSpeed = g_flClientNoclipSpeed[client];
    if (flSpeed != 0.0) {
        g_cvarNoclipSpeed.GetString(g_sOriginalNoclipSpeed,
                                    sizeof(g_sOriginalNoclipSpeed));
        g_cvarNoclipSpeed.FloatValue = flSpeed;
    }

    if (!g_bClientNoclipAccelerate[client]) {
        g_cvarNoclipAccelerate.GetString(g_sOriginalNoclipAccelerate,
                                         sizeof(g_sOriginalNoclipAccelerate));
        g_cvarNoclipAccelerate.IntValue = 0;
    }
    return Plugin_Continue;
}


public void PlayerPostThinkPost(int client) {
    if (g_flClientNoclipSpeed[client] != 0.0)
        g_cvarNoclipSpeed.SetString(g_sOriginalNoclipSpeed);

    if (!g_bClientNoclipAccelerate[client])
        g_cvarNoclipAccelerate.SetString(g_sOriginalNoclipAccelerate);
}
