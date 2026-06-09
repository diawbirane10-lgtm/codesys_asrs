// ================================================================
// 04_GVL_SEQ.st  —  État séquence (GVL "GVL_SEQ")
// Équivalent CODESYS de DB_SEQ (TIA Portal)
// Variables RETAIN : survivent au redémarrage (cocher Retain dans CODESYS)
// ================================================================

VAR_GLOBAL
    ETAPE_ACTIVE   : INT;
    CYCLE_EN_COURS : BOOL;
    HOMING_OK      : BOOL;
    DEFAUT_ACTIF   : BOOL;
    CODE_DEFAUT    : USINT;
    // Codes défaut :
    //  1=Timeout arret presse   2=Timeout debridage    3=Timeout bridage
    //  4=Timeout pilon          5=Timeout introducteur 6=Timeout Z
    //  7=Timeout X              8=RFID chambre KO      9=RFID ZPM KO
    // 10=Prise échouée         11=Depot échoue        12=Stock plein
    // 13=Moule introuvable     14=AU pendant cycle    15=Defaut homing
    // 16=Moule presse inconnu  17=Moule demande deja en presse
    // 18=Depassement nettoyage operateur 15+5 min
    // 20=Perte Profinet presse

    // ── Variables RETAIN (cocher "Retain" sur ces variables dans CODESYS)
    CYCLE_INTERROMPU  : BOOL;   // TRUE si coupure pendant cycle
    MOULE_EN_TRANSIT  : BOOL;   // TRUE si moule entre 2 positions
    NB_CYCLES_TOTAL   : DINT;   // compteur cumulé
END_VAR
