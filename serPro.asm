        NAME    SERPRO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    SERPRO                                  ;
;                         SERIAL PROCESSING Functions                        ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specifications and implementations for the
; serial processing functions as well as a Mealy state machine. By initializing
; serial processing with InitSerialProcessing, and then passing characters into
; ParseSerialChar, one is able to parse commands that set the absolute speed of
; the RoboTrike, set the relative speed of the RoboTrike, set the relative 
; direction, rotate the turret angle (both absolute and relative versions), and
; set the turret elevation angle. Parsing is accomplished via moving to 
; different state machine states and calling action functions with each 
; transition.
;
; Contents:
;     ParseSerialChar: Parses the passed serial character.
;     InitSerialProcessing: Initializes shared variables.
;     SetError: Sets the ParsingStatus shared variable to ERROR_VAL.
;     DoNOP: Does nothing.
;     AppendDigit: Appends a digit to the Num shared variable.
;     SaveSign: Saves the passed in sign to the Sign shared variable.
;     ExecuteAbsSpd: Executes the Absolute speed command with the parsed argument.
;     ExecuteRelSpd: Executes the Relative Speed command with the parsed argument.
;     ExecuteSetDir: Executes the Set Direction command with the parsed argument.
;     ExecuteRotTur: Executes the Rotate Turret Angle command with the parsed
;                    argument.
;     ExecuteTurElv: Executes the Set Turret Elevation Angle command with the
;                    parsed argument.
;     ExecuteLaserOn: Executes the Fire Laser command.
;     ExecuteLaserOff: Executes the Laser Off command.
;
; Revision History:
;    12/13/14  Victor Han       "Execute" functions now call SerialPutString
;                               after completing actions to send status info
;                               to the remote board.
;    12/06/14  Victor Han       updated comments
;    12/05/14  Victor Han       wrote the assembly code
;    12/01/14  Victor Han       initial revision

; local include files
$INCLUDE(general.inc)
$INCLUDE(serpro.inc)            ; includes definitions for token types, states,
                                ;   shared variable settings and other general
								;   constants                           
$INCLUDE(mtrlsr.inc)            ; includes definitions for motor speed constants

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA


CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
        EXTRN   SetMotorSpeed:NEAR         ;used for setting RoboTrike speed and
		                                   ;  direction
        EXTRN   GetMotorSpeed:NEAR         ;gets the RoboTrike speed
        EXTRN   GetMotorDirection:NEAR     ;gets the RoboTrike direction
        EXTRN   SetLaser:NEAR              ;turns the laser on or off
        EXTRN   SetTurretAngle:NEAR        ;sets the absolute turret angle
        EXTRN   SetRelTurretAngle:NEAR     ;sets the turret angle relative to 
		                                   ;  its current angle
        EXTRN   SetTurretElevation:NEAR    ;sets the absolute turret elevation
        EXTRN   SerialPutString:NEAR
        EXTRN   Dec2String:NEAR
        EXTRN   Hex2String:NEAR
		
		
; ParseSerialChar
;
; Description:      Parses the passed character (AL) as part of a serial command.
;                   Returns the status of the parsing operation in AX. Zero
;                   is returned if there are no parsing errors due to the 
;                   passed character and non-zero if there is a parsing error.
;
; Operation:        Uses a state machine to parse the character.  The
;                   function finds the character type and value, finds the
;                   state machine transition from the current state based on
;                   the character, executes the transition action and transitions.
;
; Arguments:        AL - character to parse
; Return Value:     AX - parsing error status. Zero if no error, non-zero if error.
;
; Local Variables:  None.
; Shared Variables: CurState - read and written to
;                   ParsingStatus - read and written to
;                   Sign - written to in InitSerialProcessing
;                   Num - written to in InitSerialProcessing
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   Returns the error status in AX. Actual handling is done by
;                   the state machine and state machine functions.
;
; Algorithms:       State Machine.
; Data Structures:  None.
;
; Registers Changed: flags, AX, BX, CX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/06/14  Victor Han      updated comments
;    12/05/14  Victor Han      now calls InitSerialProcessing after reporting 
;                              errors
;    12/01/14  Victor Han      initial revision

ParseSerialChar		PROC    NEAR
                    PUBLIC  ParseSerialChar

        MOV     CL, CurState
        CALL    GetTokenTypeVal ;get the char's token type and value and save them
        MOV	    DH, AH			
        MOV	    CH, AL
        ;JMP    ComputeTransition

ComputeTransition:			        ;figure out what transition to do
        MOV	    AL, NUM_TOKEN_TYPES	;find row in the table
        MUL	    CL			        ;AX is now start of row for current state
        ADD	    AL, DH			    ;get the actual transition in row
        ADC	    AH, 0			    ;propagate low byte carry into high byte

        IMUL	BX, AX, SIZE TRANSITION_ENTRY   ;now convert to table offset
        ;JMP    DoAction

DoAction:				        ;do the transition actions
        MOV	    AL, CH			;get token value back as argument for actions
        PUSH    BX              ;save this index
        CALL	CS:StateTable[BX].ACTION	;do the actions
        ;JMP    DoTransition

DoTransition:				;now go to next state
        POP     BX
        MOV	    CL, CS:StateTable[BX].NEXTSTATE
        MOV     CurState, CL
        ;JMP    ParseSerialCharCheckError

ParseSerialCharCheckError:				  ;done with action and transition
        CMP     ParsingStatus, ERROR_VAL  ;check if any errors
        JNE     ParseSerialCharNoError    ;if not, return with 0
        ;JE     ParseSerialCharReportError;if so, return with ERROR_VAL

ParseSerialCharReportError:
        MOV     AX, ERROR_VAL
        CALL    InitSerialProcessing      ;error, so reset processing
        JMP     ParseSerialCharDone
    
ParseSerialCharNoError:
        MOV     AX, 0
        ;JMP    ParseSerialCharDone
    
ParseSerialCharDone:
        RET

ParseSerialChar		ENDP


; InitSerialProcessing
;
; Description:       Initializes serial processing variables.
;
; Operation:         Writes initial values to all the shared variables. CurState
;                    starts at IDLE, ParsingStatus has NO_ERROR, Sign is NULL,
;                    and Num is 0.
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  CurState - written to
;                    ParsingStatus - written to
;                    Sign - written to
;                    Num - written to
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None.
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/06/14  Victor Han      updated comments
;    12/05/14  Victor Han      wrote the assembly code
;    12/01/14  Victor Han      initial revision

InitSerialProcessing    PROC    NEAR
                        Public  InitSerialProcessing
                        
        MOV     CurState, IDLE
        MOV     ParsingStatus, NO_ERROR
        MOV     Sign, NULL
        MOV     Num, 0
        RET
		
InitSerialProcessing    ENDP


; SetError
;
; Description:       Sets the ParsingStatus to be ERROR_VAL.
;
; Operation:         Sets the ParsingStatus to be ERROR_VAL.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  ParsingStatus - written to
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    This is the function that sets the error shared variable.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None.
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/06/14  Victor Han      updated comments
;    12/01/14  Victor Han      initial revision

SetError    PROC      NEAR
              
        MOV     ParsingStatus, ERROR_VAL
        RET
		
SetError    ENDP


; DoNOP
;
; Description:       Does nothing.
;
; Operation:         Does nothing.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None.
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/1/14  Victor Han      initial revision

DoNOP   PROC     NEAR
        Public   DoNOP
           
        RET
		
DoNOP   ENDP


; AppendDigit
;
; Description:       Appends a digit to the Num shared variable.
;
; Operation:         Multiplies Num by 10 and adds the passed in value to Num. 
;                    If the initial multiplication set the carry flag, an error
;                    is set. If the resulting addition produces a number above
;                    or equal to MAX_INPUT_VAL for a non-negative sign in Sign,
;                    an error is set. If the addition produces a number strictly
;                    above MAX_INPUT_VAL for a negative sign in Sign, an error
;                    is set.
;
; Arguments:         AL - digit to append
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  Num - read and written to
;                    Sign - read
;                    ParsingStatus - written to
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    Errors if multiplying Num by 10 results in a value greater
;                    than a word. Errors if the digit-appended Num is greater 
;                    than what it should be as either a positve or negative val.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, BX, CX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/06/14  Victor Han      updated comments
;    12/05/14  Victor Han      wrote the assembly code
;    12/01/14  Victor Han      initial revision

AppendDigit     PROC    NEAR
                
        MOV     BL, AL             ;save the new digit
        MOV     AX, Num            ;shift over Num by one decimal digit
        MOV     CX, 10
        MUL     CX
        JC      AppendDigitError   ;error if result is greater than a word
        ;JNC    AppendDigitAdd
        
AppendDigitAdd:
        MOV     BH, 0               ;add digit to shifted Num value
        ADD     AX, BX
        CMP     Sign, NEG_SIGN      ;see how to check max value. negative values
        JE      AppendDigitCheckNeg ;  can be one more than positive ones
        ;JNE    AppendDigitCheckPos
        
AppendDigitCheckPos:
        CMP     AX, MAX_INPUT_VAL
        JAE     AppendDigitError
        JB      AppendDigitDone
        
AppendDigitCheckNeg:
        CMP     AX, MAX_INPUT_VAL
        JBE     AppendDigitDone
        ;JA     AppendDigitError
        
AppendDigitError:
        CALL    SetError
        ;JMP    AppendDigitDone
        
AppendDigitDone:
        MOV     Num, AX
        RET
		
AppendDigit     ENDP


; SaveSign
;
; Description:       Saves the passed in sign to the Sign shared variable.
;
; Operation:         Saves the passed in sign to the Sign shared variable.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  Sign - written to.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags.
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/05/14  Victor Han      wrote the assembly code
;    12/01/14  Victor Han      initial revision

SaveSign        PROC    NEAR
        
        CMP     AL, POS_SIGN  ;check sign value
        JE      SaveSignPos
        ;JNE    SaveSignNeg
        
SaveSignNeg:
        MOV     Sign, NEG_SIGN
        JMP     SaveSignDone
        
SaveSignPos:
        MOV     Sign, POS_SIGN
        JMP     SaveSignDone
        
SaveSignDone:
        RET     
        
SaveSign        ENDP


; ExecuteAbsSpd
;
; Description:       Executes the set absolute speed command with the parsed
;                    value in Num. Errors if the sign in Sign is NEG_SIGN. Also
;                    resets serial processing upon successful command action.
;
; Operation:         Checks if Sign is NEG_SIGN. If so, sets ParsingStatus and 
;                    returns. If not, then calls  SetMotorSpeed with Num for 
;                    speed and DONT_CHANGE_ANGLE for the angle. Then calls 
;                    InitSerialProcessing to reset serial processing for the 
;                    next command.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  ParsingStatus - written to
;                    Num - read (and written to in InitSerialProcessing)
;                    Sign - read (and written to in InitSerialProcessing)
;                    CurState - written to in InitSerialProcessing
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    Checks if Sign is NEG_SIGN. Returns with ParsingStatus set 
;                    if so.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, BX, SI, ES
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/13/14  Victor Han      now sends the speed of the RoboTrike to the
;                              remote board after changing it
;    12/06/14  Victor Han      updated comments
;    12/05/14  Victor Han      wrote the assembly code
;    12/01/14  Victor Han      initial revision

ExecuteAbsSpd     PROC    NEAR

ExecuteAbsSpdCheckSign:         
        CMP     Sign, NEG_SIGN            
        JNE     ExecuteAbsSpdSuccess
        ;JE     ExecuteAbsSpdError        ;can't have negative absolute speed
        
ExecuteAbsSpdError:
        CALL    SetError
        JMP     ExecuteAbsSpdDone
        
ExecuteAbsSpdSuccess:
        MOV     AX, Num
        MOV     BX, DONT_CHANGE_ANGLE     ;only changing speed
        CALL    SetMotorSpeed
        CALL    InitSerialProcessing      ;reset serial processing for next cmd
        JMP     ExecuteAbsSpdDone
        
ExecuteAbsSpdDone:
        CALL    GetMotorSpeed             ;send status info to remote board
        MOV     SI, OFFSET(StringBuffer)
        MOV     BYTE PTR [SI], 'S'        ;characters to indicate speed value
        INC     SI
        MOV     BYTE PTR [SI], 'P'
        INC     SI
        MOV     BYTE PTR [SI], 'D'
        INC     SI
        MOV     BYTE PTR [SI], ' '
        INC     SI
        CALL    Hex2String               ;get speed as unsigned hex value string
        MOV     SI, OFFSET(StringBuffer)
        PUSH    DS
        POP     ES
        CALL    SerialPutString          ;send this string
        RET
		
ExecuteAbsSpd     ENDP


; ExecuteRelSpd
;
; Description:       Executes the set relative speed command. If Sign is 
;                    NEG_SIGN, subtracts Num from the current speed. If not, 
;                    adds Num to the current speed. If subtracting would result
;                    in a negative speed, the speed is set to 0. If adding would
;                    result in a speed above the max, the speed is set to the
;                    max. Serial processing is reset upon completion.
;
; Operation:         Checks if Sign is NEG_SIGN. If so, subtracts Num from the
;                    current speed and calls SetMotorSpeed with the resulting
;                    speed and DONT_CHANGE_ANGLE. If the result is negative, 
;                    SetMotorSpeed with a speed of 0 instead. If Sign is not
;                    NEG_SIGN, adds Num to the current speed and calls 
;                    SetMotorSpeed with the resulting speed and DONT_CHANGE_ANGLE. 
;                    If the result sets the carry flag or is above MAX_SPEED,
;                    SetMotorSpeed is called with MAX_SPEED instead. 
;                    InitSerialProcessing is called at the end to prepare for
;                    the next command.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  Num - read (and written to in InitSerialProcessing)
;                    Sign - read (and written to in InitSerialProcessing)
;                    CurState - written to in InitSerialProcessing
;                    ParsingStatus - written to in InitSerialProcessing
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, BX, SI, ES
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/13/14  Victor Han      now sends the speed of the RoboTrike to the
;                              remote board after changing it
;    12/06/14  Victor Han      updated comments
;    12/05/14  Victor Han      initial revision

ExecuteRelSpd     PROC    NEAR
        
ExecuteRelSpdGetSpd:
        MOV     BX, Num
        CALL    GetMotorSpeed          ;get current speed
        ;JMP    ExecuteRelSpdCheckSign
        
ExecuteRelSpdCheckSign:
        CMP     Sign, NEG_SIGN         ;check if should add to or subtract from
                                       ;  current speed
        JE      ExecuteRelSpdSub
        ;JNE    ExecuteRelSpdAdd
        
ExecuteRelSpdAdd:
        ADD     AX, BX
        JC      ExecuteRelSpdMax       ;if addition carries, definitely above
        ;JNC    ExecuteRelSpdNum       ;  MAX_SPEED
        
ExecuteRelSpdNum:
        CMP     AX, MAX_SPEED          ;check if above MAX_SPEED
        JBE     ExecuteRelSpdDone
        ;JA     ExecuteRelSpdMax
        
ExecuteRelSpdMax:
        MOV     AX, MAX_SPEED          ;if above MAX_SPEED change to MAX_SPEED
        JMP     ExecuteRelSpdDone
        
ExecuteRelSpdSub:
        SUB     AX, BX
        JNC     ExecuteRelSpdDone      ;if still positive, done
        ;JC     ExecuteRelSpdZero
        
ExecuteRelSpdZero:
        MOV     AX, 0                  ;if result is negative, change to 0
        ;JMP    ExecuteRelSpdDone
        
ExecuteRelSpdDone:
        MOV     BX, DONT_CHANGE_ANGLE  ;don't change the angle
        CALL    SetMotorSpeed
        CALL    GetMotorSpeed            ;send status info
        MOV     SI, OFFSET(StringBuffer)
        MOV     BYTE PTR [SI], 'S'       ;character to indicate speed value
        INC     SI
        MOV     BYTE PTR [SI], 'P'
        INC     SI
        MOV     BYTE PTR [SI], 'D'
        INC     SI
        MOV     BYTE PTR [SI], ' '
        INC     SI
        CALL    Hex2String               ;get speed as unsigned hex string
        MOV     SI, OFFSET(StringBuffer)
        PUSH    DS
        POP     ES
        CALL    SerialPutString          ;send string
        CALL    InitSerialProcessing   ;reset serial processing for next command
        RET
		
ExecuteRelSpd     ENDP


; ExecuteSetDir
;
; Description:       Executes the set direction command. Sets the RoboTrike 
;                    angle to be Num degrees relative to its current angle.
;                    If Sign is NEG_SIGN, Num is measured counter-clockwise.
;                    If not, Num is measured clockwise. Serial processing is
;                    reset after command completion.
;
; Operation:         Checks if the Sign is NEG_SIGN. If so, Num is negated, 
;                    added to 360 to make sure it won't be DONT_CHANGE_ANGLE, 
;                    the result of which is added to the current direction and
;                    is then passed to SetMotorSpeed along with DONT_CHANGE_SPEED.
;                    If Sign is not NEG_SIGN, 360 is subtracted from Num so that
;                    when Num is added to the current direction, the value won't
;                    overflow. This sum is then passed to SetMotorSpeed along
;                    with DONT_CHANGE_SPEED. In either case, InitSerialProcessing
;                    is called at the end.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  CurState - written to in InitSerialProcessing
;                    ParsingStatus - written to in InitSerialProcessing
;                    Num - read (and written to in InitSerialProcessing)
;                    Sign - read (and written to in InitSerialProcessing)
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, BX, SI, ES
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:   
;    12/13/14  Victor Han      now sends the direction of the RoboTrike to the
;                              remote board after changing it  
;    12/06/14  Victor Han      updated comments
;    12/05/14  Victor Han      initial revision

ExecuteSetDir     PROC    NEAR
        
ExecuteSetDirCheckSign:
        MOV     BX, Num
        CMP     Sign, NEG_SIGN        ;check if should add or subtract from dir
        JE      ExecuteSetDirNegSign
        ;JNE    ExecuteSetDirPosSign
        
ExecuteSetDirPosSign:
        SUB     BX, 360               ;make sure adding this value to the 
                                      ;  current direction does not overflow
        JMP     ExecuteSetDirDone
        
ExecuteSetDirNegSign:
        NEG     BX
        ADD     BX, 360               ;make sure do not call SetMotorSpeed with
                                      ;  DONT_CHANGE_ANGLE
        ;JMP    ExecuteSetDirDone
        
ExecuteSetDirDone:
        CALL    GetMotorDirection
        ADD     BX, AX                ;get new direction value
        MOV     AX, DONT_CHANGE_SPEED
        CALL    SetMotorSpeed         
        CALL    GetMotorDirection        ;send status info
        MOV     SI, OFFSET(StringBuffer)
        MOV     BYTE PTR [SI], 'D'       ;characters to indicate direction value
        INC     SI
        MOV     BYTE PTR [SI], 'R'
        INC     SI
        CALL    Dec2String               ;get string of decimal representation
        MOV     SI, OFFSET(StringBuffer)
        PUSH    DS
        POP     ES
        CALL    SerialPutString          ;send string
        CALL    InitSerialProcessing  ;reset for next command
        RET
		
ExecuteSetDir     ENDP


; ExecuteRotTur
;
; Description:       Executes the Rotate Turret Angle command. If Sign is NULL,
;                    sets the turret angle to be the absolute angle in Num. If
;                    Sign is not NULL, rotates the turret Num degrees from its
;                    current position. It is rotated clockwise if Sign is 
;                    POS_SIGN and counter-clockwise if Sign is NEG_SIGN. Resets
;                    serial processing upon completion.
;
; Operation:         Checks the value of Sign. If Sign is NULL, calls 
;                    SetTurretAngle with Num. If Sign is POS_SIGN, calls 
;                    SetRelTurretAngle with Num. If Sign is NEG_SIGN, calls
;                    SetRelTurretAngle with -Num. Finally calls 
;                    InitSerialProcessing to reset the serial processing.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  Sign - read (and written to in InitSerialProcessing)
;                    Num - read (and written to in InitSerialProcessing)
;                    CurState - written to in InitSerialProcessing
;                    ParsingStatus - written to in InitSerialProcessing
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/06/14  Victor Han      updated comments
;    12/05/14  Victor Han      initial revision

ExecuteRotTur     PROC    NEAR
        
ExecuteRotTurCheckSignNull:
        MOV     AX, Num
        CMP     Sign, NULL              ;see if should set abs angle or relative
        JNE     ExecuteRotTurCheckSign  ;if relative, which direction
        ;JE     ExecuteRotTurAbs
        
ExecuteRotTurAbs:
        CALL    SetTurretAngle
        JMP     ExecuteRotTurDone
        
ExecuteRotTurCheckSign:
        CMP     Sign, NEG_SIGN
        JNE     ExecuteRotTurRel
        ;JE     ExecuteRotTurNegSign
        
ExecuteRotTurNegSign:
        NEG     AX
        JMP     ExecuteRotTurRel
        
ExecuteRotTurRel:
        CALL    SetRelTurretAngle
        ;JMP    ExecuteRotTurDone
        
ExecuteRotTurDone:
        CALL    InitSerialProcessing  ;reset for next command
        RET
		
ExecuteRotTur     ENDP


; ExecuteTurElv
;
; Description:       Executes the set turret elevation command. Throws an
;                    error if the parsed number's magnitude is above MAX_TUR_ELV.
;                    Resets serial processing upon successful command completion.
;
; Operation:         First checks if Num is greater than MAX_TUR_ELV. If so,
;                    throws an error. If not, this function calls 
;                    SetTurretElevation with Num set to the appropriate sign as 
;                    denoted by Sign, and then calls InitSerialProcessing. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  Sign - read (and written to in InitSerialProcessing)
;                    Num - read (and written to in InitSerialProcessing)
;                    ParsingStatus - written to
;                    CurState - written to in InitSerialProcessing
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    Throws an error if Num is greater than MAX_TUR_ELV.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:
;    12/06/14  Victor Han      updated comments     
;    12/05/14  Victor Han      initial revision

ExecuteTurElv     PROC    NEAR
        
        MOV     AX, Num
        CMP     AX, MAX_TUR_ELV          ;check if Num is too big
        JG      ExecuteTurElvError       ;if so, throw error
        ;JLE    ExecuteTurElvCheckSign
        
ExecuteTurElvCheckSign:
        CMP     Sign, NEG_SIGN           ;check if should pass in a negative num
        JNE     ExecuteTurElvSuccess
        ;JE     ExecuteTurElvNeg
        
ExecuteTurElvNeg:
        NEG     AX
        JMP     ExecuteTurElvSuccess
        
ExecuteTurElvError:
        CALL    SetError
        JMP     ExecuteTurElvDone
        
ExecuteTurElvSuccess:
        CALL    SetTurretElevation
        CALL    InitSerialProcessing    ;reset serial parsing for next command
        ;JMP    ExecuteRotTurDone
        
ExecuteTurElvDone:
        RET
		
ExecuteTurElv     ENDP


; ExecuteLaserOn
;
; Description:       Turns the laser on.
;
; Operation:         Calls SetLaser with LASER_ON_VAL.

; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, SI, ES
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/13/14  Victor Han      now sends a message to the remote board saying 
;                              that the laser has been turned on
;    12/06/14  Victor Han      updated comments
;    12/01/14  Victor Han      initial revision

ExecuteLaserOn     PROC    NEAR
        
        MOV     AX, LASER_ON_VAL
        CALL    SetLaser
        MOV     SI, OFFSET(LaserOnStr)   ;get message address
        PUSH    CS
        POP     ES 
        CALL    SerialPutString          ;send it
        RET
		
ExecuteLaserOn     ENDP


; ExecuteLaserOff
;
; Description:       Turns the laser off.
;
; Operation:         Calls SetLaser with LASER_OFF_VAL.

; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/13/14  Victor Han      now sends a message to the remote board saying 
;                              that the laser has been turned off
;    12/06/14  Victor Han      updated comments
;    12/01/14  Victor Han      initial revision

ExecuteLaserOff      PROC    NEAR
              
        MOV     AX, LASER_OFF_VAL
        CALL    SetLaser
        MOV     SI, OFFSET(LaserOffStr) ;get message address
        PUSH    CS
        POP     ES
        CALL    SerialPutString         ;send it
        RET
		
ExecuteLaserOff      ENDP

; macro to make strings in tables more readable. the string is NULL terminated.
%*DEFINE(STRING(char0, char1, char2, char3, char4, char5, char6, char7))  (
        DB      %char0
        DB      %char1
        DB      %char2
        DB      %char3
        DB      %char4
        DB      %char5
        DB      %char6
        DB      %char7
        DB      ASCII_NULL
)

; LaserOnStr 
;
; Description:      Table that holds the string sent to the remote board when
;                   the laser is turned on.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Revision History:
;    12/13/14  Victor Han      initial revision

LaserOnStr          LABEL   BYTE
                    PUBLIC  LaserOnStr
			
        %STRING('F','I','R','E','L','S','R','!')
        
; LaserOffStr 
;
; Description:      Table that holds the string sent to the remote board when
;                   the laser is turned off.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Revision History:
;    12/13/14  Victor Han      initial revision

LaserOffStr         LABEL   BYTE
                    PUBLIC  LaserOffStr
			
        %STRING('L','A','S','E','R','O','F','F')
        
        
; StateTable
;
; Description:      This is the state transition table for the mealy state machine.
;                   Each entry consists of the next state and action for that
;                   transition.  The rows are associated with the current
;                   state and the columns with the input type.
;
; Revision History:     
;    12/05/14  Victor Han      changed so that each command has its own path
;    12/01/14  Victor Han      initial revision


TRANSITION_ENTRY        STRUC           ;structure used to define table
    NEXTSTATE   DB      ?               ;the next state for the transition
    ACTION      DW      ?               ;action for the transition
TRANSITION_ENTRY      ENDS


;define a macro to make table a little more readable
;macro just does an offset of the action routine entries to build the STRUC
%*DEFINE(TRANSITION(nxtst, act))  (
    TRANSITION_ENTRY< %nxtst, OFFSET(%act) >
)


StateTable	LABEL	TRANSITION_ENTRY

	;Current State = IDLE                   Input Token Type
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SIGN
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, DoNOP)	            ;TOKEN_EOS
    %TRANSITION(ABS_SPD, DoNOP)	            ;TOKEN_ABS_SPD
    %TRANSITION(REL_SPD, DoNOP)	            ;TOKEN_REL_SPD
    %TRANSITION(SET_DIR, DoNOP)	            ;TOKEN_SET_DIR
    %TRANSITION(ROT_TUR, DoNOP)	            ;TOKEN_ROT_TUR
    %TRANSITION(TUR_ELV, DoNOP)	            ;TOKEN_TUR_ELV
	%TRANSITION(LASER_ON, DoNOP)	        ;TOKEN_LASERON
	%TRANSITION(LASER_OFF, DoNOP)		    ;TOKEN_LASEROFF
    %TRANSITION(IDLE, DoNOP)		        ;TOKEN_IGNORE
    
    ;Current State = ST_ERROR               Input Token Type
    %TRANSITION(ST_ERROR, DoNOP)	        ;TOKEN_SIGN
    %TRANSITION(ST_ERROR, DoNOP)	        ;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, DoNOP)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, InitSerialProcessing)	;TOKEN_EOS
    %TRANSITION(ST_ERROR, DoNOP)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, DoNOP)            ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, DoNOP)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, DoNOP)            ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, DoNOP)            ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, DoNOP)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, DoNOP)		    ;TOKEN_LASEROFF
    %TRANSITION(ST_ERROR, DoNOP)		    ;TOKEN_IGNORE
    
    ;Current State = ABS_SPD                Input Token Type
    %TRANSITION(ABS_SPD_SIGN, SaveSign)	    ;TOKEN_SIGN
    %TRANSITION(ABS_SPD_DIGIT, AppendDigit) ;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, SetError)	            ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(ABS_SPD, DoNOP)		        ;TOKEN_IGNORE
    
    ;Current State = ABS_SPD_SIGN           Input Token Type
    %TRANSITION(ST_ERROR, SetError) 	    ;TOKEN_SIGN
    %TRANSITION(ABS_SPD_DIGIT, AppendDigit)	;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, SetError)	            ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(ABS_SPD_SIGN, DoNOP)		;TOKEN_IGNORE
    
    ;Current State = ABS_SPD_DIGIT          Input Token Type
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SIGN
    %TRANSITION(ABS_SPD_DIGIT, AppendDigit) ;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, ExecuteAbsSpd)	    ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(ABS_SPD_DIGIT, DoNOP)		;TOKEN_IGNORE
    
    ;Current State = REL_SPD                Input Token Type
    %TRANSITION(REL_SPD_SIGN, SaveSign)	    ;TOKEN_SIGN
    %TRANSITION(REL_SPD_DIGIT, AppendDigit) ;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, SetError)	            ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(REL_SPD, DoNOP)     		;TOKEN_IGNORE
    
    ;Current State = REL_SPD_SIGN           Input Token Type
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SIGN
    %TRANSITION(REL_SPD_DIGIT, AppendDigit) ;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, SetError)	            ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(REL_SPD_SIGN, DoNOP)		;TOKEN_IGNORE
    
    ;Current State = REL_SPD_DIGIT          Input Token Type
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SIGN
    %TRANSITION(REL_SPD_DIGIT, AppendDigit) ;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, ExecuteRelSpd)	    ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError) 	    ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)	    	;TOKEN_LASEROFF
    %TRANSITION(REL_SPD_DIGIT, DoNOP)		;TOKEN_IGNORE
    
    ;Current State = SET_DIR                Input Token Type
    %TRANSITION(SET_DIR_SIGN, SaveSign)	    ;TOKEN_SIGN
    %TRANSITION(SET_DIR_DIGIT, AppendDigit) ;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, SetError)	            ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(SET_DIR, DoNOP)	        	;TOKEN_IGNORE
    
    ;Current State = SET_DIR_SIGN           Input Token Type
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SIGN
    %TRANSITION(SET_DIR_DIGIT, AppendDigit)	;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, SetError)	            ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)	    	;TOKEN_LASEROFF
    %TRANSITION(SET_DIR_SIGN, DoNOP)		;TOKEN_IGNORE
    
    ;Current State = SET_DIR_DIGIT          Input Token Type
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SIGN
    %TRANSITION(SET_DIR_DIGIT, AppendDigit)	;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, ExecuteSetDir)	    ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(SET_DIR_DIGIT, DoNOP)		;TOKEN_IGNORE
    
    ;Current State = ROT_TUR                Input Token Type
    %TRANSITION(ROT_TUR_SIGN, SaveSign)	    ;TOKEN_SIGN
    %TRANSITION(ROT_TUR_DIGIT, AppendDigit)	;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, SetError)	            ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(ROT_TUR, DoNOP)		        ;TOKEN_IGNORE
    
    ;Current State = ROT_TUR_SIGN           Input Token Type
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SIGN
    %TRANSITION(ROT_TUR_DIGIT, AppendDigit)	;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, SetError)	            ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)	    	;TOKEN_LASEROFF
    %TRANSITION(ROT_TUR_SIGN, DoNOP)		;TOKEN_IGNORE
    
    ;Current State = ROT_TUR_DIGIT          Input Token Type
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SIGN
    %TRANSITION(ROT_TUR_DIGIT, AppendDigit) ;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, ExecuteRotTur)	    ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(ROT_TUR_DIGIT, DoNOP)		;TOKEN_IGNORE
    
    ;Current State = TUR_ELV                Input Token Type
    %TRANSITION(TUR_ELV_SIGN, SaveSign)	    ;TOKEN_SIGN
    %TRANSITION(TUR_ELV_DIGIT, AppendDigit)	;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, SetError)	            ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)	    	;TOKEN_LASEROFF
    %TRANSITION(TUR_ELV, DoNOP)		        ;TOKEN_IGNORE
    
    ;Current State = TUR_ELV_SIGN           Input Token Type
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SIGN
    %TRANSITION(TUR_ELV_DIGIT, AppendDigit)	;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, SetError)	            ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(TUR_ELV_SIGN, DoNOP)		;TOKEN_IGNORE
    
    ;Current State = TUR_ELV_DIGIT          Input Token Type
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SIGN
    %TRANSITION(TUR_ELV_DIGIT, AppendDigit)	;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, ExecuteTurElv)	    ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(TUR_ELV_DIGIT, DoNOP)		;TOKEN_IGNORE
    
    ;Current State = LASER_ON               Input Token Type
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SIGN
    %TRANSITION(ST_ERROR, SetError)		    ;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, ExecuteLaserOn)	    ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(LASER_ON, DoNOP)		    ;TOKEN_IGNORE
    
    ;Current State = LASER_OFF              Input Token Type
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SIGN
    %TRANSITION(ST_ERROR, SetError)		    ;TOKEN_DIGIT
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_OTHER
    %TRANSITION(IDLE, ExecuteLaserOff)	    ;TOKEN_EOS
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_ABS_SPD
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_REL_SPD
    %TRANSITION(ST_ERROR, SetError)	        ;TOKEN_SET_DIR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_ROT_TUR
    %TRANSITION(ST_ERROR, SetError)         ;TOKEN_TUR_ELV
	%TRANSITION(ST_ERROR, SetError)	        ;TOKEN_LASERON
	%TRANSITION(ST_ERROR, SetError)		    ;TOKEN_LASEROFF
    %TRANSITION(LASER_OFF, DoNOP)		    ;TOKEN_IGNORE
    

; GetTokenTypeVal
;
; Description:      This procedure returns the token class and token value for
;                   the passed character.  The character is truncated to
;                   7-bits.
;
; Operation:        Looks up the passed character in two tables, one for token
;                   types or classes, the other for token values.
;
; Arguments:        AL - character to look up.
; Return Value:     AL - token value for the character.
;                   AH - token type or class for the character.
;
; Local Variables:  BX - table pointer, points at lookup tables.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       Table lookup.
; Data Structures:  Two tables, one containing token values and the other
;                   containing token types.
;
; Registers Changed: AX, BX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/1/14  Victor Han      initial revision

GetTokenTypeVal	PROC    NEAR

InitGetTokenTypeVal:				;setup for lookups
	AND	    AL, TOKEN_MASK	     	;strip unused bits (high bit)
	MOV	    AH, AL		        	;and preserve value in AH
    ;JMP    TokenTypeLookup

TokenTypeLookup:                        ;get the token type
    MOV     BX, OFFSET(TokenTypeTable)  ;BX points at table
	XLAT	CS:TokenTypeTable	        ;have token type in AL
	XCHG	AH, AL			            ;token type in AH, character in AL
    ;JMP    TokenValueLookup

TokenValueLookup:			            ;get the token value
    MOV     BX, OFFSET(TokenValueTable) ;BX points at table
	XLAT	CS:TokenValueTable	        ;have token value in AL
    ;JMP    EndGetTokenTypeVal

EndGetTokenTypeVal:                     ;done looking up type and value
    RET

GetTokenTypeVal	ENDP


; Token Tables
;
; Description:      This creates the tables of token types and token values.
;                   Each entry corresponds to the token type and the token
;                   value for a character.  Macros are used to actually build
;                   two separate tables - TokenTypeTable for token types and
;                   TokenValueTable for token values.
;
; Revision History:     
;    12/05/14  Victor Han      changed command tokens be different for each cmd
;    12/01/14  Victor Han      initial revision

%*DEFINE(TABLE)  (
        %TABENT(TOKEN_EOS, 0)		;<null>  (end of string)
        %TABENT(TOKEN_OTHER, 1)		;SOH
        %TABENT(TOKEN_OTHER, 2)		;STX
        %TABENT(TOKEN_OTHER, 3)		;ETX
        %TABENT(TOKEN_OTHER, 4)		;EOT
        %TABENT(TOKEN_OTHER, 5)		;ENQ
        %TABENT(TOKEN_OTHER, 6)		;ACK
        %TABENT(TOKEN_OTHER, 7)		;BEL
        %TABENT(TOKEN_OTHER, 8)		;backspace
        %TABENT(TOKEN_IGNORE, 9)    ;TAB
        %TABENT(TOKEN_OTHER, 10)	;new line
        %TABENT(TOKEN_OTHER, 11)	;vertical tab
        %TABENT(TOKEN_OTHER, 12)	;form feed
        %TABENT(TOKEN_EOS, 13)	    ;carriage return
        %TABENT(TOKEN_OTHER, 14)	;SO
        %TABENT(TOKEN_OTHER, 15)	;SI
        %TABENT(TOKEN_OTHER, 16)	;DLE
        %TABENT(TOKEN_OTHER, 17)	;DC1
        %TABENT(TOKEN_OTHER, 18)	;DC2
        %TABENT(TOKEN_OTHER, 19)	;DC3
        %TABENT(TOKEN_OTHER, 20)	;DC4
        %TABENT(TOKEN_OTHER, 21)	;NAK
        %TABENT(TOKEN_OTHER, 22)	;SYN
        %TABENT(TOKEN_OTHER, 23)	;ETB
        %TABENT(TOKEN_OTHER, 24)	;CAN
        %TABENT(TOKEN_OTHER, 25)	;EM
        %TABENT(TOKEN_OTHER, 26)	;SUB
        %TABENT(TOKEN_OTHER, 27)	;escape
        %TABENT(TOKEN_OTHER, 28)	;FS
        %TABENT(TOKEN_OTHER, 29)	;GS
        %TABENT(TOKEN_OTHER, 30)	;AS
        %TABENT(TOKEN_OTHER, 31)	;US
        %TABENT(TOKEN_IGNORE, ' ')	;space
        %TABENT(TOKEN_OTHER, '!')	;!
        %TABENT(TOKEN_OTHER, '"')	;"
        %TABENT(TOKEN_OTHER, '#')	;#
        %TABENT(TOKEN_OTHER, '$')	;$
        %TABENT(TOKEN_OTHER, 37)	;percent
        %TABENT(TOKEN_OTHER, '&')	;&
        %TABENT(TOKEN_OTHER, 39)	;'
        %TABENT(TOKEN_OTHER, 40)	;open paren
        %TABENT(TOKEN_OTHER, 41)	;close paren
        %TABENT(TOKEN_OTHER, '*')	;*
        %TABENT(TOKEN_SIGN, +1)		;+  (positive sign)
        %TABENT(TOKEN_OTHER, 44)	;,
        %TABENT(TOKEN_SIGN, -1)		;-  (negative sign)
        %TABENT(TOKEN_OTHER, '.')   ;.  
        %TABENT(TOKEN_OTHER, '/')	;/
        %TABENT(TOKEN_DIGIT, 0)		;0  (digit)
        %TABENT(TOKEN_DIGIT, 1)		;1  (digit)
        %TABENT(TOKEN_DIGIT, 2)		;2  (digit)
        %TABENT(TOKEN_DIGIT, 3)		;3  (digit)
        %TABENT(TOKEN_DIGIT, 4)		;4  (digit)
        %TABENT(TOKEN_DIGIT, 5)		;5  (digit)
        %TABENT(TOKEN_DIGIT, 6)		;6  (digit)
        %TABENT(TOKEN_DIGIT, 7)		;7  (digit)
        %TABENT(TOKEN_DIGIT, 8)		;8  (digit)
        %TABENT(TOKEN_DIGIT, 9)		;9  (digit)
        %TABENT(TOKEN_OTHER, ':')	;:
        %TABENT(TOKEN_OTHER, ';')	;;
        %TABENT(TOKEN_OTHER, '<')	;<
        %TABENT(TOKEN_OTHER, '=')	;=
        %TABENT(TOKEN_OTHER, '>')	;>
        %TABENT(TOKEN_OTHER, '?')	;?
        %TABENT(TOKEN_OTHER, '@')	;@
        %TABENT(TOKEN_OTHER, 'A')	;A
        %TABENT(TOKEN_OTHER, 'B')	;B
        %TABENT(TOKEN_OTHER, 'C')	;C
        %TABENT(TOKEN_SET_DIR, 'D')	;D
        %TABENT(TOKEN_TUR_ELV, 'E') ;E 
        %TABENT(TOKEN_LASERON, 'F')	;F
        %TABENT(TOKEN_OTHER, 'G')	;G
        %TABENT(TOKEN_OTHER, 'H')	;H
        %TABENT(TOKEN_OTHER, 'I')	;I
        %TABENT(TOKEN_OTHER, 'J')	;J
        %TABENT(TOKEN_OTHER, 'K')	;K
        %TABENT(TOKEN_OTHER, 'L')	;L
        %TABENT(TOKEN_OTHER, 'M')	;M
        %TABENT(TOKEN_OTHER, 'N')	;N
        %TABENT(TOKEN_LASEROFF, 'O');O
        %TABENT(TOKEN_OTHER, 'P')	;P
        %TABENT(TOKEN_OTHER, 'Q')	;Q
        %TABENT(TOKEN_OTHER, 'R')	;R
        %TABENT(TOKEN_ABS_SPD, 'S')	;S
        %TABENT(TOKEN_ROT_TUR, 'T')	;T
        %TABENT(TOKEN_OTHER, 'U')	;U
        %TABENT(TOKEN_REL_SPD, 'V')	;V
        %TABENT(TOKEN_OTHER, 'W')	;W
        %TABENT(TOKEN_OTHER, 'X')	;X
        %TABENT(TOKEN_OTHER, 'Y')	;Y
        %TABENT(TOKEN_OTHER, 'Z')	;Z
        %TABENT(TOKEN_OTHER, '[')	;[
        %TABENT(TOKEN_OTHER, '\')	;\
        %TABENT(TOKEN_OTHER, ']')	;]
        %TABENT(TOKEN_OTHER, '^')	;^
        %TABENT(TOKEN_OTHER, '_')	;_
        %TABENT(TOKEN_OTHER, '`')	;`
        %TABENT(TOKEN_OTHER, 'a')	;a
        %TABENT(TOKEN_OTHER, 'b')	;b
        %TABENT(TOKEN_OTHER, 'c')	;c
        %TABENT(TOKEN_SET_DIR, 'd')	;d
        %TABENT(TOKEN_TUR_ELV, 'e') ;e  
        %TABENT(TOKEN_LASERON, 'f')	;f
        %TABENT(TOKEN_OTHER, 'g')	;g
        %TABENT(TOKEN_OTHER, 'h')	;h
        %TABENT(TOKEN_OTHER, 'i')	;i
        %TABENT(TOKEN_OTHER, 'j')	;j
        %TABENT(TOKEN_OTHER, 'k')	;k
        %TABENT(TOKEN_OTHER, 'l')	;l
        %TABENT(TOKEN_OTHER, 'm')	;m
        %TABENT(TOKEN_OTHER, 'n')	;n
        %TABENT(TOKEN_LASEROFF, 'o');o
        %TABENT(TOKEN_OTHER, 'p')	;p
        %TABENT(TOKEN_OTHER, 'q')	;q
        %TABENT(TOKEN_OTHER, 'r')	;r
        %TABENT(TOKEN_ABS_SPD, 's')	;s
        %TABENT(TOKEN_ROT_TUR, 't')	;t
        %TABENT(TOKEN_OTHER, 'u')	;u
        %TABENT(TOKEN_REL_SPD, 'v')	;v
        %TABENT(TOKEN_OTHER, 'w')	;w
        %TABENT(TOKEN_OTHER, 'x')	;x
        %TABENT(TOKEN_OTHER, 'y')	;y
        %TABENT(TOKEN_OTHER, 'z')	;z
        %TABENT(TOKEN_OTHER, '{')	;{
        %TABENT(TOKEN_OTHER, '|')	;|
        %TABENT(TOKEN_OTHER, '}')	;}
        %TABENT(TOKEN_OTHER, '~')	;~
        %TABENT(TOKEN_OTHER, 127)	;rubout
)

; token type table - uses first byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokentype
)

TokenTypeTable	LABEL   BYTE
        %TABLE


; token value table - uses second byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokenvalue
)

TokenValueTable	LABEL       BYTE
        %TABLE



CODE    ENDS


;the data segment

DATA    SEGMENT PUBLIC  'DATA'

ParsingStatus        DB       ? ;set if there is an error, unset if not
CurState             DB       ? ;current state of the mealy state machine
Sign                 DB       ? ;saves the parsed sign if any for input to a
                                ;  command
Num                  DW       ? ;saves the parsed number if any for input to a
                                ;  command
StringBuffer         DB       NUM_DIGITS+1    DUP (?) ;a buffer to temporarily
                                                      ;  hold strings to be sent
                                                      ;  to the remote board

DATA    ENDS


        END
