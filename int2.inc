;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  INT2.INC                                  ;
;                                INT2 Functions                              ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for constants for the INT2 functions. This
; includes definitions for the INT2 control register, EOI's, and interrupt vector 
; table location.
;
; Revision History:
;    12/02/14   Victor Han    updated comments
;    11/28/14   Victor Han    initial revision
										
; Interrupt Controller Definitions

; Addresses
INT2_CTRL_REG   EQU     0FF3CH   ;address of interrupt control register for INT2
INTCtrlrEOI     EQU     0FF22H   ;address of interrupt controller EOI register


; Register Values
INT2_CTRL_VAL    EQU     00005H         ;set priority for INT2, enable, and set
                                        ;edge triggering
                                        ;00000000000-----  reserved
                                        ;-----------0----  set edge triggering
                                        ;------------0---  enable INT2 interrupt
                                        ;-------------101  set INT2 priority

; INT2 Definitions

INT2_EOI        EQU     0000EH          ;INT2 EOI command


; Timer0 Interrupt Vector
INT2Vec         EQU     14              ;interrupt vector for INT2