// ================================================================
// 20_GVL_HMI.st  —  Variables globales IHM CODESYS Visualization
// GVL nommée "GVL_HMI" dans le projet
// Lier ces variables aux éléments visuels (voir guide 23_CODESYS_HMI_Guide.txt)
// ================================================================

VAR_GLOBAL

    // ── Textes dynamiques (mis à jour par FB_HMI_Controller) ─────
    HMI_MODE_TXT         : STRING(20) := 'HORS SERVICE';
    HMI_ETAPE_G3_TXT     : STRING(40) := '---';
    HMI_MOULE_PRESSE_TXT : STRING(10) := '?';
    HMI_MSG_SYSTEME      : STRING(80) := 'Initialisation...';
    HMI_STOCK_TXT        : ARRAY[1..5, 1..2] OF STRING(10);

    // ── Progression cycle G3 ─────────────────────────────────────
    HMI_G3_ETAPE  : INT   := 0;    // Étape courante 0-15
    HMI_G3_PCT    : REAL  := 0.0;  // Pourcentage 0.0-100.0 (pour BarDisplay)

    // ── Sélecteur moule demandé ───────────────────────────────────
    // Lier à un ComboBox : 0=Choisir 1=MOULE_A 2=MOULE_B 3=MOULE_C 4=MOULE_D 5=MOULE_E
    HMI_SEL_MOULE    : INT  := 0;
    HMI_SEL_MOULE_OK : BOOL := FALSE;

    // ── Chronomètre cycle (format "mm:ss") ───────────────────────
    HMI_TEMPS_CYCLE  : STRING(8) := '00:00';

    // ── Boutons opérateur (lier aux boutons Visualization) ───────
    HMI_BTN_HOMING   : BOOL;   // Démarrer homing
    HMI_BTN_AU       : BOOL;   // Arrêt urgence SW
    HMI_BTN_CMD_CM   : BOOL;   // Démarrer changement moule
    HMI_BTN_ACQ      : BOOL;   // Acquitter défauts
    HMI_BTN_ZONE_OK  : BOOL;   // Zone libre confirmée (opérateur)
    HMI_BTN_PROLONG_NETTOYAGE : BOOL; // Prolongation unique nettoyage +5 min

    // ── Modes dégradés — sélection et injection ───────────────────
    // Combo Box : 0=Aucun 1=D1_StockPlein 2=D2_MouleAbsent
    //             3=D3_TimeoutAxe 4=D4_RFID_KO 5=D5_CycleInterrompu
    //             6=D6_ZoneOccupee 7=D7_PerteProfinet 8=D8_CoupureSecteur
    HMI_FAULT_SEL       : INT := 0;
    HMI_FAULT_DESC      : STRING(100) := 'Sélectionner un scénario...';
    HMI_FAULT_RESULT    : STRING(120) := '';
    HMI_BTN_INJECT      : BOOL;
    HMI_BTN_FAULT_RESET : BOOL;
    HMI_FAULT_ACTIVE    : BOOL;

    // ── Couleurs dynamiques ARGB (mis à jour par FB_HMI_Controller)
    // 16#FF000000 = ARGB (A=opaque toujours à FF)
    // Palette: vert=#FF00C800  rouge=#FFFF3030  orange=#FFFFA500
    //          bleu=#FF1C6EBF  gris=#FF404040   jaune=#FFFFF000
    HMI_COL_MODE      : DWORD := 16#FF404040;
    HMI_COL_FAULT_BTN : DWORD := 16#FF8B0000;   // rouge foncé injecté

    // ── Indicateur alarme globale ─────────────────────────────────
    HMI_ALARME_ACTIVE : BOOL;  // TRUE si au moins 1 alarme

END_VAR
