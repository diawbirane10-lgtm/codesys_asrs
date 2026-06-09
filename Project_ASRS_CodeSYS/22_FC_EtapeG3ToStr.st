// ================================================================
// 22_FC_EtapeG3ToStr.st  —  Conversion étape G3 (INT) → description
// CODESYS V3.5 — FUNCTION
// ================================================================

FUNCTION FC_EtapeG3ToStr : STRING(35)
VAR_INPUT
    Step : INT;
END_VAR

CASE Step OF
    0 : FC_EtapeG3ToStr := 'REPOS';
    1 : FC_EtapeG3ToStr := 'S01 - Arrêt presse + X→P0';
    2 : FC_EtapeG3ToStr := 'S02 - Rotation NORD';
    3 : FC_EtapeG3ToStr := 'S03 - Satellite étendu ZPM';
    4 : FC_EtapeG3ToStr := 'S04 - Z ZPM - Prise ancien moule';
    5 : FC_EtapeG3ToStr := 'S05 - Satellite rétracté';
    6 : FC_EtapeG3ToStr := 'S06 - Z transport + Rotation 0';
    7 : FC_EtapeG3ToStr := 'S07 - X vers chambre dépôt';
    8 : FC_EtapeG3ToStr := 'S08 - Rotation SUD + Z dépôt';
    9 : FC_EtapeG3ToStr := 'S09 - Satellite - Dépôt moule';
    10: FC_EtapeG3ToStr := 'S10 - X vers chambre prise';
    11: FC_EtapeG3ToStr := 'S11 - Z prise + Vérif. RFID';
    12: FC_EtapeG3ToStr := 'S12 - Satellite - Prise nouveau';
    13: FC_EtapeG3ToStr := 'S13 - Retour P0';
    14: FC_EtapeG3ToStr := 'S14 - RFID ZPM + nettoyage zone';
    15: FC_EtapeG3ToStr := 'S15 - Installation + bridage + P6';
ELSE
    FC_EtapeG3ToStr := 'DEFAUT';
END_CASE;
