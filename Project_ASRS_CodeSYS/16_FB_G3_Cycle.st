// ================================================================
// 16_FB_G3_Cycle.st  —  GRAFCET G3 : Coordinateur cycle AS/RS
// CODESYS V3.5 — FUNCTION_BLOCK
// Chef d'orchestre — active G4..G10 via GVL_SIG
//
// 3 DIVERGENCES ET :
//   ET#1 : retrait introducteur ‖ chariot → P0
//   ET#2 : stockage+RFID+prise ‖ nettoyage opérateurs
//   ET#3 : autorisation presse ‖ retour garage
// ================================================================

FUNCTION_BLOCK FB_G3_Cycle
VAR
    Step       : INT := 0;
    SubA       : INT;
    SubB       : INT;
    BrA_Done   : BOOL;
    BrB_Done   : BOOL;
    i          : INT;
    j          : INT;
    DepotFound : BOOL;
    PriseFound : BOOL;
    NvZ        : USINT;
    T_Nettoyage15 : TON;
    T_Prolong5   : TON;
    NettoyageTimerEnable : BOOL;
    ProlongTimerEnable   : BOOL;
END_VAR

T_Nettoyage15(IN := NettoyageTimerEnable AND NOT GVL_SIG.ZONE_CONFIRMEE, PT := T#15m);
T_Prolong5(IN := ProlongTimerEnable AND NOT GVL_SIG.ZONE_CONFIRMEE, PT := T#5m);

// ── Surveillance AU pendant cycle (priorité absolue) ──────────
IF GVL_SIG.OP_AU AND Step > 0 AND Step < 200 THEN
    GVL_SIG.G3_DEFAUT      := TRUE;
    GVL_SIG.G3_CODE_DEFAUT := 14;
    GVL_SEQ.DEFAUT_ACTIF   := TRUE;
    GVL_SEQ.CODE_DEFAUT    := 14;
    GVL_SIG.G4_REQ         := FALSE;
    GVL_SIG.G5_REQ         := FALSE;
    GVL_SIG.G6_REQ         := FALSE;
    GVL_SIG.G7_REQ         := FALSE;
    GVL_SIG.G8_REQ         := FALSE;
    GVL_SIG.G9_REQ_ARRET     := FALSE;
    GVL_SIG.G10_REQ_ENTRER   := FALSE;
    GVL_SIG.G10_REQ_SORTIR   := FALSE;
    GVL_SIG.VYT_CYCLE_EN_COURS := FALSE;
    Step := 0;
    RETURN;
END_IF;

CASE Step OF

// ════════════════════════════════════════════════════════════
// PHASE 0 — IDLE
// ════════════════════════════════════════════════════════════
0:
    GVL_SIG.G3_FIN_CM          := FALSE;
    GVL_SIG.G3_DEFAUT          := FALSE;
    GVL_SIG.G3_CODE_DEFAUT     := 0;
    GVL_SIG.VYT_CYCLE_EN_COURS := FALSE;
    GVL_SIG.G9_ARRETEE_OK      := FALSE;
    GVL_SIG.G9_DEBRIDE_OK      := FALSE;
    GVL_SIG.G9_BRIDE_OK        := FALSE;
    GVL_SIG.G9_AUTORISE_OK     := FALSE;
    GVL_SIG.G10_EN_PRESSE      := FALSE;
    GVL_SIG.G10_A_ZPM          := FALSE;
    NettoyageTimerEnable       := FALSE;
    ProlongTimerEnable         := FALSE;
    GVL_SIG.NETTOYAGE_EN_COURS := FALSE;
    GVL_SIG.NETTOYAGE_TIMEOUT  := FALSE;
    GVL_SIG.NETTOYAGE_PROLONGATION_UTILISEE := FALSE;
    GVL_SIG.NETTOYAGE_DEPASSEMENT_MAX := FALSE;
    GVL_SIG.VYT_NETTOYAGE_TIMEOUT := FALSE;
    GVL_IO.VOYANT_NETTOYAGE_TIMEOUT := FALSE;
    GVL_IO.VOYANT_NETTOYAGE_MAX := FALSE;
    GVL_IO.BUZZER_ATTENTE_ZONE_LIBRE := FALSE;
    IF GVL_SIG.G3_REQ THEN
        DepotFound := FALSE;
        PriseFound := FALSE;
        IF GVL_MOULES.MOULE_EN_PRESSE = 0 THEN
            GVL_SIG.G3_CODE_DEFAUT := 16;
            Step := 200;
        ELSIF GVL_MOULES.MOULE_DEMANDE = 0 THEN
            GVL_SIG.G3_CODE_DEFAUT := 13;
            Step := 200;
        ELSIF GVL_MOULES.MOULE_DEMANDE = GVL_MOULES.MOULE_EN_PRESSE THEN
            GVL_SIG.G3_CODE_DEFAUT := 17;
            Step := 200;
        ELSE
            Step := 1;
        END_IF;
    END_IF;

1: // Recherche slot dépôt
    DepotFound := FALSE;
    FOR i := 1 TO 5 BY 1 DO
        IF NOT DepotFound THEN
            FOR j := 1 TO 2 BY 1 DO
                IF NOT DepotFound
                   AND NOT GVL_MOULES.CH[i, j].OCCUPE
                   AND NOT GVL_MOULES.CH[i, j].RESERVE THEN
                    GVL_MOULES.CIBLE_DEPOT_CH := INT_TO_USINT(i);
                    GVL_MOULES.CIBLE_DEPOT_NV := INT_TO_USINT(j);
                    GVL_MOULES.CH[i, j].RESERVE := TRUE;
                    DepotFound := TRUE;
                END_IF;
            END_FOR;
        END_IF;
    END_FOR;
    IF DepotFound THEN
        Step := 2;
    ELSE
        GVL_MOULES.ALM_STOCK_PLEIN := TRUE;
        GVL_SIG.ALM_STOCK_PLEIN   := TRUE;
        GVL_SIG.G3_CODE_DEFAUT    := 12;
        Step := 200;
    END_IF;

2: // Recherche slot prise
    PriseFound := FALSE;
    FOR i := 1 TO 5 BY 1 DO
        IF NOT PriseFound THEN
            FOR j := 1 TO 2 BY 1 DO
                IF NOT PriseFound
                   AND GVL_MOULES.CH[i, j].OCCUPE
                   AND GVL_MOULES.CH[i, j].ID = GVL_MOULES.MOULE_DEMANDE THEN
                    GVL_MOULES.CIBLE_PRISE_CH := INT_TO_USINT(i);
                    GVL_MOULES.CIBLE_PRISE_NV := INT_TO_USINT(j);
                    PriseFound := TRUE;
                END_IF;
            END_FOR;
        END_IF;
    END_FOR;
    IF PriseFound THEN
        GVL_SIG.VYT_CYCLE_EN_COURS := TRUE;
        Step := 3;
    ELSE
        GVL_MOULES.CH[GVL_MOULES.CIBLE_DEPOT_CH, GVL_MOULES.CIBLE_DEPOT_NV].RESERVE := FALSE;
        GVL_SIG.G3_CODE_DEFAUT := 13;
        Step := 200;
    END_IF;

3:
    GVL_SEQ.CYCLE_INTERROMPU := TRUE;
    GVL_SEQ.CYCLE_EN_COURS   := TRUE;

// ════════════════════════════════════════════════════════════
// PHASE 1 — Arrêt presse + débridage
// ════════════════════════════════════════════════════════════
10:
    GVL_SIG.G9_REQ_ARRET   := TRUE;
    GVL_SIG.G10_REQ_ENTRER := TRUE;
    Step := 11;

11:
    IF GVL_SIG.G9_ARRETEE_OK THEN
        GVL_SIG.G9_REQ_DEBRIDAGE := TRUE;
        Step := 12;
    ELSIF GVL_SIG.G9_DEFAUT THEN
        Step := 200;
    END_IF;

12:
    IF GVL_SIG.G9_DEBRIDE_OK THEN
        Step := 13;
    ELSIF GVL_SIG.G9_DEFAUT THEN
        Step := 200;
    END_IF;

// ════════════════════════════════════════════════════════════
// DIVERGENCE ET#1 — Retrait introducteur ‖ Chariot → P0
// ════════════════════════════════════════════════════════════
13:
    BrA_Done := FALSE;
    BrB_Done := FALSE;
    SubA     := 0;
    SubB     := 0;
    Step     := 14;

14:
    IF NOT BrA_Done THEN
        CASE SubA OF
        0:  GVL_SIG.G10_REQ_SORTIR := TRUE;
            SubA := 1;
        1:  IF GVL_SIG.G10_A_ZPM THEN
                BrA_Done := TRUE;
            ELSIF GVL_SIG.G10_DEFAUT THEN
                GVL_SIG.G3_CODE_DEFAUT := 5;
                Step := 200;
            END_IF;
        END_CASE;
    END_IF;

    IF NOT BrB_Done THEN
        CASE SubB OF
        0:  GVL_SIG.G4_REQ   := TRUE;
            GVL_SIG.G4_CIBLE := 0;
            SubB := 1;
        1:  IF GVL_SIG.G4_DONE THEN
                GVL_SIG.G4_DONE := FALSE;
                BrB_Done := TRUE;
            ELSIF GVL_SIG.G4_ERR THEN
                GVL_SIG.G4_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 7;
                Step := 200;
            END_IF;
        END_CASE;
    END_IF;

    IF BrA_Done AND BrB_Done THEN
        GVL_SIG.G10_REQ_ENTRER := FALSE;
        GVL_SIG.G10_REQ_SORTIR := FALSE;
        Step := 15;
    END_IF;

// ════════════════════════════════════════════════════════════
// PHASE 2 — Transfert moule : introducteur → chariot
// ════════════════════════════════════════════════════════════
15:
    IF NOT GVL_IO.MOULE_SUR_INTRO THEN
        GVL_SIG.G3_CODE_DEFAUT := 13;
        Step := 200;
    ELSE
        Step := 16;
    END_IF;

16:
    GVL_SIG.G6_REQ   := TRUE;
    GVL_SIG.G6_CIBLE := 0;  // NORD
    Step := 17;

17:
    IF GVL_SIG.G6_DONE THEN
        GVL_SIG.G6_DONE := FALSE;
        Step := 18;
    ELSIF GVL_SIG.G6_ERR THEN
        GVL_SIG.G6_ERR         := FALSE;
        GVL_SIG.G3_CODE_DEFAUT := 11;
        Step := 200;
    END_IF;

18:
    GVL_SIG.G5_REQ   := TRUE;
    GVL_SIG.G5_CIBLE := 0;  // Z_ZPM
    Step := 19;

19:
    IF GVL_SIG.G5_DONE THEN
        GVL_SIG.G5_DONE := FALSE;
        Step := 20;
    ELSIF GVL_SIG.G5_ERR THEN
        GVL_SIG.G5_ERR         := FALSE;
        GVL_SIG.G3_CODE_DEFAUT := 6;
        Step := 200;
    END_IF;

20:
    GVL_SIG.G7_REQ := TRUE;
    GVL_SIG.G7_CMD := 0;  // ETENDRE
    Step := 21;

21:
    IF GVL_SIG.G7_DONE THEN
        GVL_SIG.G7_DONE := FALSE;
        Step := 22;
    ELSIF GVL_SIG.G7_ERR THEN
        GVL_SIG.G7_ERR         := FALSE;
        GVL_SIG.G3_CODE_DEFAUT := 11;
        Step := 200;
    END_IF;

22:
    GVL_SIG.G5_REQ   := TRUE;
    GVL_SIG.G5_CIBLE := 3;  // Z_TRANSPORT
    Step := 23;

23:
    IF GVL_SIG.G5_DONE THEN
        GVL_SIG.G5_DONE := FALSE;
        IF NOT GVL_IO.CAPTEUR_CHARGE_CHARIOT THEN
            GVL_SIG.G3_CODE_DEFAUT := 10;
            Step := 200;
        ELSE
            Step := 24;
        END_IF;
    ELSIF GVL_SIG.G5_ERR THEN
        GVL_SIG.G5_ERR         := FALSE;
        GVL_SIG.G3_CODE_DEFAUT := 6;
        Step := 200;
    END_IF;

24:
    GVL_SIG.G7_REQ := TRUE;
    GVL_SIG.G7_CMD := 1;  // RETRACTER
    Step := 25;

25:
    IF GVL_SIG.G7_DONE THEN
        GVL_SIG.G7_DONE := FALSE;
        Step := 26;
    ELSIF GVL_SIG.G7_ERR THEN
        GVL_SIG.G7_ERR         := FALSE;
        GVL_SIG.G3_CODE_DEFAUT := 11;
        Step := 201;
    END_IF;

// ════════════════════════════════════════════════════════════
// DIVERGENCE ET#2 — Stockage+RFID+Prise ‖ Nettoyage
// ════════════════════════════════════════════════════════════
26:
    BrA_Done := FALSE;
    BrB_Done := FALSE;
    SubA     := 0;
    SubB     := 0;
    NettoyageTimerEnable := FALSE;
    ProlongTimerEnable := FALSE;
    GVL_SIG.NETTOYAGE_EN_COURS := FALSE;
    GVL_SIG.NETTOYAGE_TIMEOUT := FALSE;
    GVL_SIG.NETTOYAGE_PROLONGATION_UTILISEE := FALSE;
    GVL_SIG.NETTOYAGE_DEPASSEMENT_MAX := FALSE;
    GVL_SIG.VYT_NETTOYAGE_TIMEOUT := FALSE;
    GVL_IO.VOYANT_NETTOYAGE_TIMEOUT := FALSE;
    GVL_IO.VOYANT_NETTOYAGE_MAX := FALSE;
    GVL_IO.BUZZER_ATTENTE_ZONE_LIBRE := FALSE;
    Step     := 27;

27: // ET#2
    IF NOT BrA_Done THEN
        CASE SubA OF
        0:  GVL_SIG.G4_REQ   := TRUE;
            GVL_SIG.G4_CIBLE := GVL_MOULES.CIBLE_DEPOT_CH;
            SubA := 1;
        1:  IF GVL_SIG.G4_DONE THEN
                GVL_SIG.G4_DONE := FALSE; SubA := 2;
            ELSIF GVL_SIG.G4_ERR THEN
                GVL_SIG.G4_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 7; Step := 201; END_IF;
        2:  GVL_SIG.G6_REQ   := TRUE;
            GVL_SIG.G6_CIBLE := 1; // SUD
            SubA := 3;
        3:  IF GVL_SIG.G6_DONE THEN
                GVL_SIG.G6_DONE := FALSE; SubA := 4;
            ELSIF GVL_SIG.G6_ERR THEN
                GVL_SIG.G6_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 11; Step := 201; END_IF;
        4:  GVL_SIG.G7_REQ := TRUE;
            GVL_SIG.G7_CMD := 0; // EXT
            SubA := 5;
        5:  IF GVL_SIG.G7_DONE THEN
                GVL_SIG.G7_DONE := FALSE; SubA := 6;
            ELSIF GVL_SIG.G7_ERR THEN
                GVL_SIG.G7_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 11; Step := 201; END_IF;
        6:  GVL_SIG.G5_REQ   := TRUE;
            GVL_SIG.G5_CIBLE := GVL_MOULES.CIBLE_DEPOT_NV;
            SubA := 7;
        7:  IF GVL_SIG.G5_DONE THEN
                GVL_SIG.G5_DONE := FALSE; SubA := 8;
            ELSIF GVL_SIG.G5_ERR THEN
                GVL_SIG.G5_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 6; Step := 201; END_IF;
        8:  GVL_SIG.G7_REQ := TRUE;
            GVL_SIG.G7_CMD := 1; // RET
            SubA := 9;
        9:  IF GVL_SIG.G7_DONE THEN
                GVL_SIG.G7_DONE := FALSE;
                IF NOT GVL_SIG.CAPTEUR_PRES_CH[GVL_MOULES.CIBLE_DEPOT_CH,
                                               GVL_MOULES.CIBLE_DEPOT_NV] THEN
                    GVL_SIG.G3_CODE_DEFAUT := 11; Step := 202;
                ELSE
                    GVL_MOULES.CH[GVL_MOULES.CIBLE_DEPOT_CH,
                                  GVL_MOULES.CIBLE_DEPOT_NV].OCCUPE  := TRUE;
                    GVL_MOULES.CH[GVL_MOULES.CIBLE_DEPOT_CH,
                                  GVL_MOULES.CIBLE_DEPOT_NV].ID      := GVL_MOULES.MOULE_EN_PRESSE;
                    GVL_MOULES.CH[GVL_MOULES.CIBLE_DEPOT_CH,
                                  GVL_MOULES.CIBLE_DEPOT_NV].RESERVE := FALSE;
                    IF GVL_MOULES.NB_EMPLACEMENTS_LIBRES > 0 THEN
                        GVL_MOULES.NB_EMPLACEMENTS_LIBRES :=
                            GVL_MOULES.NB_EMPLACEMENTS_LIBRES - 1;
                    END_IF;
                    SubA := 10;
                END_IF;
            ELSIF GVL_SIG.G7_ERR THEN
                GVL_SIG.G7_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 11; Step := 202; END_IF;
        10: GVL_SIG.G5_REQ   := TRUE;
            GVL_SIG.G5_CIBLE := 3; // Z_TRANSPORT
            SubA := 11;
        11: IF GVL_SIG.G5_DONE THEN
                GVL_SIG.G5_DONE := FALSE; SubA := 12;
            ELSIF GVL_SIG.G5_ERR THEN
                GVL_SIG.G5_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 6; Step := 202; END_IF;
        12: GVL_SIG.G4_REQ   := TRUE;
            GVL_SIG.G4_CIBLE := GVL_MOULES.CIBLE_PRISE_CH;
            SubA := 13;
        13: IF GVL_SIG.G4_DONE THEN
                GVL_SIG.G4_DONE := FALSE; SubA := 14;
            ELSIF GVL_SIG.G4_ERR THEN
                GVL_SIG.G4_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 7; Step := 202; END_IF;
        14: GVL_SIG.G8_REQ        := TRUE;
            GVL_SIG.G8_ID_ATTENDU := GVL_MOULES.MOULE_DEMANDE;
            SubA := 15;
        15: IF GVL_SIG.G8_DONE THEN
                GVL_SIG.G8_DONE := FALSE;
                IF GVL_SIG.G8_OK THEN
                    GVL_MOULES.CH[GVL_MOULES.CIBLE_PRISE_CH,
                                  GVL_MOULES.CIBLE_PRISE_NV].RFID_OK := TRUE;
                    SubA := 16;
                ELSE
                    GVL_SIG.G8_ERR         := FALSE;
                    GVL_SIG.G3_CODE_DEFAUT := 8;
                    Step := 202;
                END_IF;
            ELSIF GVL_SIG.G8_ERR THEN
                GVL_SIG.G8_ERR         := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 8; Step := 202; END_IF;
        16: GVL_SIG.G5_REQ   := TRUE;
            GVL_SIG.G5_CIBLE := GVL_MOULES.CIBLE_PRISE_NV;
            SubA := 17;
        17: IF GVL_SIG.G5_DONE THEN
                GVL_SIG.G5_DONE := FALSE; SubA := 18;
            ELSIF GVL_SIG.G5_ERR THEN
                GVL_SIG.G5_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 6; Step := 202; END_IF;
        18: GVL_SIG.G7_REQ := TRUE;
            GVL_SIG.G7_CMD := 0; // EXT
            SubA := 19;
        19: IF GVL_SIG.G7_DONE THEN
                GVL_SIG.G7_DONE := FALSE; SubA := 20;
            ELSIF GVL_SIG.G7_ERR THEN
                GVL_SIG.G7_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 11; Step := 202; END_IF;
        20: GVL_SIG.G5_REQ   := TRUE;
            GVL_SIG.G5_CIBLE := 3; // Z_TRANSPORT
            SubA := 21;
        21: IF GVL_SIG.G5_DONE THEN
                GVL_SIG.G5_DONE := FALSE;
                IF NOT GVL_IO.CAPTEUR_CHARGE_CHARIOT THEN
                    GVL_SIG.G3_CODE_DEFAUT := 10; Step := 202;
                ELSE
                    SubA := 22;
                END_IF;
            ELSIF GVL_SIG.G5_ERR THEN
                GVL_SIG.G5_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 6; Step := 202; END_IF;
        22: GVL_SIG.G7_REQ := TRUE;
            GVL_SIG.G7_CMD := 1; // RET
            SubA := 23;
        23: IF GVL_SIG.G7_DONE THEN
                GVL_SIG.G7_DONE := FALSE;
                GVL_MOULES.CH[GVL_MOULES.CIBLE_PRISE_CH,
                               GVL_MOULES.CIBLE_PRISE_NV].OCCUPE := FALSE;
                GVL_MOULES.CH[GVL_MOULES.CIBLE_PRISE_CH,
                               GVL_MOULES.CIBLE_PRISE_NV].ID     := 0;
                GVL_MOULES.NB_EMPLACEMENTS_LIBRES :=
                    GVL_MOULES.NB_EMPLACEMENTS_LIBRES + 1;
                GVL_SEQ.MOULE_EN_TRANSIT := TRUE;
                SubA := 24;
            ELSIF GVL_SIG.G7_ERR THEN
                GVL_SIG.G7_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 11; Step := 203; END_IF;
        24: GVL_SIG.G4_REQ   := TRUE;
            GVL_SIG.G4_CIBLE := 0; // P0
            SubA := 25;
        25: IF GVL_SIG.G4_DONE THEN
                GVL_SIG.G4_DONE := FALSE; SubA := 26;
            ELSIF GVL_SIG.G4_ERR THEN
                GVL_SIG.G4_ERR := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 7; Step := 203; END_IF;
        26: GVL_SIG.G8_REQ        := TRUE;
            GVL_SIG.G8_ID_ATTENDU := GVL_MOULES.MOULE_DEMANDE;
            SubA := 27;
        27: IF GVL_SIG.G8_DONE THEN
                GVL_SIG.G8_DONE := FALSE;
                IF GVL_SIG.G8_OK THEN
                    BrA_Done := TRUE;
                ELSE
                    GVL_SIG.G8_ERR         := FALSE;
                    GVL_SIG.G3_CODE_DEFAUT := 9;
                    Step := 210;
                END_IF;
            ELSIF GVL_SIG.G8_ERR THEN
                GVL_SIG.G8_ERR         := FALSE;
                GVL_SIG.G3_CODE_DEFAUT := 9; Step := 210; END_IF;
        END_CASE;
    END_IF;

    IF NOT BrB_Done THEN
        CASE SubB OF
        0:  GVL_SIG.VYT_NETTOYAGE  := TRUE;
            GVL_IO.VOYANT_NETTOYAGE := TRUE;
            IF SubA >= 10 THEN
                GVL_IO.BUZZER_DEBUT_NETTOYAGE := TRUE;
                NettoyageTimerEnable := TRUE;
                ProlongTimerEnable := FALSE;
                GVL_SIG.NETTOYAGE_EN_COURS := TRUE;
                GVL_SIG.NETTOYAGE_TIMEOUT := FALSE;
                GVL_SIG.NETTOYAGE_PROLONGATION_UTILISEE := FALSE;
                GVL_SIG.NETTOYAGE_DEPASSEMENT_MAX := FALSE;
                SubB := 1;
            END_IF;

        1:  GVL_IO.BUZZER_DEBUT_NETTOYAGE := FALSE;
            GVL_SIG.VYT_ATTENTE_ZONE := NOT GVL_SIG.ZONE_CONFIRMEE;
            GVL_IO.VOYANT_ATTENTE_ZONE_LIBRE := NOT GVL_SIG.ZONE_CONFIRMEE;

            IF GVL_SIG.ZONE_CONFIRMEE THEN
                GVL_IO.VOYANT_NETTOYAGE := FALSE;
                GVL_IO.VOYANT_ATTENTE_ZONE_LIBRE := FALSE;
                GVL_IO.VOYANT_NETTOYAGE_TIMEOUT := FALSE;
                GVL_IO.VOYANT_NETTOYAGE_MAX := FALSE;
                GVL_IO.BUZZER_ATTENTE_ZONE_LIBRE := FALSE;
                GVL_SIG.VYT_NETTOYAGE := FALSE;
                GVL_SIG.VYT_ATTENTE_ZONE := FALSE;
                GVL_SIG.VYT_NETTOYAGE_TIMEOUT := FALSE;
                GVL_SIG.NETTOYAGE_EN_COURS := FALSE;
                GVL_SIG.NETTOYAGE_TIMEOUT := FALSE;
                NettoyageTimerEnable := FALSE;
                ProlongTimerEnable := FALSE;
                BrB_Done := TRUE;

            ELSIF T_Prolong5.Q THEN
                GVL_SIG.NETTOYAGE_DEPASSEMENT_MAX := TRUE;
                GVL_SIG.NETTOYAGE_TIMEOUT := TRUE;
                GVL_SIG.VYT_NETTOYAGE_TIMEOUT := TRUE;
                GVL_IO.VOYANT_NETTOYAGE_TIMEOUT := TRUE;
                GVL_IO.VOYANT_NETTOYAGE_MAX := TRUE;
                GVL_IO.BUZZER_ATTENTE_ZONE_LIBRE := TRUE;
                GVL_SIG.G3_CODE_DEFAUT := 18;
                IF GVL_SEQ.MOULE_EN_TRANSIT THEN
                    Step := 203;
                ELSE
                    Step := 202;
                END_IF;

            ELSIF T_Nettoyage15.Q THEN
                GVL_SIG.NETTOYAGE_TIMEOUT := TRUE;
                GVL_SIG.VYT_NETTOYAGE_TIMEOUT := TRUE;
                GVL_IO.VOYANT_NETTOYAGE_TIMEOUT := TRUE;
                GVL_IO.BUZZER_ATTENTE_ZONE_LIBRE := TRUE;

                IF GVL_SIG.OP_PROLONG_NETTOYAGE
                   AND NOT GVL_SIG.NETTOYAGE_PROLONGATION_UTILISEE THEN
                    GVL_SIG.NETTOYAGE_PROLONGATION_UTILISEE := TRUE;
                    GVL_SIG.NETTOYAGE_TIMEOUT := FALSE;
                    GVL_SIG.VYT_NETTOYAGE_TIMEOUT := FALSE;
                    GVL_IO.VOYANT_NETTOYAGE_TIMEOUT := FALSE;
                    GVL_IO.BUZZER_ATTENTE_ZONE_LIBRE := FALSE;
                    NettoyageTimerEnable := FALSE;
                    ProlongTimerEnable := TRUE;
                END_IF;
            END_IF;
        END_CASE;
    END_IF;

    IF BrA_Done AND BrB_Done THEN
        Step := 30;
    END_IF;

// ════════════════════════════════════════════════════════════
// PHASE 3 — Dépôt nouveau moule sur introducteur
// ════════════════════════════════════════════════════════════
30:
    GVL_SIG.G6_REQ   := TRUE;
    GVL_SIG.G6_CIBLE := 0; // NORD
    Step := 31;

31:
    IF GVL_SIG.G6_DONE THEN
        GVL_SIG.G6_DONE := FALSE; Step := 32;
    ELSIF GVL_SIG.G6_ERR THEN
        GVL_SIG.G6_ERR         := FALSE;
        GVL_SIG.G3_CODE_DEFAUT := 11; Step := 203; END_IF;

32:
    GVL_SIG.G7_REQ := TRUE;
    GVL_SIG.G7_CMD := 0; // EXT
    Step := 33;

33:
    IF GVL_SIG.G7_DONE THEN
        GVL_SIG.G7_DONE := FALSE; Step := 34;
    ELSIF GVL_SIG.G7_ERR THEN
        GVL_SIG.G7_ERR         := FALSE;
        GVL_SIG.G3_CODE_DEFAUT := 11; Step := 203; END_IF;

34:
    GVL_SIG.G5_REQ   := TRUE;
    GVL_SIG.G5_CIBLE := 0; // Z_ZPM
    Step := 35;

35:
    IF GVL_SIG.G5_DONE THEN
        GVL_SIG.G5_DONE := FALSE; Step := 36;
    ELSIF GVL_SIG.G5_ERR THEN
        GVL_SIG.G5_ERR         := FALSE;
        GVL_SIG.G3_CODE_DEFAUT := 6; Step := 203; END_IF;

36:
    GVL_SIG.G7_REQ := TRUE;
    GVL_SIG.G7_CMD := 1; // RET
    Step := 37;

37:
    IF GVL_SIG.G7_DONE THEN
        GVL_SIG.G7_DONE := FALSE;
        IF NOT GVL_IO.MOULE_SUR_INTRO THEN
            GVL_SIG.G3_CODE_DEFAUT := 11; Step := 203;
        ELSIF GVL_IO.CAPTEUR_CHARGE_CHARIOT THEN
            GVL_SIG.G3_CODE_DEFAUT := 11; Step := 203;
        ELSE
            Step := 38;
        END_IF;
    ELSIF GVL_SIG.G7_ERR THEN
        GVL_SIG.G7_ERR         := FALSE;
        GVL_SIG.G3_CODE_DEFAUT := 11; Step := 203; END_IF;

38:
    GVL_SIG.G5_REQ   := TRUE;
    GVL_SIG.G5_CIBLE := 3; // Z_TRANSPORT
    Step := 39;

39:
    IF GVL_SIG.G5_DONE THEN
        GVL_SIG.G5_DONE         := FALSE;
        GVL_SIG.G10_REQ_ENTRER  := TRUE;
        GVL_SIG.G9_REQ_BRIDAGE  := TRUE;
        Step := 40;
    ELSIF GVL_SIG.G5_ERR THEN
        GVL_SIG.G5_ERR         := FALSE;
        GVL_SIG.G3_CODE_DEFAUT := 6; Step := 203; END_IF;

40:
    IF GVL_SIG.G9_BRIDE_OK AND GVL_SIG.G10_A_ZPM THEN
        GVL_MOULES.MOULE_EN_PRESSE := GVL_MOULES.MOULE_DEMANDE;
        GVL_SEQ.MOULE_EN_TRANSIT   := FALSE;
        GVL_SIG.G10_REQ_ENTRER     := FALSE;
        Step := 41;
    ELSIF GVL_SIG.G9_DEFAUT THEN
        GVL_SIG.G3_CODE_DEFAUT := 3; Step := 200;
    ELSIF GVL_SIG.G10_DEFAUT THEN
        GVL_SIG.G3_CODE_DEFAUT := 5; Step := 200;
    END_IF;

// ════════════════════════════════════════════════════════════
// DIVERGENCE ET#3 — Autorisation presse ‖ Retour garage
// ════════════════════════════════════════════════════════════
41:
    BrA_Done := FALSE;
    BrB_Done := FALSE;
    SubA     := 0;
    SubB     := 0;
    Step     := 42;

42:
    IF NOT BrA_Done THEN
        CASE SubA OF
        0:  GVL_SIG.G9_REQ_AUTORISER := TRUE;
            SubA := 1;
        1:  IF GVL_SIG.G9_AUTORISE_OK THEN
                GVL_SIG.G9_REQ_AUTORISER := FALSE;
                BrA_Done := TRUE;
            ELSIF GVL_SIG.G9_DEFAUT THEN
                GVL_SIG.G3_CODE_DEFAUT := 3; Step := 200; END_IF;
        END_CASE;
    END_IF;

    IF NOT BrB_Done THEN
        CASE SubB OF
        0:  GVL_SIG.G4_REQ   := TRUE;
            GVL_SIG.G4_CIBLE := 6; // P6 Garage
            SubB := 1;
        1:  IF GVL_SIG.G4_DONE THEN
                GVL_SIG.G4_DONE := FALSE;
                BrB_Done := TRUE;
            ELSIF GVL_SIG.G4_ERR THEN
                GVL_SIG.G4_ERR := FALSE;
                BrB_Done := TRUE;  // Non bloquant
            END_IF;
        END_CASE;
    END_IF;

    IF BrA_Done AND BrB_Done THEN
        Step := 50;
    END_IF;

// ════════════════════════════════════════════════════════════
// PHASE FINALE — Fin de cycle
// ════════════════════════════════════════════════════════════
50:
    GVL_SEQ.CYCLE_INTERROMPU    := FALSE;
    GVL_SEQ.CYCLE_EN_COURS      := FALSE;
    GVL_MOULES.ALM_STOCK_PLEIN  := FALSE;
    GVL_SIG.VYT_CYCLE_EN_COURS  := FALSE;
    GVL_SIG.G3_FIN_CM           := TRUE;
    IF NOT GVL_SIG.G3_REQ THEN
        GVL_SIG.G3_FIN_CM := FALSE;
        Step := 0;
    END_IF;

// ════════════════════════════════════════════════════════════
// BRANCHES DÉFAUT
// ════════════════════════════════════════════════════════════
200: // Défaut chariot VIDE
    GVL_SIG.G3_DEFAUT          := TRUE;
    GVL_SEQ.DEFAUT_ACTIF       := TRUE;
    GVL_SEQ.CODE_DEFAUT        := GVL_SIG.G3_CODE_DEFAUT;
    GVL_SIG.VYT_CYCLE_EN_COURS := FALSE;
    GVL_SIG.VYT_DEFAUT         := TRUE;
    IF GVL_MOULES.CIBLE_DEPOT_CH >= 1
       AND GVL_MOULES.CIBLE_DEPOT_CH <= 5 THEN
        GVL_MOULES.CH[GVL_MOULES.CIBLE_DEPOT_CH,
                      GVL_MOULES.CIBLE_DEPOT_NV].RESERVE := FALSE;
    END_IF;
    IF GVL_SIG.OP_CMD_RESET AND GVL_SIG.OP_CMD_ACQ THEN
        GVL_SIG.G3_DEFAUT    := FALSE;
        GVL_SEQ.DEFAUT_ACTIF := FALSE;
        GVL_SEQ.CODE_DEFAUT  := 0;
        GVL_SIG.VYT_DEFAUT   := FALSE;
        GVL_SEQ.CYCLE_INTERROMPU := FALSE;
        Step := 0;
    END_IF;

201: // Défaut ancien moule sur fourches
    GVL_SIG.G3_DEFAUT          := TRUE;
    GVL_SEQ.DEFAUT_ACTIF       := TRUE;
    GVL_SEQ.CODE_DEFAUT        := GVL_SIG.G3_CODE_DEFAUT;
    GVL_SIG.VYT_DEFAUT         := TRUE;
    GVL_SIG.VYT_CYCLE_EN_COURS := FALSE;
    IF GVL_SIG.OP_CMD_RESET AND GVL_SIG.OP_CMD_ACQ THEN
        GVL_SIG.G3_DEFAUT    := FALSE;
        GVL_SEQ.DEFAUT_ACTIF := FALSE;
        GVL_SIG.VYT_DEFAUT   := FALSE;
        Step := 0;
    END_IF;

202: // Défaut ancien moule déposé, chariot vide
    GVL_SIG.G3_DEFAUT          := TRUE;
    GVL_SEQ.DEFAUT_ACTIF       := TRUE;
    GVL_SEQ.CODE_DEFAUT        := GVL_SIG.G3_CODE_DEFAUT;
    GVL_SIG.VYT_DEFAUT         := TRUE;
    GVL_SIG.VYT_CYCLE_EN_COURS := FALSE;
    IF GVL_SIG.OP_CMD_RESET AND GVL_SIG.OP_CMD_ACQ THEN
        GVL_SIG.G3_DEFAUT    := FALSE;
        GVL_SEQ.DEFAUT_ACTIF := FALSE;
        GVL_SIG.VYT_DEFAUT   := FALSE;
        Step := 0;
    END_IF;

203: // Défaut nouveau moule sur fourches (MOULE_EN_TRANSIT=TRUE)
    GVL_SIG.G3_DEFAUT          := TRUE;
    GVL_SEQ.DEFAUT_ACTIF       := TRUE;
    GVL_SEQ.CODE_DEFAUT        := GVL_SIG.G3_CODE_DEFAUT;
    GVL_SIG.VYT_DEFAUT         := TRUE;
    GVL_SIG.VYT_CYCLE_EN_COURS := FALSE;
    IF GVL_SIG.OP_CMD_RESET AND GVL_SIG.OP_CMD_ACQ THEN
        GVL_SIG.G3_DEFAUT    := FALSE;
        GVL_SEQ.DEFAUT_ACTIF := FALSE;
        GVL_SIG.VYT_DEFAUT   := FALSE;
        Step := 0;
    END_IF;

210: // RFID2 KO — ROLLBACK (remettre moule en chambre prise)
    GVL_SIG.ALM_RFID           := TRUE;
    GVL_SIG.G3_DEFAUT          := TRUE;
    GVL_SEQ.DEFAUT_ACTIF       := TRUE;
    GVL_SEQ.CODE_DEFAUT        := 9;
    GVL_SIG.VYT_CYCLE_EN_COURS := FALSE;
    GVL_SIG.VYT_DEFAUT         := TRUE;
    GVL_MOULES.CH[GVL_MOULES.CIBLE_PRISE_CH,
                  GVL_MOULES.CIBLE_PRISE_NV].OCCUPE := TRUE;
    GVL_MOULES.CH[GVL_MOULES.CIBLE_PRISE_CH,
                  GVL_MOULES.CIBLE_PRISE_NV].ID     := GVL_MOULES.MOULE_DEMANDE;
    GVL_MOULES.NB_EMPLACEMENTS_LIBRES :=
        GVL_MOULES.NB_EMPLACEMENTS_LIBRES - 1;
    GVL_SEQ.MOULE_EN_TRANSIT := FALSE;
    IF GVL_SIG.OP_CMD_RESET AND GVL_SIG.OP_CMD_ACQ THEN
        GVL_SIG.G3_DEFAUT    := FALSE;
        GVL_SEQ.DEFAUT_ACTIF := FALSE;
        GVL_SIG.ALM_RFID     := FALSE;
        GVL_SIG.VYT_DEFAUT   := FALSE;
        Step := 0;
    END_IF;

END_CASE;

END_FUNCTION_BLOCK
