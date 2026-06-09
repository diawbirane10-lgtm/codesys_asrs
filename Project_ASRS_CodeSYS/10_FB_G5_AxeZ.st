// ================================================================
// 10_FB_G5_AxeZ.st  —  GRAFCET G5 : Axe Z (hauteur fourches)
// CODESYS V3.5 — FUNCTION_BLOCK
// 4 positions : Z_ZPM(0) Z_NIVEAU1(1) Z_NIVEAU2(2) Z_TRANSPORT(3)
//
// E0=IMMOBILE  E1=MONTEE  E2=DESCENTE  E3=POSITION_OK  E4=DEFAUT
// ================================================================

FUNCTION_BLOCK FB_G5_AxeZ
VAR
    Step  : INT := 0;
    tmr   : TON;
    tmrIN : BOOL;
    Cible : USINT;
END_VAR

tmr(IN := tmrIN, PT := GVL_CFG.T_MVT_Z);

CASE Step OF

0: // IMMOBILE — attente requête G3
    GVL_IO.CMD_Z_HAUT := FALSE;
    GVL_IO.CMD_Z_BAS  := FALSE;
    GVL_SIG.G5_DONE   := FALSE;
    GVL_SIG.G5_ERR    := FALSE;
    tmrIN             := FALSE;
    IF GVL_SIG.G5_REQ THEN
        Cible := GVL_SIG.G5_CIBLE;
        // 0=Z_ZPM  1=Z_NIVEAU1  2=Z_NIVEAU2  3=Z_TRANSPORT
        CASE Cible OF
        0:  // Z_ZPM
            IF GVL_IO.CAPTEUR_Z_ZPM THEN
                Step := 3;
            ELSE
                GVL_IO.CMD_Z_BAS := TRUE;
                tmrIN            := TRUE;
                Step             := 2;
            END_IF;
        1:  // Z_NIVEAU1
            IF GVL_IO.CAPTEUR_Z_NIVEAU1 THEN
                Step := 3;
            ELSIF GVL_IO.CAPTEUR_Z_TRANSPORT OR GVL_IO.CAPTEUR_Z_NIVEAU2 THEN
                GVL_IO.CMD_Z_BAS := TRUE;
                tmrIN            := TRUE;
                Step             := 2;
            ELSE
                GVL_IO.CMD_Z_HAUT := TRUE;
                tmrIN             := TRUE;
                Step              := 1;
            END_IF;
        2:  // Z_NIVEAU2
            IF GVL_IO.CAPTEUR_Z_NIVEAU2 THEN
                Step := 3;
            ELSIF GVL_IO.CAPTEUR_Z_TRANSPORT THEN
                GVL_IO.CMD_Z_BAS := TRUE;
                tmrIN            := TRUE;
                Step             := 2;
            ELSE
                GVL_IO.CMD_Z_HAUT := TRUE;
                tmrIN             := TRUE;
                Step              := 1;
            END_IF;
        3:  // Z_TRANSPORT
            IF GVL_IO.CAPTEUR_Z_TRANSPORT THEN
                Step := 3;
            ELSE
                GVL_IO.CMD_Z_HAUT := TRUE;
                tmrIN             := TRUE;
                Step              := 1;
            END_IF;
        END_CASE;
    END_IF;

1: // MONTÉE en cours
    IF CapteurCibleZ(Cible) THEN
        GVL_IO.CMD_Z_HAUT := FALSE;
        tmrIN             := FALSE;
        Step              := 3;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_Z_HAUT     := FALSE;
        tmrIN                 := FALSE;
        GVL_SIG.ALM_AXE_Z    := TRUE;
        GVL_SEQ.DEFAUT_ACTIF  := TRUE;
        GVL_SEQ.CODE_DEFAUT   := 6;
        Step := 4;
    END_IF;

2: // DESCENTE en cours
    IF CapteurCibleZ(Cible) THEN
        GVL_IO.CMD_Z_BAS := FALSE;
        tmrIN            := FALSE;
        Step             := 3;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_Z_BAS      := FALSE;
        tmrIN                 := FALSE;
        GVL_SIG.ALM_AXE_Z    := TRUE;
        GVL_SEQ.DEFAUT_ACTIF  := TRUE;
        GVL_SEQ.CODE_DEFAUT   := 6;
        Step := 4;
    END_IF;

3: // POSITION ATTEINTE
    GVL_IO.CMD_Z_HAUT := FALSE;
    GVL_IO.CMD_Z_BAS  := FALSE;
    GVL_SIG.G5_DONE   := TRUE;
    GVL_SIG.G5_REQ    := FALSE;
    Step := 0;

4: // DÉFAUT AXE Z
    GVL_SIG.G5_ERR     := TRUE;
    GVL_SIG.G5_REQ     := FALSE;
    GVL_SIG.DEFAUT_AXE := TRUE;
    IF GVL_SIG.OP_CMD_ACQ AND GVL_SIG.OP_CMD_RESET THEN
        GVL_SIG.G5_ERR    := FALSE;
        GVL_SIG.ALM_AXE_Z := FALSE;
        Step := 0;
    END_IF;

END_CASE;

END_FUNCTION_BLOCK

// ── Fonction helper : capteur Z pour la cible demandée ────────────
FUNCTION CapteurCibleZ : BOOL
VAR_INPUT
    Cible : USINT;
END_VAR

CASE Cible OF
0: CapteurCibleZ := GVL_IO.CAPTEUR_Z_ZPM;
1: CapteurCibleZ := GVL_IO.CAPTEUR_Z_NIVEAU1;
2: CapteurCibleZ := GVL_IO.CAPTEUR_Z_NIVEAU2;
3: CapteurCibleZ := GVL_IO.CAPTEUR_Z_TRANSPORT;
ELSE CapteurCibleZ := FALSE;
END_CASE;

END_FUNCTION
