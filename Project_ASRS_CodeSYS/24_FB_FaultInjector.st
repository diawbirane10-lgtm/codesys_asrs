// ================================================================
// 24_FB_FaultInjector.st  —  Injection scénarios modes dégradés
// CODESYS V3.5 — FUNCTION_BLOCK
//
// Utilisé UNIQUEMENT en mode simulation/soutenance pour démontrer
// la réaction du système aux 8 modes dégradés du cahier des charges.
//
// Appelé par FB_HMI_Controller via la Visualization (écran 4)
//
// IMPORTANT : ResetFlt remet toutes les variables à leur état normal
// ================================================================

FUNCTION_BLOCK FB_FaultInjector
VAR_INPUT
    FaultID   : INT;    // 0-8 : scénario sélectionné
    Inject    : BOOL;   // R_TRIG depuis bouton INJECTER
    ResetFlt  : BOOL;   // R_TRIG depuis bouton RESET
END_VAR
VAR_OUTPUT
    Desc      : STRING(100);  // Description affichée avant injection
    Result    : STRING(120);  // Résultat affiché après injection
    FltActive : BOOL;         // TRUE si défaut injecté en cours
END_VAR
VAR
    bInjected   : BOOL;           // défaut actuellement injecté
    iInjectedID : INT;            // ID du défaut injecté
    tAutoReset  : TON;            // timeout auto-reset pour D3, D4
    rInj        : R_TRIG;
    rRst        : R_TRIG;
END_VAR

// ── Détection fronts ──────────────────────────────────────────────
rInj(CLK := Inject);
rRst(CLK := ResetFlt);

// ── Description (mise à jour à chaque cycle selon sélection) ──────
IF NOT bInjected THEN
    CASE FaultID OF
        0: Desc := 'Sélectionner un scénario de défaut...';
        1: Desc := 'D1 — Stock plein : aucune chambre libre. G3 refuse le démarrage.';
        2: Desc := 'D2 — Moule absent : ID demandé introuvable en stock.';
        3: Desc := 'D3 — Timeout axe X : déplacement bloqué (simulé).';
        4: Desc := 'D4 — RFID KO : 3 tentatives échouées, rollback moule.';
        5: Desc := 'D5 — Cycle interrompu : simule coupure secteur en cours de cycle.';
        6: Desc := 'D6 — Zone opérateurs : zone non libérée, cycle bloqué en S14.';
        7: Desc := 'D7 — Perte Profinet : presse inaccessible, arrêt tous mouvements.';
        8: Desc := 'D8 — Coupure secteur : AU + CYCLE_INTERROMPU retain, homing obligatoire.';
    ELSE
        Desc := '???';
    END_CASE;
END_IF;

// ── INJECTION ─────────────────────────────────────────────────────
IF rInj.Q AND NOT bInjected AND FaultID >= 1 AND FaultID <= 8 THEN
    bInjected   := TRUE;
    iInjectedID := FaultID;
    tAutoReset(IN := FALSE);

    CASE FaultID OF

        1: // D1 — Stock plein
            GVL_MOULES.NB_EMPLACEMENTS_LIBRES := 0;
            // Forcer toutes les chambres occupées
            GVL_MOULES.CH[5,1].OCCUPE := TRUE;
            GVL_MOULES.CH[5,2].OCCUPE := TRUE;
            Result := 'D1 injecté : NB_EMPLACEMENTS_LIBRES=0. Appuyez CMD_CM → alarme ALM_STOCK_PLEIN attendue.';

        2: // D2 — Moule absent
            GVL_IO.MOULE_DEMANDE_HMI := 9;   // ID 9 n'existe pas en stock
            GVL_MOULES.MOULE_DEMANDE := 9;
            Result := 'D2 injecté : MOULE_DEMANDE=ID9 (inexistant). Appuyez CMD_CM → G3 ne démarre pas.';

        3: // D3 — Timeout axe X (injecter erreur axe X)
            GVL_SIG.G4_ERR := TRUE;
            Result := 'D3 injecté : G4_ERR=TRUE. Si cycle en cours → G3 défaut, alarme ALM_AXE_X.';
            tAutoReset(IN := TRUE, PT := T#10S);  // auto-clear après 10s

        4: // D4 — RFID KO
            GVL_SIG.G8_ERR := TRUE;
            GVL_SIG.G8_OK  := FALSE;
            Result := 'D4 injecté : G8_ERR=TRUE. Si cycle en cours → 3 tentatives RFID → rollback → G3 défaut.';
            tAutoReset(IN := TRUE, PT := T#10S);

        5: // D5 — Cycle interrompu (simule coupure secteur)
            GVL_SEQ.CYCLE_INTERROMPU := TRUE;
            GVL_IO.AU_ACTIF := TRUE;
            Result := 'D5 injecté : CYCLE_INTERROMPU=TRUE + AU. Au reset : G0 passe en E2 (alarme reprise), homing obligatoire.';

        6: // D6 — Zone opérateurs
            GVL_IO.CAPTEUR_ZONE_OCCUPEE := TRUE;
            GVL_SIG.ZONE_CONFIRMEE := FALSE;
            GVL_HMI.HMI_BTN_ZONE_OK := FALSE;
            Result := 'D6 injecté : Zone occupée + ZONE_CONFIRMEE=FALSE. Cycle bloqué en S14 → voyant nettoyage actif.';

        7: // D7 — Perte Profinet
            GVL_SIG.PERTE_PROFINET := TRUE;
            GVL_SIG.ALM_COMM_PRESSE := TRUE;
            Result := 'D7 injecté : PERTE_PROFINET=TRUE. G9 ne peut pas commander la presse → arrêt général.';

        8: // D8 — Coupure secteur
            GVL_IO.AU_ACTIF := TRUE;
            GVL_SEQ.CYCLE_INTERROMPU := TRUE;
            GVL_SEQ.MOULE_EN_TRANSIT := TRUE;
            Result := 'D8 injecté : AU + CYCLE_INTERROMPU + MOULE_EN_TRANSIT. Redémarrer → G0 exige homing + acquittement.';

    END_CASE;
END_IF;

// ── Auto-reset D3/D4 après timeout ───────────────────────────────
tAutoReset(IN := bInjected AND (iInjectedID = 3 OR iInjectedID = 4));
IF tAutoReset.Q THEN
    GVL_SIG.G4_ERR := FALSE;
    GVL_SIG.G8_ERR := FALSE;
    GVL_SIG.G8_OK  := FALSE;
    bInjected   := FALSE;
    iInjectedID := 0;
    Result := 'Auto-reset D3/D4 effectué après 10s.';
    tAutoReset(IN := FALSE);
END_IF;

// ── RESET MANUEL ──────────────────────────────────────────────────
IF rRst.Q THEN
    // Remettre toutes les variables injectées à leur état normal
    GVL_MOULES.NB_EMPLACEMENTS_LIBRES := 4;  // 4 emplacements libres par défaut
    GVL_MOULES.CH[5,1].OCCUPE := FALSE;
    GVL_MOULES.CH[5,2].OCCUPE := FALSE;
    GVL_IO.MOULE_DEMANDE_HMI := 0;
    GVL_MOULES.MOULE_DEMANDE := 0;
    GVL_SIG.G4_ERR := FALSE;
    GVL_SIG.G8_ERR := FALSE;
    GVL_SIG.G8_OK  := FALSE;
    GVL_SEQ.CYCLE_INTERROMPU := FALSE;
    GVL_SEQ.MOULE_EN_TRANSIT := FALSE;
    GVL_IO.AU_ACTIF := FALSE;
    GVL_HMI.HMI_BTN_AU := FALSE;
    GVL_IO.CAPTEUR_ZONE_OCCUPEE := FALSE;
    GVL_SIG.PERTE_PROFINET := FALSE;
    GVL_SIG.ALM_COMM_PRESSE := FALSE;
    // Acquitter alarmes
    GVL_SIG.ALM_STOCK_PLEIN  := FALSE;
    GVL_SIG.ALM_RFID         := FALSE;
    GVL_SIG.ALM_AXE_X        := FALSE;
    GVL_SIG.ALM_AXE_Z        := FALSE;
    GVL_SIG.ALM_ZONE         := FALSE;
    GVL_SIG.ALM_HOMING       := FALSE;
    GVL_SEQ.DEFAUT_ACTIF     := FALSE;
    GVL_SEQ.CODE_DEFAUT      := 0;
    bInjected   := FALSE;
    iInjectedID := 0;
    tAutoReset(IN := FALSE);
    Result   := 'Reset complet effectué. Système remis à l état nominal.';
    Desc     := 'Sélectionner un scénario de défaut...';
END_IF;

FltActive := bInjected;
GVL_HMI.HMI_FAULT_ACTIVE := bInjected;

// Couleur bouton INJECTER : rouge foncé si déjà actif, rouge vif sinon
IF bInjected THEN
    GVL_HMI.HMI_COL_FAULT_BTN := 16#FF8B0000;   // rouge foncé = déjà injecté
ELSE
    GVL_HMI.HMI_COL_FAULT_BTN := 16#FFCC0000;   // rouge vif = prêt à injecter
END_IF;
