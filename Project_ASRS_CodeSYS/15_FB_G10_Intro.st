// ================================================================
// 15_FB_G10_Intro.st  —  GRAFCET G10 : Introducteur ZPM
// CODESYS V3.5 — FUNCTION_BLOCK
//
// SÉCURITÉ : Entrée en presse UNIQUEMENT si PILON_HAUT_OK = TRUE
//
// E0=A_ZPM  E1=VERIF_ENTREE  E2=INTRO_EN_COURS
// E3=EN_PRESSE  E4=RETRAIT_EN_COURS  E5=REVENU_ZPM  E6=DEFAUT
// ================================================================

FUNCTION_BLOCK FB_G10_Intro
VAR
    Step  : INT := 0;
    tmr   : TON;
    tmrIN : BOOL;
END_VAR

tmr(IN := tmrIN, PT := GVL_CFG.T_INTRO);

CASE Step OF

0: // À ZPM — état initial
    GVL_IO.CMD_INTRO_ENTRE  := FALSE;
    GVL_IO.CMD_INTRO_SORT   := FALSE;
    GVL_SIG.G10_DEFAUT      := FALSE;
    GVL_SIG.G10_EN_PRESSE   := FALSE;
    GVL_SIG.G10_A_ZPM       := TRUE;
    tmrIN                   := FALSE;
    IF GVL_SIG.G10_REQ_ENTRER THEN
        GVL_SIG.G10_A_ZPM := FALSE;
        Step := 1;
    END_IF;

1: // VÉRIFICATION SÉCURITÉ
    IF NOT GVL_IO.PILON_HAUT_OK THEN
        GVL_SIG.G10_DEFAUT    := TRUE;
        GVL_SEQ.DEFAUT_ACTIF  := TRUE;
        GVL_SEQ.CODE_DEFAUT   := 5;
        GVL_SIG.ALM_INTRO     := TRUE;
        Step := 6;
    ELSE
        GVL_IO.CMD_INTRO_ENTRE := TRUE;
        tmrIN                  := TRUE;
        Step                   := 2;
    END_IF;

2: // INTRODUCTION EN COURS
    IF GVL_IO.INTRODUCTEUR_EN_PRESSE THEN
        GVL_IO.CMD_INTRO_ENTRE  := FALSE;
        tmrIN                   := FALSE;
        GVL_SIG.G10_EN_PRESSE   := TRUE;
        Step := 3;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_INTRO_ENTRE := FALSE;
        tmrIN                  := FALSE;
        GVL_SIG.ALM_INTRO      := TRUE;
        GVL_SEQ.DEFAUT_ACTIF   := TRUE;
        GVL_SEQ.CODE_DEFAUT    := 5;
        Step := 6;
    END_IF;

3: // EN PRESSE — attente commande retrait
    IF GVL_SIG.G10_REQ_SORTIR THEN
        GVL_SIG.G10_EN_PRESSE := FALSE;
        GVL_IO.CMD_INTRO_SORT  := TRUE;
        tmrIN                  := TRUE;
        Step                   := 4;
    END_IF;

4: // RETRAIT EN COURS
    IF GVL_IO.INTRODUCTEUR_A_ZPM THEN
        GVL_IO.CMD_INTRO_SORT := FALSE;
        tmrIN                 := FALSE;
        GVL_SIG.G10_A_ZPM    := TRUE;
        Step                  := 5;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_INTRO_SORT  := FALSE;
        tmrIN                  := FALSE;
        GVL_SIG.ALM_INTRO      := TRUE;
        GVL_SEQ.DEFAUT_ACTIF   := TRUE;
        GVL_SEQ.CODE_DEFAUT    := 5;
        Step := 6;
    END_IF;

5: // REVENU À ZPM
    GVL_SIG.G10_REQ_ENTRER := FALSE;
    GVL_SIG.G10_REQ_SORTIR := FALSE;
    Step := 0;

6: // DÉFAUT INTRODUCTEUR
    GVL_IO.CMD_INTRO_ENTRE  := FALSE;
    GVL_IO.CMD_INTRO_SORT   := FALSE;
    GVL_SIG.G10_DEFAUT      := TRUE;
    IF GVL_SIG.OP_CMD_ACQ AND GVL_SIG.OP_CMD_RESET THEN
        GVL_SIG.G10_DEFAUT      := FALSE;
        GVL_SIG.G10_REQ_ENTRER  := FALSE;
        GVL_SIG.G10_REQ_SORTIR  := FALSE;
        GVL_SIG.ALM_INTRO       := FALSE;
        Step := 0;
    END_IF;

END_CASE;

END_FUNCTION_BLOCK
