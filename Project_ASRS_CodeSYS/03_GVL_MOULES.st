// ================================================================
// 03_GVL_MOULES.st  —  Base de données stock moules (GVL "GVL_MOULES")
// Équivalent CODESYS de DB_MOULES (TIA Portal)
// 5 chambres × 2 niveaux = 10 emplacements
// Les valeurs initiales sont chargées par PRG_STARTUP
// ================================================================

VAR_GLOBAL
    // ── Stock physique ────────────────────────────────────────────
    CH : ARRAY[1..5, 1..2] OF UDT_MOULE;   // [chambre 1-5, niveau 1-2]

    // ── État presse et demande ────────────────────────────────────
    MOULE_EN_PRESSE        : USINT;
    MOULE_DEMANDE          : USINT;

    // ── Compteur disponibilité ────────────────────────────────────
    NB_EMPLACEMENTS_LIBRES : USINT;

    // ── Cibles calculées par G3 ───────────────────────────────────
    CIBLE_DEPOT_CH : USINT;
    CIBLE_DEPOT_NV : USINT;
    CIBLE_PRISE_CH : USINT;
    CIBLE_PRISE_NV : USINT;

    // ── Alarme saturation ─────────────────────────────────────────
    ALM_STOCK_PLEIN : BOOL;
END_VAR
