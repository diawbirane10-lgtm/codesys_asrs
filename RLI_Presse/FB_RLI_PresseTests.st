FUNCTION_BLOCK FB_RLI_PresseTests
VAR_OUTPUT
    Done : BOOL;
    Passed : BOOL;
    FailedCase : USINT;
    TestStage : USINT;
END_VAR
VAR
    Bench : FB_RLI_Presse;
    StageAge : TON;
    PreviousStage : USINT := USINT#255;
    OldRequest : UINT;
END_VAR

// Use a separate bench instance so acceptance tests do not change operator inputs.
StageAge(IN := TestStage = PreviousStage, PT := T#4s);
PreviousStage := TestStage;

Bench(
    StartRequest := (TestStage = USINT#10) OR (TestStage = USINT#30)
                    OR (TestStage = USINT#50) OR (TestStage = USINT#70)
                    OR (TestStage = USINT#80) OR (TestStage = USINT#81) OR (TestStage = USINT#84),
    ReleaseRequest := TestStage = USINT#20,
    ResetFault := (TestStage = USINT#40) OR (TestStage = USINT#60)
                  OR (TestStage = USINT#81) OR (TestStage = USINT#83),
    StationEnabled := TestStage <> USINT#80,
    HoldPress := TestStage = USINT#50,
    ReplayReply := TestStage = USINT#30
);

IF NOT Done THEN
    CASE TestStage OF
        0: // Wait until the station has sent two distinct heartbeats.
            IF Bench.LinkFresh THEN
                TestStage := USINT#10;
            END_IF;
        10: // Nominal stop request, correlated confirmation and permit.
            IF Bench.TransferAllowed AND (Bench.ReplyId = Bench.RequestId)
               AND (Bench.RequestId <> UINT#0) THEN
                OldRequest := Bench.RequestId;
                TestStage := USINT#20;
            END_IF;
        20:
            IF (Bench.State = USINT#0) AND NOT Bench.TransferAllowed THEN
                TestStage := USINT#30;
            END_IF;
        30: // Replay the previous completed request while the station stays live.
            IF Bench.TransferAllowed OR NOT Bench.LinkFresh THEN
                FailedCase := TestStage;
            ELSIF Bench.FaultCode = USINT#2 THEN
                IF Bench.ReplyId = OldRequest AND Bench.RequestId <> OldRequest THEN
                    TestStage := USINT#40;
                ELSE
                    FailedCase := TestStage;
                END_IF;
            END_IF;
        40:
            IF Bench.State = USINT#0 THEN
                TestStage := USINT#50;
            END_IF;
        50: // Live station with no completion response.
            IF Bench.TransferAllowed OR NOT Bench.LinkFresh THEN
                FailedCase := TestStage;
            ELSIF Bench.FaultCode = USINT#2 THEN
                TestStage := USINT#60;
            END_IF;
        60:
            IF Bench.State = USINT#0 THEN
                TestStage := USINT#70;
            END_IF;
        70: // Obtain a permit again before interrupting the link.
            IF Bench.TransferAllowed THEN
                TestStage := USINT#80;
            END_IF;
        80: // Freeze last image, then require the watchdog to revoke the permit.
            IF Bench.FaultCode = USINT#1 THEN
                IF NOT Bench.TransferAllowed AND NOT Bench.LinkFresh THEN
                    TestStage := USINT#81;
                ELSE
                    FailedCase := TestStage;
                END_IF;
            END_IF;
        81: // Reconnect while both start and reset are already held.
            IF Bench.TransferAllowed OR (Bench.State <> USINT#90) THEN
                FailedCase := TestStage;
            ELSIF Bench.LinkFresh THEN
                TestStage := USINT#82;
            END_IF;
        82: // Release both before requesting an explicit reset.
            IF (Bench.State = USINT#90) AND NOT Bench.TransferAllowed THEN
                TestStage := USINT#83;
            ELSE
                FailedCase := TestStage;
            END_IF;
        83: // Reset returns to idle without granting the transfer.
            IF Bench.State = USINT#0 AND NOT Bench.TransferAllowed THEN
                OldRequest := Bench.RequestId;
                TestStage := USINT#84;
            END_IF;
        84: // A fresh start is required and must allocate a new request ID.
            IF Bench.TransferAllowed AND (Bench.RequestId <> OldRequest) THEN
                TestStage := USINT#100;
                Passed := TRUE;
                Done := TRUE;
            END_IF;
    END_CASE;
    IF StageAge.Q OR FailedCase <> USINT#0 THEN
        // Stage 0 has no case number, so code 1 denotes initial-link failure.
        IF FailedCase = USINT#0 THEN
            IF TestStage = USINT#0 THEN
                FailedCase := USINT#1;
            ELSE
                FailedCase := TestStage;
            END_IF;
        END_IF;
        Done := TRUE;
        Passed := FALSE;
    END_IF;
END_IF;
END_FUNCTION_BLOCK

