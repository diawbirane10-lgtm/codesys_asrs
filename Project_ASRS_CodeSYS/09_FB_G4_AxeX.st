// ================================================================
// 09_FB_G4_AxeX.st  —  GRAFCET G4 : Axe X (déplacement chariot)
// CODESYS V3.5 — FUNCTION_BLOCK
// RÈGLE ABSOLUE : aucun mouvement X si CAPTEUR_Z_TRANSPORT = FALSE
//
// E0=IMMOBILE  E1=VERIF_Z  E2=ALARME_Z  E3=DEPLACEMENT
// E4=FREINAGE  E5=POSITION_OK  E6=DEFAUT
// ================================================================

FUNCTION_BLOCK FB_G4_AxeX
VAR
    Step  : INT := 0;
    tmr   : TON;
    tmrIN : BOOL;
    Cible : USINT;
END_VAR

tmr(IN := tmrIN, PT := GVL_CFG.T_MVT_X);

CASE Step OF

0: // IMMOBILE — attente requête G3
    GVL_IO.CMD_X_AV   := FALSE;
    GVL_IO.CMD_X_AR   := FALSE;
    GVL_SIG.G4_DONE   := FALSE;
    GVL_SIG.G4_ERR    := FALSE;
    tmrIN             := FALSE;
    IF GVL_SIG.G4_REQ THEN
        Cible := GVL_SIG.G4_CIBLE;
        Step  := 1;
    END_IF;

1: // VÉRIF Z_TRANSPORT — interlock absolu
    IF GVL_IO.CAPTEUR_Z_TRANSPORT THEN
        Step := 3;
    ELSE
        Step := 2;
    END_IF;

2: // ALARME Z NON TRANSPORT
    GVL_SIG.ALM_AXE_X := TRUE;
    IF GVL_IO.CAPTEUR_Z_TRANSPORT THEN
        GVL_SIG.ALM_AXE_X := FALSE;
        Step := 3;
    END_IF;

3: // DÉPLACEMENT X vers cible
    IF GVL_SIG.CAPTEUR_POS_X[Cible] THEN
        Step := 5;
    ELSE
        GVL_IO.CONSIGNE_POS_X := INT_TO_WORD(USINT_TO_INT(Cible));
        GVL_IO.CMD_X_AV       := TRUE;
        GVL_IO.CMD_X_AR       := FALSE;
        tmrIN                 := TRUE;
        Step                  := 4;
    END_IF;

4: // Attente arrivée en position
    IF GVL_SIG.CAPTEUR_POS_X[Cible] THEN
        GVL_IO.CMD_X_AV := FALSE;
        GVL_IO.CMD_X_AR := FALSE;
        tmrIN           := FALSE;
        Step            := 5;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_X_AV       := FALSE;
        GVL_IO.CMD_X_AR       := FALSE;
        tmrIN                 := FALSE;
        GVL_SIG.ALM_AXE_X    := TRUE;
        GVL_SEQ.DEFAUT_ACTIF  := TRUE;
        GVL_SEQ.CODE_DEFAUT   := 7;
        Step := 6;
    END_IF;

5: // POSITION ATTEINTE
    GVL_IO.CMD_X_AV  := FALSE;
    GVL_IO.CMD_X_AR  := FALSE;
    GVL_SIG.G4_DONE  := TRUE;
    GVL_SIG.G4_REQ   := FALSE;
    Step := 0;

6: // DÉFAUT AXE X
    GVL_SIG.G4_ERR    := TRUE;
    GVL_SIG.G4_REQ    := FALSE;
    GVL_SIG.DEFAUT_AXE := TRUE;
    IF GVL_SIG.OP_CMD_ACQ AND GVL_SIG.OP_CMD_RESET THEN
        GVL_SIG.G4_ERR    := FALSE;
        GVL_SIG.ALM_AXE_X := FALSE;
        Step := 0;
    END_IF;

END_CASE;

END_FUNCTION_BLOCK
