// ================================================================
// 19_GVL_IO_HARDWARE_MAP.st
// CARTE COMPLÈTE I/O PHYSIQUES — ASRS QUADRA 10 / S7-1515
// Source : TIA_Import/Tags_ASRS.xml
//
// USAGE : Sur SoftPLC CODESYS (simulation) → utiliser GVL_IO sans AT
// USAGE : Sur automate physique → utiliser GVL avec AT %QX / %IX
//
// Pour activer les adresses hardware, remplacer dans GVL_IO.st :
//   CMD_X_AV : BOOL;
// par :
//   CMD_X_AV AT %QX0.0 : BOOL;
// ================================================================

// ── RÉSUMÉ ADRESSAGE SORTIES Q ────────────────────────────────
// %Q0.0   CMD_X_AV                Avance axe X
// %Q0.1   CMD_X_AR                Recul axe X
// %Q0.2   CMD_SAT_EXT             Extension satellite
// %Q0.3   CMD_SAT_RET             Rétraction satellite
// %Q0.4   CMD_Z_HAUT              Montée axe Z
// %Q0.5   CMD_Z_BAS               Descente axe Z
// %Q0.6   CMD_ROT_NORD            Rotation NORD
// %Q0.7   CMD_ROT_SUD             Rotation SUD
// %Q1.0   CMD_ARRET_PRESSE        Arrêt presse
// %Q1.1   CMD_DEBRIDAGE           Débridage moule
// %Q1.2   CMD_BRIDAGE             Bridage moule
// %Q1.3   CMD_AUTORISE_DEMARRAGE  Autorisation démarrage presse
// %Q1.4   CMD_MONTE_PILON         Montée pilon
// %Q1.5   CMD_BAISSE_PILON        Descente pilon
// %Q1.6   CMD_INTRO_ENTRE         Entrée introducteur ZPM
// %Q1.7   CMD_INTRO_SORT          Sortie introducteur ZPM
// %Q2.0   VOYANT_NETTOYAGE        Voyant nettoyage zone
// %Q2.1   BUZZER_DEBUT_NETTOYAGE  Buzzer début nettoyage
// %Q2.2   VOYANT_ATTENTE_ZONE_LIBRE
// %Q2.3   CMD_RFID_ACTIVER        Activation lecteur RFID RF350R
// %Q2.4   VOYANT_MACHINE_PRETE
// %Q2.5   VOYANT_CYCLE_EN_COURS
// %Q2.6   VOYANT_DEFAUT
// %Q2.7   VOYANT_INIT_OK
// %QW10   CONSIGNE_POS_X (WORD)   Consigne variateur axe X

// ── RÉSUMÉ ADRESSAGE ENTRÉES I ────────────────────────────────
// %I1.0   PRESSE_ARRETEE          Presse arrêtée confirmée
// %I1.1   MOULE_DEBRIDE           Moule débridé
// %I1.2   MOULE_BRIDE             Moule bridé
// %I1.3   PILON_HAUT_OK           Pilon en position haute
// %I1.4   PILON_BAS_OK            Pilon en position basse
// %I1.5   INTRODUCTEUR_EN_PRESSE  Introducteur en presse
// %I1.6   INTRODUCTEUR_A_ZPM      Introducteur à ZPM
// %I1.7   INTRO_VIDE              Introducteur vide
// %I2.0   MOULE_SUR_INTRO         Moule présent sur introducteur
// %I2.1   CAPTEUR_Z_TRANSPORT     Z position haute (transport)
// %I2.2   CAPTEUR_Z_NIVEAU1       Z niveau 1 chambre
// %I2.3   CAPTEUR_Z_NIVEAU2       Z niveau 2 chambre
// %I2.4   CAPTEUR_Z_ZPM           Z position ZPM
// %I2.5   CAPTEUR_CHARGE_CHARIOT  Charge présente sur fourches
// %I2.6   CAPTEUR_SAT_RETRACTE    Satellite rétracté
// %I2.7   CAPTEUR_SAT_ETENDU      Satellite étendu
// %I3.0   CAPTEUR_ZONE_OCCUPEE    Zone de travail occupée
// %I3.1   ZONE_LIBRE_BTN          Bouton zone libre opérateur
// %I3.2   CAPTEUR_ROT_NEUTRE      Rotation position neutre 0°
// %I3.3   CAPTEUR_ROT_NORD        Rotation position NORD
// %I3.4   CH1N1  Présence CH AGADIR N1
// %I3.5   CH1N2  Présence CH AGADIR N2
// %I3.6   CH2N1  Présence CH IFRANE N1
// %I3.7   CH2N2  Présence CH IFRANE N2
// %I4.0   CH3N1  Présence CH TANGER N1
// %I4.1   CH3N2  Présence CH TANGER N2
// %I4.2   CH4N1  Présence CH RABAT N1
// %I4.3   CH4N2  Présence CH RABAT N2
// %I4.4   CH5N1  Présence CH FEZ N1
// %I4.5   CH5N2  Présence CH FEZ N2
// %I4.6   RFID_LECTURE_OK         RFID lecture terminée
// %IB5    RFID_ID_LU (BYTE/USINT) ID moule lu par RFID MDS D160

// ── MERKERS M — COMMANDES HMI ─────────────────────────────────
// %M10.0  CMD_CM                  Commande changement moule
// %M10.1  CMD_RESET               Reset défaut
// %M10.2  CMD_ACQ_DEF             Acquittement défaut
// %M10.3  CMD_HOMING_MANUEL       Homing manuel
// %M10.4  AU_ACTIF                Arrêt urgence SW
// %M10.5  MODE_AUTO               Mode automatique
// %MB11   MOULE_DEMANDE_HMI       N° moule demandé (1-5)

// ── POSITIONS CAPTEURS X ──────────────────────────────────────
// (lire depuis Tags_ASRS.xml — adresses I5.x ou I6.x selon câblage)
// POS_P0..POS_P6 : capteurs de position chariot axe X

VAR_GLOBAL CONSTANT
    // Référence adresses pour documentation rapport
    ADDR_CMD_X_AV      : STRING := '%Q0.0';
    ADDR_CMD_Z_HAUT    : STRING := '%Q0.4';
    ADDR_PRESSE_ARRETEE: STRING := '%I1.0';
    ADDR_RFID_ID_LU    : STRING := '%IB5';
    ADDR_CMD_CM        : STRING := '%M10.0';
END_VAR
