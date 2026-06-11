// ================================================================
// 25_FB_LaserSafe.st  —  Gestion barrière laser 2D (Sick S3000 OSSD)
// CODESYS V3.5 — FUNCTION_BLOCK
//
// Rôle :
//   Remplace le bouton ZONE_LIBRE (ZONE_LIBRE_BTN) par une validation
//   automatique basée sur les sorties OSSD des scanners 2D.
//
//   Logique :
//     1. Lecture OSSD_ZPM et OSSD_PRESSE (TRUE = zone libre)
//     2. Muting automatique si CAPTEUR_Z_TRANSPORT = TRUE
//        (chariot en position haute — le faisceau serait déclenché
//         par le chariot lui-même lors du retour avec nouveau moule)
//     3. Timer T_Confirm = T_ZONE_LIBRE_CONFIRM (défaut T#10S)
//        Les deux zones doivent être libres en continu pendant 10s
//     4. Après 10s confirmées → OSSD_ZONE_LIBRE_AUTO := TRUE
//                              → ZONE_CONFIRMEE := TRUE
//     5. Ré-intrusion après validation → invalidation + alarme
//
// Appel dans PRG_MAIN : avant instG3 (coordinateur cycle)
// ================================================================

FUNCTION_BLOCK FB_LaserSafe
VAR
    T_Confirm      : TON;       // Timer confirmation 10s zone libre
    ConfirmTimerEN : BOOL;      // Enable timer
END_VAR

// ─── Muting automatique ───────────────────────────────────────────────────────
// Lorsque le chariot est en Z_TRANSPORT (hauteur de transit, bras levés),
// les lasers sont mutés pour éviter un faux déclenchement lors du retour
// chariot avec le nouveau moule.
GVL_SIG.LASER_MUTING_ACTIF := GVL_IO.CAPTEUR_Z_TRANSPORT;

// ─── Lecture OSSD (copie dans signaux inter-GRAFCETs) ────────────────────────
GVL_SIG.LASER_ZPM_LIBRE    := GVL_IO.OSSD_ZPM;
GVL_SIG.LASER_PRESSE_LIBRE := GVL_IO.OSSD_PRESSE;

// ─── Timer de confirmation 10s ────────────────────────────────────────────────
// Active uniquement si :
//   • les deux zones OSSD sont libres (= vraies)
//   • le muting n'est pas actif (chariot pas en transit)
//   • le nettoyage est en cours (phase ET#2 active)
//   • ZONE_CONFIRMEE pas encore validée (évite re-triggering)
ConfirmTimerEN :=  GVL_SIG.LASER_ZPM_LIBRE
               AND GVL_SIG.LASER_PRESSE_LIBRE
               AND NOT GVL_SIG.LASER_MUTING_ACTIF
               AND GVL_SIG.NETTOYAGE_EN_COURS
               AND NOT GVL_SIG.ZONE_CONFIRMEE;

T_Confirm(IN := ConfirmTimerEN, PT := GVL_CFG.T_ZONE_LIBRE_CONFIRM);

GVL_SIG.LASER_CONFIRM_EN_COURS := ConfirmTimerEN AND NOT T_Confirm.Q;

// ─── Confirmation automatique ─────────────────────────────────────────────────
// Quand le timer expire : zones libres depuis 10s → autoriser retour chariot
IF T_Confirm.Q THEN
    GVL_SIG.OSSD_ZONE_LIBRE_AUTO := TRUE;
    GVL_SIG.ZONE_CONFIRMEE       := TRUE;
END_IF;

// ─── Reset OSSD_ZONE_LIBRE_AUTO si conditions perdues ────────────────────────
// (avant validation — après, seul G3 reset ZONE_CONFIRMEE via ré-intrusion)
IF NOT ConfirmTimerEN AND GVL_SIG.NETTOYAGE_EN_COURS AND NOT GVL_SIG.ZONE_CONFIRMEE THEN
    GVL_SIG.OSSD_ZONE_LIBRE_AUTO := FALSE;
END_IF;

// ─── Ré-intrusion APRÈS validation ───────────────────────────────────────────
// Quelqu'un entre dans la zone après validation laser mais avant que le
// chariot soit revenu (LASER_MUTING_ACTIF indique le retour chariot en cours).
// → Invalider la validation et attendre une nouvelle confirmation 10s.
// → Déclencher alarme ALM_ZONE.
IF GVL_SIG.ZONE_CONFIRMEE
   AND GVL_SIG.NETTOYAGE_EN_COURS
   AND NOT GVL_SIG.LASER_MUTING_ACTIF
   AND (NOT GVL_IO.OSSD_ZPM OR NOT GVL_IO.OSSD_PRESSE) THEN
    GVL_SIG.ZONE_CONFIRMEE       := FALSE;
    GVL_SIG.OSSD_ZONE_LIBRE_AUTO := FALSE;
    GVL_SIG.ALM_ZONE             := TRUE;
END_IF;

END_FUNCTION_BLOCK
