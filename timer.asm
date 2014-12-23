        NAME    TIMER

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    TIMER                                   ;
;                               Timer Functions                              ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specifications and implementations for the
; Timer0EventHandler, InitTimer0, and InstallTimer0Handler functions. Together, 
; these functions initialize the timer and event handlers needed for outputting 
; a muxed LED display.
; Timer0EventHandler also calls the external function KeypadScan to get keypad
; input and debounce it.
;
; Contents:
;     Timer0EventHandler: Event handler for the timer interrupt that outputs
;                         the next segment pattern to the LED display.
;     InitTimer0:         Timer0 is initialized to generate an interrupt once
;                         every millisecond.
;     InstallTimer0Handler: Installs the event handler for the timer interrupt.
;
; Revision History:
;    11/10/14  Victor Han       updated Timer0EventHandler to also call 
;                               KeypadScan
;    11/08/14  Victor Han       wrote the assembly code and updated comments
;    11/03/14  Victor Han       initial revision

; local include files
$INCLUDE(timer.inc)             ; includes definitions for constants 

CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP

; external function declarations

        EXTRN   DisplayMux:NEAR       ;called by the Timer0EventHandler to 
                                      ;  display the next digit in the display
                                      ;  buffer
        EXTRN  KeypadScan:NEAR       ;called by the Timer0EventHandler to scan
                                      ;  for and debounce keypad input
		
		
; InitTimer0
;
; Description:       Initializes the 80188 Timer0. It is initialized to generate
;                    an interrupt every millisecond. The interrupt controller
;                    is also initialized to allow timer interrupts.
;
; Operation:         The appropriate value is written to the timer0 control
;                    register in the PCB. Also, the timer0 count register
;                    is reset to zero and the timer0 max count register is set
;                    such that the timer resets it count every millisecond. 
;                    Finally, the interrupt controller is setup to accept timer 
;                    interrupts and any pending interrupts are cleared by 
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
;    11/08/14  Victor Han      wrote the assembly code
;    11/03/14  Victor Han      initial revision

InitTimer0      PROC    NEAR
                PUBLIC  InitTimer0

                                ;initialize Timer #0 for 1ms interrupts
        MOV     DX, Tmr0Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr0MaxCntA    ;setup max count for one millisecond
        MOV     AX, COUNTS_PER_MS  
        OUT     DX, AL

        MOV     DX, Tmr0Ctrl       ;setup the control register, interrupts on
        MOV     AX, Tmr0CtrlVal
        OUT     DX, AL

                                  ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl  ;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI   ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL
		RET
		
InitTimer0       ENDP


; Timer0EventHandler
;
; Description:       This procedure is the event handler for the timer
;                    interrupt. It calls DisplayMux, which outputs the next 
;                    segment pattern to the LED display.
;
; Operation:         Pushes all the registers that this function and DisplayMux
;                    change, calls DisplayMux, sends an EOI, and finally pops 
;                    the pushed registers.

; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            A digit to the display (indirectly through DisplayMux).
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
;    11/10/14  Victor Han      now also calls KeypadScan
;    11/08/14  Victor Han      wrote the assembly code
;    11/03/14  Victor Han      initial revision

Timer0EventHandler       PROC    NEAR
                         Public  Timer0EventHandler

        PUSH    AX                      ;save the registers
        PUSH    BX                      ;Event Handlers should NEVER change
        PUSH    DX                      ;  any register values

		CALL    DisplayMux              ;display the next digit 
        CALL    KeypadScan              ;scan the keypad and debounce input

EndTimer0EventHandler:                  ;done taking care of the timer

        MOV     DX, INTCtrlrEOI         ;send the EOI to the interrupt controller
        MOV     AX, TimerEOI
        OUT     DX, AL

        POP     DX                      ;restore the registers
        POP     BX
        POP     AX

        IRET                            ;and return 
		
Timer0EventHandler       ENDP


; InstallTimer0Handler
;
; Description:       Installs the Timer0EventHandler for the timer0 interrupt.
;
; Operation:         Writes the address of the timer0 event handler to the
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
;    11/08/14  Victor Han      wrote the assembly code
;    11/03/14  Victor Han      initial revision

InstallTimer0Handler  PROC    NEAR
                      Public  InstallTimer0Handler

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(Timer0EventHandler)
        MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(Timer0EventHandler)


        RET                     ;all done, return

InstallTimer0Handler  ENDP


CODE    ENDS


        END