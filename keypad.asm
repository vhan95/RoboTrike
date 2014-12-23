        NAME    KEYPAD

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   KEYPAD                                   ;
;                               KEYPAD Functions                             ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specifications and implementations for the
; KeypadScan and KeypadScanInit functions. Together, these functions allow for
; the detection of keypad input when KeypadScanInit is used to initialize 
; variables and KeypadScan is called approximately once every millisecond.
;
; Contents:
;     KeypadScan: Scans for and debounces key presses.
;     KeypadScanInit: Initializes variables for the KeypadScan function.
;
; Revision History:
;    12/14/14  Victor Han       updated comments
;    12/13/14  Victor Han       changed keyvalue passed into EnqueueEvent
;    11/16/14  Victor Han       updated comments
;    11/15/14  Victor Han       wrote the assembly code
;    11/10/14  Victor Han       initial revision

; local include files
$INCLUDE(keypad.inc)             ;includes definitions for constants regarding
                                 ;  the physical keypad specs, debounce time,
                                 ;  key values, etc.
                                

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

        EXTRN   EnqueueEvent:NEAR    

; KeypadScan
;
; Description:       Scans the keypad for key presses. If a key is detected
;                    to be pressed, it is debounced to make sure that it should
;                    actually be registered to be pressed. If the key is 
;                    continuously held down, it is registered again every 
;                    REPEAT_TIME milliseconds, thus giving it an auto-repeat 
;                    feature.
;                    This function expects to be called once every millisecond.
;
; Operation:         Every time this function is called, it checks if a row has
;                    any keys pressed. If not, it checks the next row in the 
;                    next call, wrapping back to the first row if needed. If so,
;                    then it sets the current SwitchPressed to be the pressed
;                    switch and resets the debounce counter. Each consecutive 
;                    function call in which the switch is detected to be 
;                    pressed, the debounce counter is decremented. If the 
;                    debounce counter reaches zero, the key pressed event is
;                    sent to the EnqueueEvent function and the debounce counter
;                    is set to the REPEAT_TIME time. For each REPEAT_TIME length
;                    that the switch is pressed down afterwards, another key
;                    pressed event is sent.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  CurRow - The row that this function should scan in this
;                             call. Both read and written to.
;                    PressedKey - The key that was pressed in the last 
;                                 call if any. Both read and written to.
;                    DebounceCntr - Time left for debouncing in ms for this
;                                   switch press. Both read and written to.
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
; Registers Changed: flags, AX, BX, CX, DX
; Known Bugs:        None.
; Limitations:       Cannot detect two or more simultaneous key-presses on 
;                    different rows.
;                    Only can have unique key values for up to 16 rows (one hex
;                    digit).
; Special Notes:     None.
;
; Revision History:  
;    12/14/14  Victor Han      updated comments
;    12/13/14  Victor Han      modified COuntReached to pass a different key 
;                              value to EnqueueEvent
;    11/16/14  Victor Han      updated comments   
;    11/15/14  Victor Han      wrote the assembly code and debugged until it 
;                              worked
;    11/10/14  Victor Han      initial revision
;

KeypadScan      PROC    NEAR
                PUBLIC  KeypadScan
		
KeypadScanStart:
        MOV     DL, KEYPAD                   ;get address of current keypad row
        ADD     DL, CurRow                   ;  to scan
        MOV     DH, 0                        ;address of row is only a byte
        IN      AL, DX                       ;get key value of row
        AND     AL, DIGIT_MASK               ;reset unimportant bits
        CMP     AL, NOTHING_PRESSED          ;check if a key is pressed
        JNE     KeyPressed                   ;if so, check if it was pressed
        ;JE     NothingPressed               ;  in the last call. If not, check
                                             ;  next row in next call
NothingPressed:                              ;nothing is pressed, so inc row
        INC     CurRow
        MOV     AL, CurRow                   ;prepare for row wrapping if needed
        MOV     BL, NUM_ROWS
        MOV     AH, 0
        DIV     BL
        MOV     CurRow, AH                   ;CurRow is now CurRow mod NUM_ROWS
        MOV     DebounceCntr, DEBOUNCE_TIME  ;reset debounce counter
        JMP     KeypadScanDone               ;done for this call
        
KeyPressed:
        CMP     AL, PressedKey               ;check if pressed key is the same 
                                             ;  as in last call
        JE      DecreaseCount                ;if so, decrease debounce counter
        ;JNE    SetKeyAndCount               ;if not, reset counter and set the
                                             ;  key value
        
SetKeyAndCount:
        MOV     DebounceCntr, DEBOUNCE_TIME  ;reset debounce counter
        MOV     PressedKey, AL               ;set key value to currently pressed
                                             ;  one
        JMP     KeypadScanDone               ;done
        
DecreaseCount:
        DEC     DebounceCntr                 ;decrease debounce counter if same
                                             ;  key as last call
        CMP     DebounceCntr, 0              ;check if counter has reached 0
        JNE     KeypadScanDone               ;if not, done
        ;JE     CountReached                 ;if so, send key pressed event
        
CountReached:                                ;debouncing completed
        NOT     AL                           ;change key values represent what
                                             ;  is actually pressed
        AND     AL, DIGIT_MASK               ;reset unimportant bits
        MOV     AH, 0          
        MOV     CX, AX                       ;add row to key value
        MOV     AX, INPUTS_PER_ROW
        MOV     BL, CurRow                   
        MUL     BL
        ADD     AX, CX
        MOV     AH, KEY_EVENT                ;prepare to send key event key
        CALL    EnqueueEvent                 ;send event
        MOV     DebounceCntr, REPEAT_TIME    ;initialize auto-repeat counter
        ;JMP    KeypadScanDone
        
KeypadScanDone:
        RET                                  ;done
        
KeypadScan      ENDP        
        
        
; KeypadScanInit
;
; Description:       Initializes variables for the KeypadScan function. Must
;                    be called before KeypadScan.
;
; Operation:         Sets CurRow to zero, PressedSwitch to NOTHING_PRESSED, and 
;                    DebounceCntr to DEBOUNCE_TIME.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  CurRow - Sets this to zero. Only writes.
;                    PressedKey - Sets this to NOTHING_PRESSED. Only writes.
;                    DebounceCntr - Sets this to DEBOUNCE_TIME. Only writes.
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
;    11/16/14  Victor Han      updated comments
;    11/15/14  Victor Han      wrote the assembly code
;    11/10/14  Victor Han      initial revision
;

KeypadScanInit      PROC    NEAR
                    PUBLIC  KeypadScanInit
                    
        MOV     CurRow, 0                     ;current row is first row
        MOV     PressedKey, NOTHING_PRESSED   ;nothing is intially pressed
        MOV     DebounceCntr, DEBOUNCE_TIME   ;nothing has started debouncing
        RET
		
KeypadScanInit      ENDP        

CODE    ENDS


;the data segment

DATA    SEGMENT PUBLIC  'DATA'

CurRow          DB      ? ;represents offset from first row in scanning the rows
                          ;  of the keypad.

PressedKey      DB      ? ;represents the value of the currently pressed key if
                          ;  any for the current row.

DebounceCntr    DW      ? ;represents the amount of time in milliseconds that
                          ;  the currently pressed key should be debounced for.
                          ;  If the current key has already been debounced once,
                          ;  it represents the time before the key will be 
                          ;  registered as pressed again.

DATA    ENDS


        END