// ================================================================
// 07_FB_G0_Conduite.st  —  GRAFCET G0 : Superviseur modes
// CODESYS V3.5 — FUNCTION_BLOCK
//
// E0=HORS_SERVICE  E1=INIT_SYSTEME  E2=ALARME_REPRISE
// E3=HOMING_EN_COURS  E4=EN_ATTENTE  E5=CYCLE_EN_COURS  E6=DEFAUT_GENERAL
// ================================================================

FUNCTION_BLOCK FB_G0_Conduite
VAR
    Step        : INT := 0;
    StartupDone : BOOL;
END_VAR

CASE Step OF

// E0 — HORS SERVICE
0:
    IF NOT StartupDone THEN
        StartupDone := TRUE;
    END_IF;
    Step := 1;

// E1 — INITIALISATION SYSTÈME
1:
    GVL_SIG.VYT_MACHINE_PRETE := FALSE;
    GVL_SIG.VYT_INIT_OK       := FALSE;
    GVL_SIG.G3_REQ            := FALSE;
    GVL_SIG.G2_REQ            := FALSE;
    GVL_SEQ.HOMING_OK         := FALSE;

    IF GVL_SEQ.CYCLE_INTERROMPU THEN
        GVL_SIG.VYT_DEFAUT := TRUE;
        GVL_SIG.ALM_HOMING := TRUE;
        Step := 2;
    ELSE
        Step := 3;
    END_IF;

// E2 — ALARME REPRISE CYCLE
2:
    GVL_SIG.VYT_DEFAUT := TRUE;
    IF GVL_SIG.OP_CMD_ACQ THEN
        GVL_SIG.VYT_DEFAUT := FALSE;
        GVL_SIG.ALM_HOMING := FALSE;
        Step := 3;
    END_IF;

// E3 — HOMING EN COURS
3:
    GVL_SIG.G2_REQ         := TRUE;
    GVL_SIG.VYT_INIT_OK    := FALSE;
    GVL_SEQ.CYCLE_EN_COURS := FALSE;

    IF GVL_SIG.G2_HOMING_OK THEN
        GVL_SIG.G2_REQ      := FALSE;
        GVL_SEQ.HOMING_OK   := TRUE;
        GVL_SIG.VYT_INIT_OK := TRUE;
        Step := 4;

    ELSIF GVL_SIG.G2_DEFAUT THEN
        GVL_SIG.G2_REQ     := FALSE;
        GVL_SIG.ALM_HOMING := TRUE;
        Step := 6;
    END_IF;

// E4 — EN ATTENTE (machine prête)
4:
    GVL_SIG.VYT_MACHINE_PRETE := TRUE;
    GVL_SIG.CYCLE_CM_AUTORISE :=
        GVL_SIG.OP_CMD_CM
        AND GVL_SEQ.HOMING_OK
        AND GVL_SIG.SECURITES_OK
        AND NOT GVL_SEQ.DEFAUT_ACTIF
        AND NOT GVL_SEQ.CYCLE_EN_COURS
        AND NOT GVL_SIG.OP_AU;

    IF GVL_SIG.OP_CMD_HOMING THEN
        GVL_SIG.VYT_MACHINE_PRETE := FALSE;
        GVL_SEQ.HOMING_OK          := FALSE;
        Step := 3;

    ELSIF GVL_SIG.CYCLE_CM_AUTORISE THEN
        GVL_SIG.VYT_MACHINE_PRETE  := FALSE;
        GVL_SIG.VYT_CYCLE_EN_COURS := TRUE;
        GVL_SEQ.CYCLE_EN_COURS     := TRUE;
        GVL_MOULES.MOULE_DEMANDE   := GVL_SIG.OP_MOULE_DEMANDE;
        GVL_SIG.G3_REQ             := TRUE;
        Step := 5;

    ELSIF GVL_SIG.OP_AU OR GVL_SEQ.DEFAUT_ACTIF THEN
        Step := 6;
    END_IF;

// E5 — CYCLE EN COURS
5:
    IF GVL_SIG.G3_FIN_CM THEN
        GVL_SIG.G3_REQ              := FALSE;
        GVL_SIG.G3_FIN_CM           := FALSE;
        GVL_SEQ.CYCLE_EN_COURS      := FALSE;
        GVL_SIG.VYT_CYCLE_EN_COURS  := FALSE;
        GVL_SEQ.NB_CYCLES_TOTAL     := GVL_SEQ.NB_CYCLES_TOTAL + 1;
        Step := 4;

    ELSIF GVL_SIG.OP_AU OR GVL_SIG.G3_DEFAUT THEN
        GVL_SIG.G3_REQ := FALSE;
        Step := 6;
    END_IF;

// E6 — DEFAUT GENERAL
6:
    GVL_SIG.VYT_DEFAUT         := TRUE;
    GVL_SIG.VYT_MACHINE_PRETE  := FALSE;
    GVL_SIG.VYT_CYCLE_EN_COURS := FALSE;
    GVL_SEQ.CYCLE_EN_COURS     := FALSE;

    IF GVL_SIG.OP_CMD_ACQ
       AND GVL_SIG.OP_CMD_RESET
       AND NOT GVL_SIG.OP_AU
       AND NOT GVL_SEQ.DEFAUT_ACTIF THEN
        GVL_SIG.VYT_DEFAUT  := FALSE;
        GVL_SEQ.HOMING_OK   := FALSE;
        GVL_SIG.ALM_HOMING  := FALSE;
        Step := 3;
    END_IF;

END_CASE;

END_FUNCTION_BLOCK
