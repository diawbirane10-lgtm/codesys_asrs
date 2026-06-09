// ================================================================
// 17_PRG_STARTUP.st  —  Programme démarrage (équivalent OB100)
// CODESYS V3.5 — PROGRAM
// Configurer cette tâche en "Single" dans le Task Manager CODESYS
// (exécution une seule fois au démarrage)
// ================================================================

PROGRAM PRG_STARTUP
VAR
END_VAR

// ── Initialisation GVL_SIG ────────────────────────────────────
GVL_SIG.SECURITES_OK        := FALSE;
GVL_SIG.ZONE_CONFIRMEE      := FALSE;
GVL_SIG.DEFAUT_AXE          := FALSE;
GVL_SIG.PERTE_PROFINET      := FALSE;
GVL_SIG.G2_REQ              := FALSE;
GVL_SIG.G2_HOMING_OK        := FALSE;
GVL_SIG.G2_DEFAUT           := FALSE;
GVL_SIG.G3_REQ              := FALSE;
GVL_SIG.G3_FIN_CM           := FALSE;
GVL_SIG.G3_DEFAUT           := FALSE;
GVL_SIG.G3_CODE_DEFAUT      := 0;
GVL_SIG.G4_REQ              := FALSE;
GVL_SIG.G4_DONE             := FALSE;
GVL_SIG.G4_ERR              := FALSE;
GVL_SIG.G5_REQ              := FALSE;
GVL_SIG.G5_DONE             := FALSE;
GVL_SIG.G5_ERR              := FALSE;
GVL_SIG.G6_REQ              := FALSE;
GVL_SIG.G6_DONE             := FALSE;
GVL_SIG.G6_ERR              := FALSE;
GVL_SIG.G7_REQ              := FALSE;
GVL_SIG.G7_DONE             := FALSE;
GVL_SIG.G7_ERR              := FALSE;
GVL_SIG.G8_REQ              := FALSE;
GVL_SIG.G8_DONE             := FALSE;
GVL_SIG.G8_OK               := FALSE;
GVL_SIG.G8_ERR              := FALSE;
GVL_SIG.G9_REQ_ARRET        := FALSE;
GVL_SIG.G9_REQ_DEBRIDAGE    := FALSE;
GVL_SIG.G9_REQ_BRIDAGE      := FALSE;
GVL_SIG.G9_REQ_AUTORISER    := FALSE;
GVL_SIG.G9_ARRETEE_OK       := FALSE;
GVL_SIG.G9_DEBRIDE_OK       := FALSE;
GVL_SIG.G9_BRIDE_OK         := FALSE;
GVL_SIG.G9_AUTORISE_OK      := FALSE;
GVL_SIG.G9_DEFAUT           := FALSE;
GVL_SIG.G10_REQ_ENTRER      := FALSE;
GVL_SIG.G10_REQ_SORTIR      := FALSE;
GVL_SIG.G10_EN_PRESSE       := FALSE;
GVL_SIG.G10_A_ZPM           := FALSE;
GVL_SIG.G10_DEFAUT          := FALSE;
GVL_SIG.VYT_MACHINE_PRETE   := FALSE;
GVL_SIG.VYT_CYCLE_EN_COURS  := FALSE;
GVL_SIG.VYT_DEFAUT          := FALSE;
GVL_SIG.VYT_INIT_OK         := FALSE;
GVL_SIG.CYCLE_CM_AUTORISE   := FALSE;

// ── Initialisation GVL_SEQ (hors Retain) ─────────────────────
// CYCLE_INTERROMPU, MOULE_EN_TRANSIT, NB_CYCLES_TOTAL = Retain → conservés
GVL_SEQ.ETAPE_ACTIVE    := 0;
GVL_SEQ.CYCLE_EN_COURS  := FALSE;
GVL_SEQ.HOMING_OK       := FALSE;
GVL_SEQ.DEFAUT_ACTIF    := FALSE;
GVL_SEQ.CODE_DEFAUT     := 0;

// ── Initialisation GVL_MOULES (stock initial terrain) ─────────
// CH1 AGADIR : N1=occupé(ID=1), N2=occupé(ID=1)
GVL_MOULES.CH[1,1].ID := 1;  GVL_MOULES.CH[1,1].OCCUPE := TRUE;
GVL_MOULES.CH[1,2].ID := 1;  GVL_MOULES.CH[1,2].OCCUPE := TRUE;
// CH2 IFRANE : N1=occupé(ID=2), N2=libre
GVL_MOULES.CH[2,1].ID := 2;  GVL_MOULES.CH[2,1].OCCUPE := TRUE;
GVL_MOULES.CH[2,2].ID := 0;  GVL_MOULES.CH[2,2].OCCUPE := FALSE;
// CH3 TANGER : N1=occupé(ID=3), N2=occupé(ID=3)
GVL_MOULES.CH[3,1].ID := 3;  GVL_MOULES.CH[3,1].OCCUPE := TRUE;
GVL_MOULES.CH[3,2].ID := 3;  GVL_MOULES.CH[3,2].OCCUPE := TRUE;
// CH4 RABAT : N1=occupé(ID=4), N2=occupé(ID=4)
GVL_MOULES.CH[4,1].ID := 4;  GVL_MOULES.CH[4,1].OCCUPE := TRUE;
GVL_MOULES.CH[4,2].ID := 4;  GVL_MOULES.CH[4,2].OCCUPE := TRUE;
// CH5 FEZ : N1=libre, N2=libre
GVL_MOULES.CH[5,1].ID := 0;  GVL_MOULES.CH[5,1].OCCUPE := FALSE;
GVL_MOULES.CH[5,2].ID := 0;  GVL_MOULES.CH[5,2].OCCUPE := FALSE;

GVL_MOULES.NB_EMPLACEMENTS_LIBRES := 3;
GVL_MOULES.MOULE_EN_PRESSE        := 0;

// ── Sécurité démarrage : toutes sorties physiques à FALSE ─────
GVL_IO.CMD_X_AV                := FALSE;
GVL_IO.CMD_X_AR                := FALSE;
GVL_IO.CMD_Z_HAUT              := FALSE;
GVL_IO.CMD_Z_BAS               := FALSE;
GVL_IO.CMD_SAT_EXT             := FALSE;
GVL_IO.CMD_SAT_RET             := FALSE;
GVL_IO.CMD_ROT_NORD            := FALSE;
GVL_IO.CMD_ROT_SUD             := FALSE;
GVL_IO.CMD_ARRET_PRESSE        := FALSE;
GVL_IO.CMD_DEBRIDAGE           := FALSE;
GVL_IO.CMD_BRIDAGE             := FALSE;
GVL_IO.CMD_AUTORISE_DEMARRAGE  := FALSE;
GVL_IO.CMD_MONTE_PILON         := FALSE;
GVL_IO.CMD_BAISSE_PILON        := FALSE;
GVL_IO.CMD_INTRO_ENTRE         := FALSE;
GVL_IO.CMD_INTRO_SORT          := FALSE;
GVL_IO.VOYANT_NETTOYAGE        := FALSE;
GVL_IO.BUZZER_DEBUT_NETTOYAGE  := FALSE;
GVL_IO.VOYANT_ATTENTE_ZONE_LIBRE := FALSE;

END_PROGRAM
