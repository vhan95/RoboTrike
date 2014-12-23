;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  tmrMtr.INC                                ;
;                          Timer for Motors Functions                        ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for constants for the timer for the motors
; functions. This includes definitions for the timer1 control and max count 
; registers, definitions for EOI's, a definition for an interrupt vector table 
; location, and a constant for how many counts should be counted before each
; interrupt is fired.
;
; Revision History:
;    11/22/14   Victor Han    initial revision

; Timer1 Register Definitions

; Timer1 register addresses
Tmr1Ctrl        EQU     0FF56H          ;address of Timer 1 Control Register
Tmr1MaxCntA     EQU     0FF52H          ;address of Timer 1 Max Count A Register
Tmr1Count       EQU     0FF50H          ;address of Timer 1 Count Register

; Timer1 Control Register Value
Tmr1CtrlVal     EQU     0E001H          ;value to write to Timer 1 Control Register
                                        ;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  enable interrupts
                                        ;----000000------  reserved
                                        ;---0------0-----  read only
                                        ;-----------0----  enable counting
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
FREQ            EQU     30

TMR1_MAX_CNT    EQU     600             ;count for FREQ * NUM_SPEEDS interrupts 
                                        ;  per sec  (assumes 18.432 MHz clock)
                                        ;  NUM_SPEEDS is defined in mtrLsr.inc

TimerEOI        EQU     00008H          ;Timer EOI command (same for all timers)


; Timer1 Interrupt Vector
Tmr1Vec         EQU     8               ;interrupt vector for Timer 1