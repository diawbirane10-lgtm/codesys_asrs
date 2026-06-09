// ================================================================
// 11_FB_G6_Rotation.st  —  GRAFCET G6 : Rotation plateau
// CODESYS V3.5 — FUNCTION_BLOCK
// 2 positions : NORD=0 (face ZPM/presse)  SUD=1 (face chambres)
//
// E0=REPOS  E1=ROTATION_NORD  E2=ROTATION_SUD
// E3=ORIENTATION_OK  E4=DEFAUT
// ================================================================

FUNCTION_BLOCK FB_G6_Rotation
VAR
    Step  : INT := 0;
    tmr   : TON;
    tmrIN : BOOL;
END_VAR

tmr(IN := tmrIN, PT := GVL_CFG.T_ROTATION);

CASE Step OF

0: // REPOS — attente requête G3
    GVL_IO.CMD_ROT_NORD := FALSE;
    GVL_IO.CMD_ROT_SUD  := FALSE;
    GVL_SIG.G6_DONE     := FALSE;
    GVL_SIG.G6_ERR      := FALSE;
    tmrIN               := FALSE;
    IF GVL_SIG.G6_REQ THEN
        IF GVL_SIG.G6_CIBLE = 0 THEN
            IF GVL_IO.CAPTEUR_ROT_NORD THEN
                Step := 3;
            ELSE
                GVL_IO.CMD_ROT_NORD := TRUE;
                tmrIN               := TRUE;
                Step                := 1;
            END_IF;
        ELSE
            IF GVL_IO.CAPTEUR_ROT_SUD THEN
                Step := 3;
            ELSE
                GVL_IO.CMD_ROT_SUD := TRUE;
                tmrIN              := TRUE;
                Step               := 2;
            END_IF;
        END_IF;
    END_IF;

1: // ROTATION VERS NORD
    IF GVL_IO.CAPTEUR_ROT_NORD THEN
        GVL_IO.CMD_ROT_NORD := FALSE;
        tmrIN               := FALSE;
        Step                := 3;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_ROT_NORD   := FALSE;
        tmrIN                 := FALSE;
        GVL_SIG.ALM_ROTATION  := TRUE;
        GVL_SEQ.DEFAUT_ACTIF  := TRUE;
        GVL_SEQ.CODE_DEFAUT   := 12;
        Step := 4;
    END_IF;

2: // ROTATION VERS SUD
    IF GVL_IO.CAPTEUR_ROT_SUD THEN
        GVL_IO.CMD_ROT_SUD := FALSE;
        tmrIN              := FALSE;
        Step               := 3;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_ROT_SUD    := FALSE;
        tmrIN                 := FALSE;
        GVL_SIG.ALM_ROTATION  := TRUE;
        GVL_SEQ.DEFAUT_ACTIF  := TRUE;
        GVL_SEQ.CODE_DEFAUT   := 12;
        Step := 4;
    END_IF;

3: // ORIENTATION OK
    GVL_IO.CMD_ROT_NORD := FALSE;
    GVL_IO.CMD_ROT_SUD  := FALSE;
    GVL_SIG.G6_DONE     := TRUE;
    GVL_SIG.G6_REQ      := FALSE;
    Step := 0;

4: // DÉFAUT ROTATION
    GVL_SIG.G6_ERR      := TRUE;
    GVL_SIG.G6_REQ      := FALSE;
    GVL_SIG.DEFAUT_AXE  := TRUE;
    IF GVL_SIG.OP_CMD_ACQ AND GVL_SIG.OP_CMD_RESET THEN
        GVL_SIG.G6_ERR       := FALSE;
        GVL_SIG.ALM_ROTATION := FALSE;
        Step := 0;
    END_IF;

END_CASE;

END_FUNCTION_BLOCK
