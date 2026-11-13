FUNCTION_BLOCK FB_RLI_Presse
VAR_INPUT
    StartRequest : BOOL;
    ReleaseRequest : BOOL;
    ResetFault : BOOL;
    StationEnabled : BOOL := TRUE;
    HoldPress : BOOL;
    ReplayReply : BOOL;
END_VAR
VAR_OUTPUT
    State : USINT;
    FaultCode : USINT;
    LinkFresh : BOOL;
    TransferAllowed : BOOL;
    StaleReply : BOOL;
    ReplyValid : BOOL;
    RequestId : UINT;
    ReplyId : UINT;
    Tx : ARRAY[0..3] OF BYTE;
    Rx : ARRAY[0..3] OF BYTE;
END_VAR
VAR
    StartEdge : R_TRIG;
    ReleaseEdge : R_TRIG;
    ResetEdge : R_TRIG;
    HeartbeatPeriod : TON;
    Watchdog : TON;
    PressDelay : TON;
    CommandDeadline : TON;
    Heartbeat : BYTE;
    PreviousHeartbeat : BYTE;
    HeartbeatChanges : USINT;
    HeartbeatChanged : BOOL;
    LinkWasReady : BOOL;
    TxRequestId : UINT;
    LastReplyId : UINT;
    LastReplyValid : BOOL;

    ReplyStopped : BOOL;
END_VAR

// A virtual station consumes the output image from the preceding scan.
// Its input image freezes when the station is disabled.
HeartbeatPeriod(IN := StationEnabled AND NOT HeartbeatPeriod.Q, PT := T#100ms);
PressDelay(IN := StationEnabled AND (Tx[0] = BYTE#1) AND NOT HoldPress AND NOT ReplayReply,
           PT := T#400ms);
IF StationEnabled THEN
    IF HeartbeatPeriod.Q THEN
        IF Heartbeat = BYTE#255 THEN
            Heartbeat := BYTE#0;
        ELSE
            Heartbeat := Heartbeat + BYTE#1;
        END_IF;
    END_IF;
    Rx[1] := Heartbeat;
    TxRequestId := BYTE_TO_UINT(Tx[2]) + BYTE_TO_UINT(Tx[3]) * UINT#256;
    Rx[0] := BYTE#0;
    IF ReplayReply AND LastReplyValid THEN
        Rx[0] := BYTE#3;
        Rx[2] := UINT_TO_BYTE(LastReplyId MOD UINT#256);
        Rx[3] := UINT_TO_BYTE(LastReplyId / UINT#256);
    ELSIF PressDelay.Q THEN
        LastReplyId := TxRequestId;
        LastReplyValid := TRUE;
        Rx[0] := BYTE#3;
        Rx[2] := Tx[2];
        Rx[3] := Tx[3];
    END_IF;
END_IF;

// The watchdog consumes the image only. StationEnabled is a bench stimulus.
HeartbeatChanged := Rx[1] <> PreviousHeartbeat;
PreviousHeartbeat := Rx[1];
Watchdog(IN := NOT HeartbeatChanged, PT := T#350ms);
IF Watchdog.Q THEN
    HeartbeatChanges := USINT#0;
ELSIF HeartbeatChanged AND (HeartbeatChanges < USINT#2) THEN
    HeartbeatChanges := HeartbeatChanges + USINT#1;
END_IF;
LinkFresh := HeartbeatChanges = USINT#2;
IF LinkFresh THEN
    LinkWasReady := TRUE;
END_IF;

ReplyValid := (Rx[0] AND BYTE#1) <> BYTE#0;
ReplyStopped := (Rx[0] AND BYTE#2) <> BYTE#0;
ReplyId := BYTE_TO_UINT(Rx[2]) + BYTE_TO_UINT(Rx[3]) * UINT#256;
StaleReply := LinkFresh AND (State = USINT#10 OR State = USINT#20)
              AND ReplyValid AND (ReplyId <> RequestId);

StartEdge(CLK := StartRequest);
ReleaseEdge(CLK := ReleaseRequest);
ResetEdge(CLK := ResetFault);
CommandDeadline(IN := State = USINT#10, PT := T#2s);

IF LinkWasReady AND NOT LinkFresh AND State <> USINT#90 THEN
    FaultCode := USINT#1;
    State := USINT#90;
ELSE
    CASE State OF
        0:
            IF LinkFresh AND StartEdge.Q THEN
                IF RequestId = UINT#65535 THEN
                    RequestId := UINT#1;
                ELSE
                    RequestId := RequestId + UINT#1;
                END_IF;
                State := USINT#10;
            END_IF;
        10:
            IF CommandDeadline.Q THEN
                FaultCode := USINT#2;
                State := USINT#90;
            ELSIF LinkFresh AND ReplyValid AND ReplyStopped AND (ReplyId = RequestId) THEN
                State := USINT#20;
            END_IF;
        20:
            IF NOT ReplyValid OR NOT ReplyStopped OR (ReplyId <> RequestId) THEN
                FaultCode := USINT#3;
                State := USINT#90;
            ELSIF ReleaseEdge.Q THEN
                State := USINT#0;
            END_IF;
        90:
            IF LinkFresh AND ResetEdge.Q AND NOT StartRequest THEN
                FaultCode := USINT#0;
                State := USINT#0;
            END_IF;
    END_CASE;
END_IF;

TransferAllowed := (State = USINT#20) AND LinkFresh;
IF State = USINT#10 OR State = USINT#20 THEN
    Tx[0] := BYTE#1;
ELSE
    Tx[0] := BYTE#0;
END_IF;
Tx[1] := BYTE#0; // Reserved.
Tx[2] := UINT_TO_BYTE(RequestId MOD UINT#256);
Tx[3] := UINT_TO_BYTE(RequestId / UINT#256);
END_FUNCTION_BLOCK


