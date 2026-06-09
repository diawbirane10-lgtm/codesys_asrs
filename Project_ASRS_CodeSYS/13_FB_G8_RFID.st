// ================================================================
// 13_FB_G8_RFID.st  —  GRAFCET G8 : Lecture RFID
// CODESYS V3.5 — FUNCTION_BLOCK
//
// E0=ATTENTE  E1=LECTURE  E2=COMPARAISON
// E3=RFID_OK  E4=DEFAUT_RFID
// ================================================================

FUNCTION_BLOCK FB_G8_RFID
VAR
    Step  : INT := 0;
    tmr   : TON;
    tmrIN : BOOL;
END_VAR

tmr(IN := tmrIN, PT := GVL_CFG.T_RFID);

CASE Step OF

0: // ATTENTE requête G3
    GVL_IO.CMD_RFID_ACTIVER := FALSE;
    GVL_SIG.G8_DONE         := FALSE;
    GVL_SIG.G8_OK           := FALSE;
    GVL_SIG.G8_ERR          := FALSE;
    GVL_SIG.G8_ID_LU        := 0;
    tmrIN                   := FALSE;
    IF GVL_SIG.G8_REQ THEN
        Step := 1;
    END_IF;

1: // LECTURE RFID
    GVL_IO.CMD_RFID_ACTIVER := TRUE;
    tmrIN                   := TRUE;
    IF GVL_IO.RFID_LECTURE_OK THEN
        GVL_SIG.G8_ID_LU := GVL_IO.RFID_ID_LU;
        tmrIN            := FALSE;
        Step             := 2;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_RFID_ACTIVER := FALSE;
        tmrIN                   := FALSE;
        GVL_SIG.ALM_RFID        := TRUE;
        GVL_SEQ.DEFAUT_ACTIF    := TRUE;
        GVL_SEQ.CODE_DEFAUT     := 8;
        Step := 4;
    END_IF;

2: // COMPARAISON
    GVL_IO.CMD_RFID_ACTIVER := FALSE;
    IF GVL_SIG.G8_ID_LU = GVL_SIG.G8_ID_ATTENDU THEN
        Step := 3;
    ELSE
        GVL_SIG.ALM_RFID      := TRUE;
        GVL_SEQ.DEFAUT_ACTIF  := TRUE;
        GVL_SEQ.CODE_DEFAUT   := 9;
        Step := 4;
    END_IF;

3: // RFID OK
    GVL_SIG.G8_OK   := TRUE;
    GVL_SIG.G8_DONE := TRUE;
    GVL_SIG.G8_REQ  := FALSE;
    Step := 0;

4: // DÉFAUT RFID
    GVL_SIG.G8_OK   := FALSE;
    GVL_SIG.G8_DONE := TRUE;
    GVL_SIG.G8_ERR  := TRUE;
    GVL_SIG.G8_REQ  := FALSE;
    IF NOT GVL_SIG.G8_ERR THEN
        Step := 0;
    END_IF;

END_CASE;

END_FUNCTION_BLOCK
