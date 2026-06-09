// ================================================================
// 02_GVL_SIG.st  —  Signaux inter-GRAFCETs (GVL nommée "GVL_SIG")
// Équivalent CODESYS de DB_SIG (TIA Portal)
// Point de communication central entre G0-G10
// ================================================================

VAR_GLOBAL
    // ─── SÉCURITÉ (calculé par G1) ───────────────────────────────
    SECURITES_OK    : BOOL;
    ZONE_CONFIRMEE  : BOOL;
    DEFAUT_AXE      : BOOL;
    PERTE_PROFINET  : BOOL;

    // ─── COMMANDES OPÉRATEUR ─────────────────────────────────────
    OP_CMD_CM        : BOOL;
    OP_CMD_RESET     : BOOL;
    OP_CMD_ACQ       : BOOL;
    OP_CMD_HOMING    : BOOL;
    OP_MOULE_DEMANDE : USINT;
    OP_MODE_AUTO     : BOOL;
    OP_AU            : BOOL;
    OP_PROLONG_NETTOYAGE : BOOL;

    // ─── G0 ↔ G2 (Homing) ────────────────────────────────────────
    G2_REQ        : BOOL;
    G2_HOMING_OK  : BOOL;
    G2_DEFAUT     : BOOL;

    // ─── G0 ↔ G3 (Cycle) ─────────────────────────────────────────
    G3_REQ          : BOOL;
    G3_FIN_CM       : BOOL;
    G3_DEFAUT       : BOOL;
    G3_CODE_DEFAUT  : USINT;

    // ─── G3 ↔ G4 — Axe X ─────────────────────────────────────────
    G4_REQ   : BOOL;
    G4_CIBLE : USINT;
    G4_DONE  : BOOL;
    G4_ERR   : BOOL;

    // ─── G3 ↔ G5 — Axe Z ─────────────────────────────────────────
    G5_REQ   : BOOL;
    G5_CIBLE : USINT;
    G5_DONE  : BOOL;
    G5_ERR   : BOOL;

    // ─── G3 ↔ G6 — Rotation ──────────────────────────────────────
    G6_REQ   : BOOL;
    G6_CIBLE : USINT;
    G6_DONE  : BOOL;
    G6_ERR   : BOOL;

    // ─── G3 ↔ G7 — Satellite ─────────────────────────────────────
    G7_REQ  : BOOL;
    G7_CMD  : USINT;
    G7_DONE : BOOL;
    G7_ERR  : BOOL;

    // ─── G3 ↔ G8 — RFID ──────────────────────────────────────────
    G8_REQ        : BOOL;
    G8_ID_ATTENDU : USINT;
    G8_DONE       : BOOL;
    G8_OK         : BOOL;
    G8_ID_LU      : USINT;
    G8_ERR        : BOOL;

    // ─── G3 ↔ G9 — Interface Presse ──────────────────────────────
    G9_REQ_ARRET      : BOOL;
    G9_REQ_DEBRIDAGE  : BOOL;
    G9_REQ_BRIDAGE    : BOOL;
    G9_REQ_AUTORISER  : BOOL;
    G9_ARRETEE_OK     : BOOL;
    G9_DEBRIDE_OK     : BOOL;
    G9_BRIDE_OK       : BOOL;
    G9_AUTORISE_OK    : BOOL;
    G9_DEFAUT         : BOOL;
    G9_CODE_DEFAUT    : USINT;

    // ─── G3 ↔ G10 — Introducteur ZPM ────────────────────────────
    G10_REQ_ENTRER : BOOL;
    G10_REQ_SORTIR : BOOL;
    G10_EN_PRESSE  : BOOL;
    G10_A_ZPM      : BOOL;
    G10_DEFAUT     : BOOL;

    // ─── ALARMES ─────────────────────────────────────────────────
    ALM_STOCK_PLEIN  : BOOL;
    ALM_RFID         : BOOL;
    ALM_DEBRIDAGE    : BOOL;
    ALM_BRIDAGE      : BOOL;
    ALM_PILON        : BOOL;
    ALM_INTRO        : BOOL;
    ALM_AXE_X        : BOOL;
    ALM_AXE_Z        : BOOL;
    ALM_ROTATION     : BOOL;
    ALM_SATELLITE    : BOOL;
    ALM_COMM_PRESSE  : BOOL;
    ALM_ZONE         : BOOL;
    ALM_HOMING       : BOOL;

    // ─── VOYANTS HMI ─────────────────────────────────────────────
    VYT_MACHINE_PRETE   : BOOL;
    VYT_CYCLE_EN_COURS  : BOOL;
    VYT_DEFAUT          : BOOL;
    VYT_INIT_OK         : BOOL;
    VYT_NETTOYAGE       : BOOL;
    VYT_ATTENTE_ZONE    : BOOL;
    VYT_NETTOYAGE_TIMEOUT : BOOL;

    // Nettoyage operateur ET2 : surveillance 15 min + prolongation unique 5 min
    NETTOYAGE_EN_COURS              : BOOL;
    NETTOYAGE_TIMEOUT               : BOOL;
    NETTOYAGE_PROLONGATION_UTILISEE : BOOL;
    NETTOYAGE_DEPASSEMENT_MAX       : BOOL;

    // ─── ÉTAT SYSTÈME ────────────────────────────────────────────
    CYCLE_CM_AUTORISE : BOOL;

    // ─── IMAGES I/O (rafraîchies par PLC_PRG avant tout appel FB) ─
    CAPTEUR_POS_X   : ARRAY[0..6] OF BOOL;
    CAPTEUR_PRES_CH : ARRAY[1..5, 1..2] OF BOOL;
END_VAR
