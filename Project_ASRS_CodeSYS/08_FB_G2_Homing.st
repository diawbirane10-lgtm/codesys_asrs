// ================================================================
// 08_FB_G2_Homing.st  —  GRAFCET G2 : Référencement axes
// CODESYS V3.5 — FUNCTION_BLOCK
// ORDRE STRICT : Z_TRANSPORT → Sat_Ret → X_P0 → Rot_Neutre → X_P6
//
// E0=ATTENTE  E1=HOMING_Z  E2=HOMING_SAT  E3=HOMING_X
// E4=HOMING_ROT  E5=PARKING  E6=HOMING_OK  E7=DEFAUT
// ================================================================

FUNCTION_BLOCK FB_G2_Homing
VAR
    Step  : INT := 0;
    tmr   : TON;
    tmrIN : BOOL;
END_VAR

tmr(IN := tmrIN, PT := GVL_CFG.T_MVT_X);

CASE Step OF

// E0 — ATTENTE LANCEMENT par G0
0:
    tmrIN := FALSE;
    IF GVL_SIG.G2_REQ THEN
        GVL_SIG.G2_HOMING_OK := FALSE;
        GVL_SIG.G2_DEFAUT    := FALSE;
        Step := 1;
    END_IF;

// E1 — HOMING Z → Z_TRANSPORT
1:
    GVL_IO.CMD_Z_HAUT := TRUE;
    GVL_IO.CMD_Z_BAS  := FALSE;
    tmrIN             := TRUE;
    tmr(IN := tmrIN, PT := GVL_CFG.T_MVT_Z);
    IF GVL_IO.CAPTEUR_Z_TRANSPORT THEN
        GVL_IO.CMD_Z_HAUT := FALSE;
        tmrIN             := FALSE;
        Step              := 2;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_Z_HAUT := FALSE;
        tmrIN             := FALSE;
        Step              := 7;
    END_IF;

// E2 — HOMING SAT → Rétraction satellite
2:
    GVL_IO.CMD_SAT_RET := TRUE;
    GVL_IO.CMD_SAT_EXT := FALSE;
    tmrIN              := TRUE;
    tmr(IN := tmrIN, PT := GVL_CFG.T_SATELLITE);
    IF GVL_IO.CAPTEUR_SAT_RETRACTE THEN
        GVL_IO.CMD_SAT_RET := FALSE;
        tmrIN              := FALSE;
        Step               := 3;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_SAT_RET := FALSE;
        tmrIN              := FALSE;
        Step               := 7;
    END_IF;

// E3 — HOMING X → P0
3:
    GVL_IO.CMD_X_AV := TRUE;
    GVL_IO.CMD_X_AR := FALSE;
    tmrIN           := TRUE;
    tmr(IN := tmrIN, PT := GVL_CFG.T_MVT_X);
    IF GVL_IO.POS_P0 THEN
        GVL_IO.CMD_X_AV         := FALSE;
        GVL_IO.INIT_ENCODEUR_X  := TRUE;
        tmrIN                   := FALSE;
        Step                    := 4;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_X_AV := FALSE;
        tmrIN           := FALSE;
        Step            := 7;
    END_IF;

// E4 — HOMING ROT → Position neutre
4:
    GVL_IO.INIT_ENCODEUR_X := FALSE;
    GVL_IO.CMD_ROT_NORD    := TRUE;
    GVL_IO.CMD_ROT_SUD     := FALSE;
    tmrIN                  := TRUE;
    tmr(IN := tmrIN, PT := GVL_CFG.T_ROTATION);
    IF GVL_IO.CAPTEUR_ROT_NEUTRE THEN
        GVL_IO.CMD_ROT_NORD := FALSE;
        tmrIN               := FALSE;
        Step                := 5;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_ROT_NORD := FALSE;
        tmrIN               := FALSE;
        Step                := 7;
    END_IF;

// E5 — DEPLACEMENT PARKING → P6
5:
    GVL_IO.CMD_X_AR := TRUE;
    GVL_IO.CMD_X_AV := FALSE;
    tmrIN           := TRUE;
    tmr(IN := tmrIN, PT := GVL_CFG.T_MVT_X);
    IF GVL_IO.POS_P6 THEN
        GVL_IO.CMD_X_AR := FALSE;
        tmrIN           := FALSE;
        Step            := 6;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_X_AR := FALSE;
        tmrIN           := FALSE;
        Step            := 7;
    END_IF;

// E6 — HOMING TERMINÉ
6:
    GVL_SIG.G2_HOMING_OK      := TRUE;
    GVL_SEQ.CYCLE_INTERROMPU  := FALSE;
    GVL_SIG.G2_REQ            := FALSE;
    Step := 0;

// E7 — DÉFAUT HOMING
7:
    GVL_SIG.G2_DEFAUT    := TRUE;
    GVL_SEQ.DEFAUT_ACTIF := TRUE;
    GVL_SEQ.CODE_DEFAUT  := 15;
    IF GVL_SIG.OP_CMD_ACQ AND GVL_SIG.OP_CMD_RESET THEN
        GVL_SIG.G2_DEFAUT    := FALSE;
        GVL_SEQ.DEFAUT_ACTIF := FALSE;
        GVL_SEQ.CODE_DEFAUT  := 0;
        Step := 0;
    END_IF;

END_CASE;

END_FUNCTION_BLOCK
