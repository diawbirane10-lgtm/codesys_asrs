// ================================================================
// 00_DUT_UDT_MOULE.st  —  Type utilisateur AS/RS QUADRA 10
// CODESYS V3.5 — DUT (Data Unit Type)
// IMPORTER EN PREMIER dans le projet CODESYS
// ================================================================

TYPE
    UDT_MOULE :
    STRUCT
        ID      : USINT;   // 1=AGADIR 2=IFRANE 3=TANGER 4=RABAT 5=FEZ 0=vide
        OCCUPE  : BOOL;
        RESERVE : BOOL;    // réservé avant prise (évite double allocation)
        RFID_OK : BOOL;    // vérification RFID effectuée sur cet emplacement
    END_STRUCT;
END_TYPE
