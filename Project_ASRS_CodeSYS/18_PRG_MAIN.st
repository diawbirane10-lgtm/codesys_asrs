// ================================================================
// 18_PRG_MAIN.st  —  Programme principal cyclique (équivalent OB1)
// CODESYS V3.5 — PROGRAM
// Configurer en tâche cyclique (ex : 10ms) dans le Task Manager
//
// Modification v2 — Laser OSSD :
//   - instLaser (FB_LaserSafe) ajouté : gère ZONE_CONFIRMEE automatiquement
//   - Ligne ZONE_CONFIRMEE manuelle supprimée (bouton remplacé par laser)
// ================================================================

PROGRAM PLC_PRG
VAR
    instG1    : FB_G1_Securite;
    instG0    : FB_G0_Conduite;
    instG2    : FB_G2_Homing;
    instG4    : FB_G4_AxeX;
    instG5    : FB_G5_AxeZ;
    instG6    : FB_G6_Rotation;
    instG7    : FB_G7_Satellite;
    instG8    : FB_G8_RFID;
    instG9    : FB_G9_Presse;
    instG10   : FB_G10_Intro;
    instG3    : FB_G3_Cycle;
    // ── IHM Visualization ────────────────────────────────────
    instHMI   : FB_HMI_Controller;
    instFault : FB_FaultInjector;
    // ── Sécurité laser OSSD (Sick S3000) ─────────────────────
    instLaser : FB_LaserSafe;
END_VAR

// ── IHM : textes, couleurs, boutons, injection défauts ────────
// Appel en premier : écrit dans GVL_IO avant les copies ci-dessous
instHMI();
instFault(
    FaultID   := GVL_HMI.HMI_FAULT_SEL,
    Inject    := GVL_HMI.HMI_BTN_INJECT,
    ResetFlt  := GVL_HMI.HMI_BTN_FAULT_RESET,
    Desc      => GVL_HMI.HMI_FAULT_DESC,
    Result    => GVL_HMI.HMI_FAULT_RESULT,
    FltActive => GVL_HMI.HMI_FAULT_ACTIVE
);

// ── Rafraîchissement commandes opérateur depuis GVL_IO ────────
GVL_SIG.OP_CMD_CM        := GVL_IO.CMD_CM;
GVL_SIG.OP_CMD_RESET     := GVL_IO.CMD_RESET;
GVL_SIG.OP_CMD_ACQ       := GVL_IO.CMD_ACQ_DEF;
GVL_SIG.OP_CMD_HOMING    := GVL_IO.CMD_HOMING_MANUEL;
GVL_SIG.OP_AU            := GVL_IO.AU_ACTIF;
GVL_SIG.OP_MOULE_DEMANDE := GVL_IO.MOULE_DEMANDE_HMI;
GVL_SIG.OP_MODE_AUTO     := GVL_IO.MODE_AUTO;
// ZONE_CONFIRMEE : géré par instLaser() ci-dessous — ne pas écrire ici
GVL_SIG.OP_PROLONG_NETTOYAGE := GVL_IO.PROLONG_NETTOYAGE_BTN OR GVL_HMI.HMI_BTN_PROLONG_NETTOYAGE;

// ── Images capteurs position X → GVL_SIG ─────────────────────
GVL_SIG.CAPTEUR_POS_X[0] := GVL_IO.POS_P0;
GVL_SIG.CAPTEUR_POS_X[1] := GVL_IO.POS_P1;
GVL_SIG.CAPTEUR_POS_X[2] := GVL_IO.POS_P2;
GVL_SIG.CAPTEUR_POS_X[3] := GVL_IO.POS_P3;
GVL_SIG.CAPTEUR_POS_X[4] := GVL_IO.POS_P4;
GVL_SIG.CAPTEUR_POS_X[5] := GVL_IO.POS_P5;
GVL_SIG.CAPTEUR_POS_X[6] := GVL_IO.POS_P6;

// ── Images présence chambres → GVL_SIG ───────────────────────
GVL_SIG.CAPTEUR_PRES_CH[1,1] := GVL_IO.CH1N1;
GVL_SIG.CAPTEUR_PRES_CH[1,2] := GVL_IO.CH1N2;
GVL_SIG.CAPTEUR_PRES_CH[2,1] := GVL_IO.CH2N1;
GVL_SIG.CAPTEUR_PRES_CH[2,2] := GVL_IO.CH2N2;
GVL_SIG.CAPTEUR_PRES_CH[3,1] := GVL_IO.CH3N1;
GVL_SIG.CAPTEUR_PRES_CH[3,2] := GVL_IO.CH3N2;
GVL_SIG.CAPTEUR_PRES_CH[4,1] := GVL_IO.CH4N1;
GVL_SIG.CAPTEUR_PRES_CH[4,2] := GVL_IO.CH4N2;
GVL_SIG.CAPTEUR_PRES_CH[5,1] := GVL_IO.CH5N1;
GVL_SIG.CAPTEUR_PRES_CH[5,2] := GVL_IO.CH5N2;

// ── Scanner laser OSSD — valide ZONE_CONFIRMEE automatiquement ─
// Doit être appelé AVANT instG3 pour que ZONE_CONFIRMEE soit à jour
instLaser();

// ── Appels GRAFCETs (ordre d'exécution fixe) ──────────────────
instG1();    // G1 Sécurité — EN PREMIER, toujours actif
instG0();    // G0 Superviseur modes
instG2();    // G2 Homing
instG4();    // G4 Axe X
instG5();    // G5 Axe Z
instG6();    // G6 Rotation
instG7();    // G7 Satellite
instG8();    // G8 RFID
instG9();    // G9 Presse
instG10();   // G10 Introducteur
instG3();    // G3 Cycle — EN DERNIER (coordinateur)

// ── Rafraîchissement voyants physiques depuis GVL_SIG ─────────
GVL_IO.VOYANT_MACHINE_PRETE  := GVL_SIG.VYT_MACHINE_PRETE;
GVL_IO.VOYANT_CYCLE_EN_COURS := GVL_SIG.VYT_CYCLE_EN_COURS;
GVL_IO.VOYANT_DEFAUT         := GVL_SIG.VYT_DEFAUT;
GVL_IO.VOYANT_INIT_OK        := GVL_SIG.VYT_INIT_OK;
GVL_IO.VOYANT_NETTOYAGE_TIMEOUT := GVL_SIG.VYT_NETTOYAGE_TIMEOUT;

END_PROGRAM
