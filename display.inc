;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 display.INC                                ;
;                              Display Functions                             ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the display functions (display.asm).
;
; Revision History:
;    11/08/14  Victor Han   Initial Revision


; General Display Definitions

LEDDisplay      EQU     00H             ;display address
LEDDisplay14Seg EQU     08H

NUM_DIGITS      EQU     8               ;number of digits in the display

; Specific Digit/LED Definitions

LED_BLANK       EQU     00000000B       ;a blank LED's value

; ASCII Definitions

ASCII_NULL      EQU     0               ;the null character value