;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  timer.INC                                 ;
;                               Timer Functions                              ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for constants for the timer functions. This
; includes definitions for the timer0 control and max count registers, 
; definitions for EOI's, a definition for an interrupt vector table location,
; and a constant for how many clock counts are in a millisecond.
;
; Revision History:
;    11/08/14   Victor Han    initial revision

; Timer0 Register Definitions

; Timer0 register addresses
Tmr0Ctrl        EQU     0FF56H          ;address of Timer 0 Control Register
Tmr0MaxCntA     EQU     0FF52H          ;address of Timer 0 Max Count A Register
Tmr0Count       EQU     0FF50H          ;address of Timer 0 Count Register

; Timer0 Control Register Value
Tmr0CtrlVal     EQU     0E001H          ;value to write to Timer 0 Control Register
                                        ;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  enable interrupts
                                        ;----000000------  reserved
                                        ;---0------0-----  read only
                                        ;-----------0----  TMRIN0 is an enable
                                        ;------------00--  don't prescale
                                        ;--------------0-  single counter mode
                                        ;---------------1  continuous mode
										
; Interrupt Controller Definitions

; Addresses
INTCtrlrCtrl    EQU     0FF32H          ;address of interrupt controller for timer
INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register

; Register Values
INTCtrlrCVal    EQU     00001H          ;set priority for timers to 1 and enable
                                        ;000000000000----  reserved
                                        ;------------0---  enable timer interrupt
                                        ;-------------001  timer priority

; Timing Definitions

COUNTS_PER_MS   EQU     2304            ;number of timer counts per 1 ms (assumes 18.432 MHz clock)

TimerEOI        EQU     00008H          ;Timer EOI command (same for all timers)


; Timer0 Interrupt Vector
Tmr0Vec         EQU     8               ;interrupt vector for Timer 0