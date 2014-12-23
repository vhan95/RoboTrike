        NAME    illegalEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   illEvent                                 ;
;                            Illegal Event Functions                         ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specifications and implementations for the
; ClrIRQVectors, and IllegalEventHandler functions. Together, these functions 
; clear all non-reserved event handlers in the vector table.
;
; Contents:
;     ClrIRQVectors:      This function installs the IllegalEventHandler for all
;                         interrupt vectors in the interrupt vector table.
;     IllegalEventHandler:Event handler for illegal (uninitialized) interrupts 
;                         that does nothing.
;
; Revision History:
;    12/14/14  Victor Han       removed pseudocode
;    11/03/14  Victor Han       initial revision

; local include files
$INCLUDE(illEvent.inc)             ; includes definitions for constants 


CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP
		
; ClrIRQVectors
;
; Description:      This function installs the IllegalEventHandler for all
;                   interrupt vectors in the interrupt vector table. Note
;                   that all 256 vectors are initialized so the code must be
;                   located above 400H.  The initialization skips (does not
;                   initialize vectors) from vectors FIRST_RESERVED_VEC to
;                   LAST_RESERVED_VEC.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  CX    - vector counter.
;                   ES:SI - pointer to vector table.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   flags, AX, CX, SI, ES
; Stack Depth:      1 word
;
; Author:           Victor Han
; Last Modified:    11/03/14

ClrIRQVectors   PROC    NEAR
                Public  ClrIRQVectors

InitClrVectorLoop:              ;setup to store the same handler 256 times

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
        MOV     SI, 0           ;initialize SI to the first vector

        MOV     CX, 256         ;up to 256 vectors to initialize


ClrVectorLoop:                  ;loop clearing each vector
                                ;check if should store the vector
        CMP     SI, 4 * FIRST_RESERVED_VEC
        JB      DoStore         ;if before start of reserved field - store it
        CMP     SI, 4 * LAST_RESERVED_VEC
        JBE     DoneStore       ;if in the reserved vectors - don't store it
        ;JA     DoStore         ;otherwise past them - so do the store

DoStore:                        ;store the vector
        MOV     ES: WORD PTR [SI], OFFSET(IllegalEventHandler)
        MOV     ES: WORD PTR [SI + 2], SEG(IllegalEventHandler)

DoneStore:                      ;done storing the vector
        ADD     SI, 4           ;update pointer to next vector

        LOOP    ClrVectorLoop   ;loop until have cleared all vectors
        ;JMP    EndClrIRQVectors;and all done


EndClrIRQVectors:               ;all done, return
        RET
		
ClrIRQVectors   ENDP




; IllegalEventHandler
;
; Description:       This procedure is the event handler for illegal
;                    (uninitialized) interrupts. It does nothing - it just
;                    returns after sending a non-specific EOI.
;
; Operation:         Send a non-specific EOI and return.
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
; Registers Changed: None
; Stack Depth:       2 words
;
; Author:            Victor Han
; Last Modified:     11/03/14

IllegalEventHandler     PROC    NEAR
                        Public  IllegalEventHandler

        NOP                             ;do nothing (can set breakpoint here)

        PUSH    AX                      ;save the registers
        PUSH    DX

        MOV     DX, INTCtrlrEOI         ;send a non-sepecific EOI to the
        MOV     AX, NonSpecEOI          ;   interrupt controller to clear out
        OUT     DX, AL                  ;   the interrupt that got us here

        POP     DX                      ;restore the registers
        POP     AX

        IRET                            ;and return

IllegalEventHandler     ENDP

CODE    ENDS



        END
