// ================================================================
// 01_GVL_IO.st  —  Signaux physiques I/O (GVL nommée "GVL_IO")
// CODESYS V3.5 — Global Variable List
// Sur SoftPLC : pas d'adresse matérielle — simulé via Visualization
// ================================================================

VAR_GLOBAL
    // ── ENTRÉES CAPTEURS POSITION X ──────────────────────────────
    POS_P0  : BOOL;   // Chariot en P0 (ZPM)
    POS_P1  : BOOL;   // Chariot en P1 (AGADIR)
    POS_P2  : BOOL;   // Chariot en P2 (IFRANE)
    POS_P3  : BOOL;   // Chariot en P3 (TANGER)
    POS_P4  : BOOL;   // Chariot en P4 (RABAT)
    POS_P5  : BOOL;   // Chariot en P5 (FEZ)
    POS_P6  : BOOL;   // Chariot en P6 (Garage)

    // ── ENTRÉES PRÉSENCE CHAMBRES ─────────────────────────────────
    CH1N1   : BOOL;
    CH1N2   : BOOL;
    CH2N1   : BOOL;
    CH2N2   : BOOL;
    CH3N1   : BOOL;
    CH3N2   : BOOL;
    CH4N1   : BOOL;
    CH4N2   : BOOL;
    CH5N1   : BOOL;
    CH5N2   : BOOL;

    // ── ENTRÉES AXE Z ─────────────────────────────────────────────
    CAPTEUR_Z_ZPM       : BOOL;
    CAPTEUR_Z_NIVEAU1   : BOOL;
    CAPTEUR_Z_NIVEAU2   : BOOL;
    CAPTEUR_Z_TRANSPORT : BOOL;

    // ── ENTRÉES SATELLITE ─────────────────────────────────────────
    CAPTEUR_SAT_RETRACTE : BOOL;
    CAPTEUR_SAT_ETENDU   : BOOL;

    // ── ENTRÉES ROTATION ──────────────────────────────────────────
    CAPTEUR_ROT_NORD   : BOOL;
    CAPTEUR_ROT_SUD    : BOOL;
    CAPTEUR_ROT_NEUTRE : BOOL;

    // ── ENTRÉES SÉCURITÉ / ZONE ───────────────────────────────────
    ZONE_LIBRE_BTN        : BOOL;
    CAPTEUR_ZONE_OCCUPEE  : BOOL;
    CAPTEUR_CHARGE_CHARIOT: BOOL;

    // ── ENTRÉES RFID ──────────────────────────────────────────────
    RFID_LECTURE_OK : BOOL;
    RFID_ID_LU      : USINT;

    // ── ENTRÉES PRESSE ────────────────────────────────────────────
    PRESSE_ARRETEE      : BOOL;
    PILON_HAUT_OK       : BOOL;
    PILON_BAS_OK        : BOOL;
    MOULE_DEBRIDE       : BOOL;
    MOULE_BRIDE         : BOOL;

    // ── ENTRÉES INTRODUCTEUR ──────────────────────────────────────
    MOULE_SUR_INTRO         : BOOL;
    INTRODUCTEUR_EN_PRESSE  : BOOL;
    INTRODUCTEUR_A_ZPM      : BOOL;
    INTRO_VIDE              : BOOL;

    // ── ENTRÉES COMMANDES OPÉRATEUR (HMI / boutons) ───────────────
    CMD_CM              : BOOL;   // Démarrage changement moule
    CMD_RESET           : BOOL;
    CMD_ACQ_DEF         : BOOL;   // Acquittement défaut
    CMD_HOMING_MANUEL   : BOOL;
    PROLONG_NETTOYAGE_BTN : BOOL; // Demande unique +5 min nettoyage apres alarme T15
    AU_ACTIF            : BOOL;   // Arrêt urgence SW
    MOULE_DEMANDE_HMI   : USINT;  // 1-5
    MODE_AUTO           : BOOL;

    // ── SORTIES AXES ──────────────────────────────────────────────
    CMD_X_AV    : BOOL;
    CMD_X_AR    : BOOL;
    CMD_Z_HAUT  : BOOL;
    CMD_Z_BAS   : BOOL;

    // ── SORTIES SATELLITE ─────────────────────────────────────────
    CMD_SAT_EXT : BOOL;
    CMD_SAT_RET : BOOL;

    // ── SORTIES ROTATION ──────────────────────────────────────────
    CMD_ROT_NORD : BOOL;
    CMD_ROT_SUD  : BOOL;

    // ── SORTIES PRESSE ────────────────────────────────────────────
    CMD_ARRET_PRESSE        : BOOL;
    CMD_DEBRIDAGE           : BOOL;
    CMD_BRIDAGE             : BOOL;
    CMD_AUTORISE_DEMARRAGE  : BOOL;
    CMD_MONTE_PILON         : BOOL;
    CMD_BAISSE_PILON        : BOOL;

    // ── SORTIES INTRODUCTEUR ──────────────────────────────────────
    CMD_INTRO_ENTRE : BOOL;
    CMD_INTRO_SORT  : BOOL;

    // ── SORTIES RFID ──────────────────────────────────────────────
    CMD_RFID_ACTIVER : BOOL;

    // ── SORTIES ENCODEUR / VARIATEUR ──────────────────────────────
    INIT_ENCODEUR_X : BOOL;
    CONSIGNE_POS_X  : WORD;

    // ── SORTIES VOYANTS / BUZZER ──────────────────────────────────
    VOYANT_MACHINE_PRETE    : BOOL;
    VOYANT_CYCLE_EN_COURS   : BOOL;
    VOYANT_DEFAUT           : BOOL;
    VOYANT_INIT_OK          : BOOL;
    VOYANT_NETTOYAGE        : BOOL;
    BUZZER_DEBUT_NETTOYAGE  : BOOL;
    BUZZER_ATTENTE_ZONE_LIBRE : BOOL;
    VOYANT_ATTENTE_ZONE_LIBRE : BOOL;
    VOYANT_NETTOYAGE_TIMEOUT : BOOL;
    VOYANT_NETTOYAGE_MAX     : BOOL;
END_VAR
