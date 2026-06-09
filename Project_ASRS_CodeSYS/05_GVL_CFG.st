// ================================================================
// 05_GVL_CFG.st  —  Constantes de configuration (GVL "GVL_CFG")
// Équivalent CODESYS de DB_CFG (TIA Portal)
// Positions mécaniques (mm × 10) et timeouts
// ================================================================

VAR_GLOBAL
    // ── Positions Z (unités encoder, 0 = bas) ────────────────────
    Z_ZPM       : INT := 200;
    Z_NIVEAU1   : INT := 450;
    Z_NIVEAU2   : INT := 950;
    Z_TRANSPORT : INT := 1200;

    // ── Positions X (0=P0_ZPM .. 6=P6_Garage) ───────────────────
    X_P0 : INT :=    0;
    X_P1 : INT :=  500;
    X_P2 : INT := 1000;
    X_P3 : INT := 1500;
    X_P4 : INT := 2000;
    X_P5 : INT := 2500;
    X_P6 : INT := 3000;

    // ── Timeouts ─────────────────────────────────────────────────
    T_ARRET_PRESSE : TIME := T#120S;
    T_DEBRIDAGE    : TIME := T#120S;
    T_BRIDAGE      : TIME := T#120S;
    T_PILON        : TIME := T#120S;
    T_INTRO        : TIME := T#120S;
    T_MVT_Z        : TIME := T#120S;
    T_MVT_X        : TIME := T#120S;
    T_RFID         : TIME := T#120S;
    T_ROTATION     : TIME := T#120S;
    T_SATELLITE    : TIME := T#120S;
END_VAR
