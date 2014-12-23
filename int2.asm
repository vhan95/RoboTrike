        NAME    INT2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     INT2                                   ;
;                                INT2 Functions                              ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specifications and implementations for the
; InitINT2, and InstallINT2Handler functions. Together, these functions 
; initialize the INT2 interrupt needed for serial I/O.
;
; Contents:
;     InitINT2: Initializes the INT2 interrupt by writing to registers.
;     InstallINT2Handler: Installs the event handler for the INT2 interrupt.
;
; Revision History:
;    12/02/14  Victor Han       updated comments
;    11/24/14  Victor Han       initial revision

; local include files
$INCLUDE(int2.inc)             ; includes definitions for constants for setting
                               ;   up the INT2 interrupt                           

CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
        
        EXTRN   INT2EventHandler:NEAR ; function to install as the INT2 event 
                                      ;   handler
		
		
; InitINT2
;
; Description:       Initializes the INT2 interrupt.
;
; Operation:         The appropriate value is written to the INT2 control
;                    register. INT2 interrupts are unmasked, their priority
;                    is set to their default, and edge triggering is set. Any 
;                    pending interrupts are cleared by sending an EOI to the 
;                    interrupt controller.
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
; Registers Changed: AX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History: 
;    12/02/14  Victor Han      updated comments    
;    11/23/14  Victor Han      initial revision

InitINT2        PROC    NEAR
                PUBLIC  InitINT2
            
        MOV     DX, INT2_CTRL_REG ;write value to INT2 control register
        MOV     AX, INT2_CTRL_VAL
        OUT     DX, AL
        
        MOV     DX, INTCtrlrEOI   ;send a INT2 EOI (to clear out controller)
        MOV     AX, INT2_EOI
        OUT     DX, AL
		RET
        
InitINT2        ENDP


; InstallINT2Handler
;
; Description:       Installs the INT2EventHandler for the INT2 interrupt.
;
; Operation:         Writes the address of the INT2 event handler to the
;                    appropriate interrupt vector.
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
; Registers Changed: flags, AX, ES
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    11/23/14  Victor Han      initial revision

InstallINT2Handler  PROC    NEAR
                    Public  InstallINT2Handler

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * INT2Vec), OFFSET(INT2EventHandler)
        MOV     ES: WORD PTR (4 * INT2Vec + 2), SEG(INT2EventHandler)


        RET                     ;all done, return

InstallINT2Handler  ENDP


CODE    ENDS


        END