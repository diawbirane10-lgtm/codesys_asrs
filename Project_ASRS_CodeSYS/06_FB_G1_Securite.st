// ================================================================
// 06_FB_G1_Securite.st  —  GRAFCET G1 : Sécurité globale
// CODESYS V3.5 — FUNCTION_BLOCK
// Tourne EN PARALLÈLE, permanent, en premier dans PLC_PRG
//
// E1=SECURITES_OK  E2=ARRET_SECURITE  E3=ATTENTE_ACQ
// ================================================================

FUNCTION_BLOCK FB_G1_Securite
VAR
    Step : INT := 1;
END_VAR

VAR_INPUT
END_VAR

VAR_OUTPUT
END_VAR

// ── Corps du FB ──────────────────────────────────────────────────
// Mise à jour ZONE_CONFIRMEE
GVL_SIG.ZONE_CONFIRMEE := GVL_IO.ZONE_LIBRE_BTN AND NOT GVL_IO.CAPTEUR_ZONE_OCCUPEE;

CASE Step OF

// E1 — SECURITES_OK
1:
    GVL_SIG.SECURITES_OK := TRUE;
    GVL_SIG.ALM_ZONE     := FALSE;

    IF GVL_SIG.OP_AU OR GVL_IO.CAPTEUR_ZONE_OCCUPEE
       OR GVL_SIG.DEFAUT_AXE
       OR GVL_SIG.PERTE_PROFINET THEN
        GVL_IO.CMD_X_AV              := FALSE;
        GVL_IO.CMD_X_AR              := FALSE;
        GVL_IO.CMD_Z_HAUT            := FALSE;
        GVL_IO.CMD_Z_BAS             := FALSE;
        GVL_IO.CMD_SAT_EXT           := FALSE;
        GVL_IO.CMD_SAT_RET           := FALSE;
        GVL_IO.CMD_ROT_NORD          := FALSE;
        GVL_IO.CMD_ROT_SUD           := FALSE;
        GVL_IO.CMD_ARRET_PRESSE      := TRUE;
        GVL_IO.CMD_AUTORISE_DEMARRAGE := FALSE;

        GVL_SIG.SECURITES_OK := FALSE;
        GVL_SIG.ALM_ZONE     := GVL_IO.CAPTEUR_ZONE_OCCUPEE;
        GVL_SIG.VYT_DEFAUT   := TRUE;
        Step := 2;
    END_IF;

// E2 — ARRET_SECURITE
2:
    GVL_IO.CMD_X_AV    := FALSE;
    GVL_IO.CMD_X_AR    := FALSE;
    GVL_IO.CMD_Z_HAUT  := FALSE;
    GVL_IO.CMD_Z_BAS   := FALSE;
    GVL_IO.CMD_SAT_EXT := FALSE;
    GVL_IO.CMD_SAT_RET := FALSE;
    GVL_IO.CMD_ROT_NORD := FALSE;
    GVL_IO.CMD_ROT_SUD  := FALSE;
    Step := 3;

// E3 — ATTENTE_ACQ
3:
    GVL_IO.VOYANT_DEFAUT := TRUE;

    IF NOT GVL_SIG.OP_AU
       AND NOT GVL_IO.CAPTEUR_ZONE_OCCUPEE
       AND NOT GVL_SIG.DEFAUT_AXE
       AND NOT GVL_SIG.PERTE_PROFINET
       AND GVL_SIG.OP_CMD_ACQ THEN
        GVL_SIG.VYT_DEFAUT     := FALSE;
        GVL_IO.VOYANT_DEFAUT   := FALSE;
        GVL_IO.CMD_ARRET_PRESSE := FALSE;
        Step := 1;

    ELSIF GVL_SIG.OP_CMD_ACQ
          AND (GVL_SIG.DEFAUT_AXE OR GVL_SIG.PERTE_PROFINET) THEN
        Step := 2;
    END_IF;

END_CASE;

END_FUNCTION_BLOCK
