        NAME    trkmain

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   TRKMAIN                                  ;
;                         RoboTrike Board Main Loop                          ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program calls the functions that initialize the chip
;                   select unit, event handlers, motors, lasers, timer 1, INT2, 
;                   serial I/O, and a serial input parser. Only event 
;                   handlers for timer 1 and INT2 are installed to the interrupt
;                   vector table. All other interrupt vectors, except the ones 
;                   for reserved event handlers, are set to the 
;                   illegalEventHandler, which just returns. 
;                   A queue holding system events EventQueue and a variable
;                   denoting whether a critical event has occurred CritError,
;                   are also initialized.
;                   Once initialization is complete, this program repeatedly 
;                   attempts to dequeue the event queue and process the
;                   resulting event. If the event is a character sent over from
;                   the remote board, we attempt to parse a command to execute 
;                   on the RoboTrike. If the event is an error, it is reported 
;                   to the remote board. If in any loop iteration, it is found
;                   that CritError is set, all software is reset.
;                   This program also sends to the remote board the current 
;                   RoboTrike speed, direction, or laser status after the 
;                   execution of any command that acts on one of these.
;
; Input:            Serial input from the remote board.
; Output:           Serial output to the remote board as well as motor movement
;                   and laser action.
;
; User Interface:   Handled by the remote board. The user makes inputs on the 
;                   remote board that are sent over to the RoboTrike board to be
;                   parsed into commands and acted upon. Any errors are sent to
;                   the remote board to be displayed to the user. Status 
;                   messages about the Robotrike state are also displayed to
;                   the user.
; Error Handling:   Reports errors to the remote board to display to the user.
;                   These errors include serial command parsing errors, serial
;                   communication errors, and critical errors.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;    12/13/14    Victor Han       finished writing the assembly code
;    12/12/14    Victor Han       wrote some assembly code
;    12/04/14    Victor Han       Initial revision.

; local include files
$INCLUDE(general.inc)
$INCLUDE(main.inc)

CGROUP  GROUP   CODE
DGROUP  GROUP   STACK, DATA


CODE    SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP, DS:DGROUP
        
        ; external function declarations

        EXTRN   InitCS:NEAR              ; initializes the chip select
        EXTRN   ClrIRQVectors:NEAR       ; installs illegalEventHandlers to all
		                                 ;   interrupt vectors except reserved
        EXTRN   InitTimer1:NEAR          ; initializes timer1 registers
        EXTRN   InstallTimer1Handler:NEAR; installs the timer1 event handler in
		                                 ;   the vector table
        EXTRN   InitINT2:NEAR            ; initializes the INT2 event
        EXTRN   InstallINT2Handler:NEAR  ; installs the INT2 event handler in 
                                         ;   the vector table.
        EXTRN   InitMotorLaserParallel:NEAR ; initializes motor and laser shared
                                         ;   variables as well as parallel I/O
                                         ;   with the 8255A chip.       
        EXTRN   InitSerial:NEAR          ; initializes serial communication
        EXTRN   InitSerialProcessing:NEAR; initializes the processing of 
                                         ;   characters sent from the remote
                                         ;   board
        EXTRN   InitEventQueue:NEAR      ; initializes the EventQueue
        EXTRN   InitCritError:NEAR       ; initializes the CritError variable
        EXTRN   GetCritError:NEAR        ; gets the value of the CritError var
        
        EXTRN   SerialPutString:NEAR     ; Sends a null terminated string to the
                                         ;   remote board
        EXTRN   TrikeErrorStrTable:BYTE  ; Table holding different error strings
                                         ;   to display to the user
        EXTRN   EventQueueEmpty:NEAR     ; Checks if the EventQueue is empty
        EXTRN   DequeueEvent:NEAR        ; Removes and returns an event from the
                                         ;   EventQueue
        EXTRN   ParseSerialChar:NEAR     ; Does the serial processing on a char

START:  

MAIN:
        MOV     AX, DGROUP              ; initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)
        MOV     AX, DGROUP              ; initialize the data segment
        MOV     DS, AX
        CALL    InitCS                  ; initialize chip select
        CALL    ClrIRQVectors           ; install illegalEventHandlers
        CALL    InitTimer1              ; initialize timer1
        CALL    InstallTimer1Handler    ; installs timer1 handler in vectortable
        CALL    InitINT2                ; initialize INT2
        CALL    InstallINT2Handler      ; install INT2 handler in vector table
        
Reset:
        CLI                             ; changing settings, so stop interrupts
        CALL    InitMotorLaserParallel  ; initializes motor, laser, and parallel
                                        ;   I/O variables
        CALL    InitSerial              ; initializes serial communication
        CALL    InitSerialProcessing    ; initializes serial processing
        CALL    InitEventQueue          ; initialize the EventQueue
        CALL    InitCritError           ; initialize CritError to FALSE
        STI                             ; done with initializing, so turn on
                                        ;   interrupts
        
MainLoop:
        CALL    GetCritError            ; check if there is a critical error
        CMP     AX, FALSE              
        JE      CheckEventQueue         ; if not, move on
        ;JNE    CritialError            ; if so, report and reset
        
CriticalError:
        MOV     AX, CRITICAL_ERROR_INDEX   ; get the error string to send
        MOV     BX, ERROR_STR_LEN
        MUL     BX
        MOV     BX, AX
        LEA     SI, TrikeErrorStrTable[BX]
        PUSH    CS
        POP     ES
        CALL    SerialPutString            ; send it to the remote board to 
                                           ;   display to the user
        JMP     Reset                      ; reset the software
        
CheckEventQueue:
        CALL    EventQueueEmpty     ; check if there is an event to process
        JZ      MainLoop            ; if not, keep checking for stuff
        ;JNZ    GetEvent            ; if so, get it
        
GetEvent:
        CALL    DequeueEvent          ; get event
        CMP     AH, SERIAL_CHAR_EVENT
        JE      ParseCharacter        ; if is char, then parse the command
        ;JNE    CheckEventSerialError ; if not, check if it's something else
        
CheckEventSerialError:
        CMP     AH, SERIAL_ERROR_EVENT 
        JE      SendSerialErrorStr  ; if it's a serial error, send error msg
        ;JNE    SendUnkownErrorStr  ; if not, don't know what it is

SendUnkownErrorStr:
        MOV     AX, UNKNOWN_ERROR_INDEX  ; event unknown, so send unknown error
                                         ;   message
        MOV     BX, ERROR_STR_LEN        ; get error string to send
        MUL     BX
        MOV     BX, AX
        LEA     SI, TrikeErrorStrTable[BX]
        PUSH    CS
        POP     ES
        CALL    SerialPutString   ; send error string to remote board
        JMP     MainLoop          ; back to checking for events
        
SendSerialErrorStr:
        MOV     AH, 0                 ; get error string to send
        MOV     BX, ERROR_STR_LEN
        MUL     BX
        MOV     BX, AX
        LEA     SI, TrikeErrorStrTable[BX] 
        PUSH    CS
        POP     ES
        CALL    SerialPutString ; send error string to remote board
        JMP     MainLoop        ; back to checking for events
        
ParseCharacter:
        CALL    ParseSerialChar ; parse the character as part of a command
        CMP     AX, FALSE       ; check if there was a parse error
        JE      MainLoop        ; if not, back to checking for events
        ;JNE    SendParsingErrorStr  ; if so, gotta send an error message
        
SendParsingErrorStr:
        MOV     AX, PARSING_ERROR_INDEX ; get error string
        MOV     BX, ERROR_STR_LEN
        MUL     BX
        MOV     BX, AX
        LEA     SI, TrikeErrorStrTable[BX]
        PUSH    CS
        POP     ES
        CALL    SerialPutString  ; send error string to remote board to display
        JMP     MainLoop         ; back to checking for more events
        
CODE    ENDS


; the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ; 240 words

TopOfStack      LABEL   WORD

STACK   ENDS

; the data segment
DATA    SEGMENT PUBLIC  'DATA'  ; initialize empty data segment for use in
                                ;   files with the functions this main loop 
                                ;   calls
DATA    ENDS

        END     START