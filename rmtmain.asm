        NAME    rmtmain

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   RMTMAIN                                  ;
;                            Remote Board Main Loop                          ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program calls the functions that initialize the chip
;                   select unit, event handlers, user interface, timer 0, INT2, 
;                   serial I/O, the keypad, and the display. Only event 
;                   handlers for timer 0 and INT2 are installed to the interrupt
;                   vector table. All other interrupt vectors, except the ones 
;                   for reserved event handlers, are set to the 
;                   illegalEventHandler, which just returns. 
;                   A queue holding system events EventQueue and a variable
;                   denoting whether a critical event has occurred CritError,
;                   are also initialized.
;                   Once initialization is complete, this program repeatedly 
;                   attempts to dequeue the event queue and process the
;                   resulting event. If the event is a character sent over from
;                   the RoboTrike board and the character is saved, and if the
;                   character is a NULL character, or NUM_DIGITS characters have
;                   been send over without a NULL character, the string of saved
;                   characters is displayed to the user. These strings may 
;                   either be error messages from the RoboTrike board or status
;                   messages after completing a command. If the event happens to 
;                   be an error on this board, a message is displayed to the
;                   user. If the event is a keypress, the keypress is parsed as
;                   input to the user interface. If in any iteration of the 
;                   loop, CritError is found to be set, all software is reset.
;
; Input:            User input from the keypad and serial input from the 
;                   RoboTrike board.
; Output:           Messages on the LED display and serial output to the 
;                   RoboTrike board.
;
; User Interface:   Handled mainly by the user interface functions (user.asm).
;                   Any keypress events are sent to the user interface functions
;                   and mapped to commands to send to the RoboTrike board.
;                   Error messages from both this board and the RoboTrike board
;                   are displayed to the user, indicating both the board of 
;                   origin for the error and the error type.
;                   After commands are successfully completed by the RoboTrike
;                   board, status info about what the commands changed is 
;                   displayed to the user.
; Error Handling:   Displays error messages to the user from both the RoboTrike
;                   board and this board.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;    12/14/14    Victor Han       updated comments
;    12/13/14    Victor Han       wrote the assembly code
;    12/08/14    Victor Han       Initial revision.

; local include files
$INCLUDE(general.inc)  ;contains definitions for general, universal constants
$INCLUDE(main.inc)     ;contains definitions for error message indexing

CGROUP  GROUP   CODE
DGROUP  GROUP   STACK, DATA


CODE    SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP, DS:DGROUP
        
        ; external function declarations

        EXTRN   InitCS:NEAR              ; initializes the chip select
        EXTRN   ClrIRQVectors:NEAR       ; installs illegalEventHandlers to all
		                                 ;   interrupt vectors except reserved
        EXTRN   InitTimer0:NEAR          ; initializes timer0 registers
        EXTRN   InstallTimer0Handler:NEAR; installs the timer0 event handler in
		                                 ;   the vector table
        EXTRN   InitINT2:NEAR            ; initializes the INT2 registers
        EXTRN   InstallINT2Handler:NEAR  ; installs the INT2 event handler in 
                                         ;   the vector table
        EXTRN   InitSerial:NEAR          ; initializes serial communication
        EXTRN   InitEventQueue:NEAR      ; initializes the EventQueue
        EXTRN   InitCritError:NEAR       ; initializes CritError to FALSE
        EXTRN   GetCritError:NEAR        ; gets the CritError value
        
        EXTRN   SerialPutString:NEAR     ; sends a string to the RoboTrike board
        EXTRN   RemoteErrorStrTable:BYTE ; contains error messages for the 
                                         ;   remote board errors
        EXTRN   EventQueueEmpty:NEAR     ; Checks whether the EventQueue is empty
        EXTRN   DequeueEvent:NEAR        ; Pops and returns an event from the
                                         ;   EventQueue
        EXTRN   ParseUserKeypress:NEAR   ; Maps a user keypress to a command to
                                         ;   send to the RoboTrike board
        EXTRN   InitDisplay:NEAR         ; Initializes the LED display
        EXTRN   Display:NEAR             ; Sets a string to be displayed on the
                                         ;   LED display
        EXTRN   KeypadScanInit:NEAR      ; initializes keypad press scanning
        EXTRN   InitLEDMux:NEAR          ; initializes LED display muxing

START:  

MAIN:
        MOV     AX, DGROUP              ; initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)
        MOV     AX, DGROUP              ; initialize the data segment
        MOV     DS, AX
        CALL    InitCS                  ; initialize chip select
        CALL    ClrIRQVectors           ; install illegalEventHandlers
        CALL    InitTimer0              ; initialize timer0
        CALL    InstallTimer0Handler    ; installs timer0 handler in vectortable
        CALL    InitINT2                ; initialize INT2
        CALL    InstallINT2Handler      ; installs INT2 handler in vector table
        
Reset:
        CLI                             ; disable interrupts because initializing
        CALL    InitDisplay             ; initialize display
        CALL    InitLEDMux              ; initialize display muxing
        CALL    KeypadScanInit          ; initialize keypad scanning
        CALL    InitSerial              ; initialize serial communication
        CALL    InitEventQueue          ; initialize EventQueue
        CALL    InitCritError           ; initialize CritError to FALSE
        MOV     StringBufferPos, 0      ; initially no chars in StringBuffer
        STI                             ; done with initializing, so interrupts
        
MainLoop:
        CALL    GetCritError            ; check if there's a critical error
        CMP     AX, FALSE
        JE      CheckEventQueue         ; if not, move on to check EventQueue
        ;JNE    CritialError            ; if so, send msg and reset software
        
CriticalError:
        MOV     AX, CRITICAL_ERROR_INDEX ; get crit error message to display
        MOV     BX, ERROR_STR_LEN
        MUL     BX
        MOV     BX, AX
        LEA     SI, RemoteErrorStrTable[BX]
        PUSH    CS
        POP     ES
        CALL    Display       ; display the message 
        JMP     Reset         ; need to reset the software because losing info
        
CheckEventQueue:
        CALL    EventQueueEmpty  ; check if there is an Event
        JZ      MainLoop         ; if not, go back to continue checking things
        ;JNZ    GetEvent         ; if so, get the event
        
GetEvent:
        CALL    DequeueEvent
        CMP     AH, SERIAL_CHAR_EVENT  ; check if it's a char sent from the
                                       ;   RoboTrike board
        JE      SaveSerialChar         ; if so, save it and possibly display
        ;JNE    CheckEventSerialError  ; if not, check if it's another type
        
CheckEventSerialError:
        CMP     AH, SERIAL_ERROR_EVENT 
        JE      DisplaySerialErrorStr  ; if serial error event, display error
        ;JNE    CheckEventKeypress
        
CheckEventKeypress:
        CMP     AH, KEYPRESS_EVENT  
        JE      ParseKeypress          ; if keypress event, map it to a command
        ;JNE    DisplayUnkownErrorStr  ; if none of the above types of events,
                                       ;   its an unknown error and we report it

DisplayUnkownErrorStr:
        MOV     AX, UNKNOWN_ERROR_INDEX  ; get unknown error string
        MOV     BX, ERROR_STR_LEN
        MUL     BX
        MOV     BX, AX
        LEA     SI, RemoteErrorStrTable[BX]
        PUSH    CS
        POP     ES 
        CALL    Display    ; display it
        JMP     MainLoop   ; go back to checking for more events and errors
        
DisplaySerialErrorStr:
        MOV     AH, 0              ; get error message for specific serial error
        MOV     BX, ERROR_STR_LEN
        MUL     BX
        MOV     BX, AX
        LEA     SI, RemoteErrorStrTable[BX]
        PUSH    CS
        POP     ES
        CALL    Display         ; display it
        JMP     MainLoop        ; go back to checking for more events and errors
        
SaveSerialChar:
        MOV     SI, OFFSET(StringBuffer) ; save the character from serial
        ADD     SI, StringBufferPos
        MOV     [SI], AL
        INC     StringBufferPos               ; inc pos for next character
	    CMP	    StringBufferPos, NUM_DIGITS+1 ; check if NUM_DIGIT chars have 
                                              ;   been saved
		JE      DisplaySerialString           ; if so, display the string to
                                              ;   prevent from saving characters
                                              ;   out of buffer capacity
        CMP     AL, ASCII_NULL                ; check if end of string
        JNE     MainLoop                      ; if not, go back to checking for
                                              ;   more errors and events
        ;JE     DisplaySerialString           ; if so, display the saved string
        
DisplaySerialString:
        MOV     SI, OFFSET(StringBuffer)      ; display the sting in the buffer
        ADD     SI, StringBufferPos
        MOV     BYTE PTR [SI], ASCII_NULL     ; make sure there's a NULL char at
                                              ;   the end so the function we 
                                              ;   call knows where the str ends
        MOV     SI, OFFSET(StringBuffer)
        PUSH    DS
        POP     ES
        CALL    Display                       
        MOV     StringBufferPos, 0            ; reset the buffer pos for next 
                                              ;   string        
        JMP     MainLoop                      ; go back to check for more events
                                              ;   and errors
        
ParseKeypress:
        CALL    ParseUserKeypress             ; map keypress to a command to 
                                              ;   send to the RoboTrike board
        JMP     MainLoop                      ; go back to check for more events
                                              ;   and errors


CODE    ENDS


; the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ; 240 words

TopOfStack      LABEL   WORD

STACK   ENDS

; the data segment
DATA    SEGMENT PUBLIC  'DATA'          

StringBuffer         DB       NUM_DIGITS+1    DUP (?) ; stores characters from
                                                      ;   serial until it is to
                                                      ;   be displayed
StringBufferPos      DW       ?     ; the next position of the StringBuffer to
                                    ;   be written to

DATA    ENDS

        END     START