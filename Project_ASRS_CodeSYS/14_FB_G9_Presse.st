// ================================================================
// 14_FB_G9_Presse.st  —  GRAFCET G9 : Interface presse QUADRA 10
// CODESYS V3.5 — FUNCTION_BLOCK
//
// Séquence : ARRET → PILON_HAUT → DEBRIDAGE → (cycle chariot)
//            → PILON_BAS → BRIDAGE → AUTORISATION DEMARRAGE
// ================================================================

FUNCTION_BLOCK FB_G9_Presse
VAR
    Step  : INT := 0;
    tmr   : TON;
    tmrIN : BOOL;
END_VAR

tmr(IN := tmrIN, PT := T#1S);

CASE Step OF

// ─── ÉTAT REPOS ──────────────────────────────────────────────
0:
    GVL_IO.CMD_ARRET_PRESSE        := FALSE;
    GVL_IO.CMD_DEBRIDAGE           := FALSE;
    GVL_IO.CMD_BRIDAGE             := FALSE;
    GVL_IO.CMD_AUTORISE_DEMARRAGE  := FALSE;
    GVL_IO.CMD_MONTE_PILON         := FALSE;
    GVL_IO.CMD_BAISSE_PILON        := FALSE;
    GVL_SIG.G9_ARRETEE_OK          := FALSE;
    GVL_SIG.G9_DEBRIDE_OK          := FALSE;
    GVL_SIG.G9_BRIDE_OK            := FALSE;
    GVL_SIG.G9_AUTORISE_OK         := FALSE;
    tmrIN                          := FALSE;
    IF GVL_SIG.G9_REQ_ARRET THEN
        Step := 1;
    END_IF;

// ─── PHASE ARRÊT PRESSE ──────────────────────────────────────
1:
    GVL_IO.CMD_ARRET_PRESSE := TRUE;
    tmrIN                   := TRUE;
    tmr(IN := tmrIN, PT := GVL_CFG.T_ARRET_PRESSE);
    Step := 2;

2:
    IF GVL_IO.PRESSE_ARRETEE THEN
        GVL_IO.CMD_ARRET_PRESSE := FALSE;
        tmrIN                   := FALSE;
        GVL_SIG.G9_ARRETEE_OK  := TRUE;
        Step := 3;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_ARRET_PRESSE  := FALSE;
        tmrIN                    := FALSE;
        GVL_SIG.G9_DEFAUT        := TRUE;
        GVL_SIG.G9_CODE_DEFAUT   := 1;
        GVL_SIG.ALM_COMM_PRESSE  := TRUE;
        Step := 20;
    END_IF;

3: // Monte pilon
    GVL_IO.CMD_MONTE_PILON := TRUE;
    tmrIN                  := TRUE;
    tmr(IN := tmrIN, PT := GVL_CFG.T_PILON);
    Step := 4;

4:
    IF GVL_IO.PILON_HAUT_OK THEN
        GVL_IO.CMD_MONTE_PILON := FALSE;
        tmrIN                  := FALSE;
        IF GVL_SIG.G9_REQ_DEBRIDAGE THEN
            Step := 5;
        END_IF;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_MONTE_PILON   := FALSE;
        tmrIN                    := FALSE;
        GVL_SIG.G9_DEFAUT        := TRUE;
        GVL_SIG.G9_CODE_DEFAUT   := 4;
        GVL_SIG.ALM_PILON        := TRUE;
        Step := 20;
    END_IF;

5: // Débridage
    GVL_IO.CMD_DEBRIDAGE := TRUE;
    tmrIN                := TRUE;
    tmr(IN := tmrIN, PT := GVL_CFG.T_DEBRIDAGE);
    Step := 6;

6:
    IF GVL_IO.MOULE_DEBRIDE THEN
        GVL_IO.CMD_DEBRIDAGE     := FALSE;
        tmrIN                    := FALSE;
        GVL_SIG.G9_DEBRIDE_OK    := TRUE;
        Step := 7;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_DEBRIDAGE     := FALSE;
        tmrIN                    := FALSE;
        GVL_SIG.ALM_DEBRIDAGE    := TRUE;
        Step := 15;   // ROLLBACK
    END_IF;

7: // ATTENTE commande bridage
    IF GVL_SIG.G9_REQ_BRIDAGE THEN
        Step := 8;
    END_IF;

// ─── PHASE BRIDAGE ───────────────────────────────────────────
8: // Baisse pilon
    GVL_IO.CMD_BAISSE_PILON := TRUE;
    tmrIN                   := TRUE;
    tmr(IN := tmrIN, PT := GVL_CFG.T_PILON);
    Step := 9;

9:
    IF GVL_IO.PILON_BAS_OK AND GVL_IO.MOULE_SUR_INTRO AND GVL_IO.INTRODUCTEUR_A_ZPM THEN
        GVL_IO.CMD_BAISSE_PILON := FALSE;
        tmrIN                   := FALSE;
        Step := 10;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_BAISSE_PILON  := FALSE;
        tmrIN                    := FALSE;
        GVL_SIG.G9_DEFAUT        := TRUE;
        GVL_SIG.G9_CODE_DEFAUT   := 4;
        GVL_SIG.ALM_PILON        := TRUE;
        Step := 20;
    END_IF;

10: // Bridage
    GVL_IO.CMD_BRIDAGE := TRUE;
    tmrIN              := TRUE;
    tmr(IN := tmrIN, PT := GVL_CFG.T_BRIDAGE);
    Step := 11;

11:
    IF GVL_IO.MOULE_BRIDE THEN
        GVL_IO.CMD_BRIDAGE     := FALSE;
        tmrIN                  := FALSE;
        GVL_SIG.G9_BRIDE_OK    := TRUE;
        Step := 12;
    ELSIF tmr.Q THEN
        GVL_IO.CMD_BRIDAGE       := FALSE;
        tmrIN                    := FALSE;
        GVL_SIG.G9_DEFAUT        := TRUE;
        GVL_SIG.G9_CODE_DEFAUT   := 3;
        GVL_SIG.ALM_BRIDAGE      := TRUE;
        Step := 20;
    END_IF;

12: // ATTENTE autorisation
    IF GVL_SIG.G9_REQ_AUTORISER THEN
        Step := 13;
    END_IF;

13:
    IF GVL_IO.INTRO_VIDE AND GVL_IO.INTRODUCTEUR_A_ZPM THEN
        GVL_IO.CMD_AUTORISE_DEMARRAGE := TRUE;
        Step := 14;
    ELSE
        GVL_SIG.G9_DEFAUT      := TRUE;
        GVL_SIG.G9_CODE_DEFAUT := 5;
        Step := 20;
    END_IF;

14: // AUTORISATION ENVOYÉE
    GVL_SIG.G9_AUTORISE_OK     := TRUE;
    GVL_SIG.G9_REQ_ARRET       := FALSE;
    GVL_SIG.G9_REQ_DEBRIDAGE   := FALSE;
    GVL_SIG.G9_REQ_BRIDAGE     := FALSE;
    GVL_SIG.G9_REQ_AUTORISER   := FALSE;
    Step := 0;

// ─── ROLLBACK DÉBRIDAGE ÉCHOUÉ ───────────────────────────────
15:
    GVL_IO.CMD_BAISSE_PILON := TRUE;
    tmrIN                   := TRUE;
    tmr(IN := tmrIN, PT := GVL_CFG.T_PILON);
    Step := 16;

16:
    IF GVL_IO.PILON_BAS_OK OR tmr.Q THEN
        GVL_IO.CMD_BAISSE_PILON        := FALSE;
        tmrIN                          := FALSE;
        GVL_IO.CMD_AUTORISE_DEMARRAGE  := TRUE;
        GVL_SIG.G9_DEFAUT              := TRUE;
        GVL_SIG.G9_CODE_DEFAUT         := 2;
        Step := 17;
    END_IF;

17:
    IF NOT GVL_IO.PRESSE_ARRETEE THEN
        GVL_IO.CMD_AUTORISE_DEMARRAGE := FALSE;
        Step := 0;
    END_IF;

// ─── DÉFAUT GÉNÉRAL G9 ───────────────────────────────────────
20:
    GVL_IO.CMD_ARRET_PRESSE        := FALSE;
    GVL_IO.CMD_DEBRIDAGE           := FALSE;
    GVL_IO.CMD_BRIDAGE             := FALSE;
    GVL_IO.CMD_MONTE_PILON         := FALSE;
    GVL_IO.CMD_BAISSE_PILON        := FALSE;
    GVL_IO.CMD_AUTORISE_DEMARRAGE  := FALSE;
    IF GVL_SIG.OP_CMD_ACQ AND GVL_SIG.OP_CMD_RESET THEN
        GVL_SIG.G9_DEFAUT        := FALSE;
        GVL_SIG.G9_CODE_DEFAUT   := 0;
        GVL_SIG.ALM_COMM_PRESSE  := FALSE;
        GVL_SIG.ALM_PILON        := FALSE;
        GVL_SIG.ALM_DEBRIDAGE    := FALSE;
        GVL_SIG.ALM_BRIDAGE      := FALSE;
        Step := 0;
    END_IF;

END_CASE;

END_FUNCTION_BLOCK
