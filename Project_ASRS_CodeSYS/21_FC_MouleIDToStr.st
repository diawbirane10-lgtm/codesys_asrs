// ================================================================
// 21_FC_MouleIDToStr.st  —  Conversion ID moule (USINT) → nom
// CODESYS V3.5 — FUNCTION
// ================================================================

FUNCTION FC_MouleIDToStr : STRING(10)
VAR_INPUT
    ID : USINT;
END_VAR

CASE ID OF
    0: FC_MouleIDToStr := 'VIDE';
    1: FC_MouleIDToStr := 'MOULE_A';
    2: FC_MouleIDToStr := 'MOULE_B';
    3: FC_MouleIDToStr := 'MOULE_C';
    4: FC_MouleIDToStr := 'MOULE_D';
    5: FC_MouleIDToStr := 'MOULE_E';
ELSE
    FC_MouleIDToStr := '???';
END_CASE;
