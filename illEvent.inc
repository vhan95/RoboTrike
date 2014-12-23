;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               ILLEVENT.INC                                 ;
;                          illegal event constants                           ;
;                                 EE/CS 51                                   ;
;                               Include File                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for constants used illEvent.asm.
;
; Revision History:
;     11/03/14  Victor Han       initial revision

; General Definitions

FIRST_RESERVED_VEC      EQU     1       ;reserve vectors 1-3
LAST_RESERVED_VEC       EQU     3
NUM_IRQ_VECTORS         EQU     256     ;number of interrupt vectors

; Interrupt Controller Definitions

; Addresses
INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register

NonSpecEOI      EQU     08000H          ;Non-specific EOI command