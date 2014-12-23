        NAME    InitCS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    InitCS                                  ;
;                              Chip Select Functions                         ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specification and implementation for the
; InitCS function. It initializes the chip select unit, which makes possible
; most of the other things we do with the RoboTrike.
;
; Contents:
;     InitCS:             Initializes the Peripheral Chip Selects on the 80188.
;
; Revision History:
;    12/14/14  Victor Han       updated header title
;    11/03/14  Victor Han       initial revision

; local include files
$INCLUDE(initCS.inc)        ; includes definitions for address and corresponding
                            ;   values

CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP
		
		
; InitCS
;
; Description:       Initializes the Peripheral Chip Selects on the 80188.
;
; Operation:         Writes the initial values to the PACS and MPCS registers.
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
;    12/14/14  Victor Han     updated comments
;    11/01/14  Victor Han     initial revision

InitCS  PROC    NEAR
        Public  InitCS


        MOV     DX, PACSreg     ;setup to write to PACS register
        MOV     AX, PACSval
        OUT     DX, AL          ;write PACSval to PACS (base at 0, 3 wait states)

        MOV     DX, MPCSreg     ;setup to write to MPCS register
        MOV     AX, MPCSval
        OUT     DX, AL          ;write MPCSval to MPCS (I/O space, 3 wait states)


        RET                     ;done so return


InitCS  ENDP

CODE    ENDS



        END
