// ================================================================
// 12_FB_G7_Satellite.st  —  GRAFCET G7 : Satellite / Fourches
// CODESYS V3.5 — FUNCTION_BLOCK
//
// E0=RETRACTEES  E1=VERIF_AVANT_EXT  E2=EXTENSION
// E3=EXTENSION_OK  E4=RETRACTION  E5=RETRACTEES_OK  E6=DEFAUT
//
// GVL_SIG.G7_CMD : 0=ETENDRE  1=RETRACTER
// ================================================================

FUNCTION_BLOCK FB_G7_Satellite
VAR
    Step  : INT := 0;
    tmr   : TON;
    tmrIN : BOOL;
END_VAR

tmr(IN := tmrIN, PT := GVL_CFG.T_SATELLITE);

CASE Step OF

0: // RETRACTÉES — repos
    GVL_IO.CMD_SAT_EXT := FALSE;
    GVL_IO.CMD_SAT_RET := FALSE;
    GVL_SIG.G7_DONE    := FALSE;
    GVL_SIG.G7_ERR     := FALSE;
    tmrIN              := FALSE;
    IF GVL_SIG.G7_REQ THEN
        IF GVL_SIG.G7_CMD = 0 THEN
            Step := 1;   // Extension demandée
        ELSE
            Step := 4;   // Rétraction demandée
        END_IF;
    END_IF;

1: // VÉRIF AVANT EXTENSION
    IF GVL_IO.CAPTEUR_CHARGE_CHARIOT OR NOT GVL_IO.CAPTEUR_Z_TRANSPORT THEN
        GVL_SIG.G7_ERR := TRUE;
        GVL_SIG.G7_REQ := FALSE;
        Step := 6;
    ELSE
        Step := 2;
    END_IF;

2: // EXTENSION en cours
    GVL_IO.CMD_SAT_EXT := TRUE;
    GVL_IO.CMD_SAT_RET := FALSE;
    tmrIN              := TRUE;
    IF GVL_IO.CAPTEUR_SAT_ETENDU THEN
        GVL_IO.CMD_SAT_EXT := FALSE;
        tmrIN              := FALSE;
        Step               := 3;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_SAT_EXT    := FALSE;
        tmrIN                 := FALSE;
        GVL_SIG.ALM_SATELLITE := TRUE;
        GVL_SEQ.DEFAUT_ACTIF  := TRUE;
        GVL_SEQ.CODE_DEFAUT   := 11;
        Step := 6;
    END_IF;

3: // EXTENSION CONFIRMÉE
    GVL_SIG.G7_DONE := TRUE;
    GVL_SIG.G7_REQ  := FALSE;
    Step := 0;

4: // RÉTRACTION en cours
    GVL_IO.CMD_SAT_RET := TRUE;
    GVL_IO.CMD_SAT_EXT := FALSE;
    tmrIN              := TRUE;
    IF GVL_IO.CAPTEUR_SAT_RETRACTE THEN
        GVL_IO.CMD_SAT_RET := FALSE;
        tmrIN              := FALSE;
        Step               := 5;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_SAT_RET    := FALSE;
        tmrIN                 := FALSE;
        GVL_SIG.ALM_SATELLITE := TRUE;
        GVL_SEQ.DEFAUT_ACTIF  := TRUE;
        GVL_SEQ.CODE_DEFAUT   := 11;
        Step := 6;
    END_IF;

5: // RÉTRACTION CONFIRMÉE
    GVL_SIG.G7_DONE := TRUE;
    GVL_SIG.G7_REQ  := FALSE;
    Step := 0;

6: // DÉFAUT SATELLITE
    GVL_IO.CMD_SAT_EXT    := FALSE;
    GVL_IO.CMD_SAT_RET    := FALSE;
    GVL_SIG.G7_ERR        := TRUE;
    GVL_SIG.G7_REQ        := FALSE;
    GVL_SIG.DEFAUT_AXE    := TRUE;
    IF GVL_SIG.OP_CMD_ACQ AND GVL_SIG.OP_CMD_RESET THEN
        GVL_SIG.G7_ERR        := FALSE;
        GVL_SIG.ALM_SATELLITE := FALSE;
        Step := 0;
    END_IF;

END_CASE;

END_FUNCTION_BLOCK
