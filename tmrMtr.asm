        NAME    TIMERMOTOR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  TIMERMOTOR                                ;
;                               TMRMTR Functions                             ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specifications and implementations for the
; Timer1EventHandler, InitTimer1, and InstallTimer1Handler functions. Together, 
; these functions initialize timer1 and event handlers needed for running the
; motors at particular speeds. That is, they allow for PWMs when 
; Timer1EventHandler calls the external function PulseWidthMod. The laser is 
; also set on or off in PulseWidthMod.
;
; Contents:
;     Timer1EventHandler: Event handler for the timer1 interrupt that calls
;                         the external function PulseWidthMod to turn the
;                         motors on or off, thus using PWM to control them. The
;                         laser is also turned on or off at the same time.
;     InitTimer1:         Timer1 is initialized to generate FREQ x NUM_SPEEDS 
;                         interrupts per second.
;     InstallTimer1Handler: Installs the event handler for the timer1 interrupt.
;
; Revision History:
;    11/22/14  Victor Han       wrote the assembly code
;    11/17/14  Victor Han       initial revision

; local include files
$INCLUDE(tmrMtr.inc)             ; includes definitions for constants for timer1 
                                 ;   control and max count registers, definitions 
                                 ;   for EOI's, interrupt vector table location, 
                                 ;   and max count value
;$INCLUDE(mtrLsr.inc)            ; includes definition for NUM_SPEEDS. Mentioned
                                 ;   in comments both here and in tmrMtr.inc, 
                                 ;   but not explicitly used.                                 

CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
        
        EXTRN   PulseWidthMod:NEAR   ;called by the Timer1EventHandler to 
                                     ;  actually do the PWM as well as turn on
                                     ;  or off the laser.
		
		
; InitTimer1
;
; Description:       Initializes the 80188 Timer1. It is initialized to generate
;                    FREQ x NUM_SPEEDS interrupts per second. The interrupt 
;                    controller is also initialized to allow timer interrupts.
;
; Operation:         The appropriate value is written to the timer1 control
;                    register in the PCB. Also, the timer1 count register
;                    is reset to zero and the timer1 max count register is set
;                    such that the timer resets it FREQ x NUM_SPEEDS times per 
;                    sec. Finally, the interrupt controller is set-up to accept  
;                    timer interrupts and any pending interrupts are cleared by 
;                    sending a TimerEOI to the interrupt controller.
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
;    11/22/14  Victor Han      wrote the assembly code
;    11/17/14  Victor Han      initial revision

InitTimer1      PROC    NEAR
                PUBLIC  InitTimer1

                                ;initialize Timer #0 for 1ms interrupts
        MOV     DX, Tmr1Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr1MaxCntA    ;setup max count for FREQ x NUM_SPEEDS 
                                   ;  interrupts per second.
        MOV     AX, TMR1_MAX_CNT  
        OUT     DX, AL

        MOV     DX, Tmr1Ctrl       ;setup the control register, interrupts on
        MOV     AX, Tmr1CtrlVal
        OUT     DX, AL

                                  ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl  ;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI   ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL
		RET
		
InitTimer1       ENDP


; Timer1EventHandler
;
; Description:       This procedure is the event handler for the timer1
;                    interrupt. It calls PulseWidthMod, which takes care of
;                    the motor PWMs and turning the laser on or off.
;
; Operation:         Pushes all the registers, calls PulseWidthMod, sends an 
;                    EOI, and finally pops the pushed registers.

; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            Motor movement and laser light (indirectly through 
;                    PulseWidthMod).
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    11/22/14  Victor Han      wrote the assembly code
;    11/17/14  Victor Han      initial revision

Timer1EventHandler       PROC    NEAR
                         Public  Timer1EventHandler

        PUSHA                           ;save all register values because event
                                        ;  handlers should not change them

		CALL    PulseWidthMod           ;PWM the motors and turn the laser on/off 
   
EndTimer1EventHandler:                  ;done taking care of the motors and laser

        MOV     DX, INTCtrlrEOI         ;send the EOI to the interrupt controller
        MOV     AX, TimerEOI
        OUT     DX, AL

        POPA                            ;get all the registers back

        IRET                            ;and return 
		
Timer1EventHandler       ENDP


; InstallTimer1Handler
;
; Description:       Installs the Timer1EventHandler for the timer1 interrupt.
;
; Operation:         Writes the address of the timer1 event handler to the
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
;    11/22/14  Victor Han      wrote the assembly code
;    11/17/14  Victor Han      initial revision

InstallTimer1Handler  PROC    NEAR
                      Public  InstallTimer1Handler

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr1Vec), OFFSET(Timer1EventHandler)
        MOV     ES: WORD PTR (4 * Tmr1Vec + 2), SEG(Timer1EventHandler)


        RET                     ;all done, return

InstallTimer1Handler  ENDP


CODE    ENDS


        END