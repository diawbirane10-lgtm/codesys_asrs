// ================================================================
// 23_FB_HMI_Controller.st  —  Contrôleur IHM CODESYS Visualization
// CODESYS V3.5 — FUNCTION_BLOCK
//
// Rôle :
//   - Génère les textes et couleurs dynamiques affichés dans la Visualization
//   - Détecte les fronts montants des boutons HMI (R_TRIG)
//   - Route les commandes HMI vers GVL_IO (puis → GVL_SIG via PRG_MAIN)
//   - Gère le chronomètre cycle et la barre de progression G3
//
// Appel dans PRG_MAIN : avant le bloc de copies GVL_IO → GVL_SIG
//
// Modification v2 — Laser OSSD :
//   - HMI_BTN_ZONE_OK supprimé du flux normal (ZONE_CONFIRMEE géré par FB_LaserSafe)
//   - rZoneOk supprimé
// ================================================================

FUNCTION_BLOCK FB_HMI_Controller
VAR
    // ── Fronts montants boutons ───────────────────────────────────
    rHoming   : R_TRIG;
    rCmdCM    : R_TRIG;
    rAcq      : R_TRIG;

    // ── Chronomètre cycle ─────────────────────────────────────────
    tTick       : TON;
    iCycleSec   : DINT;
    bCycleWas   : BOOL;
    iMin, iSec  : DINT;
    sMin, sSec  : STRING(3);

    // ── Boucle stock ──────────────────────────────────────────────
    iCh, iNv    : INT;
END_VAR

// ── 1. MODE SYSTÈME → texte + couleur ────────────────────────────
IF GVL_SIG.OP_AU THEN
    GVL_HMI.HMI_MODE_TXT := 'ARRET URGENCE';
    GVL_HMI.HMI_COL_MODE := 16#FFFF3030;   // rouge vif
ELSIF GVL_SEQ.DEFAUT_ACTIF THEN
    GVL_HMI.HMI_MODE_TXT := 'DEFAUT';
    GVL_HMI.HMI_COL_MODE := 16#FFFF6600;   // orange défaut
ELSIF GVL_SEQ.CYCLE_EN_COURS THEN
    GVL_HMI.HMI_MODE_TXT := 'CYCLE EN COURS';
    GVL_HMI.HMI_COL_MODE := 16#FF00C800;   // vert cycle
ELSIF GVL_SEQ.HOMING_OK AND GVL_SIG.VYT_MACHINE_PRETE THEN
    GVL_HMI.HMI_MODE_TXT := 'EN ATTENTE';
    GVL_HMI.HMI_COL_MODE := 16#FF1C6EBF;   // bleu attente
ELSIF GVL_SIG.G2_REQ THEN
    GVL_HMI.HMI_MODE_TXT := 'HOMING...';
    GVL_HMI.HMI_COL_MODE := 16#FFFFA500;   // orange homing
ELSE
    GVL_HMI.HMI_MODE_TXT := 'HORS SERVICE';
    GVL_HMI.HMI_COL_MODE := 16#FF404040;   // gris
END_IF;

// ── 2. MOULE EN PRESSE → texte ────────────────────────────────────
GVL_HMI.HMI_MOULE_PRESSE_TXT := FC_MouleIDToStr(GVL_MOULES.MOULE_EN_PRESSE);

// ── 3. STOCK 5×2 → tableau de textes ─────────────────────────────
FOR iCh := 1 TO 5 DO
    FOR iNv := 1 TO 2 DO
        GVL_HMI.HMI_STOCK_TXT[iCh, iNv] := FC_MouleIDToStr(GVL_MOULES.CH[iCh, iNv].ID);
    END_FOR;
END_FOR;

// ── 4. PROGRESSION G3 ─────────────────────────────────────────────
GVL_HMI.HMI_G3_ETAPE    := GVL_SEQ.ETAPE_ACTIVE;
GVL_HMI.HMI_ETAPE_G3_TXT := FC_EtapeG3ToStr(GVL_SEQ.ETAPE_ACTIVE);
IF GVL_SEQ.CYCLE_EN_COURS AND GVL_SEQ.ETAPE_ACTIVE > 0 THEN
    GVL_HMI.HMI_G3_PCT := INT_TO_REAL(GVL_SEQ.ETAPE_ACTIVE) * 100.0 / 15.0;
ELSE
    GVL_HMI.HMI_G3_PCT := 0.0;
END_IF;

// ── 5. CHRONOMÈTRE CYCLE ──────────────────────────────────────────
IF GVL_SEQ.CYCLE_EN_COURS AND NOT bCycleWas THEN
    iCycleSec := 0;
    bCycleWas := TRUE;
ELSIF NOT GVL_SEQ.CYCLE_EN_COURS THEN
    bCycleWas := FALSE;
    tTick(IN := FALSE);
END_IF;
IF GVL_SEQ.CYCLE_EN_COURS THEN
    tTick(IN := TRUE, PT := T#1S);
    IF tTick.Q THEN
        iCycleSec := iCycleSec + 1;
        tTick(IN := FALSE);
    END_IF;
END_IF;
iMin := iCycleSec / 60;
iSec := iCycleSec MOD 60;
IF iMin < 10 THEN sMin := CONCAT('0', DINT_TO_STRING(iMin));
ELSE sMin := DINT_TO_STRING(iMin); END_IF;
IF iSec < 10 THEN sSec := CONCAT('0', DINT_TO_STRING(iSec));
ELSE sSec := DINT_TO_STRING(iSec); END_IF;
GVL_HMI.HMI_TEMPS_CYCLE := CONCAT(sMin, CONCAT(':', sSec));

// ── 6. SÉLECTEUR MOULE ────────────────────────────────────────────
GVL_HMI.HMI_SEL_MOULE_OK := (GVL_HMI.HMI_SEL_MOULE >= 1)
                          AND (GVL_HMI.HMI_SEL_MOULE <= 5);

// ── 7. BOUTONS → GVL_IO (détection front montant) ─────────────────

// HOMING
rHoming(CLK := GVL_HMI.HMI_BTN_HOMING);
IF rHoming.Q THEN
    GVL_IO.CMD_HOMING_MANUEL := TRUE;
ELSIF NOT GVL_SIG.G2_REQ THEN
    GVL_IO.CMD_HOMING_MANUEL := FALSE;
END_IF;

// ACQUITTEMENT DÉFAUTS
rAcq(CLK := GVL_HMI.HMI_BTN_ACQ);
IF rAcq.Q THEN
    GVL_IO.CMD_ACQ_DEF := TRUE;
ELSE
    GVL_IO.CMD_ACQ_DEF := FALSE;
END_IF;

// ZONE LIBRE : désormais pilotée automatiquement par FB_LaserSafe (OSSD Sick S3000)
// HMI_BTN_ZONE_OK conservé dans GVL_HMI uniquement pour diagnostic Visualization
// (ne déclenche plus ZONE_CONFIRMEE en production — laser prime)

// ARRÊT URGENCE SW
GVL_IO.AU_ACTIF := GVL_HMI.HMI_BTN_AU;

// CMD_CM — ne démarre que si un moule valide est sélectionné
rCmdCM(CLK := GVL_HMI.HMI_BTN_CMD_CM);
IF rCmdCM.Q AND GVL_HMI.HMI_SEL_MOULE_OK THEN
    GVL_IO.MOULE_DEMANDE_HMI := INT_TO_USINT(GVL_HMI.HMI_SEL_MOULE);
    GVL_IO.CMD_CM := TRUE;
ELSIF NOT GVL_SEQ.CYCLE_EN_COURS THEN
    GVL_IO.CMD_CM := FALSE;
END_IF;

// ── 8. INDICATEUR ALARME GLOBALE ─────────────────────────────────
GVL_HMI.HMI_ALARME_ACTIVE :=
    GVL_SIG.ALM_STOCK_PLEIN   OR GVL_SIG.ALM_RFID        OR
    GVL_SIG.ALM_DEBRIDAGE      OR GVL_SIG.ALM_BRIDAGE      OR
    GVL_SIG.ALM_PILON          OR GVL_SIG.ALM_INTRO        OR
    GVL_SIG.ALM_AXE_X          OR GVL_SIG.ALM_AXE_Z        OR
    GVL_SIG.ALM_ROTATION       OR GVL_SIG.ALM_SATELLITE     OR
    GVL_SIG.ALM_COMM_PRESSE    OR GVL_SIG.ALM_ZONE         OR
    GVL_SIG.ALM_HOMING;
